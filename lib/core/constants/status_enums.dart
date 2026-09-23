import 'package:flutter/material.dart';

enum AssetStatus {
  available(Color(0xFF2E7D32), 'Available'),
  inUse(Color(0xFF1E88E5), 'In Use'),
  maintenance(Color(0xFFF9A825), 'Maintenance'),
  damaged(Color(0xFFC62828), 'Damaged'),
  retired(Color(0xFF424242), 'Retired');

  final Color color;
  final String label;
  const AssetStatus(this.color, this.label);

  static AssetStatus fromString(String? val) {
    if (val == null) return AssetStatus.inUse;
    switch (val.toLowerCase()) {
      case 'in_service':
      case 'in_use':
      case 'active':
        return AssetStatus.inUse;
      case 'available':
      case 'in_storage':
        return AssetStatus.available;
      case 'under_maintenance':
      case 'maintenance':
        return AssetStatus.maintenance;
      case 'damaged':
      case 'poor':
        return AssetStatus.damaged;
      case 'retired':
      case 'disposed':
        return AssetStatus.retired;
      default:
        return AssetStatus.inUse;
    }
  }
}

enum PriorityLevel {
  critical(Color(0xFFD32F2F), 'Critical'),
  high(Color(0xFFE53935), 'High'),
  medium(Color(0xFFED6C02), 'Medium'),
  low(Color(0xFF0288D1), 'Low');

  final Color color;
  final String label;
  const PriorityLevel(this.color, this.label);

  static PriorityLevel fromString(String? val) {
    if (val == null) return PriorityLevel.medium;
    switch (val.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return PriorityLevel.critical;
      case 'high':
        return PriorityLevel.high;
      case 'medium':
      case 'normal':
        return PriorityLevel.medium;
      case 'low':
        return PriorityLevel.low;
      default:
        return PriorityLevel.medium;
    }
  }
}
