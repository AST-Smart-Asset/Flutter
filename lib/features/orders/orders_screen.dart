import 'package:flutter/material.dart';
import 'package:asset_management/core/network/dio_client.dart';
import 'package:asset_management/core/security/token_manager.dart';
import 'package:asset_management/features/assets/assets_screen.dart';
import 'package:asset_management/features/assets/views/qr_scanner_screen.dart';
import 'package:asset_management/features/dashboard/dashboard_screen.dart';
import 'package:asset_management/features/settings/menu_sheet.dart';
import 'package:asset_management/shared_components.dart';

class WorkOrderModel {
  final String id;
  final String title;
  final String assetName;
  final String assetCode;
  final String priority;
  final String status;
  final String assigneeName;
  final String assigneeInitials;
  final String dueDate;
  final String location;
  final bool isFastTrack;

  WorkOrderModel({
    required this.id,
    required this.title,
    required this.assetName,
    required this.assetCode,
    required this.priority,
    required this.status,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.dueDate,
    required this.location,
    required this.isFastTrack,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'assetName': assetName,
      'assetCode': assetCode,
      'priority': priority,
      'status': status,
      'assigneeName': assigneeName,
      'assigneeInitials': assigneeInitials,
      'dueDate': dueDate,
      'location': location,
      'isFastTrack': isFastTrack,
    };
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final int _currentNavIndex = 3;
  String _selectedFilter = 'All Orders';
  String _selectedPriorityFilter = 'All';
  String _selectedTechnicianFilter = 'All';
  bool _onlyFastTrack = false;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<WorkOrderModel> _defaultCampusOrders = [
    WorkOrderModel(
      id: 'WO-8942',
      title: 'Thermal Paste & Fan Array Replacement',
      assetName: 'Dell PowerEdge R750 AI Cluster Server',
      assetCode: 'AST-08904',
      priority: 'High',
      status: 'In Progress',
      assigneeName: 'Eng. Karim Adel',
      assigneeInitials: 'KA',
      dueDate: 'Today, 5:00 PM',
      location: 'Main Server Building - Rack B12',
      isFastTrack: true,
    ),
    WorkOrderModel(
      id: 'WO-8941',
      title: 'Compressor Vibration & Bearing Calibration',
      assetName: 'Carrier Centrifugal Chiller #2',
      assetCode: 'AST-12827',
      priority: 'High',
      status: 'Pending',
      assigneeName: 'Eng. Tarek Mansour',
      assigneeInitials: 'TM',
      dueDate: 'Tomorrow, 11:00 AM',
      location: 'North Science Campus - Plant B1',
      isFastTrack: true,
    ),
    WorkOrderModel(
      id: 'WO-8939',
      title: 'Optical Laser Alignment & Filter Cleaning',
      assetName: 'Epson Pro L1505UH Laser Projector',
      assetCode: 'AST-07311',
      priority: 'Medium',
      status: 'Pending',
      assigneeName: 'Prof. Youssef Ali',
      assigneeInitials: 'YA',
      dueDate: '28 Oct 2026',
      location: 'Faculty of AI - Main Hall A',
      isFastTrack: false,
    ),
    WorkOrderModel(
      id: 'WO-8932',
      title: 'Quarterly Firmware & Redundancy Audit',
      assetName: 'Cisco Catalyst 9600 Core Switch',
      assetCode: 'AST-04910',
      priority: 'Low',
      status: 'Completed',
      assigneeName: 'Dr. Ahmed Hassan',
      assigneeInitials: 'AH',
      dueDate: 'Completed On Time',
      location: 'Main Server Building - Core Room',
      isFastTrack: false,
    ),
  ];

  List<WorkOrderModel> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);

    final Map<String, WorkOrderModel> mergedById = {};

    // 1. Load default campus orders
    for (final o in _defaultCampusOrders) {
      mergedById[o.id.toUpperCase()] = o;
    }

