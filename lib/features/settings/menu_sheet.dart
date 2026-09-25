import 'package:flutter/material.dart';
import 'package:asset_management/core/security/token_manager.dart';
import 'package:asset_management/features/auth/login_screen.dart';
import 'package:asset_management/shared_components.dart';

class MenuSheet extends StatefulWidget {
  const MenuSheet({super.key});

  @override
  State<MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<MenuSheet> {
  bool _darkMode = false;
  bool _autoSyncDatabase = true;
  bool _pushHighRiskAlerts = true;
  bool _pushOrderUpdates = true;
  bool _pushStocktakeReminders = true;
  String _selectedLanguage = 'English (US)';

  void _showSystemPreferencesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF1D4ED8)),
              SizedBox(width: 10),
              Text('System Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Real-Time Database Sync', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Sync added assets & work orders immediately', style: TextStyle(fontSize: 12)),
                value: _autoSyncDatabase,
                activeTrackColor: const Color(0xFF1D4ED8),
                onChanged: (val) {
                  setDialogState(() => _autoSyncDatabase = val);
                  setState(() => _autoSyncDatabase = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High-Contrast Field Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Optimized visibility for outdoor campus scanning', style: TextStyle(fontSize: 12)),
                value: _darkMode,
                activeTrackColor: const Color(0xFF1D4ED8),
                onChanged: (val) {
                  setDialogState(() => _darkMode = val);
                  setState(() => _darkMode = val);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Interface Language',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'English (US)', child: Text('English (US)')),
                  DropdownMenuItem(value: 'Arabic (EG)', child: Text('العربية (مصر)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedLanguage = val);
                    setState(() => _selectedLanguage = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                TokenManager.logActivity(
                  title: 'System Preferences Updated',
                  subtitle: 'Auto-Sync: $_autoSyncDatabase • Language: $_selectedLanguage',
                  category: 'System',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System preferences saved to profile.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Color(0xFF1D4ED8)),
              SizedBox(width: 10),
              Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('LightGBM AI High-Risk Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Notify when failure probability >= 42.15%', style: TextStyle(fontSize: 12)),
                value: _pushHighRiskAlerts,
                activeTrackColor: const Color(0xFF1D4ED8),
                onChanged: (val) => setDialogState(() => _pushHighRiskAlerts = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Work Order Status Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Alerts for newly assigned & completed orders', style: TextStyle(fontSize: 12)),
                value: _pushOrderUpdates,
                activeTrackColor: const Color(0xFF1D4ED8),
                onChanged: (val) => setDialogState(() => _pushOrderUpdates = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ISO-55000 Stocktake Reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Scheduled campus audit notifications', style: TextStyle(fontSize: 12)),
                value: _pushStocktakeReminders,
                activeTrackColor: const Color(0xFF1D4ED8),
                onChanged: (val) => setDialogState(() => _pushStocktakeReminders = val),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification rules updated.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Apply Rules'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurityDialog() {
    final profile = TokenManager.activeProfile;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8)),
            SizedBox(width: 10),
            Text('Security & RBAC Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Role: ${profile.roleTitle}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('Account: ${TokenManager.currentEmail ?? profile.email}', style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
                  const SizedBox(height: 4),
                  Text('Scope: ${profile.department}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Active Role Capabilities:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            ...profile.permissions.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 10),
            Text('BUA Help Center & Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Badr University Enterprise Asset Management Support Desk', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            SizedBox(height: 10),
            Text('• IT Service Desk: support@bua.edu.eg'),
            SizedBox(height: 4),
            Text('• Emergency Hotline: Ext. 4400 (Campus Facilities)'),
            SizedBox(height: 4),
            Text('• AI Model Engine: LightGBM v2.4 (Threshold: 0.4215)'),
            SizedBox(height: 4),
            Text('• Cloud Backend: Render API v1 (Active)'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showIsoAuditPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Expanded(
              child: Text('ISO-55000 Compliance & Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All asset additions, custody transfers, maintenance orders, and stocktake audits are cryptographically logged with role attribution under ISO-55001:2024 Campus Asset Governance.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
            ),
            SizedBox(height: 12),
            Text('• Mandatory Audit Frequency: Quarterly per zone', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('• Predictive Maintenance SLA: 48h for Risk >= 42.15%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = TokenManager.activeProfile;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Settings & Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => AppDialogs.showUserProfile(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 5),
                          Text(
                            profile.roleTitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'System Preferences',
              subtitle: 'Real-time database sync, language & display',
              onTap: _showSystemPreferencesDialog,
            ),
            _buildMenuItem(
              icon: Icons.notifications_none_rounded,
              title: 'Push Notification Settings',
              subtitle: 'LightGBM AI alerts & work order rules',
              onTap: _showNotificationSettingsDialog,
            ),
            _buildMenuItem(
              icon: Icons.security_outlined,
              title: 'Security & Role Permissions (RBAC)',
              subtitle: 'Active role: ${profile.roleTitle} (${profile.permissions.length} permissions)',
              onTap: _showSecurityDialog,
            ),
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help Center & Support',
              subtitle: 'BUA IT service desk & predictive model info',
              onTap: _showHelpSupportDialog,
            ),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Terms & ISO-55000 Campus Policy',
              subtitle: 'Compliance standards & SLA documentation',
              onTap: _showIsoAuditPolicyDialog,
            ),
            const Divider(height: 28),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out of ${TokenManager.currentEmail ?? profile.email}',
              textColor: const Color(0xFFEF4444),
              iconColor: const Color(0xFFEF4444),
              onTap: () async {
                await TokenManager.clearTokens();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF1E293B),
    Color iconColor = const Color(0xFF64748B),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}