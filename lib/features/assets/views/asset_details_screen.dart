import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../assets_screen.dart';
import '../../../core/network/dio_client.dart';

class AssetDetailsScreen extends StatefulWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  final DioClient _dioClient = DioClient.instance;

  bool _isEvaluatingAi = false;
  Map<String, dynamic>? _aiEvaluation;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _fetchAiRiskEvaluation();
  }

  Future<void> _fetchAiRiskEvaluation() async {
    final uuid = widget.asset.rawUuid;
    if (uuid.isEmpty) return;

    setState(() {
      _isEvaluatingAi = true;
      _aiError = null;
    });

    try {
      final response = await _dioClient.dio.post(
        '/predictions/evaluate/$uuid',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _aiEvaluation = response.data['data']?['evaluation'];
            _isEvaluatingAi = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isEvaluatingAi = false;
          _aiError = e.response?.data?['error']?['message'] ?? 'Could not retrieve AI diagnostic';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEvaluatingAi = false;
          _aiError = e.toString();
        });
      }
    }
  }

  Color _getRiskColor(String? riskBand) {
    switch (riskBand?.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
      case 'moderate':
        return const Color(0xFFD97706);
      case 'low':
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return Scaffold(
      backgroundColor: AssetsTheme.background,
      appBar: AppBar(
        backgroundColor: AssetsTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AssetsTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Asset Details',
          style: TextStyle(color: AssetsTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AssetsTheme.primaryBlue),
            tooltip: 'Re-run AI Diagnostics',
            onPressed: _isEvaluatingAi ? null : _fetchAiRiskEvaluation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AssetsTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AssetsTheme.spacingMd),

            // Asset Identification
            Container(
              padding: const EdgeInsets.all(AssetsTheme.spacingLg),
              decoration: BoxDecoration(
                color: AssetsTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    asset.id,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AssetsTheme.primaryNavy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    asset.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AssetsTheme.textMain),
                  ),
                  const SizedBox(height: 4),
                  Text(asset.serialNumber, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: AssetsTheme.spacingLg),

            // AI Predictive Maintenance Risk Card
            _buildAiRiskCard(),
            const SizedBox(height: AssetsTheme.spacingLg),

            // Large QR Code
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: asset.qrPayload,
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan to Verify On-Site',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AssetsTheme.primaryBlue, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AssetsTheme.spacingLg),

            // Detailed Properties
            Container(
              decoration: BoxDecoration(
                color: AssetsTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Model Details', asset.modelDetails),
                  const Divider(height: 1),
                  _buildDetailRow('Location', asset.location),
                  const Divider(height: 1),
                  _buildDetailRow('Custodian', asset.custodian),
                  const Divider(height: 1),
                  _buildDetailRow('Warranty Status', asset.warrantyText),
                  const Divider(height: 1),
                  _buildDetailRow('Condition', asset.condition.name.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRiskCard() {
    if (_isEvaluatingAi) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text(
              'Running LightGBM AI Predictive Diagnostics...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      );
    }

    if (_aiError != null && _aiEvaluation == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _aiError!,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }

    final riskScore = _aiEvaluation?['riskScore'] ?? widget.asset.riskScore;
    final riskBand = (_aiEvaluation?['riskBand'] ?? widget.asset.telemetryMetric.replaceAll('Risk: ', '')).toString();
    final action = _aiEvaluation?['recommendedAction'] ?? 'Monitor standard operation';
    final reasons = _aiEvaluation?['riskReasons'] as List<dynamic>?;
    final riskColor = _getRiskColor(riskBand);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: riskColor, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Predictive Maintenance Risk',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    riskBand.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Failure Probability', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          '$riskScore%',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: riskColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Recommended Action', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(
                          action.toString().replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    )
                  ],
                ),
                if (reasons != null && reasons.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Contributing Telemetry Factors:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  ...reasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: riskColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r.toString(),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AssetsTheme.textSub, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AssetsTheme.textMain),
            ),
          ),
        ],
      ),
    );
  }
}