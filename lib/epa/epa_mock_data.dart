class EpaOfficer {
  final String id, name, email, role, region, avatarInitials, badge;
  const EpaOfficer({required this.id, required this.name, required this.email,
    required this.role, required this.region, required this.avatarInitials, required this.badge});
}

class ExtensionWorker {
  final String id, name, email, region, specialization, avatarInitials, status;
  final int activeFarmers, recommendationsGiven, responseRate;
  final double performanceScore;
  final DateTime lastActive;
  const ExtensionWorker({required this.id, required this.name, required this.email,
    required this.region, required this.specialization, required this.avatarInitials,
    required this.status, required this.activeFarmers, required this.recommendationsGiven,
    required this.responseRate, required this.performanceScore, required this.lastActive});
}

class OutbreakSignal {
  final String id, title, cropAffected, location, region, severity, status, reportedBy, description;
  final DateTime reportedAt;
  final int affectedFarms;
  const OutbreakSignal({required this.id, required this.title, required this.cropAffected,
    required this.location, required this.region, required this.severity, required this.status,
    required this.reportedBy, required this.description, required this.reportedAt, required this.affectedFarms});
}

class FarmerReport {
  final String id, farmerId, farmerName, issue, category, region, status, advisorAssigned;
  final DateTime submittedAt;
  final String severity;
  const FarmerReport({required this.id, required this.farmerId, required this.farmerName,
    required this.issue, required this.category, required this.region, required this.status,
    required this.advisorAssigned, required this.submittedAt, required this.severity});
}

class EpaNotification {
  final String id, title, body, type, priority;
  final DateTime timestamp;
  final bool isRead;
  const EpaNotification({required this.id, required this.title, required this.body,
    required this.type, required this.priority, required this.timestamp, required this.isRead});
}

class ResponseAction {
  final String id, title, description, type, status, targetRegion, createdBy;
  final DateTime createdAt;
  final String priority;
  const ResponseAction({required this.id, required this.title, required this.description,
    required this.type, required this.status, required this.targetRegion,
    required this.createdBy, required this.createdAt, required this.priority});
}

class EpaMockData {
  static const currentOfficer = EpaOfficer(
    id: 'epa001', name: 'Dr. Kofi Agyeman', email: 'k.agyeman@epa.gov.gh',
    role: 'Senior EPA Agricultural Officer', region: 'Ashanti Region',
    avatarInitials: 'KA', badge: 'EPA-ASH-001',
  );

  static final List<ExtensionWorker> workers = [
    ExtensionWorker(id: 'ew001', name: 'Dr. Abena Mensah', email: 'a.mensah@mofa.gh',
      region: 'Kumasi Metro', specialization: 'Crop Science & Soil Management',
      avatarInitials: 'AM', status: 'Active', activeFarmers: 48,
      recommendationsGiven: 127, responseRate: 96, performanceScore: 4.9,
      lastActive: DateTime(2025, 6, 14)),
    ExtensionWorker(id: 'ew002', name: 'Mr. Kofi Boateng', email: 'k.boateng@mofa.gh',
      region: 'Ejisu-Juaben', specialization: 'Vegetable Farming & Irrigation',
      avatarInitials: 'KB', status: 'Active', activeFarmers: 35,
      recommendationsGiven: 89, responseRate: 91, performanceScore: 4.7,
      lastActive: DateTime(2025, 6, 13)),
    ExtensionWorker(id: 'ew003', name: 'Ms. Ama Owusu', email: 'a.owusu@mofa.gh',
      region: 'Bekwai Municipal', specialization: 'Post-Harvest & Agribusiness',
      avatarInitials: 'AO', status: 'Active', activeFarmers: 41,
      recommendationsGiven: 103, responseRate: 88, performanceScore: 4.8,
      lastActive: DateTime(2025, 6, 12)),
    ExtensionWorker(id: 'ew004', name: 'Mr. Yaw Asante', email: 'y.asante@mofa.gh',
      region: 'Obuasi Municipal', specialization: 'Cocoa & Tree Crops',
      avatarInitials: 'YA', status: 'On Leave', activeFarmers: 29,
      recommendationsGiven: 64, responseRate: 79, performanceScore: 4.2,
      lastActive: DateTime(2025, 6, 5)),
    ExtensionWorker(id: 'ew005', name: 'Ms. Akua Frimpong', email: 'a.frimpong@mofa.gh',
      region: 'Mampong Municipal', specialization: 'Livestock & Mixed Farming',
      avatarInitials: 'AF', status: 'Active', activeFarmers: 52,
      recommendationsGiven: 118, responseRate: 93, performanceScore: 4.6,
      lastActive: DateTime(2025, 6, 14)),
    ExtensionWorker(id: 'ew006', name: 'Mr. Kwame Darko', email: 'k.darko@mofa.gh',
      region: 'Kwabre East', specialization: 'Cereals & Legumes',
      avatarInitials: 'KD', status: 'Inactive', activeFarmers: 18,
      recommendationsGiven: 31, responseRate: 62, performanceScore: 3.4,
      lastActive: DateTime(2025, 5, 20)),
  ];

