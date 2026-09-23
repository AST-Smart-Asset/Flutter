import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../assets/assets_screen.dart';
import '../assets/views/qr_scanner_screen.dart';
import '../../shared_components.dart';

// -----------------------------------------------------------------------------
// Theme & Constants
// -----------------------------------------------------------------------------
class RoutingTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primaryNavy = Color(0xFF0F3A80);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color badgeBg = Color(0xFFEFF6FF);
  
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  
  static const double radiusCard = 16.0;
  static const double radiusInput = 10.0;
  static const double radiusButton = 10.0;
}

// -----------------------------------------------------------------------------
// Screen Widget
// -----------------------------------------------------------------------------
class LocationAssetScreen extends StatefulWidget {
  const LocationAssetScreen({super.key});

  @override
  State<LocationAssetScreen> createState() => _LocationAssetScreenState();
}

class _LocationAssetScreenState extends State<LocationAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetIdController = TextEditingController(text: 'AST-001');

  // 6-Level Hierarchy State
  String? _selectedCampus = 'Main Campus';
  String? _selectedBuilding = 'Science Building';
  String? _selectedCollege = 'Faculty of AI & Data Management';
  String? _selectedFloor = '2nd Floor';
  String? _selectedRoom = 'Computer Lab 3';
  String? _selectedOffice = 'AI Lab';

  @override
  void dispose() {
    _assetIdController.dispose();
    super.dispose();
  }

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
  }


  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoutingTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RoutingTheme.spacingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: RoutingTheme.spacingMd),
                _buildHeaderTexts(),
                const SizedBox(height: RoutingTheme.spacingLg),
                _buildMainCard(),
                const SizedBox(height: RoutingTheme.spacingLg),
                _buildBottomUserCard(),
              ],
            ),
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
      backgroundColor: RoutingTheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: RoutingTheme.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('UniAsset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: RoutingTheme.textMain)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: RoutingTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('CORE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Text('BADR UNIVERSITY\nASSIUT', style: TextStyle(fontSize: 9, color: RoutingTheme.primaryBlue, fontWeight: FontWeight.bold, height: 1.1)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: RoutingTheme.textSub),
          onPressed: _scanQR,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: RoutingTheme.textSub),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            )
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0, left: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: RoutingTheme.primaryBlue),
            const SizedBox(width: RoutingTheme.spacingSm),
            Text(
              'STEP 2 OF 2 • ROUTING',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Icon(Icons.verified, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text('Pinned', style: TextStyle(color: Colors.blue.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: RoutingTheme.textMain, letterSpacing: -0.5),
        ),
        const SizedBox(height: RoutingTheme.spacingXs),
        Text(
          'Select a location to access asset\ninformation.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        color: RoutingTheme.surface,
        borderRadius: BorderRadius.circular(RoutingTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(RoutingTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHierarchySection(),
          const SizedBox(height: 28),
          _buildAssetPreviewCard(),
          const SizedBox(height: 28),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hierarchy 6-Level Builder
  // ---------------------------------------------------------------------------
  Widget _buildHierarchySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: const TextSpan(
                text: 'Hierarchy Location ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RoutingTheme.textMain),
                children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
              ),
            ),
            Text('6-Level Facility Hierarchy', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: RoutingTheme.spacingSm),
        
        // Breadcrumbs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: RoutingTheme.badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                _buildBreadcrumb('Main Campus'),
                _buildBreadcrumb('Science Bld'),
                _buildBreadcrumb('AI & Data...'),
                _buildBreadcrumb('2nd F'),
                _buildBreadcrumb('Lab 3'),
                _buildBreadcrumb('AI Lab', isLast: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: RoutingTheme.spacingMd),

        // Dropdowns Grid Layout
        Row(
          children: [
            Expanded(child: _buildDropdownItem('1. CAMPUS', Icons.business, _selectedCampus, ['Main Campus', 'North Campus'], (v) => setState(() => _selectedCampus = v))),
            const SizedBox(width: RoutingTheme.spacingMd),
            Expanded(child: _buildDropdownItem('2. BUILDING', Icons.business, _selectedBuilding, ['Science Building', 'Eng Building'], (v) => setState(() => _selectedBuilding = v))),
          ],
        ),
        const SizedBox(height: RoutingTheme.spacingMd),
        _buildDropdownItem('3. COLLEGE / DEPARTMENT', Icons.school_outlined, _selectedCollege, ['Faculty of AI & Data Management'], (v) => setState(() => _selectedCollege = v)),
        const SizedBox(height: RoutingTheme.spacingMd),
        Row(
          children: [
            Expanded(child: _buildDropdownItem('4. FLOOR', Icons.layers_outlined, _selectedFloor, ['1st Floor', '2nd Floor'], (v) => setState(() => _selectedFloor = v))),
            const SizedBox(width: RoutingTheme.spacingMd),
            Expanded(child: _buildDropdownItem('5. ROOM', Icons.door_front_door_outlined, _selectedRoom, ['Computer Lab 1', 'Computer Lab 3'], (v) => setState(() => _selectedRoom = v))),
          ],
        ),
        const SizedBox(height: RoutingTheme.spacingMd),
        _buildDropdownItem('6. OFFICE / STORAGE AREA', Icons.inventory_2_outlined, _selectedOffice, ['AI Lab', 'Storage A'], (v) => setState(() => _selectedOffice = v)),
      ],
    );
  }

  Widget _buildBreadcrumb(String text, {bool isLast = false}) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
        if (!isLast) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 12, color: Colors.blue.shade300),
          const SizedBox(width: 4),
        ]
      ],
    );
  }

  Widget _buildDropdownItem(String label, IconData icon, String? value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoutingTheme.textSub, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: RoutingTheme.textSub, size: 20),
          decoration: InputDecoration(
            filled: true,
            fillColor: RoutingTheme.inputBg,
            prefixIcon: Icon(icon, color: RoutingTheme.primaryBlue, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(RoutingTheme.radiusInput), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RoutingTheme.textMain),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
          isExpanded: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Asset Preview Card
  // ---------------------------------------------------------------------------
  Widget _buildAssetPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: RoutingTheme.badgeBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100)
      ),
      padding: const EdgeInsets.all(RoutingTheme.spacingMd),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RoutingTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100)
                ),
                child: const Icon(Icons.horizontal_rule_rounded, color: RoutingTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: RoutingTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Confocal Microscope Leica S...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RoutingTheme.textMain), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Operational', style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Science Bldg, Fl 3, Rm 304', style: TextStyle(fontSize: 12, color: RoutingTheme.textSub)),
                  ],
                ),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  const Text('Calibration 98.4%', style: TextStyle(fontSize: 12, color: RoutingTheme.textSub)),
                ],
              ),
              Text('Cluster: Biomedical', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Buttons
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: RoutingTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RoutingTheme.radiusButton)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: RoutingTheme.spacingSm),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: RoutingTheme.inputBg,
              foregroundColor: RoutingTheme.textSub,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RoutingTheme.radiusButton)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 18),
                SizedBox(width: 8),
                Text('Back to Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom User Card
  // ---------------------------------------------------------------------------
  Widget _buildBottomUserCard() {
    return Container(
      decoration: BoxDecoration(
        color: RoutingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://randomuser.me/api/portraits/women/44.jpg',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Dr. Elena Rostova', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RoutingTheme.textMain)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Admin', style: TextStyle(color: Colors.indigo.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Badr Univ • Zone A Main', style: TextStyle(fontSize: 11, color: RoutingTheme.textSub)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, size: 14),
            label: const Text('SOP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              backgroundColor: RoutingTheme.inputBg,
              foregroundColor: RoutingTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 4) { AppDialogs.showMenuSheet(context); return; }
          if (index == 0) {
            _onContinue();
          } else if (index == 1) {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetsScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: const Icon(Icons.grid_view),
            ),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.inventory_2_outlined),
            ),
            label: 'Assets',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.radar_outlined),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
            ),
            label: 'Risk AI',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.receipt_long_outlined),
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.more_horiz),
            ),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}