class StocktakeSessionModel {
  final String id;
  final String locationId;
  final String title;
  final String status;
  final int totalExpected;
  final int totalScanned;
  final int discrepanciesCount;
  final String startedAt;
  final String? locationName;

  StocktakeSessionModel({
    required this.id,
    required this.locationId,
    required this.title,
    required this.status,
    required this.totalExpected,
    required this.totalScanned,
    required this.discrepanciesCount,
    required this.startedAt,
    this.locationName,
  });

  factory StocktakeSessionModel.fromJson(Map<String, dynamic> json) {
    return StocktakeSessionModel(
      id: json['id'] ?? '',
      locationId: json['locationId'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'active',
      totalExpected: json['totalExpected'] ?? 0,
      totalScanned: json['totalScanned'] ?? 0,
      discrepanciesCount: json['discrepanciesCount'] ?? 0,
      startedAt: json['startedAt'] ?? '',
      locationName: json['location']?['name'],
    );
  }
}

class StocktakeObservationModel {
  final String id;
  final String assetTag;
  final String status; // verified, moved, unexpected
  final String scannedAt;
  final String? notes;

  StocktakeObservationModel({
    required this.id,
    required this.assetTag,
    required this.status,
    required this.scannedAt,
    this.notes,
  });

  factory StocktakeObservationModel.fromJson(Map<String, dynamic> json) {
    return StocktakeObservationModel(
      id: json['id'] ?? '',
      assetTag: json['asset']?['assetTag'] ?? '',
      status: json['status'] ?? 'verified',
      scannedAt: json['scannedAt'] ?? '',
      notes: json['notes'],
    );
  }
}
