import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../provider/users_provider.dart';
import '../widgets/Layout.dart';
import '../models/packet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String username = userProvider.currentUser.name;

    final almacenPackets = userProvider.currentUser.packets
        .where((packet) => packet.status.toLowerCase() == 'almacén')
        .toList();

    final repartoPackets = userProvider.currentUser.packets
        .where((packet) => packet.status.toLowerCase() == 'reparto')
        .toList();

    return LayoutWrapper(
      title: AppLocalizations.of(context)!.homeTitle,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPacketColumn(
                    context,
                    AppLocalizations.of(context)!.packagesInStorage,
                    almacenPackets,
                  ),
                  _buildPacketColumn(
                    context,
                    AppLocalizations.of(context)!.packagesInDelivery,
                    repartoPackets,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPacketColumn(
    BuildContext context,
    String title,
    List<Packet> packets,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (packets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                AppLocalizations.of(context)!.noPackages,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...packets.map((packet) => _buildPacketCard(context, packet)),
        ],
      ),
    );
  }

  Widget _buildPacketCard(BuildContext context, Packet packet) {
    return Card(
      elevation: 8,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              packet.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              packet.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.packageDetails),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${AppLocalizations.of(context)!.origin}: ${packet.origin}'),
                          const SizedBox(height: 8),
                          Text(
                              '${AppLocalizations.of(context)!.destination}: ${packet.destination}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.close),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(AppLocalizations.of(context)!.viewDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
