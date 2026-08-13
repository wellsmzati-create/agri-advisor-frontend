Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

String _asString(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _asDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

List<String> _asParagraphList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String) {
    return value
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim().replaceFirst(RegExp(r'^[-*0-9.\s]+'), ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return const [];
}

String _initialsFor(String value) => value
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0])
    .join()
    .toUpperCase();

String _emojiForCropName(String value) {
  final name = value.toLowerCase();
  if (name.contains('maize') || name.contains('corn')) return '🌽';
  if (name.contains('rice')) return '🌾';
  if (name.contains('tomato')) return '🍅';
  if (name.contains('cassava')) return '🥔';
  if (name.contains('banana') || name.contains('plantain')) return '🍌';
  if (name.contains('groundnut') || name.contains('peanut')) return '🥜';
  return '🌱';
}

String _advisorNameFromRecommendation(Map<String, dynamic> json) {
  final direct = _asString(json['advisor_name']) != ''
      ? _asString(json['advisor_name'])
      : _asString(json['advisorName']);
  if (direct.isNotEmpty) return direct;

  final advisorProfile =
      _asMap(json['advisor_profile']) ?? _asMap(json['advisorProfile']);
  final advisorUser = _asMap(advisorProfile?['user']);
  final nestedName = _asString(advisorUser?['name']);
  if (nestedName.isNotEmpty) return nestedName;

  final organization = _asString(advisorProfile?['organization']);
  return organization.isNotEmpty ? organization : 'Advisor';
}

String _advisorNameFromFarm(Map<String, dynamic> json) {
  final advisorProfile =
      _asMap(json['advisor_profile']) ?? _asMap(json['advisorProfile']);
  final advisorUser = _asMap(advisorProfile?['user']);
  final advisorName = _asString(advisorUser?['name']);
  if (advisorName.isNotEmpty) return advisorName;

  return _asString(advisorProfile?['organization']);
}

String _extensionPlanningAreaNameFromFarm(Map<String, dynamic> json) {
  final area =
      _asMap(json['extension_planning_area']) ??
      _asMap(json['extensionPlanningArea']);

  return _asString(area?['name']);
}

Map<String, dynamic>? _pickUserByRole(Map<String, dynamic> json, String role) {
  final users = _asMapList(json['users']);
  for (final user in users) {
    if (_asString(user['role']).toLowerCase() == role.toLowerCase()) {
      return user;
    }
  }
  return users.isNotEmpty ? users.first : null;
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic>? farmerProfile;
  final Map<String, dynamic>? advisorProfile;
  final Map<String, dynamic>? epaProfile;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.farmerProfile,
    this.advisorProfile,
    this.epaProfile,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: _asString(j['id']),
        name: _asString(j['name'], 'User'),
        email: _asString(j['email']),
        role: _asString(j['role'], 'farmer'),
        farmerProfile:
            _asMap(j['farmerProfile']) ?? _asMap(j['farmer_profile']),
        advisorProfile:
            _asMap(j['advisorProfile']) ?? _asMap(j['advisor_profile']),
        epaProfile: _asMap(j['epaProfile']) ?? _asMap(j['epa_profile']),
      );
}

class Farmer {
  final String id;
  final String name;
  final String location;
  final String phone;
  final String email;
  final String avatarInitials;
  final int farmSizeAcres;

  const Farmer({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
    required this.avatarInitials,
    required this.farmSizeAcres,
  });

  factory Farmer.fromJson(Map<String, dynamic> j) => Farmer(
        id: _asString(j['id']),
        name: _asString(j['name'], 'Farmer'),
        location: _asString(j['location']),
        phone: _asString(j['phone']),
        email: _asString(j['email']),
        avatarInitials: _initialsFor(_asString(j['name'], 'User')),
        farmSizeAcres: (j['farm_size_acres'] as num?)?.toInt() ?? 0,
      );
}

class Farm {
  final String id;
  final String name;
  final String location;
  final String soilType;
  final String advisorName;
  final String extensionPlanningAreaName;
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String rainfall;
  final String temperature;
  final String notes;
  final double sizeAcres;
  final double lat;
  final double lng;
  final double soilPh;

