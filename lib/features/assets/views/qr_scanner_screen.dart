import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../assets_screen.dart';
import 'asset_details_screen.dart';

// -----------------------------------------------------------------------------
// Theme & Constants
// -----------------------------------------------------------------------------
class ScannerTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primaryNavy = Color(0xFF072C5F);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color inputBg = Color(0xFFF0F4FA);
  static const Color viewfinderBg = Color(0xFF0C1628);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color sensorBg = Color(0xFFE0EDFF);
}

// -----------------------------------------------------------------------------
// Screen Widget
// -----------------------------------------------------------------------------
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final TextEditingController _manualInputController = TextEditingController();
  final FocusNode _manualFocusNode = FocusNode();

  bool _isScanned = false;
  bool _isLoading = false;
  bool _showGrid = false;
  
  // Basic validation regex
  final RegExp _assetIdRegex = RegExp(r'^AST-[0-9]{4}-[A-Z]{3}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _laserController, curve: Curves.easeInOut));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _scannerController.stop();
        break;
      case AppLifecycleState.resumed:
        _scannerController.start();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _laserController.dispose();
    _manualInputController.dispose();
    _manualFocusNode.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
          _manualInputController.text = barcode.rawValue!;
        });
        HapticFeedback.lightImpact();
        _verifyAsset(barcode.rawValue!);
        break;
      }
    }
  }

  void _verifyAsset(String assetId) async {
    final cleanId = assetId.trim();
    if (cleanId.isEmpty) return;

    final isStandardFormat = _assetIdRegex.hasMatch(cleanId) || cleanId.startsWith('AST-');

    setState(() {
      _isLoading = true;
    });
    
    // Simulate network lookup delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isStandardFormat ? Icons.check_circle : Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(isStandardFormat ? 'Verified Campus Asset: $cleanId' : 'Recognized Code: $cleanId'),
          ],
        ),
        backgroundColor: isStandardFormat ? Colors.green.shade600 : Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewAssetDetails() {
    final assetId = _manualInputController.text.trim();
    if (assetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter an Asset ID first.')),
      );
      return;
    }

    // Pass a dummy/mock asset to details for demonstration based on scanned ID
    final mockScannedAsset = AssetModel(
      id: assetId,
      serialNumber: 'S/N: N/A',
      name: 'Scanned Physical Asset',
      modelDetails: 'Verified via QR',
      location: 'Unknown Location',
      imageUrl: 'https://randomuser.me/api/portraits/lego/1.jpg',
      custodian: 'Pending Assignment',
      warrantyText: 'Valid',
      isWarrantyExpiring: false,
      riskScore: 0,
      telemetryMetric: 'No Data',
      sparklineData: [0,0,0],
      status: AssetStatus.inUse,
      condition: AssetCondition.good,
      accentColor: ScannerTheme.primaryBlue,
      qrPayload: '{"id":"$assetId"}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetDetailsScreen(asset: mockScannedAsset)),
    );
  }

  void _scanAgain() {
    setState(() {
      _isScanned = false;
      _manualInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScannerTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleAndStatus(),
              const SizedBox(height: 20),
              _buildOpticalViewfinder(),
              const SizedBox(height: 24),
              _buildManualInputCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ScannerTheme.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: ScannerTheme.textMain),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ScannerTheme.primaryNavy, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.school_rounded, color: Colors.blueAccent, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('UNIASSET CORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ScannerTheme.textSub, letterSpacing: 0.5)),
              const Text('Qr Scanner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ScannerTheme.textMain)),
            ],
          ),
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildTitleAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scan Asset QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ScannerTheme.textMain, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Align the QR code inside the optical\nviewfinder frame.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: ScannerTheme.sensorBg, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.5, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  return Opacity(
                    opacity: val,
                    child: const Icon(Icons.circle, size: 8, color: ScannerTheme.primaryBlue),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text('SENSOR ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ScannerTheme.primaryBlue, letterSpacing: 0.5)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOpticalViewfinder() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: ScannerTheme.viewfinderBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: ScannerTheme.primaryBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Scanner View
            if (!_isScanned)
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              
            if (_isScanned)
              Container(color: ScannerTheme.viewfinderBg.withOpacity(0.8)),

            // Grid Overlay
            if (_showGrid && !_isScanned)
              CustomPaint(
                painter: _GridPainter(),
                child: Container(),
              ),

            // Neon Blue Brackets Frame
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: ScannerTheme.neonBlue.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    _buildCornerBracket(top: true, left: true),
                    _buildCornerBracket(top: true, left: false),
                    _buildCornerBracket(top: false, left: true),
                    _buildCornerBracket(top: false, left: false),

                    // Laser Line
                    if (!_isScanned)
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: _laserAnimation.value * 210, // Moves from 0 to 210
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: ScannerTheme.neonBlue,
                                boxShadow: [
                                  BoxShadow(color: ScannerTheme.neonBlue.withOpacity(0.8), blurRadius: 8, spreadRadius: 2),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: ScannerTheme.surface, shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                    if (_isScanned)
                      const Center(
                        child: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                      )
                  ],
                ),
              ),
            ),

            // In-Viewfinder Floating Controls
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Torch Toggle
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _scannerController,
                    builder: (context, state, child) {
                      final bool isTorchOn = state.torchState == TorchState.on;
                      return InkWell(
                        onTap: () => _scannerController.toggleTorch(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(isTorchOn ? Icons.flashlight_on : Icons.flashlight_off, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(isTorchOn ? 'Torch On' : 'Torch Off', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Camera Actions
                  Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.grid_4x4_rounded, 
                        isActive: _showGrid,
                        onTap: () => setState(() => _showGrid = !_showGrid),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.flip_camera_ios_rounded, 
                        onTap: () => _scannerController.switchCamera(),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: ScannerTheme.neonBlue, width: 4) : BorderSide.none,
            bottom: top ? BorderSide.none : const BorderSide(color: ScannerTheme.neonBlue, width: 4),
            left: left ? const BorderSide(color: ScannerTheme.neonBlue, width: 4) : BorderSide.none,
            right: left ? BorderSide.none : const BorderSide(color: ScannerTheme.neonBlue, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(16) : Radius.zero,
            topRight: top && !left ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? ScannerTheme.primaryBlue.withOpacity(0.5) : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildManualInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: ScannerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Or enter Asset ID manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ScannerTheme.textMain)),
              Text('FORMAT: AST-XXXX-CAT', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualInputController,
                  focusNode: _manualFocusNode,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ScannerTheme.textMain),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ScannerTheme.inputBg,
                    hintText: 'AST-8492-MED',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.document_scanner_outlined, color: ScannerTheme.primaryBlue, size: 20),
                    suffixIcon: _manualInputController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: ScannerTheme.textSub),
                            onPressed: () {
                              setState(() {
                                _manualInputController.clear();
                                _isScanned = false;
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() {}),
                  onSubmitted: (v) => _verifyAsset(v),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _manualInputController.text.isNotEmpty ? () => _verifyAsset(_manualInputController.text) : null,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: ScannerTheme.sensorBg,
                  foregroundColor: ScannerTheme.primaryBlue,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _viewAssetDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: ScannerTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Asset Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Scan Again', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: ScannerTheme.inputBg,
                  foregroundColor: ScannerTheme.textSub,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Assets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: ScannerTheme.inputBg,
                  foregroundColor: ScannerTheme.textSub,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

// Custom Painter for the optional Grid Overlay
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), paint);
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}