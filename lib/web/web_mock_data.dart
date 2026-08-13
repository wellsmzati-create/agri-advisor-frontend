import '../models/models.dart';
import '../data/mock_data.dart';

class AdvisorProfile {
  final String id, name, email, role, avatarInitials, region, phone;
  final int totalFarmers, activeRecommendations;
  const AdvisorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarInitials,
    required this.region,
    required this.phone,
    required this.totalFarmers,
    required this.activeRecommendations,
  });
}

class WebFarmer {
  final String id, name, location, phone, email, avatarInitials, soilType, status, primaryFarmId;
  final int farmSizeAcres, recommendationCount;
  final DateTime registeredDate, lastActivity;
  final List<Map<String, dynamic>> farms;
  final List<Map<String, dynamic>> reports;
  final List<CropRecommendation> recommendations;
  final double lat, lng;
  const WebFarmer({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
    required this.avatarInitials,
    required this.soilType,
    required this.status,
    this.primaryFarmId = '',
    required this.farmSizeAcres,
    required this.recommendationCount,
    required this.registeredDate,
    required this.lastActivity,
    this.farms = const [],
    this.reports = const [],
    this.recommendations = const [],
    required this.lat,
    required this.lng,
  });

  factory WebFarmer.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name =
        (json['name'] as String?) ??
        (user['name'] as String?) ??
        'Farmer';
    final farms = (json['farms'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final reports = (json['reports'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final firstFarm = farms.isNotEmpty ? farms.first : const <String, dynamic>{};
    final farmSize =
        _webIntValue(json['farm_size_acres']) ??
        _webIntValue(firstFarm['size_acres']) ??
        0;
    final recommendationCount =
        _webIntValue(json['recommendation_count']) ??
        ((json['recommendations'] as List?)?.length ?? 0);
    final recommendations =
        (json['recommendations'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => CropRecommendation.fromJson(
                item.cast<String, dynamic>(),
              ),
            )
            .toList() ??
        const <CropRecommendation>[];
    final registeredRaw =
        json['registered_at'] ??
        user['created_at'] ??
        json['created_at'] ??
        json['registeredDate'];
    final lastActiveRaw =
        json['last_activity'] ??
        user['updated_at'] ??
        json['updated_at'] ??
        json['lastActivity'];

    return WebFarmer(
      id: json['id'] as String? ?? '',
      name: name,
      location:
          json['location'] as String? ??
          firstFarm['location_text'] as String? ??
          firstFarm['location'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? user['email'] as String? ?? '',
      avatarInitials: name
          .split(' ')
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0])
          .join()
          .toUpperCase(),
      soilType:
          json['soil_type'] as String? ??
          firstFarm['soil_type'] as String? ??
          '',
      status:
          json['status'] as String? ??
          user['status'] as String? ??
          'Active',
      primaryFarmId: firstFarm['id'] as String? ?? '',
      farmSizeAcres: farmSize,
      recommendationCount: recommendationCount,
      registeredDate: registeredRaw is String
          ? DateTime.tryParse(registeredRaw) ?? DateTime.now()
          : DateTime.now(),
      lastActivity: lastActiveRaw is String
          ? DateTime.tryParse(lastActiveRaw) ?? DateTime.now()
          : DateTime.now(),
      farms: farms,
      reports: reports,
      recommendations: recommendations,
      lat:
          _webDoubleValue(json['lat']) ??
          _webDoubleValue(firstFarm['lat']) ??
          _webDoubleValue(json['latitude']) ??
          0,
      lng:
          _webDoubleValue(json['lng']) ??
          _webDoubleValue(firstFarm['lng']) ??
          _webDoubleValue(json['longitude']) ??
          0,
    );
  }
}

int? _webIntValue(dynamic value) {
  if (value is num) return value.toInt();
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt();
}

double? _webDoubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return double.tryParse(text);
}

class SeasonalNotice {
  final String id, title, content, type, status, authorName, targetRegion;
  final DateTime publishedAt;
  const SeasonalNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    required this.authorName,
    required this.targetRegion,
    required this.publishedAt,
  });
}

class FarmRecord {
  final String farmerId, soilType, soilPh, nitrogenLevel, phosphorusLevel,
      potassiumLevel, rainfallMm, avgTempC, location, notes;
  final DateTime recordedAt;
  const FarmRecord({
    required this.farmerId,
    required this.soilType,
    required this.soilPh,
    required this.nitrogenLevel,
    required this.phosphorusLevel,
    required this.potassiumLevel,
    required this.rainfallMm,
    required this.avgTempC,
    required this.location,
    required this.notes,
    required this.recordedAt,
  });
}