  const Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.soilType,
    this.advisorName = '',
    this.extensionPlanningAreaName = '',
    this.nitrogen = '',
    this.phosphorus = '',
    this.potassium = '',
    this.rainfall = '',
    this.temperature = '',
    this.notes = '',
    required this.sizeAcres,
    this.lat = 0,
    this.lng = 0,
    this.soilPh = 0,
  });

  factory Farm.fromJson(Map<String, dynamic> j) => Farm(
        id: _asString(j['id']),
        name: _asString(j['name'], 'Farm'),
        location: _asString(j['location'], _asString(j['location_text'])),
        soilType: _asString(j['soil_type']),
        advisorName: _advisorNameFromFarm(j),
        extensionPlanningAreaName: _extensionPlanningAreaNameFromFarm(j),
        nitrogen: _asString(j['nitrogen']),
        phosphorus: _asString(j['phosphorus']),
        potassium: _asString(j['potassium']),
        rainfall: _asString(j['rainfall']),
        temperature: _asString(j['temperature']),
        notes: _asString(j['notes']),
        sizeAcres: _asDouble(j['size_acres']),
        lat: _asDouble(j['lat']),
        lng: _asDouble(j['lng']),
        soilPh: _asDouble(j['soil_ph']),
      );
}

class CropRecommendation {
  final String id;
  final String cropName;
  final String advisorName;
  final String reason;
  final String soilType;
  final String season;
  final String rainfall;
  final List<String> steps;
  final DateTime date;
  final String status;

  const CropRecommendation({
    required this.id,
    required this.cropName,
    required this.advisorName,
    required this.reason,
    required this.soilType,
    required this.season,
    required this.rainfall,
    required this.steps,
    required this.date,
    required this.status,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> j) =>
      CropRecommendation(
        id: _asString(j['id']),
        cropName: _asString(j['crop_name'], _asString(j['cropName'])),
        advisorName: _advisorNameFromRecommendation(j),
        reason: _asString(j['reason']),
        soilType: _asString(j['soil_type'], _asString(j['soilType'])),
        season: _asString(j['season']),
        rainfall: _asString(j['rainfall']),
        steps: _asStringList(j['steps']),
        date: _asDate(j['recommended_at'] ?? j['created_at']),
        status: _asString(j['status'], 'pending'),
      );

  bool get isPublished => status == 'published' || status == 'Active';
}

class Crop {
  final String id;
  final String name;
  final String category;
  final String description;
  final String season;
  final String status;
  final String soilType;
  final String climate;
  final String imageEmoji;
  final int growthDays;
  final List<String> plantingSteps;
  final List<String> maintenanceTips;
  final String rainfall;
  final String temperature;

  const Crop({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.season,
    required this.status,
    required this.soilType,
    required this.climate,
    required this.imageEmoji,
    required this.growthDays,
    required this.plantingSteps,
    required this.maintenanceTips,
    required this.rainfall,
    required this.temperature,
  });

  factory Crop.fromJson(Map<String, dynamic> j) => Crop(
        id: _asString(j['id']),
        name: _asString(j['name'], 'Crop'),
        category: _asString(j['category']),
        description: _asString(j['description']),
        season: _asString(j['season']),
        status: _asString(j['status'], 'published'),
        soilType: _asString(
          j['soil_type'],
          _asString(j['soil_requirements']),
        ),
        climate: _asString(
          j['climate'],
          _asString(j['climate_requirements']),
        ),
        imageEmoji: _asString(
          j['image_emoji'],
          _emojiForCropName(_asString(j['name'])),
        ),
        growthDays: (j['growth_days'] as num?)?.toInt() ?? 0,
        plantingSteps: _asParagraphList(j['planting_steps']),
        maintenanceTips: _asParagraphList(j['maintenance_tips']),
        rainfall: _asString(j['rainfall'], _asString(j['season'])),
        temperature: _asString(
          j['temperature'],
          _asString(j['climate_requirements']),
        ),
      );
}

class FarmingTip {
  final String id;
  final String title;
  final String content;
  final String category;
  final String season;
  final String status;
  final String authorName;
  final DateTime publishedAt;

