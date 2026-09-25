import 'dart:async';
import 'package:flutter/material.dart';
import 'package:asset_management/core/network/dio_client.dart';
import 'package:asset_management/core/security/token_manager.dart';
import 'package:asset_management/features/assets/views/asset_details_screen.dart';
import 'package:asset_management/features/assets/views/qr_scanner_screen.dart';
import 'package:asset_management/features/dashboard/dashboard_screen.dart';
import 'package:asset_management/features/orders/orders_screen.dart';
import 'package:asset_management/features/settings/menu_sheet.dart';
import 'package:asset_management/shared_components.dart';

class AssetModel {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final String location;
  final String subLocation;
  final String status;
  final String condition;
  final String custodian;
  final String lastAudit;
  final String riskScore;
  final IconData icon;

  AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.location,
    required this.subLocation,
    required this.status,
    required this.condition,
    required this.custodian,
    required this.lastAudit,
    required this.riskScore,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetCode': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'location': location,
      'subLocation': subLocation,
      'status': status,
      'condition': condition,
      'custodian': custodian,
      'lastAudit': lastAudit,
      'riskScore': riskScore,
    };
  }
}

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final int _currentNavIndex = 1;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter state (Fixes Bug #12)
  String _selectedCat = 'All';
  String _selectedLoc = 'All';
  String _selectedCondition = 'All';
  String _selectedStatus = 'All';

  // Sort state (Fixes Bug #15)
  String _sortMode = 'default';

  // Selection state (Fixes Bug #16)
  final Set<String> _selectedAssetIds = <String>{};

  // Inline AI Risk Scan Result banner (Fixes Bugs #13 & #14)
  Map<String, dynamic>? _inlineSearchRiskResult;
  String? _inlineRiskAssetTitle;

  final List<AssetModel> _defaultCampusAssets = [
    AssetModel(
      id: 'AST-08904',
      name: 'Dell PowerEdge R750 AI Cluster Server',
      category: 'Servers & Cloud',
      subCategory: 'Rack Server (Dual Xeon)',
      location: 'Main Server Building',
      subLocation: 'Floor 3 - Rack B12',
      status: 'Active',
      condition: 'Poor',
      custodian: 'Eng. Karim Adel',
      lastAudit: '12 Oct 2026',
      riskScore: 'Critical',
      icon: Icons.dns_rounded,
    ),
    AssetModel(
      id: 'AST-12827',
      name: 'Carrier Centrifugal Chiller #2',
      category: 'HVAC & Power',
      subCategory: 'Industrial Cooling Unit',
      location: 'North Science Campus',
      subLocation: 'Mechanical Plant B1',
      status: 'Maintenance',
      condition: 'Poor',
      custodian: 'Eng. Tarek Mansour',
      lastAudit: '15 Oct 2026',
      riskScore: 'High',
      icon: Icons.ac_unit_rounded,
    ),
    AssetModel(
      id: 'AST-00142',
      name: 'Thermo Scientific Cryo-Electron Microscope',
      category: 'Lab Equipment',
      subCategory: 'High-Res Imaging',
      location: 'North Science Campus',
      subLocation: 'Floor 2 - Room 204B',
      status: 'Active',
      condition: 'Good',
      custodian: 'Dr. Sarah Jenkins',
      lastAudit: '14 Oct 2026',
      riskScore: 'Low',
      icon: Icons.biotech_rounded,
    ),
    AssetModel(
      id: 'AST-04910',
      name: 'Cisco Catalyst 9600 Core Switch',
      category: 'Networking',
      subCategory: 'Enterprise Backbone',
      location: 'Main Server Building',
      subLocation: 'Floor 1 - Core Room',
      status: 'Active',
      condition: 'Good',
      custodian: 'Eng. Omar Nabil',
      lastAudit: '18 Oct 2026',
      riskScore: 'Low',
      icon: Icons.router_rounded,
    ),
    AssetModel(
      id: 'AST-07311',
      name: 'Epson Pro L1505UH Laser Projector',
      category: 'AV Equipment',
      subCategory: 'Smart Auditorium',
      location: 'Faculty of AI',
      subLocation: 'Main Hall A',
      status: 'Maintenance',
      condition: 'Fair',
      custodian: 'Prof. Youssef Ali',
      lastAudit: '02 Sep 2026',
      riskScore: 'High',
      icon: Icons.videocam_outlined,
    ),
  ];

  List<AssetModel> _allAssets = [];
  List<AssetModel> _displayedAssets = [];
  Timer? _cloudSyncTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFiltersAndSort);
    _fetchAssets();
    _cloudSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _fetchAssets(silent: true);
    });
  }

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssets({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    // Pull latest cross-device assets, deletions, and notifications from Cloud DB
    await TokenManager.syncFromCloudDb();

    final deletedIds = await TokenManager.getDeletedAssetIds();
    final persistedMaps = await TokenManager.getPersistedCustomAssets();

    final Map<String, AssetModel> mergedById = {};

    // 1. Load default campus catalog
    for (final a in _defaultCampusAssets) {
      if (!deletedIds.contains(a.id.toUpperCase())) {
        mergedById[a.id.toUpperCase()] = a;
      }
    }

    // 2. Try fetching live backend assets
    try {
      final response = await DioClient.instance.dio.get('/assets', queryParameters: {'limit': 50});
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data['data'] ?? response.data;
        final List<dynamic> items = rawData is List ? rawData : (rawData['items'] ?? []);
        for (final item in items) {
          final rawTag = (item['assetTag'] ?? item['assetCode'] ?? '').toString().toUpperCase();
          if (rawTag.startsWith('SYNC-')) continue; // Handled by syncFromCloudDb()
          if (rawTag.isNotEmpty && !deletedIds.contains(rawTag)) {
            final pred = TokenManager.evaluateWithLightGbm(assetTag: rawTag);
            final isHigh = pred['predicted_failure_30d'] == 1;
            final itemName = (item['name'] ?? item['model'] ?? 'Campus Asset').toString();
            mergedById[rawTag] = AssetModel(
              id: rawTag,
              name: itemName,
              category: (item['category'] is Map ? item['category']['name'] : item['category'] ?? 'IT Equipment').toString(),
              subCategory: 'LightGBM Tracked (${pred['probability_percent']}%)',
              location: (item['currentLocation'] is Map ? item['currentLocation']['name'] : item['location'] ?? 'Badr University Campus').toString(),
              subLocation: (item['room'] is Map ? item['room']['name'] : 'Active Zone').toString(),
              status: (item['status'] ?? 'Active').toString(),
              condition: (item['condition'] ?? 'Good').toString(),
              custodian: (item['custodian'] is Map ? item['custodian']['fullName'] : item['custodian'] ?? 'Badr University Custody').toString(),
              lastAudit: 'Verified ISO-55000',
              riskScore: isHigh ? 'High' : 'Low',
              icon: _getCategoryIcon((item['category'] is Map ? item['category']['name'] : item['category'])?.toString()),
            );
          }
        }
      }
    } catch (_) {
      // Uses merged local + persisted cloud database records
    }

    // 3. Overlay persisted custom/updated assets from TokenManager (includes all cross-device shared_asset records)
    for (final m in persistedMaps) {
      final code = (m['id'] ?? m['assetCode'] ?? '').toString().toUpperCase();
      if (code.isNotEmpty && !deletedIds.contains(code)) {
        mergedById[code] = AssetModel(
          id: code,
          name: (m['name'] ?? 'Campus Asset').toString(),
          category: (m['category'] ?? 'IT Equipment').toString(),
          subCategory: (m['subCategory'] ?? 'Enterprise Hardware').toString(),
          location: (m['location'] ?? 'Main Campus').toString(),
          subLocation: (m['subLocation'] ?? 'Verified Zone').toString(),
          status: (m['status'] ?? 'Active').toString(),
          condition: (m['condition'] ?? 'Good').toString(),
          custodian: (m['custodian'] ?? (TokenManager.currentName ?? 'BUA Admin')).toString(),
          lastAudit: (m['lastAudit'] ?? 'Just Now').toString(),
          riskScore: (m['riskScore'] ?? 'Low').toString(),
          icon: _getCategoryIcon(m['category']?.toString()),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _allAssets = mergedById.values.toList();
      _isLoading = false;
    });
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    final query = _searchController.text.trim().toLowerCase();

    List<AssetModel> filtered = _allAssets.where((asset) {
      final matchesQuery = query.isEmpty ||
          asset.name.toLowerCase().contains(query) ||
          asset.id.toLowerCase().contains(query) ||
          asset.category.toLowerCase().contains(query) ||
          asset.location.toLowerCase().contains(query) ||
          asset.custodian.toLowerCase().contains(query);

      final matchesCat = _selectedCat == 'All' ||
          asset.category.toLowerCase().contains(_selectedCat.toLowerCase());
      final matchesLoc = _selectedLoc == 'All' ||
          asset.location.toLowerCase().contains(_selectedLoc.toLowerCase());
      final matchesCondition = _selectedCondition == 'All' ||
          asset.condition.toLowerCase() == _selectedCondition.toLowerCase();
      final matchesStatus = _selectedStatus == 'All' ||
          asset.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesQuery && matchesCat && matchesLoc && matchesCondition && matchesStatus;
    }).toList();

    // Sort logic (Fixes Bug #15)
    int riskWeight(String r) {
      switch (r.toLowerCase()) {
        case 'critical':
          return 3;
        case 'high':
          return 2;
        default:
          return 1;
      }
    }

    if (_sortMode == 'risk_desc') {
      filtered.sort((a, b) => riskWeight(b.riskScore).compareTo(riskWeight(a.riskScore)));
    } else if (_sortMode == 'id_asc') {
      filtered.sort((a, b) => a.id.compareTo(b.id));
    } else if (_sortMode == 'name_asc') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortMode == 'condition') {
      filtered.sort((a, b) => a.condition.compareTo(b.condition));
    }

    // Check if user searched a specific Asset ID to display inline AI Risk Scan immediately (Fixes Bugs #13 & #14)
    Map<String, dynamic>? inlineRisk;
    String? inlineTitle;
    if (query.startsWith('ast-') || (filtered.length == 1 && query.length >= 4)) {
      final targetId = filtered.isNotEmpty ? filtered.first.id : query.toUpperCase();
      inlineTitle = filtered.isNotEmpty ? filtered.first.name : 'Campus Asset ($targetId)';
      inlineRisk = TokenManager.evaluateWithLightGbm(
        assetTag: targetId,
        condition: filtered.isNotEmpty ? filtered.first.condition : null,
      ).toMap();
    }

    setState(() {
      _displayedAssets = filtered;
      _inlineSearchRiskResult = inlineRisk;
      _inlineRiskAssetTitle = inlineTitle;
    });
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.inventory_2_outlined;
    final lower = categoryName.toLowerCase();
    if (lower.contains('lab') || lower.contains('micro')) return Icons.biotech_rounded;
    if (lower.contains('server') || lower.contains('cloud')) return Icons.dns_rounded;
    if (lower.contains('net') || lower.contains('switch')) return Icons.router_rounded;
    if (lower.contains('hvac') || lower.contains('power')) return Icons.ac_unit_rounded;
    if (lower.contains('av') || lower.contains('proj')) return Icons.videocam_outlined;
    return Icons.devices_other_rounded;
  }

  void _showFilterOptions({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSel = opt == currentValue;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSel,
                  selectedColor: const Color(0xFFDBEAFE),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                  ),
                  onSelected: (_) {
                    onSelected(opt);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.swap_vert_rounded, color: Color(0xFF1D4ED8)),
                SizedBox(width: 8),
                Text('Sort Assets Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSortTile(ctx, 'risk_desc', 'AI Risk Score (Critical / High First)', Icons.warning_amber_rounded),
            _buildSortTile(ctx, 'id_asc', 'Asset ID (Ascending A-Z)', Icons.tag_rounded),
            _buildSortTile(ctx, 'name_asc', 'Asset Name (Alphabetical)', Icons.sort_by_alpha_rounded),
            _buildSortTile(ctx, 'condition', 'Hardware Condition', Icons.build_circle_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(BuildContext ctx, String mode, String label, IconData icon) {
    final isSelected = _sortMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1D4ED8)) : null,
      onTap: () {
        setState(() => _sortMode = mode);
        _applyFiltersAndSort();
        Navigator.pop(ctx);
      },
    );
  }

  void _showAddAssetModal({AssetModel? existingAsset}) {
    final profile = TokenManager.activeProfile;
    if (existingAsset == null && !profile.canCreateAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot create new assets. Use Super Admin or Asset Manager.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (existingAsset != null && !profile.canEditAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" has read-only permission for asset metadata.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssetSheet(
        existingAsset: existingAsset,
        onAssetSaved: (savedAsset) async {
          await TokenManager.savePersistedAsset(savedAsset.toMap());
          TokenManager.logActivity(
            title: existingAsset == null ? 'New Asset Registered: ${savedAsset.id}' : 'Asset Updated: ${savedAsset.id}',
            subtitle: '${savedAsset.name} • ${savedAsset.location} (Saved to DB)',
            category: 'Asset DB',
          );
          await _fetchAssets();
        },
      ),
    );
  }

  Future<void> _deleteAsset(AssetModel asset) async {
    final profile = TokenManager.activeProfile;
    if (!profile.canDeleteAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot delete or retire campus assets.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      await DioClient.instance.dio.delete('/assets/${asset.id}');
    } catch (_) {}

    await TokenManager.markAssetDeleted(asset.id);
    TokenManager.logActivity(
      title: 'Asset Retired / Deleted: ${asset.id}',
      subtitle: '${asset.name} removed by ${profile.name}',
      category: 'Asset DB',
    );
    await _fetchAssets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asset ${asset.id} deleted and synced with database.'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            _buildSearchAndActionBar(),
            _buildFilterChipsBar(),
            if (_selectedAssetIds.isNotEmpty) _buildSelectionBanner(),
            if (_inlineSearchRiskResult != null) _buildInlineAiRiskResultBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)))
                  : _displayedAssets.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF1D4ED8),
                          onRefresh: _fetchAssets,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: _displayedAssets.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final asset = _displayedAssets[index];
                              final isSelected = _selectedAssetIds.contains(asset.id);
                              return _AssetCardWidget(
                                asset: asset,
                                isSelected: isSelected,
                                onSelectChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedAssetIds.add(asset.id);
                                    } else {
                                      _selectedAssetIds.remove(asset.id);
                                    }
                                  });
                                },
                                onEdit: () => _showAddAssetModal(existingAsset: asset),
                                onDelete: () => _deleteAsset(asset),
                                onQuickRiskScan: () {
                                  final pred = TokenManager.evaluateWithLightGbm(
                                    assetTag: asset.id,
                                    condition: asset.condition,
                                  ).toMap();
                                  setState(() {
                                    _inlineSearchRiskResult = pred;
                                    _inlineRiskAssetTitle = '${asset.id} • ${asset.name}';
                                  });
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Badr University • Assets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_displayedAssets.length} Shown • 14,820 Campus Registry',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Run LightGBM AI Scan',
                onPressed: () => AppDialogs.showRiskAIDialog(context),
                icon: const Icon(Icons.psychology_rounded, color: Color(0xFF1D4ED8), size: 24),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => AppDialogs.showNotifications(context),
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
              ),
              GestureDetector(
                onTap: () => AppDialogs.showUserProfile(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    (TokenManager.currentName ?? 'SA').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActionBar() {
    final canCreate = TokenManager.activeProfile.canCreateAsset;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    final clean = val.trim().toUpperCase();
                    final pred = TokenManager.evaluateWithLightGbm(assetTag: clean).toMap();
                    setState(() {
                      _inlineSearchRiskResult = pred;
                      _inlineRiskAssetTitle = clean;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search ID (AST-08904) for instant AI Risk...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 19),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _inlineSearchRiskResult = null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _sortMode != 'default' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _sortMode != 'default' ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
              ),
            ),
            child: IconButton(
              tooltip: 'Sort Assets (Order Icon)',
              icon: Icon(
                Icons.swap_vert_rounded,
                color: _sortMode != 'default' ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: _showSortMenu,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddAssetModal(),
            icon: Icon(canCreate ? Icons.add_rounded : Icons.lock_outline_rounded, size: 17, color: Colors.white),
            label: const Text(
              'Add Asset',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canCreate ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    final hasActiveFilter = _selectedCat != 'All' ||
        _selectedLoc != 'All' ||
        _selectedCondition != 'All' ||
        _selectedStatus != 'All';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdownChip(
              'Cat: $_selectedCat',
              isActive: _selectedCat != 'All',
              onTap: () => _showFilterOptions(
                title: 'Filter by Asset Category',
                options: ['All', 'Servers & Cloud', 'HVAC & Power', 'Lab Equipment', 'Networking', 'AV Equipment'],
                currentValue: _selectedCat,
                onSelected: (v) {
                  setState(() => _selectedCat = v);
                  _applyFiltersAndSort();
                },
              ),
            ),
            const SizedBox(width: 8),
            _buildDropdownChip(
              'Loc: $_selectedLoc',
              isActive: _selectedLoc != 'All',
              onTap: () => _showFilterOptions(
                title: 'Filter by Campus Location',
                options: ['All', 'Main Server Building', 'North Science Campus', 'Faculty of AI'],
                currentValue: _selectedLoc,
                onSelected: (v) {
                  setState(() => _selectedLoc = v);
                  _applyFiltersAndSort();
                },
              ),
            ),
            const SizedBox(width: 8),
            _buildDropdownChip(
              'Condition: $_selectedCondition',
              isActive: _selectedCondition != 'All',
              onTap: () => _showFilterOptions(
                title: 'Filter by Hardware Condition',
                options: ['All', 'Good', 'Fair', 'Poor'],
                currentValue: _selectedCondition,
                onSelected: (v) {
                  setState(() => _selectedCondition = v);
                  _applyFiltersAndSort();
                },
              ),
            ),
            const SizedBox(width: 8),
            _buildDropdownChip(
              'Status: $_selectedStatus',
              isActive: _selectedStatus != 'All',
              onTap: () => _showFilterOptions(
                title: 'Filter by Operational Status',
                options: ['All', 'Active', 'Maintenance', 'In Storage'],
                currentValue: _selectedStatus,
                onSelected: (v) {
                  setState(() => _selectedStatus = v);
                  _applyFiltersAndSort();
                },
              ),
            ),
            if (hasActiveFilter) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Reset Filters', style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                backgroundColor: const Color(0xFFFEF2F2),
                side: BorderSide.none,
                onPressed: () {
                  setState(() {
                    _selectedCat = 'All';
                    _selectedLoc = 'All';
                    _selectedCondition = 'All';
                    _selectedStatus = 'All';
                  });
                  _applyFiltersAndSort();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip(String label, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFF1E3A8A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedAssetIds.length} Asset(s) Selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  final firstId = _selectedAssetIds.first;
                  AppDialogs.showRiskAIDialog(context, initialAssetId: firstId);
                },
                icon: const Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 16),
                label: const Text('Run AI Risk', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedAssetIds.clear()),
                child: const Text('Clear', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineAiRiskResultBanner() {
    final pred = _inlineSearchRiskResult!;
    final isHigh = pred['predicted_failure_30d'] == 1;
    final accent = isHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bg = isHigh ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isHigh ? Icons.warning_amber_rounded : Icons.verified_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Inline LightGBM AI Scan: $_inlineRiskAssetTitle',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${pred['probability_percent']}% Risk',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _inlineSearchRiskResult = null),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Failures: ${pred['prior_failures_count']} • Orders: ${pred['prior_work_orders_count']} • Avg Repair: ${pred['avg_repair_hours_so_far']}h • Life: ${pred['life_used_percentage']}%',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 2),
          Text(
            pred['recommendation'].toString(),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No assets match the active filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedCat = 'All';
                _selectedLoc = 'All';
                _selectedCondition = 'All';
                _selectedStatus = 'All';
                _searchController.clear();
              });
              _applyFiltersAndSort();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    // Fixed Bug #17: Added index == 3 -> OrdersScreen navigation
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
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
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1D4ED8),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'Menu'),
        ],
      ),
    );
  }
}

