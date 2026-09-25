import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _searchController = TextEditingController();
  List<AssetModel> _assets = [];
  bool _isLoading = true;
  String? _selectedFilter; // null, in_service, under_maintenance, critical

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() => _isLoading = true);
    try {
      String? status;
      String? riskBand;

      if (_selectedFilter == 'in_service' || _selectedFilter == 'under_maintenance') {
        status = _selectedFilter;
      } else if (_selectedFilter == 'critical' || _selectedFilter == 'high') {
        riskBand = _selectedFilter;
      }

      final results = await ApiClient().getAssets(
        search: _searchController.text.trim(),
        status: status,
        riskBand: riskBand,
      );
      setState(() {
        _assets = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assets: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Tag, Serial, or Model...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchAssets();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _fetchAssets(),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Service', 'in_service'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Under Maintenance', 'under_maintenance'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Critical Risk', 'critical'),
                      const SizedBox(width: 8),
                      _buildFilterChip('High Risk', 'high'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Asset List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assets.isEmpty
                    ? const Center(
                        child: Text(
                          'No assets match your search filters.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAssets,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _assets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final asset = _assets[index];
                            return _buildAssetCard(asset);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: AppTheme.accentTeal,
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) {
        setState(() => _selectedFilter = filterValue);
        _fetchAssets();
      },
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    final riskColor = AppTheme.getRiskColor(asset.riskBand);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.computer, color: AppTheme.primaryNavy),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                asset.assetTag,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor, width: 1),
              ),
              child: Text(
                asset.riskBand.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${asset.brand ?? ""} ${asset.model ?? ""}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.room_outlined, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    asset.locationName ?? 'Unassigned Location',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(assetId: asset.id),
            ),
          ).then((_) => _fetchAssets());
        },
      ),
    );
  }
}