  const FarmingTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.season,
    required this.status,
    required this.authorName,
    required this.publishedAt,
  });

  factory FarmingTip.fromJson(Map<String, dynamic> j) => FarmingTip(
        id: _asString(j['id']),
        title: _asString(j['title']),
        content: _asString(j['content']),
        category: _asString(j['category']),
        season: _asString(j['season']),
        status: _asString(j['status'], 'published'),
        authorName:
            _asString(j['author_name'], _asString(j['authorName'], 'Advisor')),
        publishedAt: _asDate(j['published_at']),
      );
}

class FarmRecordEntry {
  final String id;
  final String farmId;
  final String soilType;
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String rainfall;
  final String temperature;
  final String notes;
  final double soilPh;
  final DateTime recordedAt;

  const FarmRecordEntry({
    required this.id,
    required this.farmId,
    required this.soilType,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.rainfall,
    required this.temperature,
    required this.notes,
    required this.soilPh,
    required this.recordedAt,
  });

  factory FarmRecordEntry.fromJson(Map<String, dynamic> j) => FarmRecordEntry(
        id: _asString(j['id']),
        farmId: _asString(j['farm_id']),
        soilType: _asString(j['soil_type']),
        nitrogen: _asString(j['nitrogen']),
        phosphorus: _asString(j['phosphorus']),
        potassium: _asString(j['potassium']),
        rainfall: _asString(j['rainfall']),
        temperature: _asString(j['temperature']),
        notes: _asString(j['notes']),
        soilPh: _asDouble(j['soil_ph']),
        recordedAt: _asDate(j['recorded_at'] ?? j['created_at']),
      );
}

class SeasonalNoticeItem {
  final String id;
  final String title;
  final String category;
  final String season;
  final String summary;
  final String status;
  final String authorName;
  final String targetRegion;
  final DateTime publishedAt;

  const SeasonalNoticeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.season,
    required this.summary,
    required this.status,
    required this.authorName,
    required this.targetRegion,
    required this.publishedAt,
  });

  factory SeasonalNoticeItem.fromJson(Map<String, dynamic> j) =>
      SeasonalNoticeItem(
        id: _asString(j['id']),
        title: _asString(j['title']),
        category: _asString(j['category'], 'Seasonal Advisory'),
        season: _asString(j['season']),
        summary: _asString(j['summary']),
        status: _asString(j['status'], 'published'),
        authorName:
            _asString(j['author_name'], _asString(j['authorName'], 'Advisor')),
        targetRegion: _asString(
          j['target_region'],
          _asString(j['targetRegion'], 'All Regions'),
        ),
        publishedAt: _asDate(j['published_at'] ?? j['created_at']),
      );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isFromFarmer;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isFromFarmer,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: _asString(j['id']),
        senderId: _asString(
          j['sender_id'],
          _asString(j['senderId'], _asString(_asMap(j['sender'])?['id'])),
        ),
        senderName: _asString(
          j['sender_name'],
          _asString(
            j['senderName'],
            _asString(_asMap(j['sender'])?['name'], 'User'),
          ),
        ),
        content: _asString(j['message'], _asString(j['content'])),
        timestamp: _asDate(j['created_at']),
        isFromFarmer: j['is_from_farmer'] as bool? ??
            j['isFromFarmer'] as bool? ??
            _asString(_asMap(j['sender'])?['role']).toLowerCase() == 'farmer',
      );
}

class Conversation {
  final String id;
  final String title;
  final String type;
  final String counterpartId;
  final String counterpartName;
  final String counterpartInitials;
  final String counterpartRole;
  final String advisorId;
  final String advisorName;
  final String advisorInitials;
  final String farmerId;
  final String farmerName;
  final String farmerInitials;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.counterpartId,
    required this.counterpartName,
    required this.counterpartInitials,
    required this.counterpartRole,
    required this.advisorId,
    required this.advisorName,
    required this.advisorInitials,
    required this.farmerId,
    required this.farmerName,
    required this.farmerInitials,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final advisorUser = _pickUserByRole(j, 'advisor');
    final farmerUser = _pickUserByRole(j, 'farmer');
    final counterpartRole = _asString(j['counterpart_role']);
    final advisorName = _asString(
      j['advisor_name'],
      _asString(advisorUser?['name'], 'Advisor'),
    );
    final farmerName = _asString(
      j['farmer_name'],
      _asString(farmerUser?['name'], 'Farmer'),
    );
    final counterpartName = _asString(
      j['counterpart_name'],
      counterpartRole.toLowerCase() == 'farmer'
          ? farmerName
          : counterpartRole.toLowerCase() == 'advisor'
              ? advisorName
              : _asString(j['title'], 'Conversation'),
    );