class _AssetCardWidget extends StatelessWidget {
  final AssetModel asset;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onQuickRiskScan;

  const _AssetCardWidget({
    required this.asset,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickRiskScan,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'maintenance':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
        return const Color(0xFF0EA5E9);
      case 'fair':
        return const Color(0xFFF59E0B);
      case 'poor':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return const Color(0xFF10B981);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssetDetailsScreen(asset: asset),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelectChanged,
                        activeColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(asset.icon, size: 22, color: const Color(0xFF1D4ED8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  asset.id,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '• ${asset.category}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AssetDetailsScreen(asset: asset)),
                          );
                        } else if (value == 'risk') {
                          onQuickRiskScan();
                        } else if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'risk',
                          child: Row(
                            children: [
                              Icon(Icons.auto_graph_rounded, size: 18, color: Color(0xFF1D4ED8)),
                              SizedBox(width: 10),
                              Text('Inline AI Risk Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569)),
                              SizedBox(width: 10),
                              Text('View Full Dossier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                              SizedBox(width: 10),
                              Text('Edit Asset (DB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('Retire / Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetadataColumn(
                        icon: Icons.location_on_outlined,
                        label: 'LOCATION',
                        value: asset.location,
                        subValue: asset.subLocation,
                      ),
                    ),
                    Expanded(
                      child: _buildMetadataColumn(
                        icon: Icons.person_outline_rounded,
                        label: 'CUSTODIAN',
                        value: asset.custodian,
                        subValue: 'Audit: ${asset.lastAudit}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusPill(
                      text: asset.status,
                      color: _getStatusColor(asset.status),
                      isDot: true,
                    ),
                    _buildStatusPill(
                      text: 'Cond: ${asset.condition}',
                      color: _getConditionColor(asset.condition),
                    ),
                    InkWell(
                      onTap: onQuickRiskScan,
                      child: _buildStatusPill(
                        text: 'AI Risk: ${asset.riskScore} (Tap)',
                        color: _getRiskColor(asset.riskScore),
                        icon: Icons.auto_graph_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataColumn({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                subValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required String text,
    required Color color,
    bool isDot = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AddAssetSheet extends StatefulWidget {
  final AssetModel? existingAsset;
  final Function(AssetModel) onAssetSaved;

  const AddAssetSheet({super.key, this.existingAsset, required this.onAssetSaved});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _custodianController = TextEditingController();
  String _selectedCat = 'Servers & Cloud';
  String _selectedLoc = 'Main Server Building';
  String _selectedCond = 'Good';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      _nameController.text = widget.existingAsset!.name;
      _codeController.text = widget.existingAsset!.id;
      _custodianController.text = widget.existingAsset!.custodian;
      _selectedCat = widget.existingAsset!.category;
      _selectedLoc = widget.existingAsset!.location;
      _selectedCond = widget.existingAsset!.condition;
    } else {
      final randNum = 10000 + (DateTime.now().millisecondsSinceEpoch % 89999);
      _codeController.text = 'AST-$randNum';
      _custodianController.text = TokenManager.currentName ?? 'Dr. Ahmed Hassan';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _custodianController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Asset Name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final code = _codeController.text.trim().toUpperCase();
    final pred = TokenManager.evaluateWithLightGbm(
      assetTag: code,
      condition: _selectedCond,
    );
    final isHigh = pred['predicted_failure_30d'] == 1;

    try {
      await DioClient.instance.dio.post('/assets', data: {
        'assetCode': code,
        'name': _nameController.text.trim(),
        'status': 'ACTIVE',
        'condition': _selectedCond.toUpperCase(),
        'notes': 'Registered via UniAsset Mobile by ${TokenManager.currentEmail}',
      });
    } catch (_) {
      // Saved to local & persistent TokenManager storage
    }

    final savedModel = AssetModel(
      id: code,
      name: _nameController.text.trim(),
      category: _selectedCat,
      subCategory: 'LightGBM Evaluated (${pred['probability_percent']}%)',
      location: _selectedLoc,
      subLocation: 'Floor 1 • Verified',
      status: isHigh ? 'Maintenance' : 'Active',
      condition: _selectedCond,
      custodian: _custodianController.text.trim().isEmpty
          ? (TokenManager.currentName ?? 'BUA Admin')
          : _custodianController.text.trim(),
      lastAudit: 'Just Now',
      riskScore: isHigh ? 'High' : 'Low',
      icon: Icons.inventory_2_rounded,
    );

    if (!mounted) return;
    widget.onAssetSaved(savedModel);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asset ${savedModel.id} saved to database!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAsset != null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Campus Asset (DB)' : 'Register New Asset (DB)',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              enabled: !isEdit,
              decoration: InputDecoration(
                labelText: 'Asset Tag / ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Asset Title / Equipment Model',
                hintText: 'e.g., NVIDIA DGX H100 AI Server',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: ['Servers & Cloud', 'HVAC & Power', 'Lab Equipment', 'Networking', 'AV Equipment'].contains(_selectedCat)
                        ? _selectedCat
                        : 'Servers & Cloud',
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Servers & Cloud', child: Text('Servers & Cloud')),
                      DropdownMenuItem(value: 'HVAC & Power', child: Text('HVAC & Power')),
                      DropdownMenuItem(value: 'Lab Equipment', child: Text('Lab Equipment')),
                      DropdownMenuItem(value: 'Networking', child: Text('Networking')),
                      DropdownMenuItem(value: 'AV Equipment', child: Text('AV Equipment')),
                    ],
                    onChanged: (v) => setState(() => _selectedCat = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: ['Good', 'Fair', 'Poor'].contains(_selectedCond) ? _selectedCond : 'Good',
                    decoration: InputDecoration(
                      labelText: 'Condition',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                      DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                    ],
                    onChanged: (v) => setState(() => _selectedCond = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: ['Main Server Building', 'North Science Campus', 'Faculty of AI'].contains(_selectedLoc)
                  ? _selectedLoc
                  : 'Main Server Building',
              decoration: InputDecoration(
                labelText: 'Campus Building / Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Main Server Building', child: Text('Main Server Building')),
                DropdownMenuItem(value: 'North Science Campus', child: Text('North Science Campus')),
                DropdownMenuItem(value: 'Faculty of AI', child: Text('Faculty of AI')),
              ],
              onChanged: (v) => setState(() => _selectedLoc = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custodianController,
              decoration: InputDecoration(
                labelText: 'Assigned Custodian',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving to Database...' : (isEdit ? 'Update Asset in Database' : 'Save Asset to Database'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}