  static final List<OutbreakSignal> outbreaks = [
    OutbreakSignal(id: 'ob001', title: 'Fall Armyworm Outbreak — Maize Fields',
      cropAffected: 'Maize', location: 'Ejisu-Juaben District', region: 'Ashanti',
      severity: 'Critical', status: 'Unvalidated', reportedBy: 'Mr. Kofi Boateng',
      description: 'Multiple farmers in Ejisu-Juaben reporting severe fall armyworm (Spodoptera frugiperda) infestation across maize fields. Estimated 40% crop loss in affected areas. Immediate intervention required.',
      reportedAt: DateTime(2025, 6, 13), affectedFarms: 23),
    OutbreakSignal(id: 'ob002', title: 'Tomato Leaf Curl Virus — Bekwai',
      cropAffected: 'Tomatoes', location: 'Bekwai Municipal', region: 'Ashanti',
      severity: 'High', status: 'Under Review', reportedBy: 'Ms. Ama Owusu',
      description: 'Tomato leaf curl virus detected in 12 farms across Bekwai. Whitefly vector population unusually high. Risk of rapid spread to neighboring farms.',
      reportedAt: DateTime(2025, 6, 11), affectedFarms: 12),
    OutbreakSignal(id: 'ob003', title: 'Cocoa Black Pod Disease — Obuasi',
      cropAffected: 'Cocoa', location: 'Obuasi Municipal', region: 'Ashanti',
      severity: 'Medium', status: 'Validated', reportedBy: 'Mr. Yaw Asante',
      description: 'Phytophthora palmivora (black pod disease) confirmed in cocoa farms. Wet season conditions accelerating spread. Fungicide intervention underway.',
      reportedAt: DateTime(2025, 6, 8), affectedFarms: 8),
    OutbreakSignal(id: 'ob004', title: 'Cassava Mosaic Virus — Mampong',
      cropAffected: 'Cassava', location: 'Mampong Municipal', region: 'Ashanti',
      severity: 'Low', status: 'Resolved', reportedBy: 'Ms. Akua Frimpong',
      description: 'Cassava mosaic virus detected in isolated farms. Affected plants removed. Certified clean planting material distributed to affected farmers.',
      reportedAt: DateTime(2025, 6, 2), affectedFarms: 4),
    OutbreakSignal(id: 'ob005', title: 'Stem Borer Infestation — Kumasi Metro',
      cropAffected: 'Maize', location: 'Kumasi Metro', region: 'Ashanti',
      severity: 'High', status: 'Unvalidated', reportedBy: 'Dr. Abena Mensah',
      description: 'Busseola fusca (maize stem borer) infestation reported across 18 farms in Kumasi Metro. Larvae tunneling observed in 60% of sampled plants.',
      reportedAt: DateTime(2025, 6, 14), affectedFarms: 18),
  ];

  static final List<FarmerReport> farmerReports = [
    FarmerReport(id: 'fr001', farmerId: 'wf001', farmerName: 'Austin Libwathi',
      issue: 'Yellowing maize leaves — possible nitrogen deficiency',
      category: 'Nutrient Deficiency', region: 'Kumasi Metro', status: 'Resolved',
      advisorAssigned: 'Dr. Abena Mensah', submittedAt: DateTime(2025, 6, 14), severity: 'Low'),
    FarmerReport(id: 'fr002', farmerId: 'wf002', farmerName: 'Kwame Asante',
      issue: 'Unusual pest damage on tomato seedlings',
      category: 'Pest Infestation', region: 'Ejisu-Juaben', status: 'In Progress',
      advisorAssigned: 'Mr. Kofi Boateng', submittedAt: DateTime(2025, 6, 13), severity: 'Medium'),
    FarmerReport(id: 'fr003', farmerId: 'wf003', farmerName: 'Akosua Boateng',
      issue: 'Waterlogging after heavy rains — crop damage',
      category: 'Weather Damage', region: 'Mampong Municipal', status: 'In Progress',
      advisorAssigned: 'Ms. Akua Frimpong', submittedAt: DateTime(2025, 6, 12), severity: 'High'),
    FarmerReport(id: 'fr004', farmerId: 'wf005', farmerName: 'Ama Owusu',
      issue: 'Cocoa pod borer detected in plantation',
      category: 'Pest Infestation', region: 'Bekwai Municipal', status: 'Escalated',
      advisorAssigned: 'Ms. Ama Owusu', submittedAt: DateTime(2025, 6, 11), severity: 'Critical'),
    FarmerReport(id: 'fr005', farmerId: 'wf006', farmerName: 'Kofi Mensah',
      issue: 'Soil pH too acidic — poor germination',
      category: 'Soil Issue', region: 'Konongo', status: 'Resolved',
      advisorAssigned: 'Dr. Abena Mensah', submittedAt: DateTime(2025, 6, 10), severity: 'Low'),
    FarmerReport(id: 'fr006', farmerId: 'wf004', farmerName: 'Yaw Darko',
      issue: 'Drought stress — irrigation system failure',
      category: 'Water Management', region: 'Obuasi Municipal', status: 'Pending',
      advisorAssigned: 'Unassigned', submittedAt: DateTime(2025, 6, 9), severity: 'High'),
  ];

