import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@bua.edu.eg');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isLoading = false;
  String? _errorMessage;

  void _quickFill(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'Password123!';
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiClient().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showServerSettings() {
    final serverController = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Connection Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the backend API endpoint:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:5000/api/v1',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => serverController.text = 'http://10.0.2.2:5000/api/v1',
                ),
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () => serverController.text = 'http://localhost:5000/api/v1',
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AppConfig.setBaseUrl(serverController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated API Base URL to: ${AppConfig.apiBaseUrl}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppTheme.accentTeal,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Smart Asset Inventory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Badr University in Assiut • DevHub Field Phase',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // Card Container
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sign In to Your Workspace',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Institutional Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Quick Role Fill for Demonstrations
                        const Text(
                          'Quick Demo Switcher:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuickChip('Super Admin', 'admin@bua.edu.eg'),
                            _buildQuickChip('Asset Mgr', 'asset.manager@bua.edu.eg'),
                            _buildQuickChip('Custodian', 'custodian.ai@bua.edu.eg'),
                            _buildQuickChip('Technician', 'technician@bua.edu.eg'),
                            _buildQuickChip('Auditor', 'auditor@bua.edu.eg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _showServerSettings,
                    icon: const Icon(Icons.settings, color: Colors.white70, size: 16),
                    label: const Text(
                      'Configure Backend API Endpoint',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String email) {
    final isSelected = _emailController.text == email;
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.primaryNavy)),
      backgroundColor: isSelected ? AppTheme.accentTeal : const Color(0xFFF1F5F9),
      onPressed: () => _quickFill(email),
    );
  }
}
