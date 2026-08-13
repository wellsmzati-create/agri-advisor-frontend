import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';

/// Keeps farmer data alive across tabs so the mobile shell behaves like one
/// connected workspace instead of isolated screens.
class FarmerProvider extends ChangeNotifier {
  FarmerDashboard? _dashboard;
  bool _dashboardLoading = false;
  String? _dashboardError;

  List<Farm> _farms = [];
  bool _farmsLoading = false;
  String? _farmsError;

  List<Crop> _crops = [];
  bool _cropsLoading = false;
  String? _cropsError;

  List<CropRecommendation> _recommendations = [];
  bool _recsLoading = false;
  String? _recsError;

  List<FarmingTip> _tips = [];
  bool _tipsLoading = false;
  String? _tipsError;

  List<SeasonalNoticeItem> _seasonalNotices = [];
  bool _seasonalLoading = false;
  String? _seasonalError;

  List<AppNotification> _notifications = [];
  bool _notifLoading = false;
  String? _notifError;

  List<Conversation> _conversations = [];
  bool _convsLoading = false;
  String? _convsError;

  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _msgLoading = {};
  final Map<String, String?> _msgError = {};

  FarmerDashboard? get dashboard => _dashboard;
  bool get dashboardLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  List<Farm> get farms => _farms;
  bool get farmsLoading => _farmsLoading;
  String? get farmsError => _farmsError;

  List<Crop> get crops => _crops;
  bool get cropsLoading => _cropsLoading;
  String? get cropsError => _cropsError;

  List<CropRecommendation> get recommendations => _recommendations;
  bool get recsLoading => _recsLoading;
  String? get recsError => _recsError;

  List<FarmingTip> get tips => _tips;
  bool get tipsLoading => _tipsLoading;
  String? get tipsError => _tipsError;

  List<SeasonalNoticeItem> get seasonalNotices => _seasonalNotices;
  bool get seasonalLoading => _seasonalLoading;
  String? get seasonalError => _seasonalError;

  List<AppNotification> get notifications => _notifications;
  bool get notifLoading => _notifLoading;
  String? get notifError => _notifError;
  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;

  List<Conversation> get conversations => _conversations;
  bool get convsLoading => _convsLoading;
  String? get convsError => _convsError;

  Future<void> loadWorkspace({bool force = false}) async {
    await Future.wait([
      loadFarms(force: force),
      loadCrops(force: force),
      loadRecommendations(force: force),
      loadTips(force: force),
      loadSeasonalNotices(force: force),
      loadNotifications(force: force),
    ]);
  }

  Future<void> syncFromBackend({bool includeConversations = true}) async {
    var changed = false;

    try {
      _farms = await ApiService.farmerFarms();
      _farmsError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_farms.isEmpty) _farmsError = e.message;
    } catch (_) {
      if (_farms.isEmpty) _farmsError = 'Failed to load farms.';
    }

