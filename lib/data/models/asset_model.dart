class AssetModel {
  final String id;
  final String assetTag;
  final String? serialNumber;
  final String categoryId;
  final String currentLocationId;
  final String? custodianUserId;
  final String? brand;
  final String? model;
  final Map<String, dynamic>? specifications;
  final String condition;
  final String status;
  final String? purchaseDate;
  final double? purchaseCost;
  final String riskBand;
  final List<String> riskReasons;
  final String? categoryName;
  final String? locationName;
  final String? custodianName;

  AssetModel({
    required this.id,
    required this.assetTag,
    this.serialNumber,
    required this.categoryId,
    required this.currentLocationId,
    this.custodianUserId,
    this.brand,
    this.model,
    this.specifications,
    required this.condition,
    required this.status,
    this.purchaseDate,
    this.purchaseCost,
    required this.riskBand,
    required this.riskReasons,
    this.categoryName,
    this.locationName,
    this.custodianName,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    List<String> reasons = [];
    if (json['riskReasons'] != null) {
      if (json['riskReasons'] is List) {
        reasons = (json['riskReasons'] as List).map((e) => e.toString()).toList();
      }
    }

    double? cost;
    if (json['purchaseCost'] != null) {
      cost = double.tryParse(json['purchaseCost'].toString());
    }

    return AssetModel(
      id: json['id'] ?? '',
      assetTag: json['assetTag'] ?? '',
      serialNumber: json['serialNumber'],
      categoryId: json['categoryId'] ?? '',
      currentLocationId: json['currentLocationId'] ?? '',
      custodianUserId: json['custodianUserId'],
      brand: json['brand'],
      model: json['model'],
      specifications: json['specifications'] != null
          ? Map<String, dynamic>.from(json['specifications'])
          : null,
      condition: json['condition'] ?? 'good',
      status: json['status'] ?? 'in_service',
      purchaseDate: json['purchaseDate'],
      purchaseCost: cost,
      riskBand: json['riskBand'] ?? 'low',
      riskReasons: reasons,
      categoryName: json['category']?['name'],
      locationName: json['currentLocation']?['name'] ?? json['currentLocation']?['code'],
      custodianName: json['custodian']?['fullName'],
    );
  }
}
