import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/messages_provider.dart';
import '../services/UserService.dart';
import '../provider/users_provider.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser.id == null) {
      final user = await UserService.getCurrentUser();
      userProvider.setCurrentUser(user);
    }
    final currentUser = userProvider.currentUser;
    if (currentUser.id != null) {
      Provider.of<MessagesProvider>(
        context,
        listen: false,
      ).fetchContacts(currentUser.id!);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }
        if (provider.contacts.isEmpty) {
          return const Center(child: Text('No hay contactos.'));
        }
        return ListView.builder(
          itemCount: provider.contacts.length,
          itemBuilder: (context, index) {
            User contact = provider.contacts[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(contact.name ?? 'Sin nombre'),
              subtitle: Text(contact.email ?? ''),
              onTap: () {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                final currentUser = userProvider.currentUser;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          currentUser: currentUser,
                          contact: contact,
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