  static final List<EpaNotification> notifications = [
    EpaNotification(id: 'en001', title: 'CRITICAL: Fall Armyworm Outbreak Reported',
      body: 'Mr. Kofi Boateng has flagged a critical fall armyworm outbreak in Ejisu-Juaben. 23 farms affected. Immediate validation required.',
      type: 'outbreak', priority: 'Critical', timestamp: DateTime(2025, 6, 13, 14, 30), isRead: false),
    EpaNotification(id: 'en002', title: 'New Stem Borer Signal — Kumasi Metro',
      body: 'Dr. Abena Mensah reported stem borer infestation across 18 farms. Awaiting EPA validation.',
      type: 'outbreak', priority: 'High', timestamp: DateTime(2025, 6, 14, 9, 0), isRead: false),
    EpaNotification(id: 'en003', title: 'Monthly Performance Report Ready',
      body: 'June 2025 extension worker performance report is ready for review. 6 workers evaluated.',
      type: 'report', priority: 'Normal', timestamp: DateTime(2025, 6, 14, 8, 0), isRead: false),
    EpaNotification(id: 'en004', title: 'MOFA Fertilizer Subsidy — Distribution Update',
      body: 'NPK subsidy distribution 78% complete across Ashanti Region. 3 districts pending.',
      type: 'notice', priority: 'Normal', timestamp: DateTime(2025, 6, 13, 10, 0), isRead: true),
    EpaNotification(id: 'en005', title: 'Cocoa Black Pod — Validated & Response Sent',
      body: 'Obuasi cocoa black pod outbreak validated. Fungicide intervention notice dispatched to 8 affected farms.',
      type: 'response', priority: 'Normal', timestamp: DateTime(2025, 6, 10, 16, 0), isRead: true),
    EpaNotification(id: 'en006', title: 'New Extension Worker Registration',
      body: 'Ms. Akua Frimpong has been assigned to Mampong Municipal district. Profile pending EPA approval.',
      type: 'system', priority: 'Low', timestamp: DateTime(2025, 6, 8, 11, 0), isRead: true),
  ];

  static final List<ResponseAction> responseActions = [
    ResponseAction(id: 'ra001', title: 'Emergency Pesticide Distribution — Ejisu',
      description: 'Coordinate emergency distribution of Emamectin benzoate to 23 affected farms in Ejisu-Juaben. Partner with MOFA district office.',
      type: 'Intervention', status: 'Active', targetRegion: 'Ejisu-Juaben',
      createdBy: 'Dr. Kofi Agyeman', createdAt: DateTime(2025, 6, 13), priority: 'Critical'),
    ResponseAction(id: 'ra002', title: 'Whitefly Control Advisory — Bekwai Tomato Farms',
      description: 'Issue advisory notice to all tomato farmers in Bekwai Municipal on whitefly vector control. Recommend imidacloprid application.',
      type: 'Advisory', status: 'Active', targetRegion: 'Bekwai Municipal',
      createdBy: 'Dr. Kofi Agyeman', createdAt: DateTime(2025, 6, 11), priority: 'High'),
    ResponseAction(id: 'ra003', title: 'Cocoa Fungicide Intervention — Obuasi',
      description: 'Coordinate fungicide (Ridomil Gold) application across 8 affected cocoa farms. Schedule field visits with extension workers.',
      type: 'Intervention', status: 'Completed', targetRegion: 'Obuasi Municipal',
      createdBy: 'Dr. Kofi Agyeman', createdAt: DateTime(2025, 6, 8), priority: 'Medium'),
    ResponseAction(id: 'ra004', title: 'Seasonal Flood Risk Broadcast — All Districts',
      description: 'Broadcast flood risk advisory to all extension workers and farmers ahead of heavy rainfall forecast June 18-25.',
      type: 'Broadcast', status: 'Sent', targetRegion: 'All Ashanti Districts',
      createdBy: 'Dr. Kofi Agyeman', createdAt: DateTime(2025, 6, 12), priority: 'High'),
    ResponseAction(id: 'ra005', title: 'Soil Testing Campaign — Kwabre East',
      description: 'Organize free soil testing for 50 farmers in Kwabre East. Partner with CSIR-SARI for laboratory analysis.',
      type: 'Campaign', status: 'Scheduled', targetRegion: 'Kwabre East',
      createdBy: 'Dr. Kofi Agyeman', createdAt: DateTime(2025, 6, 10), priority: 'Normal'),
  ];

