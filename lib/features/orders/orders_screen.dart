import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared_components.dart';
import '../dashboard/dashboard_screen.dart';
import '../assets/assets_screen.dart';
import '../assets/views/qr_scanner_screen.dart';
import '../../core/network/dio_client.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------
enum OrderStatus { pending, scheduled, inProgress, completed }
enum PriorityLevel { critical, high, medium, low }

class WorkOrderModel {
  final String orderId;
  final String title;
  final String assetId;
  final String location;
  final String description;
  final OrderStatus status;
  final PriorityLevel priority;
  final String assigneeName;
  final String assigneeRole;
  final String assigneeImage;
  final String dueDate;
  final String scheduledDate;
  final String type; // e.g. "Corrective maintenance"

  const WorkOrderModel({
    required this.orderId,
    required this.title,
    required this.assetId,
    required this.location,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeName,
    required this.assigneeRole,
    required this.assigneeImage,
    required this.dueDate,
    required this.scheduledDate,
    required this.type,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? '';
    OrderStatus st = OrderStatus.pending;
    if (statusStr.contains('progress')) {
      st = OrderStatus.inProgress;
    } else if (statusStr.contains('sched')) {
      st = OrderStatus.scheduled;
    } else if (statusStr.contains('comp')) {
      st = OrderStatus.completed;
    }

    final prioStr = json['priority']?.toString().toLowerCase() ?? '';
    PriorityLevel prio = PriorityLevel.medium;
    if (prioStr.contains('crit')) {
      prio = PriorityLevel.critical;
    } else if (prioStr.contains('high')) {
      prio = PriorityLevel.high;
    } else if (prioStr.contains('low')) {
      prio = PriorityLevel.low;
    }

    final assetObj = json['asset'] as Map<String, dynamic>?;
    final tag = assetObj?['assetTag'] ?? json['assetTag'] ?? 'AST-CAMPUS';
    final assetBrand = assetObj?['brand'] ?? '';
    final assetModel = assetObj?['model'] ?? '';
    final fullTitle = (assetBrand.isNotEmpty || assetModel.isNotEmpty)
        ? '$assetBrand $assetModel'.trim()
        : (json['title'] ?? 'Campus Maintenance Order');

    final techObj = json['assignedTo'] as Map<String, dynamic>?;
    final techName = techObj?['fullName'] ?? 'Field Technician';

    return WorkOrderModel(
      orderId: json['orderNumber'] ?? json['id']?.toString().substring(0, 8).toUpperCase() ?? 'WO-2025',
      title: fullTitle,
      assetId: tag.toString(),
      location: assetObj?['currentLocation']?['name']?.toString() ?? 'Faculty of AI Lab',
      description: json['description']?.toString() ?? 'Scheduled telemetry & preventive inspection',
      status: st,
      priority: prio,
      assigneeName: techName.toString(),
      assigneeRole: 'Field Specialist',
      assigneeImage: 'https://randomuser.me/api/portraits/men/32.jpg',
      dueDate: json['dueAt']?.toString().split('T')[0] ?? '48h',
      scheduledDate: json['scheduledFor']?.toString().split('T')[0] ?? 'Today',
      type: json['maintenanceType']?.toString() ?? 'Corrective maintenance',
    );
  }
}

// -----------------------------------------------------------------------------
// Theme
// -----------------------------------------------------------------------------
class OrdersTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primaryNavy = Color(0xFF0F3A80);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  
  static Color getPriorityColor(PriorityLevel level) {
    switch (level) {
      case PriorityLevel.critical: return const Color(0xFFDC2626);
      case PriorityLevel.high: return const Color(0xFFD97706);
      case PriorityLevel.medium: return const Color(0xFF2563EB);
      case PriorityLevel.low: return const Color(0xFF64748B);
    }
  }
}

