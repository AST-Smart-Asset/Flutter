class DashboardKPIModel {
  final int totalAssets;
  final double totalAssetValue;
  final int activeWorkOrders;
  final int overdueMaintenanceCount;
  final double totalMaintenanceCost;
  final double totalDowntimeHours;
  final Map<String, int> statusDistribution;
  final Map<String, int> conditionDistribution;
  final Map<String, int> riskDistribution;

  DashboardKPIModel({
    required this.totalAssets,
    required this.totalAssetValue,
    required this.activeWorkOrders,
    required this.overdueMaintenanceCount,
    required this.totalMaintenanceCost,
    required this.totalDowntimeHours,
    required this.statusDistribution,
    required this.conditionDistribution,
    required this.riskDistribution,
  });

  factory DashboardKPIModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    final dist = json['distributions'] ?? {};

    Map<String, int> parseMap(dynamic map) {
      if (map is Map) {
        return map.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
      }
      return {};
    }

    return DashboardKPIModel(
      totalAssets: summary['totalAssets'] ?? 0,
      totalAssetValue: double.tryParse(summary['totalAssetValue']?.toString() ?? '0') ?? 0.0,
      activeWorkOrders: summary['activeWorkOrders'] ?? 0,
      overdueMaintenanceCount: summary['overdueMaintenanceCount'] ?? 0,
      totalMaintenanceCost: double.tryParse(summary['totalMaintenanceCost']?.toString() ?? '0') ?? 0.0,
      totalDowntimeHours: double.tryParse(summary['totalDowntimeHours']?.toString() ?? '0') ?? 0.0,
      statusDistribution: parseMap(dist['byStatus']),
      conditionDistribution: parseMap(dist['byCondition']),
      riskDistribution: parseMap(dist['byRiskBand']),
    );
  }
}
