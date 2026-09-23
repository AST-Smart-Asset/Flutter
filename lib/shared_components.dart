import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/assets/assets_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/settings/menu_sheet.dart';
import 'features/assets/views/qr_scanner_screen.dart';
import 'features/routing/location_asset_screen.dart';
import 'features/auth/login_screen.dart';
import 'core/security/token_manager.dart';

class AppDialogs {
  static void showUserProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('User Profile'),
        content: FutureBuilder<List<String?>>(
          future: Future.wait([
            TokenManager.getUserFullName(),
            TokenManager.getUserEmail(),
            TokenManager.getUserRole(),
          ]),
          builder: (context, snapshot) {
            final name = snapshot.data?[0] ?? 'Dr. Karim Mansour';
            final email = snapshot.data?[1] ?? 'admin@bua.edu.eg';
            final role = snapshot.data?[2] ?? 'Super Admin';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFF0F3A80),
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(role, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await TokenManager.clearTokens();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: Text('AI Risk Engine Warning'),
              subtitle: Text('High risk detected on UA-NMR-4110.'),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Asset Added'),
              subtitle: Text('New asset UA-NEW-857035 registered.'),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text('Asset Edited'),
              subtitle: Text('Location updated for DELL-221.'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  static void showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MenuSheet(),
    );
  }

  static void showRiskAIDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(8), 
                     decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), 
                     child: const Icon(Icons.psychology, color: Color(0xFF2563EB))
                   ),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Risk AI Insight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                         Text('Predictive anomaly scan & telemetry', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                       ],
                     )
                   ),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Assets id',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                )
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Close the dialog first
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text('Scan QR', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Running AI Risk Analysis...')));
                },
                icon: const Icon(Icons.radar, size: 18),
                label: const Text('Run Risk Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3A80),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                )
              )
            ]
          )
        )
      )
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String activeRoute; 

  const AppDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF0A2540), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UniAsset Core', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Enterprise Asset Hub', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    )
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildItem(context, 'Dashboard', Icons.grid_view, 'dashboard', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }),
            _buildItem(context, 'Assets', Icons.inventory_2_outlined, 'assets', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssetsScreen()));
            }),
            _buildItem(context, 'Locations', Icons.location_on_outlined, 'locations', () {
              Navigator.pop(context); // Close drawer first
              Navigator.push(context, MaterialPageRoute(builder: (_) => LocationAssetScreen()));
            }),
            _buildItem(context, 'Work Orders', Icons.receipt_long_outlined, 'orders', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }),
            _buildItem(context, 'Risk Prediction', Icons.psychology_outlined, 'risk', () {
              Navigator.pop(context); // Close drawer
              AppDialogs.showRiskAIDialog(context);
            }),
            const Spacer(),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/44.jpg')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dr. Alistair Vance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Asset Administrator', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          ],
                        )
                      ],
                    )
                  ),
                  IconButton(icon: const Icon(Icons.tune), onPressed: () {})
                ],
              )
            )
          ]
        )
      )
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String routeId, VoidCallback onTap) {
    bool isActive = activeRoute == routeId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.blue.shade700 : Colors.grey.shade700),
        title: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.blue.shade700 : Colors.black87)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isActive ? Colors.blue.shade50 : Colors.transparent,
        onTap: onTap,
      ),
    );
  }
}