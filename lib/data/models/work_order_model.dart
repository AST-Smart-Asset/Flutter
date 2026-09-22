class WorkOrderModel {
  final String id;
  final String assetId;
  final String? templateId;
  final String? technicianUserId;
  final String priority;
  final String status;
  final String? scheduledDate;
  final String? dueDate;
  final String? completedAt;
  final double? cost;
  final double? downtimeHours;
  final String? outcome;
  final String? completionNotes;
  final String? nextDueAt;
  final String? assetTag;
  final String? assetBrand;
  final String? assetModel;
  final String? locationName;

  WorkOrderModel({
    required this.id,
    required this.assetId,
    this.templateId,
    this.technicianUserId,
    required this.priority,
    required this.status,
    this.scheduledDate,
    this.dueDate,
    this.completedAt,
    this.cost,
    this.downtimeHours,
    this.outcome,
    this.completionNotes,
    this.nextDueAt,
    this.assetTag,
    this.assetBrand,
    this.assetModel,
    this.locationName,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] ?? '',
      assetId: json['assetId'] ?? '',
      templateId: json['templateId'],
      technicianUserId: json['technicianUserId'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'draft',
      scheduledDate: json['scheduledDate'],
      dueDate: json['dueDate'],
      completedAt: json['completedAt'],
      cost: double.tryParse(json['cost']?.toString() ?? ''),
      downtimeHours: double.tryParse(json['downtimeHours']?.toString() ?? ''),
      outcome: json['outcome'],
      completionNotes: json['completionNotes'],
      nextDueAt: json['nextDueAt'],
      assetTag: json['asset']?['assetTag'],
      assetBrand: json['asset']?['brand'],
      assetModel: json['asset']?['model'],
      locationName: json['asset']?['currentLocation']?['name'],
    );
  }
}
