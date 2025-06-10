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

    _socket!.onConnect((_) {
      print('Socket.IO conectado para notificaciones');
    });

    _socket!.on('push_notification', (data) {
      print('Notificación recibida: $data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificación',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['body'] ?? '¡Tienes una notificación!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
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

  Future<void> _loadUserAndPackets(BuildContext context) async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        currentUser = user;
      });

      final token = await AuthService.getAccessToken();
      if (token != null && user.id != null && user.id!.isNotEmpty) {
        _setupSocketNotifications(token, user.id!);
      }

      List<Packet> userPackets = [];
      if (user.role == 'delivery') {
        userPackets = await UserService.getAllPackets();
      } else {
        for (final packetId in user.packetsIds) {
          final packet = await UserService.getPacketById(packetId);
          userPackets.add(packet);
        }
      }

      setState(() {
        packets = userPackets;
        _isDataLoaded = true;
      });
    } catch (e) {
      print('Error al cargar los datos del usuario o los paquetes: $e');
      throw Exception(
        'Error al cargar los datos del usuario o los paquetes: $e',
      );
    }
  }

  Future<void> _asignarPaqueteAlRepartidor(String packetId) async {
    print('Intentando asignar paquete $packetId al usuario ${currentUser!.id}');
    try {
      await UserService.assignPacketToDelivery(currentUser!.id!, packetId);
      print('Asignación exitosa, recargando paquetes...');
      await _loadUserAndPackets(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paquete asignado correctamente')),
      );
    } catch (e) {
      print('Error al asignar paquete: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar paquete: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndPackets(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return const Center(child: Text('No se pudo cargar el usuario.'));
    }

    if (currentUser!.role == 'delivery') {
      final almacenPackets = packets
          .where((packet) => packet.status.toLowerCase() == 'almacén')
          .toList();

      final assignedPacketIds = List<String>.from(
        currentUser!.deliveryProfile?['assignedPacket'] ?? [],
      );
      final assignedPackets = packets
          .where((packet) => assignedPacketIds.contains(packet.id))
          .toList();

      final deliveredPacketIds = List<String>.from(
        currentUser!.deliveryProfile?['deliveredPackets'] ?? [],
      );
      final deliveredPackets = packets
          .where((packet) => deliveredPacketIds.contains(packet.id))
          .toList();

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bienvenido repartidor, ${currentUser!.name}!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildPacketColumn(
                          context,
                          'En almacén',
                          almacenPackets,
                          false,
                          showAddButton: true,
                          centerContent: true,
                        ),
                      ),
                      Expanded(
                        child: _buildPacketColumn(
                          context,
                          'Asignados a ti',
                          assignedPackets,
                          true,
                          centerContent: true,
                        ),
                      ),
                      Expanded(
                        child: _buildPacketColumn(
                          context,
                          'Entregados por ti',
                          deliveredPackets,
                          false,
                          centerContent: true,
                        ),
                      ),
                    ],
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
          ),
        ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${currentUser!.name}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPacketColumn(
                      context,
                      AppLocalizations.of(context)!.packagesInStorage,
                      almacenPackets,
                      false,
                      centerContent: true,
                    ),
                    _buildPacketColumn(
                      context,
                      AppLocalizations.of(context)!.packagesInDelivery,
                      repartoPackets,
                      true,
                      centerContent: true,
                    ),
                  ],
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
        ),
      ),
    );
  }

  Widget _buildPacketColumn(
    BuildContext context,
    String title,
    List<Packet> packets,
    bool showRouteButton, {
    bool showAddButton = false,
    bool centerContent = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (packets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.noPackages,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ...packets.map(
          (packet) => Align(
            alignment: Alignment.center,
            child: _buildPacketCard(
              context,
              packet,
              showRouteButton,
              showAddButton: showAddButton,
              height: 150,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacketCard(
    BuildContext context,
    Packet packet,
    bool showRouteButton, {
    bool showAddButton = false,
    double height = 150,
  }) {
    return SizedBox(
      height: height,
      width: 300,
      child: Card(
        elevation: 8,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  if (showRouteButton)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPacket = packet;
                          });
                        },
                        child: const Text('Ver ruta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (showRouteButton && showAddButton)
                    const SizedBox(width: 8),
                  if (showAddButton)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Añadir paquete'),
                              content: const Text('¿Añadir este paquete a tu cola?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Sí'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _asignarPaqueteAlRepartidor(packet.id);
                          }
                        },
                        child: const Text('Añadir a mi cola'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng _toLatLng(dynamic coords) {
    if (coords is List && coords.length == 2) {
      return LatLng(coords[0].toDouble(), coords[1].toDouble());
    }
    if (coords is String) {
      final parts =
          coords.split(',').map((e) => double.tryParse(e.trim())).toList();
      if (parts.length == 2 && parts[0] != null && parts[1] != null) {
        return LatLng(parts[0]!, parts[1]!);
      }
    }
    return const LatLng(40.4168, -3.7038);
  }
}