// -----------------------------------------------------------------------------
// Screen
// -----------------------------------------------------------------------------
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _selectedFilter; // null = show all
  final int _currentIndex = 3; // 'Orders' index
  final DioClient _dioClient = DioClient.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dioClient.dio.get('/work-orders');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        if (list.isNotEmpty && mounted) {
          final parsed = list.map((j) => WorkOrderModel.fromJson(j as Map<String, dynamic>)).toList();
          setState(() {
            _mockOrders.clear();
            _mockOrders.addAll(parsed);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final List<WorkOrderModel> _mockOrders = [
    const WorkOrderModel(
      orderId: 'WO-2025-0841',
      title: 'Dell Latitude 5520 Laptop',
      assetId: 'AST-IT-LAPTOP-00418',
      location: 'Engineering Building',
      description: 'Urgent system restoration - Diagnosing power fault and thermal throttling',
      status: OrderStatus.inProgress,
      priority: PriorityLevel.critical,
      assigneeName: 'Hany Bakr',
      assigneeRole: 'Senior IT Specialist',
      assigneeImage: 'https://randomuser.me/api/portraits/men/32.jpg',
      dueDate: 'Tomorrow 10:00 AM',
      scheduledDate: 'Today 2:00 PM',
      type: 'Corrective maintenance',
    ),
    const WorkOrderModel(
      orderId: 'WO-2025-0839',
      title: 'HP EliteDesk 800 G5',
      assetId: 'AST-IT-PC-00169',
      location: 'Engineering Building - Lab B1',
      description: 'Scheduled preventive maintenance & hardware diagnostic before exam period.',
      status: OrderStatus.scheduled,
      priority: PriorityLevel.high,
      assigneeName: 'Omar Zaki',
      assigneeRole: 'Systems Admin',
      assigneeImage: 'https://randomuser.me/api/portraits/men/44.jpg',
      dueDate: 'Oct 29',
      scheduledDate: 'Oct 28',
      type: 'Preventive maintenance',
    ),
    const WorkOrderModel(
      orderId: 'WO-2025-0811',
      title: 'HP LaserJet Enterprise Printer',
      assetId: 'AST-IT-PRINTER-00091',
      location: 'Administration Building',
      description: 'Service checklist verified. Maintenance log synchronized.',
      status: OrderStatus.completed,
      priority: PriorityLevel.medium,
      assigneeName: 'Salma Ibrahim',
      assigneeRole: 'Hardware Tech',
      assigneeImage: 'https://randomuser.me/api/portraits/women/68.jpg',
      dueDate: 'Completed',
      scheduledDate: 'Oct 25',
      type: 'Completed',
    ),
  ];

  List<WorkOrderModel> get _filteredOrders {
    if (_selectedFilter == null) return _mockOrders;
    return _mockOrders.where((o) => o.status == _selectedFilter).toList();
  }

  void _showCreateOrderSheet([WorkOrderModel? orderToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOrderSheet(orderToEdit: orderToEdit),
    ).then((val) {
      if (val != null && val is WorkOrderModel) {
        setState(() {
          if (orderToEdit != null) {
            final idx = _mockOrders.indexWhere((o) => o.orderId == orderToEdit.orderId);
            if (idx != -1) _mockOrders[idx] = val;
          } else {
            _mockOrders.insert(0, val);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderToEdit != null ? 'Work Order updated successfully!' : 'Work Order created successfully!'),
            backgroundColor: OrdersTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _markAsCompleted(String orderId) {
    setState(() {
      final idx = _mockOrders.indexWhere((o) => o.orderId == orderId);
      if (idx != -1) {
        final old = _mockOrders[idx];
        _mockOrders[idx] = WorkOrderModel(
          orderId: old.orderId,
          title: old.title,
          assetId: old.assetId,
          location: old.location,
          description: old.description,
          status: OrderStatus.completed, // Updated Status
          priority: old.priority,
          assigneeName: old.assigneeName,
          assigneeRole: old.assigneeRole,
          assigneeImage: old.assigneeImage,
          dueDate: old.dueDate,
          scheduledDate: old.scheduledDate,
          type: old.type,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Work Order marked as Completed!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrdersTheme.background,
      drawer: const AppDrawer(activeRoute: 'orders'),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: OrdersTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_isLoading)
              const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('ACTIVE DISPATCH QUEUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: OrdersTheme.primaryBlue, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Work Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OrdersTheme.textMain)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: OrdersTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text('${_mockOrders.length} Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateOrderSheet(),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('+ New Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OrdersTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row 1 (Priority, Tech, Fast Track)
                  Row(
                    children: [
                      _buildOutlinedFilter('Priority: All ▾'),
                      const SizedBox(width: 8),
                      _buildOutlinedFilter('Technician ▾'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: OrdersTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text('Fast-Track', style: TextStyle(fontSize: 12, color: OrdersTheme.primaryBlue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Row 2 (Status Toggles)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusFilterToggle('Pending', OrderStatus.pending, _mockOrders.where((o) => o.status == OrderStatus.pending).length),
                        const SizedBox(width: 8),
                        _buildStatusFilterToggle('Scheduled', OrderStatus.scheduled, _mockOrders.where((o) => o.status == OrderStatus.scheduled).length),
                        const SizedBox(width: 8),
                        _buildStatusFilterToggle('In Progress', OrderStatus.inProgress, _mockOrders.where((o) => o.status == OrderStatus.inProgress).length),
                        const SizedBox(width: 8),
                        _buildStatusFilterToggle('Completed', OrderStatus.completed, _mockOrders.where((o) => o.status == OrderStatus.completed).length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = _filteredOrders[index];
                  return _WorkOrderCard(
                    order: order,
                    onInspectComplete: () => _markAsCompleted(order.orderId),
                    onEdit: () => _showCreateOrderSheet(order),
                    onDelete: () {
                      setState(() => _mockOrders.removeWhere((o) => o.orderId == order.orderId));
                    },
                  );
                },
                childCount: _filteredOrders.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    ),
    bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: OrdersTheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false, 
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: OrdersTheme.textSub),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFF0A2540), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.school_rounded, color: Colors.blueAccent, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('UniAsset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: OrdersTheme.textMain)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: OrdersTheme.primaryBlue, borderRadius: BorderRadius.circular(8)),
                    child: const Text('CORE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Text('Asset Manifest', style: TextStyle(fontSize: 10, color: OrdersTheme.textSub)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded, color: OrdersTheme.textSub), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: OrdersTheme.textSub), 
              onPressed: () => AppDialogs.showNotifications(context),
            ),
            Positioned(right: 12, top: 14, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: InkWell(
            onTap: () => AppDialogs.showUserProfile(context),
            borderRadius: BorderRadius.circular(16),
            child: const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg')),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedFilter(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: OrdersTheme.textMain, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusFilterToggle(String label, OrderStatus status, int count) {
    bool isSelected = _selectedFilter == status;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : status; // toggle off if already selected
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? OrdersTheme.primaryNavy : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : OrdersTheme.textSub)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : OrdersTheme.textMain)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) { AppDialogs.showMenuSheet(context); return; }
          if (index == 2) { AppDialogs.showRiskAIDialog(context); return; }
          
          if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssetsScreen()));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: OrdersTheme.primaryBlue,
        unselectedItemColor: OrdersTheme.textSub,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Assets'),
          BottomNavigationBarItem(
            icon: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.psychology_outlined),
              Positioned(right: -2, top: -2, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ]),
            label: 'Risk AI',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Menu'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Work Order Card
// -----------------------------------------------------------------------------
class _WorkOrderCard extends StatelessWidget {
  final WorkOrderModel order;
  final VoidCallback onInspectComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkOrderCard({
    required this.order, 
    required this.onInspectComplete,
    required this.onEdit,
    required this.onDelete,
  });

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Asset QR: ${order.assetId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: QrImageView(data: '{"id": "${order.assetId}", "order": "${order.orderId}"}', version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 16),
            const Text('Scan this code to identify this physical asset.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: order.status == OrderStatus.completed ? Colors.green : OrdersTheme.getPriorityColor(order.priority)),
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
                              Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: OrdersTheme.textMain)),
                              const SizedBox(width: 8),
                              _buildPriorityChip(),
                              if (order.status == OrderStatus.completed) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(4)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified, size: 10, color: Color(0xFF16A34A)),
                                      SizedBox(width: 2),
                                      Text('COMPLETED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: OrdersTheme.textSub),
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'edit') onEdit();
                              if (val == 'delete') onDelete();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(order.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OrdersTheme.textMain)),
                      const SizedBox(height: 2),
                      Text('${order.assetId} · ${order.location}', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      // Status Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: _getStatusColor(order.status)),
                                    const SizedBox(width: 6),
                                    Text(order.status.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(order.status))),
                                  ],
                                ),
                                Text(order.type, style: const TextStyle(fontSize: 10, color: OrdersTheme.textSub)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(order.description, style: const TextStyle(fontSize: 12, color: OrdersTheme.textSub, height: 1.4)),
                            if (order.status == OrderStatus.inProgress) ...[
                               const SizedBox(height: 12),
                               LinearProgressIndicator(value: 0.6, backgroundColor: Colors.blue.shade100, color: Colors.blue),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assignee & Dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 14, backgroundImage: NetworkImage(order.assigneeImage)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.assigneeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OrdersTheme.textMain)),
                                  Text(order.assigneeRole, style: const TextStyle(fontSize: 10, color: OrdersTheme.textSub)),
                                ],
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 12, color: order.priority == PriorityLevel.critical && order.status != OrderStatus.completed ? Colors.red : OrdersTheme.textMain),
                                  const SizedBox(width: 4),
                                  Text(order.status == OrderStatus.completed ? order.dueDate : 'Due: ${order.dueDate}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: order.priority == PriorityLevel.critical && order.status != OrderStatus.completed ? Colors.red : OrdersTheme.textMain)),
                                ],
                              ),
                              Text('Sched: ${order.scheduledDate}', style: const TextStyle(fontSize: 10, color: OrdersTheme.textSub)),
                            ],
                          )
                        ],
                      ),

                      if (order.status != OrderStatus.completed) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onInspectComplete,
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Inspect Task & Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: OrdersTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showQrDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.qr_code, color: OrdersTheme.primaryNavy),
                              ),
                            )
                          ],
                        )
                      ]
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.scheduled: return Colors.purple;
      case OrderStatus.inProgress: return Colors.blue;
      case OrderStatus.completed: return Colors.green;
    }
  }

  Widget _buildPriorityChip() {
    Color bg; Color text; String label;
    switch (order.priority) {
      case PriorityLevel.critical: bg = const Color(0xFFDC2626); text = Colors.white; label = 'CRITICAL'; break;
      case PriorityLevel.high: bg = const Color(0xFFFEF3C7); text = const Color(0xFFD97706); label = 'HIGH'; break;
      case PriorityLevel.medium: bg = const Color(0xFFDBEAFE); text = const Color(0xFF2563EB); label = 'MEDIUM'; break;
      case PriorityLevel.low: bg = const Color(0xFFF1F5F9); text = const Color(0xFF64748B); label = 'LOW'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text)),
    );
  }
}