    try {
      _crops = await ApiService.farmerCrops();
      _cropsError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_crops.isEmpty) _cropsError = e.message;
    } catch (_) {
      if (_crops.isEmpty) _cropsError = 'Failed to load crop library.';
    }

    try {
      _recommendations = await ApiService.farmerRecommendations();
      _recsError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_recommendations.isEmpty) _recsError = e.message;
    } catch (_) {
      if (_recommendations.isEmpty) _recsError = 'Failed to load recommendations.';
    }

    try {
      _tips = await ApiService.farmerTips();
      _tipsError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_tips.isEmpty) _tipsError = e.message;
    } catch (_) {
      if (_tips.isEmpty) _tipsError = 'Failed to load tips.';
    }

    try {
      _seasonalNotices = await ApiService.farmerSeasonalNotices();
      _seasonalError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_seasonalNotices.isEmpty) _seasonalError = e.message;
    } catch (_) {
      if (_seasonalNotices.isEmpty) {
        _seasonalError = 'Failed to load seasonal notices.';
      }
    }

    try {
      _notifications = await ApiService.farmerNotifications();
      _notifError = null;
      changed = true;
    } on ApiException catch (e) {
      if (_notifications.isEmpty) _notifError = e.message;
    } catch (_) {
      if (_notifications.isEmpty) _notifError = 'Failed to load notifications.';
    }

    if (includeConversations) {
      try {
        _conversations = await ApiService.farmerConversations()
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
        _convsError = null;
        changed = true;
      } on ApiException catch (e) {
        if (_conversations.isEmpty) _convsError = e.message;
      } catch (_) {
        if (_conversations.isEmpty) {
          _convsError = 'Failed to load conversations.';
        }
      }
    }

    if (changed) {
      _dashboard = FarmerDashboard(
        farms: _farms,
        activeRecommendations: _recommendations
            .where((rec) => rec.status != 'archived')
            .toList(),
        unreadNotifications:
            _notifications.where((notification) => !notification.isRead).toList(),
        recentTips: _tips.take(6).toList(),
        seasonalNotices: _seasonalNotices.take(4).toList(),
      );
      _dashboardError = null;
      notifyListeners();
    }
  }

  Future<void> loadDashboard({bool force = false}) async {
    if (_dashboard != null && !force) return;
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await ApiService.farmerDashboard();
    } on ApiException catch (e) {
      _dashboardError = e.message;
    } catch (_) {
      _dashboardError = 'Failed to load dashboard.';
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFarms({bool force = false}) async {
    if (_farms.isNotEmpty && !force) return;
    _farmsLoading = true;
    _farmsError = null;
    notifyListeners();
    try {
      _farms = await ApiService.farmerFarms();
    } on ApiException catch (e) {
      _farmsError = e.message;
    } catch (_) {
      _farmsError = 'Failed to load farms.';
    } finally {
      _farmsLoading = false;
      notifyListeners();
    }
  }

  Future<Farm> createFarm(Map<String, dynamic> data) async {
    final created = await ApiService.createFarmerFarm(data);
    _farms = [created, ..._farms.where((farm) => farm.id != created.id)];
    notifyListeners();
    await _refreshDashboardIfLoaded();
    return created;
  }

  Future<Farm> updateFarm(String farmId, Map<String, dynamic> data) async {
    final updated = await ApiService.updateFarmerFarm(farmId, data);
    _farms = _farms
        .map((farm) => farm.id == farmId ? updated : farm)
        .toList();
    notifyListeners();
    await _refreshDashboardIfLoaded();
    return updated;
  }

  Future<void> deleteFarm(String farmId) async {
    await ApiService.deleteFarmerFarm(farmId);
    _farms = _farms.where((farm) => farm.id != farmId).toList();
    notifyListeners();
    await _refreshDashboardIfLoaded();
  }

  Future<void> loadCrops({bool force = false}) async {
    if (_crops.isNotEmpty && !force) return;
    _cropsLoading = true;
    _cropsError = null;
    notifyListeners();
    try {
      _crops = await ApiService.farmerCrops();
    } on ApiException catch (e) {
      _cropsError = e.message;
    } catch (_) {
      _cropsError = 'Failed to load crop library.';
    } finally {
      _cropsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations({bool force = false}) async {
    if (_recommendations.isNotEmpty && !force) return;
    _recsLoading = true;
    _recsError = null;
    notifyListeners();
    try {
      _recommendations = await ApiService.farmerRecommendations();
    } on ApiException catch (e) {
      _recsError = e.message;
    } catch (_) {
      _recsError = 'Failed to load recommendations.';
    } finally {
      _recsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTips({bool force = false}) async {
    if (_tips.isNotEmpty && !force) return;
    _tipsLoading = true;
    _tipsError = null;
    notifyListeners();
    try {
      _tips = await ApiService.farmerTips();
    } on ApiException catch (e) {
      _tipsError = e.message;
    } catch (_) {
      _tipsError = 'Failed to load tips.';
    } finally {
      _tipsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSeasonalNotices({bool force = false}) async {
    if (_seasonalNotices.isNotEmpty && !force) return;
    _seasonalLoading = true;
    _seasonalError = null;
    notifyListeners();
    try {
      _seasonalNotices = await ApiService.farmerSeasonalNotices();
    } on ApiException catch (e) {
      _seasonalError = e.message;
    } catch (_) {
      _seasonalError = 'Failed to load seasonal notices.';
    } finally {
      _seasonalLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications({bool force = false}) async {
    if (_notifications.isNotEmpty && !force) return;
    _notifLoading = true;
    _notifError = null;
    notifyListeners();
    try {
      _notifications = await ApiService.farmerNotifications();
    } on ApiException catch (e) {
      _notifError = e.message;
    } catch (_) {
      _notifError = 'Failed to load notifications.';
    } finally {
      _notifLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      _notifications = _notifications
          .map((notification) => notification.id == id
              ? notification.copyWith(isRead: true)
              : notification)
          .toList();
      if (_dashboard != null) {
        _dashboard = FarmerDashboard(
          farms: _dashboard!.farms,
          activeRecommendations: _dashboard!.activeRecommendations,
          unreadNotifications: _notifications
              .where((notification) => !notification.isRead)
              .toList(),
          recentTips: _dashboard!.recentTips,
          seasonalNotices: _dashboard!.seasonalNotices,
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final unread = _notifications.where((notification) => !notification.isRead).toList();
    await Future.wait(unread.map((notification) => markRead(notification.id)));
  }

  Future<void> loadConversations({bool force = false}) async {
    if (_conversations.isNotEmpty && !force) return;
    _convsLoading = true;
    _convsError = null;
    notifyListeners();
    try {
      _conversations = await ApiService.farmerConversations()
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    } on ApiException catch (e) {
      _convsError = e.message;
    } catch (_) {
      _convsError = 'Failed to load conversations.';
    } finally {
      _convsLoading = false;
      notifyListeners();
    }
  }

  List<ChatMessage> messagesFor(String conversationId) =>
      _messages[conversationId] ?? const [];

  bool msgLoading(String conversationId) => _msgLoading[conversationId] ?? false;

  String? msgError(String conversationId) => _msgError[conversationId];

  Future<void> refreshConversation(String conversationId) async {
    try {
      final messages = await ApiService.conversationMessages(conversationId);
      _messages[conversationId] = messages;
      _conversations = _conversations
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(
                    unreadCount: 0,
                    lastMessage: messages.isNotEmpty ? messages.last : null,
                    updatedAt: messages.isNotEmpty
                        ? messages.last.timestamp
                        : conversation.updatedAt,
                  )
                : conversation,
          )
          .toList()
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMessages(String conversationId, {bool force = false}) async {
    if ((_messages[conversationId]?.isNotEmpty ?? false) && !force) return;
    _msgLoading[conversationId] = true;
    _msgError[conversationId] = null;
    notifyListeners();
    try {
      final messages = await ApiService.conversationMessages(conversationId);
      _messages[conversationId] = messages;
      _conversations = _conversations
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(
                    unreadCount: 0,
                    lastMessage: messages.isNotEmpty ? messages.last : null,
                    updatedAt: messages.isNotEmpty
                        ? messages.last.timestamp
                        : conversation.updatedAt,
                  )
                : conversation,
          )
          .toList();
    } on ApiException catch (e) {
      _msgError[conversationId] = e.message;
    } catch (_) {
      _msgError[conversationId] = 'Failed to load messages.';
    } finally {
      _msgLoading[conversationId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final optimistic = ChatMessage(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: '',
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
      isFromFarmer: true,
    );
    _messages[conversationId] = [...messagesFor(conversationId), optimistic];
    notifyListeners();

    try {
      final sent = await ApiService.sendMessage(conversationId, text);
      final messages = List<ChatMessage>.from(_messages[conversationId] ?? const []);
      final index = messages.indexWhere((message) => message.id == optimistic.id);
      if (index != -1) {
        messages[index] = sent;
        _messages[conversationId] = messages;
      }
      _conversations = _conversations
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(
                    unreadCount: 0,
                    lastMessage: sent,
                    updatedAt: sent.timestamp,
                  )
                : conversation,
          )
          .toList()
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    } catch (_) {
      _messages[conversationId] = (_messages[conversationId] ?? const [])
          .where((message) => message.id != optimistic.id)
          .toList();
    }
    notifyListeners();
  }

  void reset() {
    _dashboard = null;
    _dashboardError = null;
    _dashboardLoading = false;

    _farms = [];
    _farmsError = null;
    _farmsLoading = false;

    _crops = [];
    _cropsError = null;
    _cropsLoading = false;

    _recommendations = [];
    _recsError = null;
    _recsLoading = false;

    _tips = [];
    _tipsError = null;
    _tipsLoading = false;

    _seasonalNotices = [];
    _seasonalError = null;
    _seasonalLoading = false;

    _notifications = [];
    _notifError = null;
    _notifLoading = false;

    _conversations = [];
    _convsError = null;
    _convsLoading = false;

    _messages.clear();
    _msgLoading.clear();
    _msgError.clear();
    notifyListeners();
  }

  Future<void> _refreshDashboardIfLoaded() async {
    if (_dashboard != null) {
      await loadDashboard(force: true);
    }
  }
}
