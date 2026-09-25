import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import 'custody_transfer_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  AssetModel? _asset;
  bool _isLoading = true;
  bool _isEvaluatingAI = false;

  @override
  void initState() {
    super.initState();
    _loadAssetDetails();
  }

  Future<void> _loadAssetDetails() async {
    setState(() => _isLoading = true);
    try {
      final asset = await ApiClient().getAssetById(widget.assetId);
      setState(() {
        _asset = asset;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load asset details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runAIEvaluation() async {
    setState(() => _isEvaluatingAI = true);
    try {
      final result = await ApiClient().evaluateAssetRisk(widget.assetId);
      final evaluation = result['evaluation'] ?? {};

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentTeal,
            content: Text(
              'AI Health Assessment Complete: Risk Band is ${evaluation["riskBand"]?.toString().toUpperCase()}',
            ),
          ),
        );
      }
      await _loadAssetDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Evaluation error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEvaluatingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asset Dossier')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_asset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asset Dossier')),
        body: const Center(child: Text('Asset record not found')),
      );
    }

    final asset = _asset!;
    final riskColor = AppTheme.getRiskColor(asset.riskBand);
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.assetTag),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssetDetails,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with QR / Tag
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 40, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.assetTag,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${asset.brand ?? ""} ${asset.model ?? ""}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${asset.status.toUpperCase()} • Condition: ${asset.condition.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Predictive Maintenance & Failure Risk Card (AST-FR-09)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: riskColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: AppTheme.accentTeal),
                          SizedBox(width: 8),
                          Text(
                            'Predictive Maintenance Risk',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          asset.riskBand.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Contributing Risk Factors & Insights:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  if (asset.riskReasons.isEmpty)
                    const Text('• Asset is operating within standard parameters.', style: TextStyle(fontSize: 13))
                  else
                    ...asset.riskReasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(reason, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _isEvaluatingAI
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Run Live Health Assessment'),
                      onPressed: _isEvaluatingAI ? null : _runAIEvaluation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Specifications and Location Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registry Dossier',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Serial Number', asset.serialNumber ?? 'N/A'),
                  _buildDetailRow('Category', asset.categoryName ?? 'Hardware'),
                  _buildDetailRow('Assigned Room', asset.locationName ?? 'Unassigned'),
                  _buildDetailRow('Responsible Custodian', asset.custodianName ?? 'Institutional Ownership'),
                  if (asset.purchaseCost != null)
                    _buildDetailRow('Purchase Value', currencyFormatter.format(asset.purchaseCost!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Actions
          ElevatedButton.icon(
            icon: const Icon(Icons.transfer_within_a_station),
            label: const Text('Transfer / Move Asset Location'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustodyTransferScreen(asset: asset),
                ),
              ).then((_) => _loadAssetDetails());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