// -----------------------------------------------------------------------------
// Create Order Bottom Sheet
// -----------------------------------------------------------------------------
class CreateOrderSheet extends StatefulWidget {
  final WorkOrderModel? orderToEdit;
  const CreateOrderSheet({super.key, this.orderToEdit});

  @override
  State<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  
  String _asset = 'Dell Latitude 5520 (UA-RM3-00412)';
  PriorityLevel _priority = PriorityLevel.high;
  String _assignee = 'Sabrina Ibrahim (Lead Hardware Tech)';

  @override
  void initState() {
    super.initState();
    if (widget.orderToEdit != null) {
      _titleCtrl.text = widget.orderToEdit!.title;
      _descCtrl.text = widget.orderToEdit!.description;
      _dateCtrl.text = widget.orderToEdit!.dueDate;
      _priority = widget.orderToEdit!.priority;
    } else {
      _dateCtrl.text = '11/04/2025';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newOrder = WorkOrderModel(
        orderId: widget.orderToEdit?.orderId ?? 'WO-NEW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        title: _titleCtrl.text.isEmpty ? 'New Task' : _titleCtrl.text,
        assetId: 'AST-NEW-000',
        location: 'Room 304 - Faculty of Engineering Lab',
        description: _descCtrl.text.isEmpty ? 'Maintenance request' : _descCtrl.text,
        status: widget.orderToEdit?.status ?? OrderStatus.pending,
        priority: _priority,
        assigneeName: 'Sabrina Ibrahim',
        assigneeRole: 'Lead Hardware Tech',
        assigneeImage: 'https://randomuser.me/api/portraits/women/68.jpg',
        dueDate: _dateCtrl.text,
        scheduledDate: 'Unscheduled',
        type: 'Corrective maintenance',
      );
      Navigator.pop(context, newOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: OrdersTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(widget.orderToEdit != null ? 'Edit Work Order' : 'Create Work Order', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Work Order Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Select Asset *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _asset,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  items: ['Dell Latitude 5520 (UA-RM3-00412)', 'HP EliteDesk (UA-RM1-002)'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _asset = v!),
                ),
                const SizedBox(height: 4),
                Text('📍 Room 304 • Faculty of Engineering Lab', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                const SizedBox(height: 16),

                const Text('Priority Level *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPrioritySelect(PriorityLevel.critical, 'Critical', Colors.red),
                    _buildPrioritySelect(PriorityLevel.high, 'High', Colors.orange),
                    _buildPrioritySelect(PriorityLevel.medium, 'Medium', Colors.blue),
                    _buildPrioritySelect(PriorityLevel.low, 'Low', Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Assignee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _assignee,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  items: ['Sabrina Ibrahim (Lead Hardware Tech)', 'Omar Zaki (Systems Admin)'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _assignee = v!),
                ),
                const SizedBox(height: 16),

                const Text('Target Completion Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _dateCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(widget.orderToEdit != null ? 'Update Order' : 'Create Order', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrdersTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelect(PriorityLevel level, String label, Color dotColor) {
    bool isSel = _priority == level;
    return InkWell(
      onTap: () => setState(() => _priority = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? dotColor.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSel ? dotColor : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 8, color: dotColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: OrdersTheme.textMain)),
          ],
        ),
      ),
    );
  }
}