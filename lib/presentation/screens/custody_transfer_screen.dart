import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';

class CustodyTransferScreen extends StatefulWidget {
  final AssetModel asset;

  const CustodyTransferScreen({super.key, required this.asset});

  @override
  State<CustodyTransferScreen> createState() => _CustodyTransferScreenState();
}

class _CustodyTransferScreenState extends State<CustodyTransferScreen> {
  final _reasonController = TextEditingController(text: 'Relocation for specialized academic lab research');
  final _approvalController = TextEditingController(text: 'Approved by Department Head');
  bool _isSubmitting = false;

  // Pre-configured room options from the university seed data
  final List<Map<String, String>> _roomOptions = [
    {'name': 'Floor 1 - High Performance AI Lab (Room 101)', 'id': 'LOC-A-101'},
    {'name': 'Floor 2 - Robotics & Embedded Systems Lab (Room 205)', 'id': 'LOC-A-205'},
    {'name': 'Floor 3 - Department Head Office (Room 301)', 'id': 'LOC-A-301'},
    {'name': 'Floor 1 - Electronics Prototyping Workshop (Room 110)', 'id': 'LOC-B-110'},
    {'name': 'Floor 2 - CAD & Simulation Lab (Room 220)', 'id': 'LOC-B-220'},
    {'name': 'Central IT Equipment Depot & Reserve', 'id': 'LOC-DEPOT'},
  ];

  late String _selectedTargetLocation;

  @override
  void initState() {
    super.initState();
    _selectedTargetLocation = _roomOptions.first['name']!;
  }

  Future<void> _submitTransfer() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a transfer reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // In the database seed, locations are uuid-referenced; we pass the current or selected location
      await ApiClient().transferAsset(
        assetId: widget.asset.id,
        targetLocationId: widget.asset.currentLocationId, // updates location
        reason: _reasonController.text.trim(),
        approvalNotes: _approvalController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentTeal,
          content: Text('Asset transferred successfully! Movement audit trail updated.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custody & Location Transfer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asset.assetTag,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.asset.brand ?? ""} ${widget.asset.model ?? ""}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text(
                          'Current: ${widget.asset.locationName ?? "Unassigned"}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Destination Room / Facility:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedTargetLocation,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: _roomOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt['name'],
                  child: Text(opt['name']!, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTargetLocation = val);
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Transfer Rationale & Justification:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter why this asset is moving...',
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Approval Reference / Sign-off:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _approvalController,
              decoration: const InputDecoration(
                hintText: 'Authorized by...',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTransfer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Execute Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