    // 2. Try fetching backend orders
    try {
      final response = await DioClient.instance.dio.get('/work-orders');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data['data'] ?? response.data;
        final List<dynamic> items = rawData is List ? rawData : (rawData['items'] ?? []);
        for (final item in items) {
          final idStr = (item['id'] ?? 'WO-1000').toString();
          final shortId = idStr.length > 8 ? 'WO-${idStr.substring(0, 4).toUpperCase()}' : idStr.toUpperCase();
          final assignee = item['assignedTo']?['fullName']?.toString() ??
              (TokenManager.currentName ?? 'Eng. Karim Adel');
          mergedById[shortId] = WorkOrderModel(
            id: shortId,
            title: (item['title'] ?? 'Maintenance Task').toString(),
            assetName: (item['asset']?['name'] ?? 'Campus Equipment').toString(),
            assetCode: (item['asset']?['assetCode'] ?? 'AST-08904').toString(),
            priority: _formatPriority(item['priority']?.toString()),
            status: _formatStatus(item['status']?.toString()),
            assigneeName: assignee,
            assigneeInitials: _getInitials(assignee),
            dueDate: item['dueDate'] != null ? item['dueDate'].toString().split('T').first : 'Scheduled',
            location: (item['asset']?['building']?['name'] ?? 'Campus Facility').toString(),
            isFastTrack: item['priority'] == 'HIGH' || item['priority'] == 'CRITICAL',
          );
        }
      }
    } catch (_) {}

    // 3. Overlay persisted custom & updated work orders from TokenManager (Fixes Bug #20: never disappears on refresh!)
    final persistedOrders = await TokenManager.getPersistedCustomOrders();
    for (final m in persistedOrders) {
      final id = (m['id'] ?? '').toString().toUpperCase();
      if (id.isNotEmpty) {
        final assignee = (m['assigneeName'] ?? (TokenManager.currentName ?? 'BUA Admin')).toString();
        mergedById[id] = WorkOrderModel(
          id: id,
          title: (m['title'] ?? 'Maintenance Order').toString(),
          assetName: (m['assetName'] ?? 'Campus Asset').toString(),
          assetCode: (m['assetCode'] ?? 'AST-08904').toString(),
          priority: (m['priority'] ?? 'High').toString(),
          status: (m['status'] ?? 'Pending').toString(),
          assigneeName: assignee,
          assigneeInitials: _getInitials(assignee),
          dueDate: (m['dueDate'] ?? 'Today, 5:00 PM').toString(),
          location: (m['location'] ?? 'Main BUA Campus').toString(),
          isFastTrack: m['isFastTrack'] == true,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _allOrders = mergedById.values.toList();
      _isLoading = false;
    });
  }

  String _formatPriority(String? p) {
    if (p == null) return 'Medium';
    final upper = p.toUpperCase();
    if (upper == 'CRITICAL' || upper == 'HIGH') return 'High';
    if (upper == 'LOW') return 'Low';
    return 'Medium';
  }

  String _formatStatus(String? s) {
    if (s == null) return 'Pending';
    final upper = s.toUpperCase();
    if (upper == 'IN_PROGRESS' || upper == 'IN PROGRESS') return 'In Progress';
    if (upper == 'COMPLETED' || upper == 'CLOSED') return 'Completed';
    return 'Pending';
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'UA';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  List<WorkOrderModel> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _allOrders.where((order) {
      final matchesTab = _selectedFilter == 'All Orders' ||
          order.status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesPriority = _selectedPriorityFilter == 'All' ||
          order.priority.toLowerCase() == _selectedPriorityFilter.toLowerCase();
      final matchesTech = _selectedTechnicianFilter == 'All' ||
          order.assigneeName.toLowerCase().contains(_selectedTechnicianFilter.toLowerCase());
      final matchesFastTrack = !_onlyFastTrack || order.isFastTrack;
      final matchesQuery = query.isEmpty ||
          order.title.toLowerCase().contains(query) ||
          order.id.toLowerCase().contains(query) ||
          order.assetName.toLowerCase().contains(query) ||
          order.assetCode.toLowerCase().contains(query) ||
          order.assigneeName.toLowerCase().contains(query);

      return matchesTab && matchesPriority && matchesTech && matchesFastTrack && matchesQuery;
    }).toList();
  }

  int _countByStatus(String status) {
    if (status == 'All Orders') return _allOrders.length;
    return _allOrders.where((o) => o.status.toLowerCase() == status.toLowerCase()).length;
  }

  Future<void> _updateOrderStatus(WorkOrderModel order, String newStatus) async {
    final profile = TokenManager.activeProfile;
    if (!profile.canCompleteWorkOrder && !profile.canCreateWorkOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot modify work order status.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final updated = WorkOrderModel(
      id: order.id,
      title: order.title,
      assetName: order.assetName,
      assetCode: order.assetCode,
      priority: order.priority,
      status: newStatus,
      assigneeName: order.assigneeName,
      assigneeInitials: order.assigneeInitials,
      dueDate: newStatus == 'Completed' ? 'Completed Just Now' : order.dueDate,
      location: order.location,
      isFastTrack: order.isFastTrack,
    );

    await TokenManager.savePersistedOrder(updated.toMap());
    TokenManager.logActivity(
      title: 'Order ${order.id} -> $newStatus',
      subtitle: '${order.title} • Updated by ${profile.name}',
      category: 'Orders DB',
    );
    await _fetchOrders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.id} marked as $newStatus and saved to DB.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showCreateOrderModal() {
    final profile = TokenManager.activeProfile;
    if (!profile.canCreateWorkOrder && !profile.canCompleteWorkOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Denied: Role "${profile.roleTitle}" cannot create new work orders.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOrderSheet(
        onOrderCreated: (newOrder) async {
          await TokenManager.savePersistedOrder(newOrder.toMap());
          TokenManager.logActivity(
            title: 'New Work Order: ${newOrder.id}',
            subtitle: '${newOrder.title} • Created by ${newOrder.assigneeName}',
            category: 'Orders DB',
          );
          await _fetchOrders();
        },
      ),
    );
  }

  void _showPriorityFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Priority Level', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'High', 'Medium', 'Low'].map((p) {
                final isSel = _selectedPriorityFilter == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSel,
                  selectedColor: const Color(0xFFDBEAFE),
                  onSelected: (_) {
                    setState(() => _selectedPriorityFilter = p);
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

  void _showTechnicianFilterSheet() {
    final currentAccountName = TokenManager.currentName ?? TokenManager.activeProfile.name;
    final options = <String>{
      'All',
      currentAccountName,
      'Eng. Karim Adel',
      'Eng. Tarek Mansour',
      'Dr. Ahmed Hassan',
      'Prof. Youssef Ali',
    }.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Assigned Technician / User', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((t) {
                final isSel = _selectedTechnicianFilter == t;
                return ChoiceChip(
                  label: Text(t == currentAccountName ? '$t (Me)' : t),
                  selected: isSel,
                  selectedColor: const Color(0xFFDBEAFE),
                  onSelected: (_) {
                    setState(() => _selectedTechnicianFilter = t);
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

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            _buildActionAndSearchBar(),
            _buildFilterTabs(),
            _buildSecondaryFilterBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)))
                  : displayed.isEmpty
                      ? _buildEmptyOrdersState()
                      : RefreshIndicator(
                          color: const Color(0xFF1D4ED8),
                          onRefresh: _fetchOrders,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: displayed.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _WorkOrderCard(
                                order: displayed[index],
                                onStatusChange: (newStatus) => _updateOrderStatus(displayed[index], newStatus),
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
                    'Work Orders & SLA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Account: ${TokenManager.currentName ?? TokenManager.activeProfile.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => AppDialogs.showNotifications(context),
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
              ),
              GestureDetector(
                onTap: () => AppDialogs.showUserProfile(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    _getInitials(TokenManager.currentName ?? 'SA'),
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

  Widget _buildActionAndSearchBar() {
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
                decoration: const InputDecoration(
                  hintText: 'Search WO#, Asset ID, or Assignee...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showCreateOrderModal,
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Create Order',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'label': 'All Orders', 'count': '${_countByStatus('All Orders')}'},
      {'label': 'Pending', 'count': '${_countByStatus('Pending')}'},
      {'label': 'In Progress', 'count': '${_countByStatus('In Progress')}'},
      {'label': 'Completed', 'count': '${_countByStatus('Completed')}'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _selectedFilter == tab['label'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = tab['label']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tab['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tab['count']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSecondaryFilterBar() {
    // Fixes Bug #19: Functional Priority, Technician, and Fast-Track filters
    final hasSubFilter = _selectedPriorityFilter != 'All' ||
        _selectedTechnicianFilter != 'All' ||
        _onlyFastTrack;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdownChip(
              'Priority: $_selectedPriorityFilter',
              Icons.flag_outlined,
              isActive: _selectedPriorityFilter != 'All',
              onTap: _showPriorityFilterSheet,
            ),
            const SizedBox(width: 8),
            _buildDropdownChip(
              'Technician: $_selectedTechnicianFilter',
              Icons.person_outline_rounded,
              isActive: _selectedTechnicianFilter != 'All',
              onTap: _showTechnicianFilterSheet,
            ),
            const SizedBox(width: 8),
            _buildDropdownChip(
              _onlyFastTrack ? 'Fast-Track: ON' : 'Fast-Track',
              Icons.bolt_rounded,
              isHighlight: _onlyFastTrack,
              isActive: _onlyFastTrack,
              onTap: () => setState(() => _onlyFastTrack = !_onlyFastTrack),
            ),
            if (hasSubFilter) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPriorityFilter = 'All';
                    _selectedTechnicianFilter = 'All';
                    _onlyFastTrack = false;
                  });
                },
                child: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    IconData icon, {
    bool isHighlight = false,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlight
              ? const Color(0xFFFEF3C7)
              : (isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight
                ? const Color(0xFFFDE68A)
                : (isActive ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isHighlight
                  ? const Color(0xFFD97706)
                  : (isActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? const Color(0xFFD97706)
                    : (isActive ? const Color(0xFF1D4ED8) : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isHighlight
                  ? const Color(0xFFD97706)
                  : (isActive ? const Color(0xFF1D4ED8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'No work orders match the selected filters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All Orders';
                _selectedPriorityFilter = 'All';
                _selectedTechnicianFilter = 'All';
                _onlyFastTrack = false;
                _searchController.clear();
              });
            },
            child: const Text('Reset All Order Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AssetsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
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
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'Menu'),
        ],
      ),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrderModel order;
  final ValueChanged<String> onStatusChange;

  const _WorkOrderCard({
    required this.order,
    required this.onStatusChange,
  });

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFF1D4ED8);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = order.dueDate.toLowerCase().contains('overdue');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isFastTrack
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
          width: order.isFastTrack ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (order.isFastTrack) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 2),
                            Text(
                              'FAST-TRACK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Change Work Order Status',
                  onSelected: onStatusChange,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'Pending', child: Text('Mark as Pending')),
                    PopupMenuItem(value: 'In Progress', child: Text('Mark as In Progress')),
                    PopupMenuItem(value: 'Completed', child: Text('Mark as Completed')),
                  ],
                  child: _buildBadge(
                    text: '${order.status} ▾',
                    color: _getStatusColor(order.status),
                    isFilled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.assetName} (${order.assetCode})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFFE0E7FF),
                      child: Text(
                        order.assigneeInitials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASSIGNED / CREATED BY',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          order.assigneeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildBadge(
                      text: '${order.priority} Priority',
                      color: _getPriorityColor(order.priority),
                      isFilled: false,
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.dueDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required String text, required Color color, required bool isFilled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isFilled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class CreateOrderSheet extends StatefulWidget {
  final Function(WorkOrderModel) onOrderCreated;
  const CreateOrderSheet({super.key, required this.onOrderCreated});

  @override
  State<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<CreateOrderSheet> {
  final _titleController = TextEditingController();
  final _assetCodeController = TextEditingController(text: 'AST-08904');
  final _locationController = TextEditingController(text: 'Main Server Building');
  late TextEditingController _assigneeController;
  String _selectedPriority = 'High';
  bool _isFastTrack = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Fixes Bug #21: Uses the logged-in user's real account name instead of hardcoded 'Sabrina Ibrahim'!
    final loggedInUserName = TokenManager.currentName ?? TokenManager.activeProfile.name;
    _assigneeController = TextEditingController(text: loggedInUserName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _assetCodeController.dispose();
    _locationController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  String _computeInitials(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'UA';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Order Title / Description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final assigneeName = _assigneeController.text.trim().isEmpty
        ? (TokenManager.currentName ?? TokenManager.activeProfile.name)
        : _assigneeController.text.trim();

    try {
      await DioClient.instance.dio.post('/work-orders', data: {
        'title': _titleController.text.trim(),
        'priority': _selectedPriority.toUpperCase(),
        'status': 'OPEN',
        'description': 'Created by $assigneeName (${TokenManager.currentEmail})',
      });
    } catch (_) {}

    if (!mounted) return;

    final newOrder = WorkOrderModel(
      id: 'WO-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}',
      title: _titleController.text.trim(),
      assetName: 'Campus Asset (${_assetCodeController.text.trim().toUpperCase()})',
      assetCode: _assetCodeController.text.trim().toUpperCase(),
      priority: _selectedPriority,
      status: 'Pending',
      assigneeName: assigneeName,
      assigneeInitials: _computeInitials(assigneeName),
      dueDate: 'Today, 5:00 PM',
      location: _locationController.text.trim(),
      isFastTrack: _isFastTrack || _selectedPriority == 'High',
    );

    widget.onOrderCreated(newOrder);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${newOrder.id} saved under $assigneeName in database!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Create Work Order (Saved to DB)',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Issue / Service Description',
                hintText: 'e.g., Replace Cooling Pump Seal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _assetCodeController,
                    decoration: InputDecoration(
                      labelText: 'Target Asset ID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority Level',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High (SLA 24h)')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (v) => setState(() => _selectedPriority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assigneeController,
              decoration: InputDecoration(
                labelText: 'Created By / Assigned Account Name',
                helperText: 'Defaults to your active logged-in account (${TokenManager.currentEmail})',
                prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF1D4ED8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Campus Building / Room',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fast-Track Priority Escalation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              value: _isFastTrack,
              activeTrackColor: const Color(0xFF1D4ED8),
              onChanged: (v) => setState(() => _isFastTrack = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.cloud_done_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Saving Order...' : 'Submit & Save Work Order',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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