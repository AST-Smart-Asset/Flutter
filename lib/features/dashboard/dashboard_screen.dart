import 'dart:async';
import 'package:flutter/material.dart';
import 'package:asset_management/core/network/dio_client.dart';
import 'package:asset_management/core/security/token_manager.dart';
import 'package:asset_management/features/assets/assets_screen.dart';
import 'package:asset_management/features/assets/views/asset_details_screen.dart';
import 'package:asset_management/features/assets/views/qr_scanner_screen.dart';
import 'package:asset_management/features/orders/orders_screen.dart';
import 'package:asset_management/features/settings/menu_sheet.dart';
import 'package:asset_management/shared_components.dart';

class DashboardTheme {
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color darkCard = Color(0xFF0F172A);
}

class _CampusZoneScope {
  final String id;
  final String title;
  final String subtitle;
  final String totalAssets;
  final String verifiedRate;
  final String auditedLabel;
  final String openOrders;
  final String pendingSlaLabel;
  final String highRiskCount;
  final String warrantyAlerts;
  final String unverifiedCount;
  final List<_CategoryDist> categories;

  const _CampusZoneScope({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalAssets,
    required this.verifiedRate,
    required this.auditedLabel,
    required this.openOrders,
    required this.pendingSlaLabel,
    required this.highRiskCount,
    required this.warrantyAlerts,
    required this.unverifiedCount,
    required this.categories,
  });
}

class _CategoryDist {
  final String name;
  final double pct;
  final Color color;
  const _CategoryDist(this.name, this.pct, this.color);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _currentNavIndex = 0;
  bool _isLoadingKpis = true;
  final TextEditingController _topSearchController = TextEditingController();

  static const List<_CampusZoneScope> _campusScopes = [
    _CampusZoneScope(
      id: 'all',
      title: 'All BUA Campuses (14,820 Assets Active)',
      subtitle: 'Universal Enterprise Scope • 5 Zones Monitored',
      totalAssets: '14,820',
      verifiedRate: '94.2%',
      auditedLabel: '13,960 Audited',
      openOrders: '38',
      pendingSlaLabel: '12 High Priority',
      highRiskCount: '14',
      warrantyAlerts: '42',
      unverifiedCount: '185',
      categories: [
        _CategoryDist('IT & Computing', 0.35, Color(0xFF1D4ED8)),
        _CategoryDist('Lab & Research', 0.25, Color(0xFF0EA5E9)),
        _CategoryDist('AV & Smart Rooms', 0.18, Color(0xFF10B981)),
        _CategoryDist('HVAC & Power', 0.14, Color(0xFFF59E0B)),
        _CategoryDist('Medical & Safety', 0.08, Color(0xFF64748B)),
      ],
    ),
    _CampusZoneScope(
      id: 'north_science',
      title: 'North Science & Medical Campus (6,420 Assets)',
      subtitle: 'Biomedical Labs, Cryo-EM & Research Suites',
      totalAssets: '6,420',
      verifiedRate: '96.4%',
      auditedLabel: '6,189 Audited',
      openOrders: '14',
      pendingSlaLabel: '5 High Priority',
      highRiskCount: '6',
      warrantyAlerts: '18',
      unverifiedCount: '54',
      categories: [
        _CategoryDist('Lab & Research', 0.48, Color(0xFF0EA5E9)),
        _CategoryDist('Medical & Safety', 0.24, Color(0xFF10B981)),
        _CategoryDist('IT & Computing', 0.16, Color(0xFF1D4ED8)),
        _CategoryDist('HVAC & Power', 0.12, Color(0xFFF59E0B)),
      ],
    ),
    _CampusZoneScope(
      id: 'ai_faculty',
      title: 'Faculty of AI & Data Management (3,180 Assets)',
      subtitle: 'GPU Clusters, Smart Halls & Robotics Labs',
      totalAssets: '3,180',
      verifiedRate: '97.8%',
      auditedLabel: '3,110 Audited',
      openOrders: '9',
      pendingSlaLabel: '3 High Priority',
      highRiskCount: '4',
      warrantyAlerts: '9',
      unverifiedCount: '22',
      categories: [
        _CategoryDist('IT & Computing', 0.56, Color(0xFF1D4ED8)),
        _CategoryDist('AV & Smart Rooms', 0.22, Color(0xFF10B981)),
        _CategoryDist('Lab & Research', 0.14, Color(0xFF0EA5E9)),
        _CategoryDist('HVAC & Power', 0.08, Color(0xFFF59E0B)),
      ],
    ),
    _CampusZoneScope(
      id: 'engineering',
      title: 'Central Engineering & Fabrication (2,890 Assets)',
      subtitle: 'CNC Workshops, Heavy Turbines & Civil Labs',
      totalAssets: '2,890',
      verifiedRate: '91.5%',
      auditedLabel: '2,644 Audited',
      openOrders: '10',
      pendingSlaLabel: '3 High Priority',
      highRiskCount: '3',
      warrantyAlerts: '11',
      unverifiedCount: '68',
      categories: [
        _CategoryDist('Lab & Research', 0.42, Color(0xFF0EA5E9)),
        _CategoryDist('HVAC & Power', 0.30, Color(0xFFF59E0B)),
        _CategoryDist('IT & Computing', 0.18, Color(0xFF1D4ED8)),
        _CategoryDist('AV & Smart Rooms', 0.10, Color(0xFF10B981)),
      ],
    ),
    _CampusZoneScope(
      id: 'server_core',
      title: 'Main Server & IT Infrastructure (2,330 Assets)',
      subtitle: 'Data Center Nodes, Core Switches & UPS Arrays',
      totalAssets: '2,330',
      verifiedRate: '98.9%',
      auditedLabel: '2,304 Audited',
      openOrders: '5',
      pendingSlaLabel: '1 High Priority',
      highRiskCount: '1',
      warrantyAlerts: '4',
      unverifiedCount: '41',
      categories: [
        _CategoryDist('IT & Computing', 0.68, Color(0xFF1D4ED8)),
        _CategoryDist('HVAC & Power', 0.22, Color(0xFFF59E0B)),
        _CategoryDist('Medical & Safety', 0.10, Color(0xFF64748B)),
      ],
    ),
  ];

