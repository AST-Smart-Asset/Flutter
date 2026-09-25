import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:asset_management/core/network/dio_client.dart';
import 'package:asset_management/core/security/token_manager.dart';
import 'package:asset_management/features/assets/assets_screen.dart';
import 'package:asset_management/shared_components.dart';

class AssetDetailsScreen extends StatefulWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  late Map<String, dynamic> _aiEvaluation;
  late String _currentCustodian;
  late String _currentStatus;
  late String _lastAuditDate;
  bool _isSavingAction = false;

  @override
  void initState() {
    super.initState();
    _currentCustodian = widget.asset.custodian;
    _currentStatus = widget.asset.status;
    _lastAuditDate = widget.asset.lastAudit;
    _runLightGbmEvaluation();
  }

  void _runLightGbmEvaluation() {
    setState(() {
      _aiEvaluation = TokenManager.evaluateWithLightGbm(
        assetTag: widget.asset.id,
        condition: widget.asset.condition,
      ).toMap();
    });
  }

  Future<void> _handleCustodyCheckInOut() async {
    final profile = TokenManager.activeProfile;
    if (!profile.canCheckInOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot perform Custody Check-In/Out.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSavingAction = true);
    final updatedCustodian = profile.name;
    final updatedMap = {
      ...widget.asset.toMap(),
      'custodian': updatedCustodian,
      'lastAudit': 'Custody Accepted Just Now',
    };
    await TokenManager.savePersistedAsset(updatedMap);
    TokenManager.logActivity(
      title: 'Custody Handover: ${widget.asset.id}',
      subtitle: 'Checked in by $updatedCustodian (${profile.roleTitle})',
      category: 'Custody',
    );
    if (!mounted) return;
    setState(() {
      _currentCustodian = updatedCustodian;
      _lastAuditDate = 'Custody Accepted Just Now';
      _isSavingAction = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custody assigned to $updatedCustodian and saved to DB.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _handleCreatePreventiveOrder() async {
    final profile = TokenManager.activeProfile;
    if (!profile.canCreateWorkOrder && !profile.canCompleteWorkOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot create maintenance work orders.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSavingAction = true);
    final orderId = 'WO-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    final newOrderMap = {
      'id': orderId,
      'title': 'Preventive Service: ${widget.asset.name}',
      'assetName': widget.asset.name,
      'assetCode': widget.asset.id,
      'priority': _aiEvaluation['predicted_failure_30d'] == 1 ? 'High' : 'Medium',
      'status': 'Pending',
      'assigneeName': TokenManager.currentName ?? profile.name,
      'assigneeInitials': (TokenManager.currentName ?? profile.name).substring(0, 2).toUpperCase(),
      'dueDate': 'Within 48h SLA',
      'location': '${widget.asset.location} - ${widget.asset.subLocation}',
      'isFastTrack': _aiEvaluation['predicted_failure_30d'] == 1,
    };

    try {
      await DioClient.instance.dio.post('/work-orders', data: {
        'title': newOrderMap['title'],
        'priority': 'HIGH',
        'status': 'OPEN',
        'description': 'Generated from LightGBM AI Risk Scan (${_aiEvaluation['probability_percent']}%)',
      });
    } catch (_) {}

    await TokenManager.savePersistedOrder(newOrderMap);
    TokenManager.logActivity(
      title: 'Work Order Created: $orderId',
      subtitle: '${widget.asset.id} • Assigned to ${newOrderMap['assigneeName']}',
      category: 'Orders DB',
    );
    if (!mounted) return;
    setState(() {
      _currentStatus = 'Maintenance';
      _isSavingAction = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Work Order $orderId created under ${newOrderMap['assigneeName']} & saved to DB!'),
        backgroundColor: const Color(0xFF1D4ED8),
      ),
    );
  }

  Future<void> _handleAuditorVerification() async {
    final profile = TokenManager.activeProfile;
    if (!profile.canRunStocktakeAudit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot sign off ISO-55000 stocktake audits.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final updatedMap = {
      ...widget.asset.toMap(),
      'lastAudit': 'ISO-55000 Verified by ${profile.name}',
    };
    await TokenManager.savePersistedAsset(updatedMap);
    TokenManager.logActivity(
      title: 'ISO-55000 Audit Verified: ${widget.asset.id}',
      subtitle: 'Certified by ${profile.name} (${profile.roleTitle})',
      category: 'Audit',
    );
    if (!mounted) return;
    setState(() {
      _lastAuditDate = 'ISO-55000 Verified by ${profile.name}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ISO-55000 Stocktake Audit recorded in database.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final isHighRisk = _aiEvaluation['predicted_failure_30d'] == 1;
    final riskColor = isHighRisk ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Asset Dossier • ${asset.id}',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1D4ED8)),
            tooltip: 'Open LightGBM Telemetry Simulator',
            onPressed: () => AppDialogs.showRiskAIDialog(context, initialAssetId: asset.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Asset Identification & QR Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: QrImageView(
                          data: asset.id,
                          version: QrVersions.auto,
                          size: 82.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                asset.id,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              asset.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${asset.category} • ${asset.subCategory}',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. LightGBM Predictive AI Telemetry Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'LIGHTGBM AI TELEMETRY PREDICTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF38BDF8),
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_aiEvaluation['probability_percent']}% FAILURE PROB',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _aiEvaluation['risk_level'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _aiEvaluation['recommendation'].toString(),
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDarkMetricTile('Prior Failures', '${_aiEvaluation['prior_failures_count']}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDarkMetricTile('Work Orders', '${_aiEvaluation['prior_work_orders_count']}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDarkMetricTile('Avg Repair', '${_aiEvaluation['avg_repair_hours_so_far']}h'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDarkMetricTile('Life Used', '${_aiEvaluation['life_used_percentage']}%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Role-Based Operations & Database Sync Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROLE ACTIONS (${TokenManager.activeProfile.roleTitle.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSavingAction ? null : _handleCreatePreventiveOrder,
                          icon: const Icon(Icons.build_circle_outlined, size: 17),
                          label: const Text('Create Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSavingAction ? null : _handleCustodyCheckInOut,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                          label: const Text('Check-In/Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleAuditorVerification,
                      icon: const Icon(Icons.verified_user_outlined, size: 17, color: Color(0xFF10B981)),
                      label: const Text(
                        'Verify ISO-55000 Stocktake Audit (Save to DB)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Specifications & Location Metadata
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPECIFICATIONS & CUSTODY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow('Operational Status', _currentStatus),
                  const Divider(height: 22),
                  _buildDetailRow('Hardware Condition', asset.condition),
                  const Divider(height: 22),
                  _buildDetailRow('Building / Zone', asset.location),
                  const Divider(height: 22),
                  _buildDetailRow('Room / Sub-Location', asset.subLocation),
                  const Divider(height: 22),
                  _buildDetailRow('Assigned Custodian', _currentCustodian),
                  const Divider(height: 22),
                  _buildDetailRow('Last ISO Audit', _lastAuditDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}