import '../models/models.dart';
import 'api_client.dart';
import 'token_storage.dart';

Map<String, dynamic>? _serviceMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<Map<String, dynamic>> _serviceMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
}

String _serviceString(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _serviceInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.toInt() ??
      fallback;
}

double _serviceDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String _capitalizedStatus(String value) {
  if (value.isEmpty) return 'Active';
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

/// Repository layer. Screens never call ApiClient directly.
class ApiService {
  ApiService._();

  static final _c = ApiClient.instance;

  static Future<({User user, String token})> login(
    String email,
    String password,
  ) async {
    final body = await _c.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    final token = body['token'] as String;
    await TokenStorage.instance.write(token);
    return (
      user: User.fromJson(body['user'] as Map<String, dynamic>),
      token: token,
    );
  }

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String farmName,
    required String farmLocation,
    required int farmSizeAcres,
  }) async {
    final body = await _c.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'farm_name': farmName,
        'farm_location': farmLocation,
        'farm_size_acres': farmSizeAcres,
      },
      auth: false,
    );
    await TokenStorage.instance.write(body['token'] as String);
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  static Future<User> me() async {
    final body = await _c.get('/auth/me');
    return User.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> logout() async {
    try {
      await _c.post('/auth/logout');
    } finally {
      await TokenStorage.instance.clear();
    }
  }

  static Future<FarmerDashboard> farmerDashboard() async {
    final results = await Future.wait([
      farmerFarms(),
      farmerRecommendations(),
      farmerNotifications(),
      farmerTips(),
      farmerSeasonalNotices(),
    ]);

    final farms = results[0] as List<Farm>;
    final recommendations = results[1] as List<CropRecommendation>;
    final notifications = results[2] as List<AppNotification>;
    final tips = results[3] as List<FarmingTip>;
    final seasonalNotices = results[4] as List<SeasonalNoticeItem>;

    return FarmerDashboard(
      farms: farms,
      activeRecommendations: recommendations
          .where((rec) => rec.status != 'archived')
          .toList(),
      unreadNotifications: notifications.where((n) => !n.isRead).toList(),
      recentTips: tips.take(6).toList(),
      seasonalNotices: seasonalNotices.take(4).toList(),
    );
  }

  static Future<List<Farm>> farmerFarms() async {
    final body = await _c.get('/farmer/farms');
    return ApiClient.asList(body).map(Farm.fromJson).toList();
  }

  static Future<Farm> createFarmerFarm(Map<String, dynamic> data) async {
    final body = await _c.post('/farmer/farms', body: data);
    return Farm.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<Farm> updateFarmerFarm(
    String farmId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/farmer/farms/$farmId', body: data);
    return Farm.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> deleteFarmerFarm(String farmId) =>
      _c.delete('/farmer/farms/$farmId');

  static Future<List<Crop>> farmerCrops() async {
    final body = await _c.get('/farmer/crops');
    return ApiClient.asList(body).map(Crop.fromJson).toList();
  }

  static Future<List<CropRecommendation>> farmerRecommendations() async {
    final body = await _c.get('/farmer/recommendations');
    return ApiClient.asList(body).map(CropRecommendation.fromJson).toList();
  }

  static Future<List<FarmingTip>> farmerTips() async {
    final body = await _c.get('/farmer/tips');
    return ApiClient.asList(body).map(FarmingTip.fromJson).toList();
  }

  static Future<List<SeasonalNoticeItem>> farmerSeasonalNotices() async {
    final body = await _c.get('/farmer/seasonal-notices');
    return ApiClient.asList(body).map(SeasonalNoticeItem.fromJson).toList();
  }

  static Future<List<AppNotification>> farmerNotifications() async {
    final body = await _c.get('/farmer/notifications');
    return ApiClient.asList(body).map(AppNotification.fromJson).toList();
  }

  static Future<void> markNotificationRead(String id) =>
      _c.post('/farmer/notifications/$id/read');

  static Future<List<Conversation>> farmerConversations() async {
    final body = await _c.get('/farmer/conversations');
    return ApiClient.asList(body).map(Conversation.fromJson).toList();
  }

  static Future<List<ChatMessage>> conversationMessages(String id) async {
    final body = await _c.get('/farmer/conversations/$id/messages');
    return ApiClient.asList(body).map(ChatMessage.fromJson).toList();
  }

  static Future<ChatMessage> sendMessage(
    String conversationId,
    String message,
  ) async {
    final body = await _c.post(
      '/farmer/conversations/$conversationId/messages',
      body: {'message': message},
    );
    return ChatMessage.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<List<Conversation>> advisorConversations() async {
    final body = await _c.get('/advisor/conversations');
    return ApiClient.asList(body).map(Conversation.fromJson).toList();
  }

  static Future<Conversation> ensureAdvisorConversation(
    String farmerProfileId,
  ) async {
    final body = await _c.post('/advisor/farmers/$farmerProfileId/conversation');
    return Conversation.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<List<ChatMessage>> advisorConversationMessages(String id) async {
    final body = await _c.get('/advisor/conversations/$id/messages');
    return ApiClient.asList(body).map(ChatMessage.fromJson).toList();
  }

  static Future<ChatMessage> advisorSendMessage(
    String conversationId,
    String message,
  ) async {
    final body = await _c.post(
      '/advisor/conversations/$conversationId/messages',
      body: {'message': message},
    );
    return ChatMessage.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<Map<String, dynamic>> advisorDashboard() async {
    final body = await _c.get('/advisor/dashboard');
    return _serviceMap(body['data']) ?? body;
  }

  static Future<List<CropRecommendation>> advisorRecommendations() async {
    final body = await _c.get('/advisor/recommendations');
    return ApiClient.asList(body).map(CropRecommendation.fromJson).toList();
  }

  static Future<CropRecommendation> createRecommendation({
    required String farmId,
    required String season,
    List<String> currentCrops = const [],
    String notes = '',
  }) async {
    final body = await _c.post(
      '/advisor/recommendations',
      body: {
        'farm_id': farmId,
        'season': season,
        'current_crops': currentCrops,
        'notes': notes,
      },
    );
    return CropRecommendation.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<CropRecommendation> getRecommendation(String id) async {
    final body = await _c.get('/advisor/recommendations/$id');
    return CropRecommendation.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<List<Map<String, dynamic>>> advisorFarmers() async {
    final body = await _c.get('/advisor/farmers');
    return ApiClient.asList(body).map(_normalizeAdvisorFarmer).toList();
  }

  static Future<Map<String, dynamic>> advisorFarmer(String id) async {
    final body = await _c.get('/advisor/farmers/$id');
    return _normalizeAdvisorFarmer(_serviceMap(body['data']) ?? body);
  }

  static Future<List<FarmingTip>> advisorTips() async {
    final body = await _c.get('/advisor/tips');
    return ApiClient.asList(body).map(FarmingTip.fromJson).toList();
  }

  static Future<Farm> createAdvisorFarm(
    String farmerProfileId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.post('/advisor/farmers/$farmerProfileId/farms', body: data);
    return Farm.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<Farm> updateAdvisorFarm(
    String farmId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/advisor/farms/$farmId', body: data);
    return Farm.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> deleteAdvisorFarm(String farmId) =>
      _c.delete('/advisor/farms/$farmId');

  static Future<FarmRecordEntry> createAdvisorFarmRecord(
    String farmId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.post('/advisor/farms/$farmId/records', body: data);
    return FarmRecordEntry.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<FarmRecordEntry> updateAdvisorFarmRecord(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/advisor/farm-records/$recordId', body: data);
    return FarmRecordEntry.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<List<SeasonalNoticeItem>> advisorSeasonalNotices() async {
    final body = await _c.get('/advisor/seasonal-notices');
    return ApiClient.asList(body).map(SeasonalNoticeItem.fromJson).toList();
  }

  static Future<SeasonalNoticeItem> createAdvisorSeasonalNotice(
    Map<String, dynamic> data,
  ) async {
    final body = await _c.post('/advisor/seasonal-notices', body: data);
    return SeasonalNoticeItem.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<SeasonalNoticeItem> updateAdvisorSeasonalNotice(
    String noticeId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/advisor/seasonal-notices/$noticeId', body: data);
    return SeasonalNoticeItem.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> deleteAdvisorSeasonalNotice(String noticeId) =>
      _c.delete('/advisor/seasonal-notices/$noticeId');

  static Future<List<AppNotification>> advisorNotifications() async {
    final body = await _c.get('/advisor/notifications');
    return ApiClient.asList(body).map(AppNotification.fromJson).toList();
  }

  static Future<void> markAdvisorNotificationRead(String id) =>
      _c.post('/advisor/notifications/$id/read');

  static Future<int> broadcastAdvisorNotification(
    Map<String, dynamic> data,
  ) async {
    final body = await _c.post('/advisor/notifications/broadcast', body: data);
    return (body['sent'] as num?)?.toInt() ?? 0;
  }

  static Future<List<Crop>> advisorCrops() async {
    final body = await _c.get('/advisor/crops');
    return ApiClient.asList(body).map(Crop.fromJson).toList();
  }

  static Future<Crop> createAdvisorCrop(Map<String, dynamic> data) async {
    final body = await _c.post('/advisor/crops', body: data);
    return Crop.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<Crop> updateAdvisorCrop(
    String cropId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/advisor/crops/$cropId', body: data);
    return Crop.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> deleteAdvisorCrop(String cropId) =>
      _c.delete('/advisor/crops/$cropId');

  static Future<FarmingTip> createAdvisorTip(Map<String, dynamic> data) async {
    final body = await _c.post('/advisor/tips', body: data);
    return FarmingTip.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<FarmingTip> updateAdvisorTip(
    String tipId,
    Map<String, dynamic> data,
  ) async {
    final body = await _c.put('/advisor/tips/$tipId', body: data);
    return FarmingTip.fromJson(body['data'] as Map<String, dynamic>? ?? body);
  }

  static Future<void> deleteAdvisorTip(String tipId) =>
      _c.delete('/advisor/tips/$tipId');

  static Future<String?> getToken() => TokenStorage.instance.read();

  static Future<void> clearToken() => TokenStorage.instance.clear();

  static Map<String, dynamic> _normalizeAdvisorFarmer(
    Map<String, dynamic> raw,
  ) {
    final user = _serviceMap(raw['user']) ?? const {};
    final farms = _serviceMapList(raw['farms']);
    final recommendations = _serviceMapList(raw['recommendations']);
    final primaryFarm =
        farms.isNotEmpty ? farms.first : const <String, dynamic>{};
    final rawStatus =
        _serviceString(user['status'], _serviceString(raw['status']));

    return {
      'id': _serviceString(raw['id']),
      'name': _serviceString(
        user['name'],
        _serviceString(raw['name'], 'Farmer'),
      ),
      'location': _serviceString(
        primaryFarm['location_text'],
        _serviceString(
          primaryFarm['location'],
          _serviceString(raw['location']),
        ),
      ),
      'phone': _serviceString(raw['phone']),
      'email': _serviceString(user['email'], _serviceString(raw['email'])),
      'soil_type': _serviceString(
        primaryFarm['soil_type'],
        _serviceString(raw['soil_type']),
      ),
      'status': rawStatus.isEmpty ? 'Active' : _capitalizedStatus(rawStatus),
      'farm_size_acres': _serviceInt(
        raw['farm_size_acres'],
        _serviceInt(primaryFarm['size_acres']),
      ),
      'recommendation_count':
          _serviceInt(raw['recommendation_count'], recommendations.length),
      'registered_at': user['created_at'] ?? raw['created_at'],
      'last_activity': user['updated_at'] ?? raw['updated_at'],
      'lat': _serviceDouble(primaryFarm['lat'], _serviceDouble(raw['lat'])),
      'lng': _serviceDouble(primaryFarm['lng'], _serviceDouble(raw['lng'])),
      'farm_id': _serviceString(primaryFarm['id']),
      'farms': farms,
      'reports': _serviceMapList(raw['reports']),
      'recommendations': recommendations,
    };
  }
}