    return Conversation(
      id: _asString(j['id']),
      title: _asString(j['title'], counterpartName),
      type: _asString(j['type'], 'chat'),
      counterpartId: _asString(
        j['counterpart_id'],
        counterpartRole.toLowerCase() == 'farmer'
            ? _asString(j['farmer_id'], _asString(farmerUser?['id']))
            : _asString(j['advisor_id'], _asString(advisorUser?['id'])),
      ),
      counterpartName: counterpartName,
      counterpartInitials: _initialsFor(counterpartName),
      counterpartRole: counterpartRole,
      advisorId: _asString(j['advisor_id'], _asString(advisorUser?['id'])),
      advisorName: advisorName,
      advisorInitials: _initialsFor(advisorName),
      farmerId: _asString(j['farmer_id'], _asString(farmerUser?['id'])),
      farmerName: farmerName,
      farmerInitials: _initialsFor(farmerName),
      lastMessage: j['last_message'] != null
          ? ChatMessage.fromJson(j['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      updatedAt: _asDate(j['updated_at']),
    );
  }

  Conversation copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) =>
      Conversation(
        id: id,
        title: title,
        type: type,
        counterpartId: counterpartId,
        counterpartName: counterpartName,
        counterpartInitials: counterpartInitials,
        counterpartRole: counterpartRole,
        advisorId: advisorId,
        advisorName: advisorName,
        advisorInitials: advisorInitials,
        farmerId: farmerId,
        farmerName: farmerName,
        farmerInitials: farmerInitials,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class Advisor {
  final String id;
  final String name;
  final String specialization;
  final String avatarInitials;
  final double rating;
  final int yearsExperience;
  final String? conversationId;

  const Advisor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.avatarInitials,
    required this.rating,
    required this.yearsExperience,
    this.conversationId,
  });

  factory Advisor.fromConversation(Conversation c) => Advisor(
        id: c.advisorId,
        name: c.advisorName,
        specialization: '',
        avatarInitials: c.advisorInitials,
        rating: 0,
        yearsExperience: 0,
        conversationId: c.id,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: _asString(j['id']),
        title: _asString(j['title']),
        body: _asString(j['body'], _asString(j['message'])),
        type: _asString(j['type'], 'general'),
        timestamp: _asDate(j['created_at']),
        isRead: j['read_at'] != null || j['is_read'] == true,
      );
}

class FarmerDashboard {
  final List<Farm> farms;
  final List<CropRecommendation> activeRecommendations;
  final List<AppNotification> unreadNotifications;
  final List<FarmingTip> recentTips;
  final List<SeasonalNoticeItem> seasonalNotices;

  const FarmerDashboard({
    required this.farms,
    required this.activeRecommendations,
    required this.unreadNotifications,
    required this.recentTips,
    this.seasonalNotices = const [],
  });

  factory FarmerDashboard.fromJson(Map<String, dynamic> j) => FarmerDashboard(
        farms: _asMapList(j['farms']).map(Farm.fromJson).toList(),
        activeRecommendations: _asMapList(j['active_recommendations'])
            .map(CropRecommendation.fromJson)
            .toList(),
        unreadNotifications: _asMapList(j['unread_notifications'])
            .map(AppNotification.fromJson)
            .toList(),
        recentTips:
            _asMapList(j['recent_tips']).map(FarmingTip.fromJson).toList(),
        seasonalNotices: _asMapList(j['seasonal_notices'])
            .map(SeasonalNoticeItem.fromJson)
            .toList(),
      );
}
