import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seminari_flutter/provider/users_provider.dart';
import '../widgets/Layout.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final currentUser = userProvider.currentUser;

    return LayoutWrapper(
      title: 'Profile',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: const AssetImage('lib/images/ronaldinho.jpg'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // User's name
                  Text(
                    currentUser.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // User's email
                  Text(
                    currentUser.email,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // Profile details card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildProfileItem(
                            context,
                            Icons.badge,
                            'ID',
                            currentUser.id ?? 'No ID',
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.phone,
                            'Phone',
                            currentUser.phone.isNotEmpty
                                ? currentUser.phone
                                : 'Not registered',
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.calendar_today,
                            'Date of Birth',
                            currentUser.birthdate.isNotEmpty
                                ? currentUser.birthdate
                                : 'Not registered',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account settings card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingItem(
                            context,
                            Icons.edit,
                            'Edit Profile',
                            'Update your personal information',
                            onTap: () => context.go('/edit'),
                          ),
                          _buildSettingItem(
                            context,
                            Icons.lock,
                            'Change Password',
                            'Update your password',
                            onTap: () => context.go('/changepassword'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Logout button
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final authService = AuthService();
                        authService.logout();
                        context.go('/login');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging out: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('LOG OUT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}