class Startup {
  final String id;
  final String name;
  final String description;
  final String stage;
  final String sector;
  final int capitalInvested;
  final int totalTokens;
  final int tokensAvailable;
  final int initialPrice;
  final int currentPrice;
  final int totalInvested;
  final String status;
  final bool isActive;
  final List<dynamic> founders;
  final List<dynamic> mentors;
  final String videoDemo;

  Startup({
    required this.id,
    required this.name,
    required this.description,
    required this.stage,
    required this.sector,
    required this.capitalInvested,
    required this.totalTokens,
    required this.tokensAvailable,
    required this.initialPrice,
    required this.currentPrice,
    required this.totalInvested,
    required this.status,
    required this.isActive,
    required this.founders,
    required this.mentors,
    required this.videoDemo,
  });

  factory Startup.fromMap(String id, Map<String, dynamic> map) {
    return Startup(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      stage: map['stage'] ?? '',
      sector: map['sector'] ?? '',
      capitalInvested: ((map['capitalInvested'] ?? 0) as num).toInt(),
      totalTokens: ((map['totalTokens'] ?? 0) as num).toInt(),
      tokensAvailable: ((map['tokensAvailable'] ?? 0) as num).toInt(),
      initialPrice: ((map['initialPrice'] ?? 0) as num).toInt(),
      currentPrice: ((map['currentPrice'] ?? 0) as num).toInt(),
      totalInvested: ((map['totalInvested'] ?? 0) as num).toInt(),
      status: map['status'] ?? '',
      isActive: map['isActive'] ?? false,
      founders: List<dynamic>.from(map['founders'] ?? []),
      mentors: List<dynamic>.from(map['mentors'] ?? []),
      videoDemo: map['videoDemo'] ?? '',
    );
  }
}