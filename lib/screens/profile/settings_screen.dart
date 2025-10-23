import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local placeholder state (until real settings provider is wired)
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool smsNotifications = true;

  String themePreference = 'System'; // System | Light | Dark

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  void _showThemeSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget option(String label, IconData icon) {
          return ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(label),
            trailing: themePreference == label
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              setState(() => themePreference = label);
              Navigator.pop(ctx);
              _showComingSoon('Theme: $label');
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option('System', Icons.settings_suggest_outlined),
              option('Light', Icons.light_mode_outlined),
              option('Dark', Icons.dark_mode_outlined),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: cs.primary.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final iconColor = Theme.of(context).iconTheme.color;
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _switch({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: (v) {
        setState(() => onChanged(v));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Account',
            children: [
              _tile(
                icon: Icons.person_outline,
                title: 'Edit profile',
                onTap: () => _showComingSoon('Edit profile'),
              ),
              _tile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () => _showComingSoon('Change password'),
              ),
              _tile(
                icon: Icons.location_on_outlined,
                title: 'Saved addresses',
                onTap: () => _showComingSoon('Saved addresses'),
              ),
              _tile(
                icon: Icons.credit_card_outlined,
                title: 'Payment methods',
                onTap: () => _showComingSoon('Payment methods'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Notifications',
            children: [
              _switch(
                icon: Icons.notifications_active_outlined,
                title: 'Push notifications',
                subtitle: 'Important updates and status alerts',
                value: pushNotifications,
                onChanged: (v) => pushNotifications = v,
              ),
              _switch(
                icon: Icons.email_outlined,
                title: 'Email notifications',
                subtitle: 'Receipts and announcements',
                value: emailNotifications,
                onChanged: (v) => emailNotifications = v,
              ),
              _switch(
                icon: Icons.sms_outlined,
                title: 'SMS notifications',
                subtitle: 'Backup alerts when offline',
                value: smsNotifications,
                onChanged: (v) => smsNotifications = v,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Appearance',
            children: [
              _tile(
                icon: Icons.color_lens_outlined,
                title: 'Theme',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themePreference,
                      style: TextStyle(color: theme.hintColor),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _showThemeSheet,
              ),
              _tile(
                icon: Icons.text_increase_outlined,
                title: 'Text size',
                subtitle: 'Medium',
                onTap: () => _showComingSoon('Text size'),
              ),
              _switch(
                icon: Icons.visibility_outlined,
                title: 'High contrast',
                subtitle: 'Improve visibility and readability',
                value: false,
                onChanged: (_) => _showComingSoon('High contrast'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'About',
            children: [
              _tile(
                icon: Icons.info_outline,
                title: 'About Molo',
                onTap: () => _showComingSoon('About Molo'),
              ),
              _tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => _showComingSoon('Privacy policy'),
              ),
              _tile(
                icon: Icons.gavel_outlined,
                title: 'Terms of service',
                onTap: () => _showComingSoon('Terms of service'),
              ),
              _tile(
                icon: Icons.bug_report_outlined,
                title: 'Send feedback',
                onTap: () => _showComingSoon('Send feedback'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
