import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:seminari_flutter/provider/theme_provider.dart';
import 'package:seminari_flutter/provider/users_provider.dart';
import 'package:seminari_flutter/services/auth_service.dart';
import 'package:seminari_flutter/provider/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final currentUser = userProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Hero(
                  tag: 'profile-pic',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : const AssetImage('lib/images/ronaldinho.jpg')
                              as ImageProvider,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentUser.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                currentUser.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              _buildCard(
                context,
                title: localizations.profileDetails,
                children: [
                  _buildProfileItem(
                    context,
                    Icons.phone,
                    localizations.phone,
                    currentUser.phone.isNotEmpty
                        ? currentUser.phone
                        : localizations.notRegistered,
                  ),
                  const Divider(),
                  _buildProfileItem(
                    context,
                    Icons.calendar_today,
                    localizations.dateOfBirth,
                    currentUser.birthdate.isNotEmpty
                        ? currentUser.birthdate
                        : localizations.notRegistered,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCard(
                context,
                title: localizations.accountSettings,
                children: [
                  _buildSettingItem(
                    context,
                    Icons.edit,
                    localizations.editProfile,
                    localizations.updatePersonalInfo,
                    onTap: () => context.go('/edit'),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        themeProvider.isDarkMode
                            ? localizations.darkMode
                            : localizations.lightMode,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.language,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      DropdownButton<Locale>(
                        value: context.watch<LocaleProvider>().locale,
                        onChanged: (locale) {
                          if (locale != null) {
                            context.read<LocaleProvider>().setLocale(locale);
                          }
                        },
                        items: L10n.supportedLocales.map((locale) {
                          final flag = locale.languageCode == 'es'
                              ? '🇪🇸'
                              : locale.languageCode == 'ca'
                                  ? '🇨🇦'
                                  : '🇺🇸';
                          return DropdownMenuItem(
                            value: locale,
                            child: Text(flag),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    authService.logout();
                    context.go('/login');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localizations.logoutError}: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(localizations.logout),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