  static final List<Map<String, dynamic>> monthlyOutbreaks = [
    {'month': 'Jan', 'count': 2}, {'month': 'Feb', 'count': 3},
    {'month': 'Mar', 'count': 5}, {'month': 'Apr', 'count': 4},
    {'month': 'May', 'count': 7}, {'month': 'Jun', 'count': 5},
  ];

  static final List<Map<String, dynamic>> reportCategories = [
    {'category': 'Pest Infestation', 'count': 38, 'color': 0xFFC62828},
    {'category': 'Nutrient Deficiency', 'count': 24, 'color': 0xFFF57C00},
    {'category': 'Weather Damage', 'count': 19, 'color': 0xFF1565C0},
    {'category': 'Soil Issues', 'count': 15, 'color': 0xFF6A1B9A},
    {'category': 'Water Management', 'count': 12, 'color': 0xFF00695C},
    {'category': 'Disease', 'count': 21, 'color': 0xFF880E4F},
  ];

  static final List<Map<String, dynamic>> regionalActivity = [
    {'region': 'Kumasi Metro', 'farmers': 48, 'reports': 31, 'outbreaks': 1, 'score': 87},
    {'region': 'Ejisu-Juaben', 'farmers': 35, 'reports': 24, 'outbreaks': 2, 'score': 72},
    {'region': 'Bekwai Municipal', 'farmers': 41, 'reports': 19, 'outbreaks': 1, 'score': 81},
    {'region': 'Obuasi Municipal', 'farmers': 29, 'reports': 14, 'outbreaks': 1, 'score': 76},
    {'region': 'Mampong Municipal', 'farmers': 52, 'reports': 28, 'outbreaks': 0, 'score': 91},
    {'region': 'Kwabre East', 'farmers': 18, 'reports': 9, 'outbreaks': 0, 'score': 65},
  ];

  static final List<Map<String, dynamic>> activityFeed = [
    {'time': '30 min ago', 'action': 'Outbreak signal flagged', 'detail': 'Stem borer — Kumasi Metro', 'icon': '⚠️', 'color': 0xFFC62828},
    {'time': '2 hrs ago', 'action': 'Response dispatched', 'detail': 'Pesticide distribution — Ejisu', 'icon': '🚨', 'color': 0xFFF57C00},
    {'time': '4 hrs ago', 'action': 'Report resolved', 'detail': 'Nitrogen deficiency — Austin Libwathi', 'icon': '✅', 'color': 0xFF2E7D32},
    {'time': 'Yesterday', 'action': 'Outbreak validated', 'detail': 'Cocoa black pod — Obuasi', 'icon': '🔬', 'color': 0xFF1565C0},
    {'time': 'Yesterday', 'action': 'Broadcast sent', 'detail': 'Flood risk advisory — All districts', 'icon': '📢', 'color': 0xFF6A1B9A},
    {'time': '2 days ago', 'action': 'Worker performance reviewed', 'detail': 'June 2025 — 6 workers evaluated', 'icon': '📊', 'color': 0xFF00695C},
  ];

  static final List<Map<String, dynamic>> recommendationAudit = [
    {'advisor': 'Dr. Abena Mensah', 'crop': 'Maize', 'farmer': 'Austin Libwathi', 'date': '14 Jun', 'consistency': 'Normal', 'flag': false},
    {'advisor': 'Mr. Kofi Boateng', 'crop': 'Tomatoes', 'farmer': 'Kwame Asante', 'date': '13 Jun', 'consistency': 'Normal', 'flag': false},
    {'advisor': 'Ms. Ama Owusu', 'crop': 'Cocoa', 'farmer': 'Ama Owusu', 'date': '12 Jun', 'consistency': 'Anomaly', 'flag': true},
    {'advisor': 'Dr. Abena Mensah', 'crop': 'Cassava', 'farmer': 'Kofi Mensah', 'date': '11 Jun', 'consistency': 'Normal', 'flag': false},
    {'advisor': 'Ms. Akua Frimpong', 'crop': 'Groundnuts', 'farmer': 'Nana Adjei', 'date': '10 Jun', 'consistency': 'Normal', 'flag': false},
    {'advisor': 'Mr. Kofi Boateng', 'crop': 'Plantain', 'farmer': 'Abena Frimpong', 'date': '09 Jun', 'consistency': 'Review', 'flag': true},
  ];
}
