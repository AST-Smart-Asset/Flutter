import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'views/asset_details_screen.dart';
import 'views/qr_scanner_screen.dart';
import '../../shared_components.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../../core/network/dio_client.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------
enum AssetStatus { inUse, maintenance, retired }
enum AssetCondition { good, fair, poor }

class AssetModel {
  final String rawUuid;
  final String id;
  final String serialNumber;
  final String name;
  final String modelDetails;
  final String location;
  final String imageUrl;
  final String custodian;
  final String warrantyText;
  final bool isWarrantyExpiring;
  final int riskScore;
  final String telemetryMetric;
  final List<double> sparklineData;
  final AssetStatus status;
  final AssetCondition condition;
  final Color accentColor;
  final String qrPayload; // Embedded QR Payload string

  const AssetModel({
    this.rawUuid = '',
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.modelDetails,
    required this.location,
    required this.imageUrl,
    required this.custodian,
    required this.warrantyText,
    required this.isWarrantyExpiring,
    required this.riskScore,
    required this.telemetryMetric,
    required this.sparklineData,
    required this.status,
    required this.condition,
    required this.accentColor,
    required this.qrPayload,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final brand = json['brand']?.toString() ?? '';
    final model = json['model']?.toString() ?? '';
    final name = (brand.isNotEmpty || model.isNotEmpty) ? '$brand $model'.trim() : (json['assetTag'] ?? 'Campus Asset');
    final locObj = json['currentLocation'] as Map<String, dynamic>?;
    final locName = locObj != null ? (locObj['name'] ?? locObj['building'] ?? 'BUA Campus') : 'BUA Campus';
    final custObj = json['custodian'] as Map<String, dynamic>?;
    final custName = custObj != null ? (custObj['fullName'] ?? 'General Pool') : 'Department Pool';
    final riskBand = json['riskBand']?.toString().toLowerCase() ?? 'low';
    final rawRiskScore = json['riskScore'];
    final riskScore = rawRiskScore is num ? rawRiskScore.toInt() : (riskBand.contains('crit') ? 85 : riskBand.contains('high') ? 65 : 15);
    
    AssetStatus status = AssetStatus.inUse;
    final statusStr = json['status']?.toString().toLowerCase() ?? '';
    if (statusStr.contains('maint')) status = AssetStatus.maintenance;
    else if (statusStr.contains('retir') || statusStr.contains('disp')) status = AssetStatus.retired;
    
    AssetCondition cond = AssetCondition.good;
    final condStr = json['condition']?.toString().toLowerCase() ?? '';
    if (condStr.contains('poor') || condStr.contains('damag')) cond = AssetCondition.poor;
    else if (condStr.contains('fair')) cond = AssetCondition.fair;

    final tag = json['assetTag']?.toString() ?? json['id']?.toString() ?? 'AST-000';
    final uuid = json['id']?.toString() ?? '';

    return AssetModel(
      rawUuid: uuid,
      id: tag,
      serialNumber: json['serialNumber']?.toString() ?? 'SN-UNKNOWN',
      name: name,
      modelDetails: json['category']?['name']?.toString() ?? 'University Asset',
      location: locName,
      imageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=300',
      custodian: custName,
      warrantyText: 'Warranty Valid',
      isWarrantyExpiring: false,
      riskScore: riskScore,
      telemetryMetric: 'Risk: ${riskBand.toUpperCase()}',
      sparklineData: const [40, 45, 42, 50, 48, 55, 60],
      status: status,
      condition: cond,
      accentColor: riskScore > 60 ? Colors.red : Colors.blue,
      qrPayload: tag,
    );
  }
}

// -----------------------------------------------------------------------------
// Theme & Constants
// -----------------------------------------------------------------------------
class AssetsTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color inputBg = Color(0xFFF1F5F9);
  
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
}

