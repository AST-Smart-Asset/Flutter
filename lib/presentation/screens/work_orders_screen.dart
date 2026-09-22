import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/work_order_model.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  List<WorkOrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkOrders();
  }

  Future<void> _fetchWorkOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiClient().getWorkOrders();
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load work orders: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompleteDialog(WorkOrderModel order) {
    final costController = TextEditingController(text: '120.00');
    final downtimeController = TextEditingController(text: '2.5');
    final notesController = TextEditingController(text: 'Service completed, fan replaced, diagnostics verified.');
    String selectedOutcome = 'repaired';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Complete Service: ${order.assetTag ?? "Asset"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              const Text('Maintenance Outcome:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedOutcome,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'repaired', child: Text('Repaired & Operational')),
                  DropdownMenuItem(value: 'passed', child: Text('Routine PM Passed')),
                  DropdownMenuItem(value: 'replaced_parts', child: Text('Replaced Parts')),
                  DropdownMenuItem(value: 'unresolvable', child: Text('Decommission / Unresolvable')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedOutcome = val);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Parts/Labor Cost (\$)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: downtimeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Downtime (Hours)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Technician Notes & Observations'),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                      setModalState(() => isSubmitting = true);
                      try {
                        await ApiClient().closeWorkOrder(
                          workOrderId: order.id,
                          outcome: selectedOutcome,
                          cost: double.tryParse(costController.text) ?? 0.0,
                          downtimeHours: double.tryParse(downtimeController.text) ?? 0.0,
                          completionNotes: notesController.text.trim(),
                          newCondition: 'good',
                        );

                        if (!mounted) return;
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.accentTeal,
                            content: Text('Work order completed! Next due date automatically scheduled.'),
                          ),
                        );
                        _fetchWorkOrders();
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error closing order: $e')),
                        );
                      }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Completion & Update Next Due Date'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders & PM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWorkOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No active work orders found.'))
              : RefreshIndicator(
                  onRefresh: _fetchWorkOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final isCompleted = order.status == 'completed';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.assetTag ?? 'Work Order',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.assetBrand ?? ""} ${order.assetModel ?? ""}',
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Location: ${order.locationName ?? "Server Room / Lab"}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Priority: ${order.priority.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: order.priority == 'critical' ? Colors.red : Colors.blueGrey,
                                    ),
                                  ),
                                  if (!isCompleted)
                                    ElevatedButton(
                                      onPressed: () => _showCompleteDialog(order),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Complete Service', style: TextStyle(fontSize: 12)),
                                    )
                                  else
                                    Text(
                                      'Outcome: ${order.outcome ?? "repaired"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