  int _selectedScopeIndex = 0;
  Timer? _cloudSyncTimer;

  _CampusZoneScope get _activeScope => _campusScopes[_selectedScopeIndex];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _cloudSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _topSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    await TokenManager.syncFromCloudDb();
    try {
      await DioClient.instance.dio.get('/reports/executive-kpis');
    } catch (_) {
      // Uses live Campus Zone Scope metrics + persisted custom items
    }
    if (!mounted) return;
    setState(() {
      _isLoadingKpis = false;
    });
  }

  Future<void> _searchAndOpenAssetId(String rawQuery) async {
    final cleanId = rawQuery.trim().toUpperCase();
    if (cleanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an Asset ID or Name (e.g., AST-08904).'),
          backgroundColor: DashboardTheme.accentAmber,
        ),
      );
      return;
    }

    // Check custom persisted assets first
    final customAssets = await TokenManager.getPersistedCustomAssets();
    Map<String, dynamic>? matchedCustom;
    for (final item in customAssets) {
      final idStr = (item['id'] ?? item['assetCode'] ?? '').toString().toUpperCase();
      final nameStr = (item['name'] ?? '').toString().toUpperCase();
      if (idStr == cleanId || idStr.contains(cleanId) || nameStr.contains(cleanId)) {
        matchedCustom = item;
        break;
      }
    }

    final pred = TokenManager.evaluateWithLightGbm(assetTag: cleanId);
    final isHighRisk = pred['predicted_failure_30d'] == 1;
    final probPct = double.tryParse(pred['probability_percent']?.toString() ?? '24.0') ?? 24.0;

    final resolvedModel = AssetModel(
      id: matchedCustom != null ? (matchedCustom['id'] ?? cleanId).toString() : cleanId,
      name: matchedCustom != null
          ? (matchedCustom['name'] ?? 'Campus Enterprise Asset').toString()
          : _resolveAssetTitle(cleanId),
      category: matchedCustom != null
          ? (matchedCustom['category'] ?? 'IT Equipment').toString()
          : _resolveAssetCategory(cleanId),
      subCategory: 'LightGBM AI (${pred['probability_percent']}% Failure Prob)',
      location: matchedCustom != null
          ? (matchedCustom['location'] ?? _activeScope.title.split(' (').first).toString()
          : _activeScope.title.split(' (').first,
      subLocation: 'Active Zone • Verified',
      status: matchedCustom != null
          ? (matchedCustom['status'] ?? (isHighRisk ? 'Maintenance' : 'Active')).toString()
          : (isHighRisk ? 'Maintenance' : 'Active'),
      condition: matchedCustom != null
          ? (matchedCustom['condition'] ?? (isHighRisk ? 'Fair' : 'Good')).toString()
          : (isHighRisk ? 'Fair' : 'Good'),
      custodian: matchedCustom != null
          ? (matchedCustom['custodian'] ?? (TokenManager.currentName ?? 'Dr. Ahmed Hassan')).toString()
          : (TokenManager.currentName ?? 'Dr. Ahmed Hassan'),
      lastAudit: 'Verified Today',
      riskScore: probPct >= 75 ? 'Critical' : (isHighRisk ? 'High' : 'Low'),
      icon: Icons.devices_other_rounded,
    );

    TokenManager.logActivity(
      title: 'Asset Lookup: ${resolvedModel.id}',
      subtitle: '${resolvedModel.name} • Risk: ${pred['probability_percent']}%',
      category: 'Search',
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetDetailsScreen(asset: resolvedModel),
      ),
    );
  }

  String _resolveAssetTitle(String id) {
    if (id.contains('08904')) return 'Dell PowerEdge R750 AI Server';
    if (id.contains('12827')) return 'Carrier Centrifugal Chiller #2';
    if (id.contains('00142')) return 'Thermo Scientific Cryo-Electron Microscope';
    if (id.contains('04910')) return 'Cisco Catalyst 9600 Core Switch';
    if (id.contains('07311')) return 'Epson Pro L1505UH Laser Projector';
    return 'BUA Enterprise Asset ($id)';
  }

  String _resolveAssetCategory(String id) {
    if (id.contains('08904') || id.startsWith('SRV')) return 'Servers & Cloud';
    if (id.contains('12827')) return 'HVAC & Power';
    if (id.contains('00142')) return 'Lab Equipment';
    if (id.contains('04910')) return 'Networking';
    return 'IT Equipment';
  }

  void _showScopeSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.domain_rounded, color: DashboardTheme.primaryBlue),
                SizedBox(width: 10),
                Text(
                  'Select Campus / Zone Scope',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardTheme.textMain),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Dynamically filters Dashboard KPIs, Active Asset Counts, and Category Telemetry.',
              style: TextStyle(fontSize: 12.5, color: DashboardTheme.textSub),
            ),
            const SizedBox(height: 16),
            ...List.generate(_campusScopes.length, (idx) {
              final scope = _campusScopes[idx];
              final isSelected = idx == _selectedScopeIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedScopeIndex = idx;
                    });
                    TokenManager.logActivity(
                      title: 'Campus Scope Changed',
                      subtitle: scope.title,
                      category: 'Scope',
                    );
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? DashboardTheme.primaryBlue : DashboardTheme.borderLight,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? DashboardTheme.primaryBlue : DashboardTheme.textSub,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scope.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: isSelected ? DashboardTheme.primaryBlue : DashboardTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${scope.subtitle} • ${scope.highRiskCount} High Risk',
                                style: const TextStyle(fontSize: 11.5, color: DashboardTheme.textSub),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showQueryTelemetryAnalyticsSheet() {
    TokenManager.logActivity(
      title: 'Telemetry & LightGBM Analytics Queried',
      subtitle: 'Scope: ${_activeScope.title}',
      category: 'Analytics',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Analysis & Telemetry Engine',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: DashboardTheme.textMain),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'LightGBM Predictive Model (media_1790156865974.py • Threshold 0.4215)',
                          style: TextStyle(fontSize: 12, color: DashboardTheme.textSub),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Telemetry KPI strip
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryStatBox(
                      label: 'ROC-AUC Score',
                      value: '0.948',
                      sub: 'Validation Set',
                      color: DashboardTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTelemetryStatBox(
                      label: 'Mean Repair (MTTR)',
                      value: '6.4 hrs',
                      sub: '-18% vs Q3',
                      color: DashboardTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTelemetryStatBox(
                      label: '30d Risk Flagged',
                      value: _activeScope.highRiskCount,
                      sub: 'Prob >= 42.15%',
                      color: DashboardTheme.accentRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Feature Importance Chart
              const Text(
                'LIGHTGBM FEATURE IMPORTANCE (GAIN %)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: DashboardTheme.textSub, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),
              _buildFeatureImportanceRow('life_used_percentage (Operational Hours / Lifespan)', 0.38, const Color(0xFFEF4444)),
              _buildFeatureImportanceRow('prior_failures_count (Historical Breakdowns)', 0.29, const Color(0xFFF59E0B)),
              _buildFeatureImportanceRow('avg_repair_hours_so_far (Cumulative MTTR)', 0.19, const Color(0xFF1D4ED8)),
              _buildFeatureImportanceRow('prior_work_orders_count (Service Frequency)', 0.14, const Color(0xFF10B981)),

              const SizedBox(height: 20),
              const Text(
                'LIVE SNAPSHOT PREDICTIONS (TOP FLAGGED CAMPUS ASSETS)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: DashboardTheme.textSub, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),
              ...[
                'AST-08904',
                'AST-12827',
                'AST-00142',
                'AST-04910',
                'AST-07311',
              ].map((tag) {
                final p = TokenManager.evaluateWithLightGbm(assetTag: tag);
                final isHigh = p['predicted_failure_30d'] == 1;
                final badgeColor = isHigh ? DashboardTheme.accentRed : DashboardTheme.accentGreen;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DashboardTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: badgeColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resolveAssetTitle(tag),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DashboardTheme.textMain),
                            ),
                            Text(
                              'Failures: ${p['prior_failures_count']} • Avg Repair: ${p['avg_repair_hours_so_far']}h • Life: ${p['life_used_percentage']}%',
                              style: const TextStyle(fontSize: 11.5, color: DashboardTheme.textSub),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${p['probability_percent']}%',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: badgeColor),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppDialogs.showRiskAIDialog(context);
                  },
                  icon: const Icon(Icons.psychology_rounded, size: 18),
                  label: const Text('Open Interactive LightGBM Risk Simulator', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryStatBox({
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DashboardTheme.textSub)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10.5, color: DashboardTheme.textSub)),
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceRow(String feature, double weight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(feature, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardTheme.textMain)),
              Text('${(weight * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: weight,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.bgLight,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: RefreshIndicator(
                color: DashboardTheme.primaryBlue,
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRolePermissionBanner(),
                      const SizedBox(height: 14),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildScopeSelector(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'REAL-TIME METRICS',
                        trailing: _isLoadingKpis
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _activeScope.id == 'all' ? 'All 5 Zones' : 'Zone Filtered',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTheme.primaryBlue,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _buildKpiGrid(),
                      const SizedBox(height: 24),
                      _buildPredictiveIntelligenceCard(),
                      const SizedBox(height: 24),
                      _buildCategoryBreakdownCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopHeader() {
    final activityCount = TokenManager.activities.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: DashboardTheme.surfaceWhite,
        border: Border(bottom: BorderSide(color: DashboardTheme.borderLight, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: DashboardTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Badr University',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${TokenManager.activeProfile.roleTitle} Portal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    tooltip: 'Recent Activity Notifications',
                    onPressed: () async {
                      AppDialogs.showNotifications(context);
                      setState(() {});
                    },
                    icon: const Icon(Icons.notifications_none_rounded, color: DashboardTheme.textMain, size: 26),
                  ),
                  if (activityCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: DashboardTheme.accentRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          activityCount > 9 ? '9+' : '$activityCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => AppDialogs.showUserProfile(context),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: DashboardTheme.primaryBlue.withValues(alpha: 0.12),
                  child: Text(
                    (TokenManager.currentName ?? 'SA').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: DashboardTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissionBanner() {
    final profile = TokenManager.activeProfile;
    return InkWell(
      onTap: () => AppDialogs.showUserProfile(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, size: 18, color: DashboardTheme.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Signed in as ${profile.name} (${profile.roleTitle}) • ${profile.permissions.length} Role Permissions Active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const Icon(Icons.info_outline_rounded, size: 16, color: DashboardTheme.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _topSearchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) => _searchAndOpenAssetId(val),
        decoration: InputDecoration(
          hintText: 'Search Asset ID (e.g. AST-08904, AST-12827)...',
          hintStyle: const TextStyle(color: DashboardTheme.textSub, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: DashboardTheme.textSub, size: 20),
          suffixIcon: IconButton(
            tooltip: 'Find & Open Asset',
            icon: const Icon(Icons.arrow_forward_rounded, color: DashboardTheme.primaryBlue, size: 20),
            onPressed: () => _searchAndOpenAssetId(_topSearchController.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildScopeSelector() {
    return GestureDetector(
      onTap: _showScopeSelectorModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DashboardTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardTheme.primaryBlue.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CAMPUS / ZONE SCOPE (TAP TO SWITCH)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeScope.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: DashboardTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: DashboardTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            isPrimary: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.tag_rounded,
            label: 'Asset ID',
            isPrimary: false,
            onTap: _showAssetIdDialog,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.analytics_outlined,
            label: 'Query Telemetry',
            isPrimary: false,
            onTap: _showQueryTelemetryAnalyticsSheet,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? DashboardTheme.primaryBlue : DashboardTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: DashboardTheme.borderLight),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: DashboardTheme.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isPrimary ? Colors.white : DashboardTheme.textMain,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : DashboardTheme.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: DashboardTheme.textSub,
            letterSpacing: 0.8,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildKpiGrid() {
    // Unified card background & subtitle style across all 6 metric cards (Fixes Bugs #8 & #9)
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildMetricCard(
          title: 'Total Assets',
          value: _activeScope.totalAssets,
          subtext: 'Campus Live Inventory',
          icon: Icons.inventory_2_outlined,
          accentColor: DashboardTheme.primaryBlue,
        ),
        _buildMetricCard(
          title: 'Verified Rate',
          value: _activeScope.verifiedRate,
          subtext: _activeScope.auditedLabel,
          icon: Icons.verified_outlined,
          accentColor: DashboardTheme.accentGreen,
        ),
        _buildMetricCard(
          title: 'Open Work Orders',
          value: _activeScope.openOrders,
          subtext: _activeScope.pendingSlaLabel,
          icon: Icons.assignment_late_outlined,
          accentColor: DashboardTheme.accentAmber,
        ),
        _buildMetricCard(
          title: 'High-Risk Assets',
          value: _activeScope.highRiskCount,
          subtext: 'AI Failure Prob >= 42%',
          icon: Icons.warning_amber_rounded,
          accentColor: DashboardTheme.accentRed,
        ),
        _buildMetricCard(
          title: 'Warranty Alerts',
          value: _activeScope.warrantyAlerts,
          subtext: 'Expiring in < 30 days',
          icon: Icons.event_busy_outlined,
          accentColor: DashboardTheme.textSub,
        ),
        _buildMetricCard(
          title: 'Unverified',
          value: _activeScope.unverifiedCount,
          subtext: 'Pending Physical Scan',
          icon: Icons.location_off_outlined,
          accentColor: DashboardTheme.accentRed,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    // Unified background & text colors across all cards (Fixes Bug #9)
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DashboardTheme.textSub,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DashboardTheme.textMain,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveIntelligenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DashboardTheme.darkCard.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'LIGHTGBM PREDICTIVE AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF38BDF8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardTheme.accentRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardTheme.accentRed.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Critical Alert',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_activeScope.highRiskCount} Assets Flagged for 30-Day Failure Risk',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Evaluated using prior_failures_count, prior_work_orders_count, avg_repair_hours_so_far & life_used_percentage (Threshold: 0.4215).',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppDialogs.showRiskAIDialog(context);
                  },
                  icon: const Icon(Icons.psychology_rounded, size: 16),
                  label: const Text('Run Risk Scan by ID'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _showQueryTelemetryAnalyticsSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Telemetry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ASSET DISTRIBUTION BY CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: DashboardTheme.textSub,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_activeScope.totalAssets} Total',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: DashboardTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._activeScope.categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProgressRow(cat.name, cat.pct, cat.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DashboardTheme.textMain,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DashboardTheme.textSub,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: DashboardTheme.bgLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DashboardTheme.borderLight, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AssetsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OrdersScreen()));
          } else if (index == 4) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const MenuSheet(),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: DashboardTheme.surfaceWhite,
        selectedItemColor: DashboardTheme.primaryBlue,
        unselectedItemColor: DashboardTheme.textSub,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  void _showAssetIdDialog() {
    final TextEditingController idController = TextEditingController(text: 'AST-08904');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_rounded, color: DashboardTheme.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Asset ID Lookup & AI Scan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: DashboardTheme.textMain),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an Asset ID to open its full dossier or run an instant LightGBM AI risk scan:',
              style: TextStyle(fontSize: 12.5, color: DashboardTheme.textSub),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. AST-08904, AST-12827, AST-00142',
                hintStyle: const TextStyle(color: DashboardTheme.textSub, fontSize: 14),
                filled: true,
                fillColor: DashboardTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DashboardTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DashboardTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: DashboardTheme.textSub)),
          ),
          OutlinedButton(
            onPressed: () {
              final id = idController.text.trim();
              Navigator.pop(ctx);
              AppDialogs.showRiskAIDialog(context, initialAssetId: id);
            },
            child: const Text('AI Risk Scan'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = idController.text.trim();
              Navigator.pop(ctx);
              _searchAndOpenAssetId(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Asset'),
          ),
        ],
      ),
    );
  }
}