// -----------------------------------------------------------------------------
// Screen Widget
// -----------------------------------------------------------------------------
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  int _currentIndex = 1; // Assets tab selected
  final DioClient _dioClient = DioClient.instance;

  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<AssetModel> _allAssets = [];
  List<AssetModel> _displayedAssets = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dioClient.dio.get(
        '/assets',
        queryParameters: {'limit': 100},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawList = response.data['data'] ?? [];
        final parsed = rawList.map((j) => AssetModel.fromJson(j as Map<String, dynamic>)).toList();

        if (mounted) {
          setState(() {
            _allAssets.clear();
            _allAssets.addAll(parsed);
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load assets');
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.response?.data?['error']?['message'] ?? 'Could not load assets from university server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _displayedAssets = _allAssets.where((asset) {
        final matchesQuery = query.isEmpty ||
            asset.id.toLowerCase().contains(query) ||
            asset.name.toLowerCase().contains(query) ||
            asset.serialNumber.toLowerCase().contains(query) ||
            asset.location.toLowerCase().contains(query) ||
            asset.custodian.toLowerCase().contains(query);

        final matchesCategory = _selectedCategory == 'All' ||
            asset.modelDetails.toLowerCase().contains(_selectedCategory.toLowerCase());

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _showAssetForm([AssetModel? assetToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssetBottomSheet(assetToEdit: assetToEdit),
    ).then((returnedAsset) {
      if (returnedAsset != null && returnedAsset is AssetModel) {
        setState(() {
          if (assetToEdit != null) {
            final index = _allAssets.indexWhere((a) => a.id == assetToEdit.id);
            if (index != -1) _allAssets[index] = returnedAsset;
          } else {
            _allAssets.insert(0, returnedAsset);
          }
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assetToEdit != null ? 'Asset updated successfully!' : 'Asset & Generated QR saved successfully to database!'),
            backgroundColor: AssetsTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AssetsTheme.background,
      drawer: const AppDrawer(activeRoute: 'assets'),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAssets,
          color: AssetsTheme.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AssetsTheme.spacingMd),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: AssetsTheme.spacingMd),
                      _buildFilterChips(),
                      const SizedBox(height: AssetsTheme.spacingLg),
                      _buildActionControls(),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading university assets from Supabase...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchAssets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_displayedAssets.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No assets match your search criteria', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AssetsTheme.spacingMd),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _AssetCardWidget(
                        asset: _displayedAssets[index],
                        onEdit: () => _showAssetForm(_displayedAssets[index]),
                        onDelete: () {
                          setState(() {
                            _allAssets.removeWhere((a) => a.id == _displayedAssets[index].id);
                            _applyFilters();
                          });
                        },
                      ),
                      childCount: _displayedAssets.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
          );
        },
        backgroundColor: AssetsTheme.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AssetsTheme.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AssetsTheme.textSub),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2540),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.blueAccent, size: 18),
          ),
          const SizedBox(width: AssetsTheme.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('UniAsset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AssetsTheme.textMain)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AssetsTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('CORE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Text('Asset Manifest', style: TextStyle(fontSize: 10, color: AssetsTheme.textSub, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded, color: AssetsTheme.textSub), 
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScannerScreen()),
            );
          }
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AssetsTheme.textSub), 
              onPressed: () => AppDialogs.showNotifications(context),
            ),
            Positioned(
              right: 12,
              top: 14,
              child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: InkWell(
            onTap: () => AppDialogs.showUserProfile(context),
            borderRadius: BorderRadius.circular(16),
            child: const CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AssetsTheme.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _applyFilters(),
        decoration: InputDecoration(
          hintText: 'Search tag, serial, model, or custodian...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AssetsTheme.textSub),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AssetsTheme.primaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Cat: Laboratory ▾'),
          const SizedBox(width: 8),
          _buildFilterChip('Loc: All ▾'),
          const SizedBox(width: 8),
          _buildFilterChip('Condition: Any ☷'),
          const SizedBox(width: 8),
          _buildFilterChip('Status ▾'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AssetsTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AssetsTheme.textMain)),
    );
  }

  Widget _buildActionControls() {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _showAssetForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AssetsTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(0, 40),
              ),
              child: const Text('+ Add Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.table_rows_outlined, color: AssetsTheme.textSub),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: AssetsTheme.primaryBlue),
            const SizedBox(width: 6),
            const Text('14,820 Assets Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AssetsTheme.textMain)),
            const Spacer(),
            Text('• 3 Filters Active', style: TextStyle(fontSize: 11, color: AssetsTheme.primaryBlue, fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            const Text('Live Sync: 12s ago', style: TextStyle(fontSize: 10, color: AssetsTheme.textSub)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) { AppDialogs.showMenuSheet(context); return; }
          if (index == 2) {
            AppDialogs.showRiskAIDialog(context);
            return;
          }
          if (index == 4) {
            Scaffold.of(context).openDrawer();
            return;
          }
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AssetsTheme.surface,
        selectedItemColor: AssetsTheme.primaryBlue,
        unselectedItemColor: AssetsTheme.textSub,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Assets'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.psychology_outlined),
                Positioned(right: -2, top: -2, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ],
            ),
            label: 'Risk AI',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Menu'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reusable Widget Components
// -----------------------------------------------------------------------------
class _AssetCardWidget extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetCardWidget({
    required this.asset,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AssetsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left stripe
              Container(width: 4, color: asset.accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(value: false, onChanged: (v) {}, side: BorderSide(color: Colors.grey.shade400)),
                              ),
                              const SizedBox(width: 8),
                              Text(asset.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AssetsTheme.textMain)),
                              const SizedBox(width: 8),
                              Text(asset.serialNumber, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                          Row(
                            children: [
                              _buildStatusChip(),
                              const SizedBox(width: 4),
                              _buildConditionChip(),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: AssetsTheme.textSub),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'edit') onEdit();
                                  if (value == 'delete') onDelete();
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Identity Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AssetsTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(asset.modelDetails, style: const TextStyle(fontSize: 12, color: AssetsTheme.textSub)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.business, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(asset.location, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metrics Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricPair('Custodian', asset.custodian),
                                _buildMetricPair('Warranty', asset.warrantyText, isAlert: asset.isWarrantyExpiring),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricPair('Risk Index', '${asset.riskScore} / 100', isAlert: asset.riskScore > 80),
                                _buildMetricPair('Sensor', asset.telemetryMetric, isAlert: asset.status == AssetStatus.maintenance),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Footer
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AssetDetailsScreen(asset: asset)),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text('View Details', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AssetsTheme.textMain,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const Spacer(),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color bg = asset.status == AssetStatus.inUse ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2);
    Color text = asset.status == AssetStatus.inUse ? const Color(0xFF2563EB) : const Color(0xFFDC2626);
    String label = asset.status == AssetStatus.inUse ? 'In Use' : 'Maintenance';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConditionChip() {
    Color bg = asset.condition == AssetCondition.good ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    Color text = asset.condition == AssetCondition.good ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    String label = asset.condition == AssetCondition.good ? 'Good' : 'Fair';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMetricPair(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AssetsTheme.textSub)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isAlert ? const Color(0xFFDC2626) : AssetsTheme.textMain,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Add Asset Bottom Sheet (Form)
// -----------------------------------------------------------------------------
class AddAssetBottomSheet extends StatefulWidget {
  final AssetModel? assetToEdit;

  const AddAssetBottomSheet({super.key, this.assetToEdit});

  @override
  State<AddAssetBottomSheet> createState() => _AddAssetBottomSheetState();
}

class _AddAssetBottomSheetState extends State<AddAssetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _custodianCtrl = TextEditingController();
  
  AssetStatus _status = AssetStatus.inUse;
  AssetCondition _condition = AssetCondition.good;

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      _idCtrl.text = widget.assetToEdit!.id;
      _nameCtrl.text = widget.assetToEdit!.name;
      _serialCtrl.text = widget.assetToEdit!.serialNumber;
      _modelCtrl.text = widget.assetToEdit!.modelDetails;
      _locationCtrl.text = widget.assetToEdit!.location;
      _custodianCtrl.text = widget.assetToEdit!.custodian;
      _status = widget.assetToEdit!.status;
      _condition = widget.assetToEdit!.condition;
    } else {
      _idCtrl.text = 'UA-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    
    // Listeners to update the real-time QR code when typing
    _idCtrl.addListener(_updateQr);
    _nameCtrl.addListener(_updateQr);
  }

  void _updateQr() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _serialCtrl.dispose();
    _modelCtrl.dispose();
    _locationCtrl.dispose();
    _custodianCtrl.dispose();
    super.dispose();
  }

  String get _currentQrPayload {
    final map = {
      "id": _idCtrl.text.trim(),
      "name": _nameCtrl.text.trim(),
      "timestamp": DateTime.now().toIso8601String(),
    };
    return jsonEncode(map);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newAsset = AssetModel(
        id: _idCtrl.text.trim(),
        serialNumber: _serialCtrl.text.trim().isEmpty ? 'S/N: N/A' : _serialCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        modelDetails: _modelCtrl.text.trim().isEmpty ? 'Generic Model' : _modelCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        imageUrl: 'https://randomuser.me/api/portraits/lego/3.jpg',
        custodian: _custodianCtrl.text.trim(),
        warrantyText: 'Valid (New)',
        isWarrantyExpiring: false,
        riskScore: 0,
        telemetryMetric: 'No Data',
        sparklineData: [0, 0, 0, 0, 0],
        status: _status,
        condition: _condition,
        accentColor: _status == AssetStatus.inUse ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
        qrPayload: _currentQrPayload, // Saves generated QR string into "database"
      );
      Navigator.pop(context, newAsset);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AssetsTheme.inputBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'Required field' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AssetsTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.assetToEdit != null ? 'Edit Asset' : 'Add New Asset', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AssetsTheme.textMain)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Device QR Code Generator View
                Center(
                  child: Column(
                    children: [
                      const Text('Device QR Code Generator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AssetsTheme.textSub)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: _currentQrPayload,
                          version: QrVersions.auto,
                          size: 120.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('QR updates dynamically as you type', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField('Asset ID *', _idCtrl),
                _buildTextField('Asset Name *', _nameCtrl),
                _buildTextField('Serial Number', _serialCtrl, isRequired: false),
                _buildTextField('Model Details', _modelCtrl, isRequired: false),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Location *', _locationCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Custodian *', _custodianCtrl)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AssetStatus>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          filled: true,
                          fillColor: AssetsTheme.inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: AssetStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<AssetCondition>(
                        value: _condition,
                        decoration: InputDecoration(
                          labelText: 'Condition',
                          filled: true,
                          fillColor: AssetsTheme.inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: AssetCondition.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _condition = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AssetsTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save to Database & Encode QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}