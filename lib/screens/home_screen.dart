import 'package:flutter/material.dart';
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

    // Fetch packets by their status (Almacen and Reparto)
    final almacenPackets =
        userProvider.currentUser.packets
            .where((packet) => packet.status.toLowerCase() == 'almacén')
            .toList();

    final repartoPackets =
        userProvider.currentUser.packets
            .where((packet) => packet.status.toLowerCase() == 'reparto')
            .toList();

    return LayoutWrapper(
      title: 'Home',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left column for Almacen packets
                  _buildPacketColumn(
                    context,
                    'Packages in Storage',
                    almacenPackets,
                  ),

                  // Right column for Reparto packets
                  _buildPacketColumn(
                    context,
                    'Packages in Delivery',
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

  // Create a column of packets (Almacen or Reparto)
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // If there are no packets, display a message
          if (packets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No packages in this category.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          // Display each packet in an elevated card
          ...packets.map((packet) => _buildPacketCard(context, packet)),
        ],
      ),
    );
  }

  // Create an elevated card for each packet
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              packet.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Package Details'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Origin: ${packet.origin}'),
                          const SizedBox(height: 8),
                          Text('Destination: ${packet.destination}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('View Details'),
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
