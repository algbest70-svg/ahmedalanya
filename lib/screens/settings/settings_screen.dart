import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/property_provider.dart';
import '../../providers/settings_provider.dart';
import '../admin/admin_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات (Settings)'),
      ),
      body: Consumer2<SettingsProvider, PropertyProvider>(
        builder: (context, settings, propertyProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme Section
              _buildSectionTitle('المظهر (Appearance)'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dark_mode, color: AppColors.primaryGold),
                  title: const Text('الوضع الليلي (Dark Mode)'),
                  trailing: Switch(
                    value: settings.isDarkMode,
                    activeColor: AppColors.primaryGold,
                    onChanged: (val) => settings.toggleDarkMode(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Language Section
              _buildSectionTitle('اللغة (Language)'),
              Card(
                child: Column(
                  children: AppConstants.languages.entries.map((entry) {
                    final isSelected = propertyProvider.currentLang == entry.key;
                    return ListTile(
                      title: Text(entry.value),
                      leading: Icon(
                        Icons.language,
                        color: isSelected ? AppColors.primaryGold : Colors.grey,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primaryGold)
                          : null,
                      onTap: () {
                        propertyProvider.setLanguage(entry.key);
                        settings.setLanguage(entry.key);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Currency Section
              _buildSectionTitle('العملة (Currency)'),
              Card(
                child: Column(
                  children: SettingsProvider.exchangeRates.keys.map((currency) {
                    final isSelected = settings.currencyCode == currency;
                    return ListTile(
                      title: Text(currency),
                      leading: Icon(
                        Icons.payments_outlined,
                        color: isSelected ? AppColors.primaryGold : Colors.grey,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primaryGold)
                          : null,
                      onTap: () => settings.setCurrency(currency),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 48),

              // Admin Panel Section
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAdminLoginDialog(context),
                  icon: const Icon(Icons.admin_panel_settings, color: AppColors.primaryGold),
                  label: const Text(
                    'لوحة الإدارة (Admin Panel)',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دخول الإدارة'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'كلمة السر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == AppConstants.adminPassword) {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة سر خاطئة!')),
                );
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }
}