class WebMockData {
  static const currentAdvisor = AdvisorProfile(
    id: 'adv001',
    name: 'Dr. Abena Mensah',
    email: 'abena.mensah@agri-advisor.gh',
    role: 'Senior Agricultural Advisor',
    avatarInitials: 'AM',
    region: 'Ashanti Region, Ghana',
    phone: '+233 20 123 4567',
    totalFarmers: 48,
    activeRecommendations: 23,
  );

  static final List<WebFarmer> farmers = [
    WebFarmer(
      id: 'wf001', name: 'Austin Libwathi', location: 'Kumasi, Ashanti',
      phone: '+233 24 567 8901', email: 'austin.libwathi@farm.mw',
      avatarInitials: 'AL', soilType: 'Loamy', status: 'Active',
      farmSizeAcres: 12, recommendationCount: 3,
      registeredDate: DateTime(2024, 3, 10), lastActivity: DateTime(2025, 6, 14),
      lat: 6.6885, lng: -1.6244,
    ),
    WebFarmer(
      id: 'wf002', name: 'Kwame Asante', location: 'Ejisu, Ashanti',
      phone: '+233 27 345 6789', email: 'kwame.asante@gmail.com',
      avatarInitials: 'KA', soilType: 'Sandy Loam', status: 'Active',
      farmSizeAcres: 8, recommendationCount: 5,
      registeredDate: DateTime(2024, 1, 22), lastActivity: DateTime(2025, 6, 12),
      lat: 6.7167, lng: -1.4833,
    ),
    WebFarmer(
      id: 'wf003', name: 'Akosua Boateng', location: 'Mampong, Ashanti',
      phone: '+233 26 789 0123', email: 'akosua.b@farm.gh',
      avatarInitials: 'AB', soilType: 'Clay Loam', status: 'Active',
      farmSizeAcres: 20, recommendationCount: 4,
      registeredDate: DateTime(2023, 11, 5), lastActivity: DateTime(2025, 6, 10),
      lat: 7.0667, lng: -1.4000,
    ),
    WebFarmer(
      id: 'wf004', name: 'Yaw Darko', location: 'Obuasi, Ashanti',
      phone: '+233 24 234 5678', email: 'yaw.darko@agri.gh',
      avatarInitials: 'YD', soilType: 'Loamy', status: 'Inactive',
      farmSizeAcres: 5, recommendationCount: 2,
      registeredDate: DateTime(2024, 6, 18), lastActivity: DateTime(2025, 4, 3),
      lat: 6.2000, lng: -1.6667,
    ),
    WebFarmer(
      id: 'wf005', name: 'Ama Owusu', location: 'Bekwai, Ashanti',
      phone: '+233 55 678 9012', email: 'ama.owusu@farm.gh',
      avatarInitials: 'AO', soilType: 'Sandy Loam', status: 'Active',
      farmSizeAcres: 15, recommendationCount: 6,
      registeredDate: DateTime(2023, 8, 14), lastActivity: DateTime(2025, 6, 13),
      lat: 6.4500, lng: -1.5833,
    ),
    WebFarmer(
      id: 'wf006', name: 'Kofi Mensah', location: 'Konongo, Ashanti',
      phone: '+233 20 456 7890', email: 'kofi.mensah@gmail.com',
      avatarInitials: 'KM', soilType: 'Deep Forest', status: 'Active',
      farmSizeAcres: 30, recommendationCount: 7,
      registeredDate: DateTime(2023, 5, 20), lastActivity: DateTime(2025, 6, 11),
      lat: 6.6167, lng: -1.2167,
    ),
    WebFarmer(
      id: 'wf007', name: 'Abena Frimpong', location: 'Kumasi, Ashanti',
      phone: '+233 24 890 1234', email: 'abena.f@farm.gh',
      avatarInitials: 'AF', soilType: 'Loamy', status: 'Pending',
      farmSizeAcres: 7, recommendationCount: 1,
      registeredDate: DateTime(2025, 5, 30), lastActivity: DateTime(2025, 6, 1),
      lat: 6.7000, lng: -1.6167,
    ),
    WebFarmer(
      id: 'wf008', name: 'Nana Adjei', location: 'Ashanti Mampong',
      phone: '+233 27 012 3456', email: 'nana.adjei@agri.gh',
      avatarInitials: 'NA', soilType: 'Clay', status: 'Active',
      farmSizeAcres: 18, recommendationCount: 4,
      registeredDate: DateTime(2024, 2, 8), lastActivity: DateTime(2025, 6, 9),
      lat: 7.0500, lng: -1.3833,
    ),
  ];

