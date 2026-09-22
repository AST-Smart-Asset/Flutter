import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'asset_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _tagController = TextEditingController();
  bool _isSearching = false;

  Future<void> _lookupTag(String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final assets = await ApiClient().getAssets(search: cleanTag);
      final exactMatch = assets.firstWhere(
        (a) => a.assetTag.toLowerCase() == cleanTag.toLowerCase(),
        orElse: () => assets.isNotEmpty ? assets.first : throw Exception('Asset tag "$cleanTag" not found in registry.'),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssetDetailScreen(assetId: exactMatch.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('QR Code Scanner & Audit'),
      ),
      body: Column(
        children: [
          // Scanning Target Frame
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.accentTeal, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const Positioned(
                    top: 20,
                    child: Text(
                      'Align QR / Barcode within frame',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: AppTheme.accentTeal.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with Manual / Demo Tag Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Instant Tag Lookup / Keyboard Input',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. AST-PC-A101-001',
                            prefixIcon: Icon(Icons.qr_code_2),
                          ),
                          onSubmitted: _lookupTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSearching ? null : () => _lookupTag(_tagController.text),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: _isSearching
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Quick Sample Tags to Test:',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('AST-PC-A101-001 (Workstation)'),
                        onPressed: () => _lookupTag('AST-PC-A101-001'),
                      ),
                      ActionChip(
                        label: const Text('AST-SRV-A-001 (H100 Node)'),
                        onPressed: () => _lookupTag('AST-SRV-A-001'),
                      ),
                      ActionChip(
                        label: const Text('AST-ENG-B220-001 (CAD PC)'),
                        onPressed: () => _lookupTag('AST-ENG-B220-001'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
