import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/assets/assets_screen.dart';
import 'features/assets/views/asset_details_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/settings/menu_sheet.dart';
import 'features/assets/views/qr_scanner_screen.dart';
import 'features/routing/location_asset_screen.dart';
import 'features/auth/login_screen.dart';
import 'core/security/token_manager.dart';

class AppDialogs {
  static void showUserProfile(BuildContext context) {
    final profile = TokenManager.activeProfile;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.verified_user, color: Color(0xFF0F3A80)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Role & Permissions Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFF0F3A80),
                child: Text(
                  profile.fullName.isNotEmpty ? profile.fullName.substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(profile.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(profile.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  profile.roleName.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.department,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Granted Role Permissions:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    ...profile.permissions.map(
                      (perm) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(perm, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            icon: const Icon(Icons.logout, size: 16),
            onPressed: () async {
              await TokenManager.logActivity(
                title: 'User Logged Out',
                subtitle: '${profile.fullName} (${profile.roleName}) signed out',
                category: 'auth',
              );
              await TokenManager.clearTokens();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  static void showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final events = TokenManager.activities;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live Activity & Notifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text('${events.length} recent events logged in session', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: events.isEmpty
                        ? const Center(
                            child: Text('No recent activity recorded yet.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: events.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final ev = events[index];
                              IconData icon = Icons.info_outline;
                              Color color = Colors.blue;
                              if (ev.category == 'ai') {
                                icon = Icons.psychology;
                                color = Colors.deepOrange;
                              } else if (ev.category == 'asset') {
                                icon = Icons.inventory_2_outlined;
                                color = Colors.green.shade700;
                              } else if (ev.category == 'order') {
                                icon = Icons.build_circle_outlined;
                                color = Colors.purple;
                              } else if (ev.category == 'auth') {
                                icon = Icons.verified_user_outlined;
                                color = const Color(0xFF0F3A80);
                              }
                              final minsAgo = DateTime.now().difference(ev.timestamp).inMinutes;
                              final timeLabel = minsAgo <= 0 ? 'Just now' : '${minsAgo}m ago';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                leading: CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.12),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ev.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Text(timeLabel, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(ev.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                    const SizedBox(height: 4),
                                    Text(
                                      'By ${ev.actorName} (${ev.actorRole})',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MenuSheet(),
    );
  }

  static void showRiskAIDialog(BuildContext context, {String? initialAssetId}) {
    showDialog(
      context: context,
      builder: (context) => _RiskAiInteractiveDialog(initialAssetId: initialAssetId),
    );
  }
}

class _RiskAiInteractiveDialog extends StatefulWidget {
  final String? initialAssetId;
  const _RiskAiInteractiveDialog({this.initialAssetId});

  @override
  State<_RiskAiInteractiveDialog> createState() => _RiskAiInteractiveDialogState();
}

class _RiskAiInteractiveDialogState extends State<_RiskAiInteractiveDialog> {
  late final TextEditingController _assetIdCtrl;
  final TextEditingController _failuresCtrl = TextEditingController(text: '11');
  final TextEditingController _workOrdersCtrl = TextEditingController(text: '16');
  final TextEditingController _repairHoursCtrl = TextEditingController(text: '19.6');
  final TextEditingController _lifeUsedCtrl = TextEditingController(text: '124.3');

  AiPredictionResult? _prediction;
  bool _showTelemetryInputs = false;

  static const List<String> _quickSampleTags = [
    'AST-IT-PC-00316',
    'AST-IT-PROJ-00285',
    'AST-IT-LAPTOP-00202',
    'AST-UPS-SRV-005',
    'AST-UPS-SRV-004',
  ];

  @override
  void initState() {
    super.initState();
    _assetIdCtrl = TextEditingController(text: widget.initialAssetId ?? 'AST-IT-PC-00316');
    _syncPresetFields(_assetIdCtrl.text);
    if (widget.initialAssetId != null && widget.initialAssetId!.isNotEmpty) {
      _runScan();
    }
  }

  void _syncPresetFields(String tag) {
    final res = TokenManager.evaluateWithLightGbm(assetTag: tag);
    _failuresCtrl.text = res.priorFailuresCount.toString();
    _workOrdersCtrl.text = res.priorWorkOrdersCount.toString();
    _repairHoursCtrl.text = res.avgRepairHoursSoFar.toStringAsFixed(1);
    _lifeUsedCtrl.text = res.lifeUsedPercentage.toStringAsFixed(1);
  }

  void _runScan() {
    final tag = _assetIdCtrl.text.trim().isEmpty ? 'AST-IT-PC-00316' : _assetIdCtrl.text.trim();
    final res = TokenManager.evaluateWithLightGbm(
      assetTag: tag,
      customPriorFailures: int.tryParse(_failuresCtrl.text),
      customWorkOrders: int.tryParse(_workOrdersCtrl.text),
      customAvgRepairHours: double.tryParse(_repairHoursCtrl.text),
      customLifeUsedPercent: double.tryParse(_lifeUsedCtrl.text),
    );

    TokenManager.logActivity(
      title: 'AI Risk Scan: ${res.assetTag} (${res.riskLevel})',
      subtitle: 'Failure Prob: ${res.riskScorePercent}% • 30d Fail: ${res.predictedFailure30d ? "YES" : "NO"}',
      category: 'ai',
    );

    setState(() {
      _prediction = res;
    });
  }

  @override
  void dispose() {
    _assetIdCtrl.dispose();
    _failuresCtrl.dispose();
    _workOrdersCtrl.dispose();
    _repairHoursCtrl.dispose();
    _lifeUsedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: const Icon(Icons.psychology, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LightGBM AI Risk Predictor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Instant 30-day failure prediction & telemetry scan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Asset ID Field + Instant Scan
              TextField(
                controller: _assetIdCtrl,
                onChanged: (v) => _syncPresetFields(v),
                onSubmitted: (_) => _runScan(),
                decoration: InputDecoration(
                  labelText: 'Asset ID / Tag',
                  hintText: 'e.g. AST-IT-PC-00316',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB)),
                    tooltip: 'Open Camera Scanner',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                      );
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),

              // Quick sample asset tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickSampleTags.map((tag) {
                  final isSel = _assetIdCtrl.text.trim().toUpperCase() == tag;
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isSel ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                    label: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF1E40AF) : const Color(0xFF334155))),
                    onPressed: () {
                      setState(() {
                        _assetIdCtrl.text = tag;
                        _syncPresetFields(tag);
                      });
                      _runScan();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Collapsible Telemetry & Time Parameters (for custom AI prediction)
              InkWell(
                onTap: () => setState(() => _showTelemetryInputs = !_showTelemetryInputs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Adjust Asset Telemetry & Service Times (LightGBM Features)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    Icon(_showTelemetryInputs ? Icons.expand_less : Icons.expand_more, size: 18, color: const Color(0xFF2563EB)),
                  ],
                ),
              ),
              if (_showTelemetryInputs) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _failuresCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Prior Failures', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _workOrdersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Work Orders', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _repairHoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Avg Repair Hours', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lifeUsedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Life Used (%)', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              ElevatedButton.icon(
                onPressed: _runScan,
                icon: const Icon(Icons.radar, size: 18),
                label: const Text('Run AI Risk Scan Now', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3A80),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // Immediate Inline AI Risk Scan Results (Without needing to enter Asset Details first!)
              if (_prediction != null) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final p = _prediction!;
                    final isCritOrHigh = p.failureProbability >= p.decisionThreshold;
                    final badgeColor = p.riskLevel.contains('Critical')
                        ? const Color(0xFFDC2626)
                        : p.riskLevel.contains('High')
                            ? const Color(0xFFEA580C)
                            : p.riskLevel.contains('Medium')
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.assetTag, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                                    Text(p.assetName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  p.riskLevel.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniStat('Failure Prob (30d)', '${(p.failureProbability * 100).toStringAsFixed(1)}%', badgeColor),
                              _buildMiniStat('30d Failure Pred', isCritOrHigh ? 'YES (1)' : 'NO (0)', isCritOrHigh ? Colors.red : Colors.green),
                              _buildMiniStat('Est. RUL', '${p.estimatedDaysToFailure} Days', const Color(0xFF0F172A)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniStat('Prior Failures', '${p.priorFailuresCount}', const Color(0xFF334155)),
                              _buildMiniStat('Avg Repair (MTTR)', '${p.avgRepairHoursSoFar.toStringAsFixed(1)}h', const Color(0xFF334155)),
                              _buildMiniStat('Lifecycle Used', '${p.lifeUsedPercentage.toStringAsFixed(0)}%', const Color(0xFF334155)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Action: ${p.recommendedAction}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                ),
                                const SizedBox(height: 4),
                                ...p.contributingFactors.take(3).map(
                                      (f) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0),
                                        child: Text('• $f', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final model = AssetModel(
                                      id: p.assetTag,
                                      name: p.assetName,
                                      category: p.categoryCode,
                                      subCategory: 'LightGBM AI (${p.riskScorePercent}% Risk)',
                                      location: p.building,
                                      subLocation: p.department,
                                      status: isCritOrHigh ? 'Maintenance' : 'Active',
                                      condition: isCritOrHigh ? 'Fair' : 'Good',
                                      custodian: p.department,
                                      lastAudit: 'Verified ISO-55000',
                                      riskScore: p.riskLevel,
                                      icon: Icons.precision_manufacturing_outlined,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => AssetDetailsScreen(asset: model)),
                                    );
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: const Text('Asset Details', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: badgeColor, foregroundColor: Colors.white),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.build, size: 14),
                                  label: const Text('Create Order', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String activeRoute;

  const AppDrawer({super.key, this.activeRoute = '/dashboard'});

  @override
  Widget build(BuildContext context) {
    final profile = TokenManager.activeProfile;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF0A2540), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.school, color: Colors.blueAccent, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UniAsset Core', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Role: ${profile.roleName}', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildItem(context, 'Dashboard', Icons.grid_view, 'dashboard', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }),
            _buildItem(context, 'Assets', Icons.inventory_2_outlined, 'assets', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssetsScreen()));
            }),
            _buildItem(context, 'Locations', Icons.location_on_outlined, 'locations', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationAssetScreen()));
            }),
            _buildItem(context, 'Work Orders', Icons.receipt_long_outlined, 'orders', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            _buildItem(context, 'Risk Prediction (AI)', Icons.psychology_outlined, 'risk', () {
              Navigator.pop(context);
              AppDialogs.showRiskAIDialog(context);
            }),
            const Spacer(),
            InkWell(
              onTap: () => AppDialogs.showUserProfile(context),
              child: Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0F3A80),
                      child: Text(
                        profile.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${profile.roleName} • ${profile.email}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => AppDialogs.showMenuSheet(context),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String routeId, VoidCallback onTap) {
    bool isActive = activeRoute == routeId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.blue.shade700 : Colors.grey.shade700),
        title: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.blue.shade700 : Colors.black87)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? Colors.blue.shade50 : Colors.transparent,
        onTap: onTap,
      ),
    );
  }
}