  static final List<SeasonalNotice> seasonalNotices = [
    SeasonalNotice(
      id: 'sn001',
      title: 'Major Rainy Season 2025 — Planting Advisory',
      content:
          'The 2025 major rainy season is expected to begin in late March across the Ashanti Region. Farmers are advised to prepare land by mid-March. Recommended crops: Maize, Tomatoes, Pepper, and Leafy Vegetables. Ensure soil testing is completed before planting. NPK 15-15-15 fertilizer is available at subsidized rates from MOFA district offices.',
      type: 'Seasonal Advisory',
      status: 'Published',
      authorName: 'Dr. Abena Mensah',
      targetRegion: 'Ashanti Region',
      publishedAt: DateTime(2025, 3, 1),
    ),
    SeasonalNotice(
      id: 'sn002',
      title: 'Fall Armyworm Alert — Immediate Action Required',
      content:
          'Fall armyworm (Spodoptera frugiperda) has been detected in maize fields across Ejisu and Bekwai districts. Farmers with maize crops should inspect fields immediately. Apply recommended pesticides (Emamectin benzoate or Chlorpyrifos) at first sign of infestation. Contact your advisor for free pesticide vouchers.',
      type: 'Pest Alert',
      status: 'Published',
      authorName: 'Dr. Abena Mensah',
      targetRegion: 'Ejisu & Bekwai Districts',
      publishedAt: DateTime(2025, 5, 15),
    ),
    SeasonalNotice(
      id: 'sn003',
      title: 'MOFA Fertilizer Subsidy Program — June 2025',
      content:
          'The Ministry of Food and Agriculture (MOFA) has announced a 50% subsidy on NPK and Urea fertilizers for registered farmers. The program runs until June 30, 2025. Farmers must present their registration card at the district MOFA office. Maximum allocation: 5 bags per farmer.',
      type: 'Government Notice',
      status: 'Published',
      authorName: 'MOFA Ghana',
      targetRegion: 'All Regions',
      publishedAt: DateTime(2025, 6, 1),
    ),
    SeasonalNotice(
      id: 'sn004',
      title: 'Minor Season Preparation Guide — September 2025',
      content:
          'Prepare for the minor rainy season (September–November). Recommended crops: Cowpea, Groundnuts, Soybean, and quick-maturing vegetables. Land preparation should begin in August. Soil moisture conservation techniques are critical for this shorter season.',
      type: 'Seasonal Advisory',
      status: 'Draft',
      authorName: 'Dr. Abena Mensah',
      targetRegion: 'Ashanti Region',
      publishedAt: DateTime(2025, 7, 20),
    ),
    SeasonalNotice(
      id: 'sn005',
      title: 'New Hybrid Maize Varieties — CSIR Release 2025',
      content:
          'CSIR-SARI has released three new drought-tolerant maize varieties for the 2025 season: Obatanpa Plus, Mamaba, and Aburohemaa. These varieties show 30% higher yield under drought conditions. Certified seeds available at CSIR offices and registered agro-input dealers.',
      type: 'Research Update',
      status: 'Published',
      authorName: 'CSIR-SARI',
      targetRegion: 'All Regions',
      publishedAt: DateTime(2025, 2, 28),
    ),
  ];

  static final List<FarmRecord> farmRecords = [
    FarmRecord(
      farmerId: 'wf001', soilType: 'Loamy', soilPh: '6.5',
      nitrogenLevel: 'Medium (45 ppm)', phosphorusLevel: 'High (32 ppm)',
      potassiumLevel: 'Medium (180 ppm)', rainfallMm: '850',
      avgTempC: '27', location: 'Kumasi, Ashanti',
      notes: 'Good drainage. Previous crop: Maize. Recommended for maize/tomato rotation.',
      recordedAt: DateTime(2025, 3, 15),
    ),
    FarmRecord(
      farmerId: 'wf002', soilType: 'Sandy Loam', soilPh: '6.2',
      nitrogenLevel: 'Low (28 ppm)', phosphorusLevel: 'Medium (22 ppm)',
      potassiumLevel: 'High (210 ppm)', rainfallMm: '780',
      avgTempC: '28', location: 'Ejisu, Ashanti',
      notes: 'Slight erosion on slopes. Needs organic matter addition. Good for groundnuts.',
      recordedAt: DateTime(2025, 2, 20),
    ),
    FarmRecord(
      farmerId: 'wf003', soilType: 'Clay Loam', soilPh: '5.8',
      nitrogenLevel: 'High (62 ppm)', phosphorusLevel: 'Low (15 ppm)',
      potassiumLevel: 'Medium (165 ppm)', rainfallMm: '1100',
      avgTempC: '26', location: 'Mampong, Ashanti',
      notes: 'Slightly acidic. Lime application recommended. Excellent for cocoa.',
      recordedAt: DateTime(2025, 4, 5),
    ),
  ];

