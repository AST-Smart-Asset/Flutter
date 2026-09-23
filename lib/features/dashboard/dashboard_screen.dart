import 'package:flutter/material.dart';
import '../assets/assets_screen.dart';
import '../../shared_components.dart';
import '../assets/views/qr_scanner_screen.dart';
import '../orders/orders_screen.dart';
import '../../core/network/dio_client.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------
class MetricItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color titleColor;
  final Color valueColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color bgColor;
  final bool isAlert;

  const MetricItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.titleColor = DashboardTheme.textMain,
    this.valueColor = DashboardTheme.textMain,
    this.subtitleColor = DashboardTheme.textSub,
    this.iconColor = DashboardTheme.primaryBlue,
    this.bgColor = DashboardTheme.surface,
    this.isAlert = false,
  });
}

class EntityDistributionItem {
  final String name;
  final int percentage;
  final Color color;

  const EntityDistributionItem({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

// -----------------------------------------------------------------------------
// Theme & Constants
// -----------------------------------------------------------------------------
class DashboardTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color inputBg = Color(0xFFF1F5F9);
  
  // Alert Colors
  static const Color alertRedBg = Color(0xFFFEF2F2);
  static const Color alertRedText = Color(0xFF991B1B);
  static const Color alertRedIcon = Color(0xFFDC2626);
  
  static const Color alertBlueBg = Color(0xFFEFF6FF);
  static const Color alertBlueText = Color(0xFF1E40AF);
  
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  
  static const double radiusCard = 16.0;
}

// -----------------------------------------------------------------------------
// Screen Widget
// -----------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DioClient _dioClient = DioClient.instance;

  bool _isLoadingKpis = true;
  List<MetricItem> _metrics = [];

  final List<EntityDistributionItem> _distributions = const [
    EntityDistributionItem(name: 'Lab Equipment', percentage: 38, color: Color(0xFF1D4ED8)),
    EntityDistributionItem(name: 'Computing & Servers', percentage: 29, color: Color(0xFF3B82F6)),
    EntityDistributionItem(name: 'Audio/Visual', percentage: 16, color: Color(0xFF64748B)),
    EntityDistributionItem(name: 'Classroom Facilities', percentage: 12, color: Color(0xFF94A3B8)),
    EntityDistributionItem(name: 'Allied Health Devices', percentage: 5, color: Color(0xFF0F172A)),
  ];

  @override
  void initState() {
    super.initState();
    _fetchKpis();
  }

  Future<void> _fetchKpis() async {
    setState(() {
      _isLoadingKpis = true;
    });

    try {
      final response = await _dioClient.dio.get('/dashboard/kpis');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        final dist = data['distributions'] as Map<String, dynamic>? ?? {};
        final statusDist = dist['byStatus'] as Map<String, dynamic>? ?? {};
        final riskDist = dist['byRiskBand'] as Map<String, dynamic>? ?? {};

        final total = summary['totalAssets'] ?? 110;
        final inService = statusDist['in_service'] ?? 88;
        final maint = statusDist['under_maintenance'] ?? summary['activeWorkOrders'] ?? 12;
        final overdue = summary['overdueMaintenanceCount'] ?? 0;
        final highRisk = (riskDist['high'] ?? 0) + (riskDist['critical'] ?? 0) + (riskDist['High Risk'] ?? 0) + (riskDist['Critical Risk'] ?? 0);
        final inStorage = statusDist['in_storage'] ?? 10;

        if (mounted) {
          setState(() {
            _metrics = [
              MetricItem(
                title: 'Total Assets',
                value: '$total',
                subtitle: 'Campus Live Inventory',
                subtitleColor: DashboardTheme.primaryBlue,
                icon: Icons.inventory_2_outlined,
                iconColor: DashboardTheme.textSub,
              ),
              MetricItem(
                title: 'Active Service',
                value: '$inService',
                subtitle: '${total > 0 ? ((inService / total) * 100).toStringAsFixed(1) : 0}% operational',
                icon: Icons.check_circle_outline,
              ),
              MetricItem(
                title: 'In Maintenance',
                value: '$maint',
                subtitle: '${summary['activeWorkOrders'] ?? 0} active work orders',
                icon: Icons.build_outlined,
              ),
              MetricItem(
                title: 'Overdue Maint.',
                value: '$overdue',
                subtitle: overdue > 0 ? 'Requires attention' : 'All schedules on track',
                icon: Icons.warning_amber_rounded,
                bgColor: overdue > 0 ? DashboardTheme.alertRedBg : DashboardTheme.surface,
                titleColor: overdue > 0 ? DashboardTheme.alertRedText : DashboardTheme.textMain,
                valueColor: overdue > 0 ? DashboardTheme.alertRedText : DashboardTheme.textMain,
                subtitleColor: overdue > 0 ? DashboardTheme.alertRedText : DashboardTheme.textSub,
                iconColor: overdue > 0 ? DashboardTheme.alertRedIcon : DashboardTheme.primaryBlue,
                isAlert: overdue > 0,
              ),
              MetricItem(
                title: 'In Storage Pool',
                value: '$inStorage',
                subtitle: 'Ready for allocation',
                icon: Icons.warehouse_outlined,
                iconColor: DashboardTheme.textSub,
              ),
              MetricItem(
                title: 'AI High-Risk',
                value: '$highRisk',
                subtitle: 'LightGBM Flagged',
                icon: Icons.auto_awesome,
                bgColor: highRisk > 0 ? DashboardTheme.alertBlueBg : DashboardTheme.surface,
                titleColor: highRisk > 0 ? DashboardTheme.alertBlueText : DashboardTheme.textMain,
                valueColor: highRisk > 0 ? DashboardTheme.alertBlueText : DashboardTheme.textMain,
                subtitleColor: highRisk > 0 ? DashboardTheme.alertBlueText : DashboardTheme.textSub,
              ),
            ];
            _isLoadingKpis = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingKpis = false;
          // Fallback to initial display
          if (_metrics.isEmpty) {
            _metrics = _defaultMetrics();
          }
        });
      }
    }
  }

  List<MetricItem> _defaultMetrics() => const [
        MetricItem(
          title: 'Total Assets',
          value: '110',
          subtitle: 'Campus Live Inventory',
          subtitleColor: DashboardTheme.primaryBlue,
          icon: Icons.inventory_2_outlined,
          iconColor: DashboardTheme.textSub,
        ),
        MetricItem(
          title: 'Active Service',
          value: '95',
          subtitle: '● 86.4% in service',
          icon: Icons.check_circle_outline,
        ),
        MetricItem(
          title: 'Maintenance',
          value: '15',
          subtitle: 'Active work orders',
          icon: Icons.build_outlined,
        ),
        MetricItem(
          title: 'Overdue Maint.',
          value: '0',
          subtitle: 'All schedules on track',
          icon: Icons.warning_amber_rounded,
        ),
        MetricItem(
          title: 'In Storage Pool',
          value: '10',
          subtitle: 'Ready for allocation',
          icon: Icons.warehouse_outlined,
        ),
        MetricItem(
          title: 'AI High-Risk',
          value: '4',
          subtitle: 'LightGBM Model Flagged',
          icon: Icons.auto_awesome,
          bgColor: DashboardTheme.alertBlueBg,
          titleColor: DashboardTheme.alertBlueText,
          valueColor: DashboardTheme.alertBlueText,
          subtitleColor: DashboardTheme.alertBlueText,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.background,
      drawer: const AppDrawer(activeRoute: 'dashboard'),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchKpis,
        color: DashboardTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DashboardTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingKpis)
                const LinearProgressIndicator(minHeight: 2),
              _buildScopeSelector(),
            const SizedBox(height: DashboardTheme.spacingMd),
            _buildQuickActions(),
            const SizedBox(height: DashboardTheme.spacingMd),
            _buildSearchBar(),
            const SizedBox(height: DashboardTheme.spacingLg),
            _buildMetricsSection(),
            const SizedBox(height: DashboardTheme.spacingLg),
            _buildDiagnosticsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DashboardTheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false, 
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DashboardTheme.textSub),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('UniAsset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DashboardTheme.textMain)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DashboardTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('CORE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Text('BADR UNIVERSITY ASSIUT', style: TextStyle(fontSize: 9, color: DashboardTheme.primaryBlue, fontWeight: FontWeight.bold, height: 1.1)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: DashboardTheme.textSub),
          onPressed: () {},
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: DashboardTheme.textSub),
              onPressed: () => AppDialogs.showNotifications(context),
            ),
            Positioned(
              right: 12,
              top: 14,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: InkWell(
            onTap: () => AppDialogs.showUserProfile(context),
            borderRadius: BorderRadius.circular(16),
            child: const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingMd),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF), 
        borderRadius: BorderRadius.circular(DashboardTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text('CAMPUS ZONE SCOPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'North Science & Medical Campus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardTheme.textMain),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade900),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, size: 6, color: DashboardTheme.primaryBlue),
              const SizedBox(width: 6),
              const Text('Sync: Online • 14,820 Assets Active', style: TextStyle(fontSize: 11, color: DashboardTheme.textSub, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 10, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text('v4.2 Telemetry', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionBtn(Icons.qr_code_scanner, 'Scan QR Audit', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
        })),
        const SizedBox(width: DashboardTheme.spacingSm),
        Expanded(child: _buildActionBtn(Icons.troubleshoot, 'Run Risk Scan', isRed: true, onTap: () {
          AppDialogs.showRiskAIDialog(context);
        })),
        const SizedBox(width: DashboardTheme.spacingSm),
        Expanded(child: _buildActionBtn(Icons.sync_alt, 'Asset ID', onTap: () {
          _showAssetIdDialog();
        })),
      ],
    );
  }

  void _showAssetIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Asset ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'e.g. AST-001',
            filled: true,
            fillColor: DashboardTheme.inputBg,
            prefixIcon: const Icon(Icons.numbers, color: DashboardTheme.primaryBlue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching database for Asset ID...')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.primaryNavy, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, {bool isRed = false, required VoidCallback onTap}) {
    final color = isRed ? const Color(0xFF0F766E) : Colors.blue.shade700; 
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Floor, Room..',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: Icon(Icons.filter_alt_outlined, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Metrics Section
  // ---------------------------------------------------------------------------
  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Institutional Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
            Text('Campus Total • FY 2025', style: TextStyle(fontSize: 11, color: DashboardTheme.textSub)),
          ],
        ),
        const SizedBox(height: DashboardTheme.spacingMd),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _metrics.length,
          itemBuilder: (context, index) {
            return _MetricCardWidget(metric: _metrics[index]);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Diagnostics Section
  // ---------------------------------------------------------------------------
  Widget _buildDiagnosticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Diagnostics & Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
            Text('Real-Time', style: TextStyle(fontSize: 11, color: DashboardTheme.primaryBlue, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: DashboardTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(DashboardTheme.spacingMd),
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(DashboardTheme.radiusCard),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
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
                      Icon(Icons.pie_chart_outline, size: 16, color: DashboardTheme.primaryBlue),
                      const SizedBox(width: 8),
                      const Text('Assets by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DashboardTheme.textMain)),
                    ],
                  ),
                  Text('5 Categories', style: TextStyle(fontSize: 11, color: DashboardTheme.textSub)),
                ],
              ),
              const SizedBox(height: DashboardTheme.spacingMd),
              
              // Segmented Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: _distributions.map((e) => Expanded(
                      flex: e.percentage,
                      child: Container(color: e.color),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Multi-column Legend Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 5,
                ),
                itemCount: _distributions.length,
                itemBuilder: (context, index) {
                  final item = _distributions[index];
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontSize: 11, color: DashboardTheme.textMain), overflow: TextOverflow.ellipsis),
                      ),
                      Text('${item.percentage}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
                    ],
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Relational Integrity: 100%', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Text('Query Telemetry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_outward, size: 12, color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Navigation
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            AppDialogs.showMenuSheet(context);
            return;
          }
          if (index == 2) {
            AppDialogs.showRiskAIDialog(context);
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          }
          
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AssetsScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: DashboardTheme.surface,
        selectedItemColor: DashboardTheme.primaryBlue,
        unselectedItemColor: DashboardTheme.textSub,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.dashboard)),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.inventory_2_outlined)),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.psychology_outlined),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: DashboardTheme.primaryBlue, shape: BoxShape.circle)),
                  )
                ],
              ),
            ),
            label: 'Risk AI',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long_outlined)),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.more_horiz)),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reusable Widget Components
// -----------------------------------------------------------------------------
class _MetricCardWidget extends StatelessWidget {
  final MetricItem metric;

  const _MetricCardWidget({required this.metric});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, 
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: metric.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: metric.isAlert ? Colors.transparent : const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(metric.title, style: TextStyle(fontSize: 12, color: metric.titleColor, fontWeight: metric.isAlert ? FontWeight.bold : FontWeight.normal)),
                Icon(metric.icon, size: 16, color: metric.iconColor),
              ],
            ),
            Text(metric.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: metric.valueColor, letterSpacing: -0.5)),
            Text(metric.subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: metric.subtitleColor)),
          ],
        ),
      ),
    );
  }
}