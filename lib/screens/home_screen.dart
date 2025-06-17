import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/packet.dart';
import '../widgets/packet_map.dart';
import 'package:seminari_flutter/services/UserService.dart';
import 'package:seminari_flutter/services/auth_service.dart';
import '../models/user.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Packet? selectedPacket;
  List<Packet> packets = [];
  User? currentUser;
  bool _isDataLoaded = false;
  IO.Socket? _socket;

  void _setupSocketNotifications(String token, String userId) {
    _socket = IO.io(
      'http://localhost:4005',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) => print('Socket.IO conectado'));
    _socket!.on('push_notification', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Icon(Icons.notifications_active,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['body'] ?? '¡Tienes una notificación!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
    _socket!.onDisconnect((_) => print('Socket.IO desconectado'));
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndPackets() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null || user.id == null || user.id!.isEmpty) {
        throw Exception('Usuario inválido o no encontrado.');
      }

      final token = await AuthService.getAccessToken();
      if (token != null && user.id != null && user.id!.isNotEmpty) {
        _setupSocketNotifications(token, user.id!);
      }

      List<Packet> userPackets = [];
      if (user.role == 'delivery') {
        userPackets = await UserService.getAllPackets();
        if (userPackets.isEmpty) {
          print('No hay paquetes disponibles para el rol delivery.');
        }
      } else {
        for (final pid in user.packetsIds) {
          final packet = await UserService.getPacketById(pid);
          userPackets.add(packet);
        }
      }

      setState(() {
        currentUser = user;
        packets = userPackets;
        _isDataLoaded = true;
      });
    } catch (e) {
      print('Error al cargar los datos del usuario o los paquetes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
      setState(() {
        _isDataLoaded = true; // Para evitar que se quede en un estado de carga infinito
      });
    }
  }

  Future<void> _assignPacket(String packetId) async {
    await UserService.assignPacketToDelivery(currentUser!.id!, packetId);
    await _loadUserAndPackets();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paquete asignado correctamente')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndPackets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isDataLoaded
            ? _buildContent(context)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (currentUser == null) {
      return const Center(
        child: Text('No se pudo cargar el usuario.'),
      );
    }

    if (packets.isEmpty) {
      return const Center(
        child: Text('No hay paquetes disponibles.'),
      );
    }

    final almacenPackets = packets
        .where((packet) => packet.status.toLowerCase() == 'almacén')
        .toList();
    final repartoPackets = packets
        .where((packet) => packet.status.toLowerCase() == 'en reparto')
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${currentUser!.name}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'Packages in Storage',
              subtitle: 'Paquetes almacenados',
              icon: Icons.storage,
              iconColor: Colors.blue,
              packets: almacenPackets,
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: 'Packages in Delivery',
              subtitle: 'Paquetes en reparto',
              icon: Icons.local_shipping,
              iconColor: Colors.green,
              packets: repartoPackets,
              showRoute: true,
              onViewRoute: (packet) {
                setState(() {
                  selectedPacket = packet;
                });
              },
            ),
            if (selectedPacket != null)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: PacketMap(
                  origin: _toLatLng(selectedPacket!.origin),
                  destination: _toLatLng(selectedPacket!.destination),
                  current: selectedPacket!.location != null
                      ? _toLatLng(selectedPacket!.location)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Packet> packets,
    bool showRoute = false,
    void Function(Packet)? onViewRoute,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(.1),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        packets.isEmpty
            ? Center(child: Text('No packages'))
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: packets.map((p) {
                  return Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(icon, color: iconColor),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.status,
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text(p.description),
                        const SizedBox(height: 12),
                        Text(
                          'From: ${_toLatLng(p.origin)}  →  To: ${_toLatLng(p.destination)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (showRoute)
                          ElevatedButton.icon(
                            onPressed: () => onViewRoute?.call(p),
                            icon: const Icon(Icons.route),
                            label: const Text('View Route'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              )
      ],
    );
  }

  LatLng _toLatLng(dynamic c) {
    try {
      if (c is String) {
        final cleaned = c.replaceAll('[', '').replaceAll(']', '');
        final parts =
            cleaned.split(',').map((e) => double.parse(e.trim())).toList();
        return LatLng(parts[0], parts[1]);
      } else if (c is List) {
        final list = c.map((e) => (e as num).toDouble()).toList();
        return LatLng(list[0], list[1]);
      } else {
        throw const FormatException('Invalid coordinate format');
      }
    } catch (e) {
      debugPrint('Error parsing coordinates: $e');
      return const LatLng(0, 0);
    }
  }
}