  static final List<Map<String, dynamic>> activityTimeline = [
    {'time': '2 hours ago', 'action': 'Sent recommendation', 'farmer': 'Austin Libwathi', 'crop': 'Maize', 'icon': '🌽', 'color': 0xFF2E7D32},
    {'time': '5 hours ago', 'action': 'Updated farm record', 'farmer': 'Kwame Asante', 'crop': 'Soil Analysis', 'icon': '🧪', 'color': 0xFF1565C0},
    {'time': 'Yesterday', 'action': 'Published seasonal notice', 'farmer': 'All Farmers', 'crop': 'Fall Armyworm Alert', 'icon': '⚠️', 'color': 0xFFFB8C00},
    {'time': '2 days ago', 'action': 'New farmer registered', 'farmer': 'Abena Frimpong', 'crop': 'Onboarding', 'icon': '👤', 'color': 0xFF7B1FA2},
    {'time': '3 days ago', 'action': 'Sent recommendation', 'farmer': 'Ama Owusu', 'crop': 'Tomatoes', 'icon': '🍅', 'color': 0xFFE53935},
    {'time': '4 days ago', 'action': 'Field visit completed', 'farmer': 'Kofi Mensah', 'crop': 'Cocoa Inspection', 'icon': '🏡', 'color': 0xFF5D4037},
  ];

  static final List<Map<String, dynamic>> monthlyRecommendations = [
    {'month': 'Jan', 'count': 8},
    {'month': 'Feb', 'count': 12},
    {'month': 'Mar', 'count': 18},
    {'month': 'Apr', 'count': 22},
    {'month': 'May', 'count': 19},
    {'month': 'Jun', 'count': 23},
  ];

  static final List<Map<String, dynamic>> cropDistribution = [
    {'crop': 'Maize', 'percentage': 35.0, 'color': 0xFFFFA000},
    {'crop': 'Tomatoes', 'percentage': 22.0, 'color': 0xFFE53935},
    {'crop': 'Cocoa', 'percentage': 18.0, 'color': 0xFF5D4037},
    {'crop': 'Cassava', 'percentage': 15.0, 'color': 0xFF8D6E63},
    {'crop': 'Others', 'percentage': 10.0, 'color': 0xFF78909C},
  ];

  static final List<CropRecommendation> allRecommendations = [
    ...MockData.recommendations,
    CropRecommendation(
      id: 'r004', cropName: 'Cassava', advisorName: 'Dr. Abena Mensah',
      reason: 'Drought-tolerant crop ideal for your sandy loam soil. Excellent food security crop.',
      soilType: 'Sandy Loam', season: 'Major Season (Mar–Jul)',
      rainfall: '500–800mm', steps: ['Prepare stem cuttings', 'Plant at 45° angle', 'Apply NPK at 6 weeks'],
      date: DateTime(2025, 6, 8), status: 'Active',
    ),
    CropRecommendation(
      id: 'r005', cropName: 'Groundnuts', advisorName: 'Dr. Abena Mensah',
      reason: 'Nitrogen-fixing legume perfect for crop rotation after maize. Improves soil fertility.',
      soilType: 'Sandy Loam', season: 'Minor Season (Sep–Nov)',
      rainfall: '400–600mm', steps: ['Shell pods before planting', 'Plant 5cm deep', 'Earth up at flowering'],
      date: DateTime(2025, 5, 30), status: 'Active',
    ),
    CropRecommendation(
      id: 'r006', cropName: 'Plantain', advisorName: 'Dr. Abena Mensah',
      reason: 'High-demand staple with year-round production. Excellent for intercropping with cocoa.',
      soilType: 'Rich Moist Soil', season: 'Year-round',
      rainfall: '1200–2500mm', steps: ['Select disease-free suckers', 'Dig 60cm holes', 'Mulch heavily'],
      date: DateTime(2025, 4, 20), status: 'Completed',
    ),
  ];
}
