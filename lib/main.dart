import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/asset_list_screen.dart';
import 'presentation/screens/qr_scanner_screen.dart';
import 'presentation/screens/work_orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AST-SEC-REQ-41: Initialize session from flutter_secure_storage
  await ApiClient().initSecureSession();
  runApp(const SmartAssetApp());
}

class SmartAssetApp extends StatelessWidget {
  const SmartAssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AST Smart Asset',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: ApiClient().isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/assets': (context) => const AssetListScreen(),
        '/scan': (context) => const QRScannerScreen(),
        '/work-orders': (context) => const WorkOrdersScreen(),
      },
    );
  }
}
