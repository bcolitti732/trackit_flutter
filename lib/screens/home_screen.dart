import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:seminari_flutter/provider/socket_provider.dart';
import 'package:seminari_flutter/provider/users_provider.dart';
import '../models/packet.dart';
import '../widgets/packet_map.dart';
import 'package:seminari_flutter/services/UserService.dart';
import 'package:seminari_flutter/services/auth_service.dart';
import '../models/user.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:latlong2/latlong.dart';
import '../widgets/RouteMapWidget.dart';
import '../widgets/UserPacketRouteMapWidget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  List<Packet> reorderQueue = [];
  bool isReordering = false;
  bool _showRouteMap = false;


  
  Map<String, dynamic>? parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      final payload = parts[1];
      // Base64Url decode
      String normalized = base64Url.normalize(payload);
      final payloadBytes = base64Url.decode(normalized);
      final jsonString = utf8.decode(payloadBytes);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadUserAndPackets(BuildContext context) async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        currentUser = user;
      });
      Provider.of<UserProvider>(context, listen: false).setCurrentUser(user);

      final socketProvider = Provider.of<SocketProvider>(context, listen: false);

      // Ensure the socket is connected before emitting events
      if (!socketProvider.socket.connected) {
        await socketProvider.connect();
      }

      final token = await AuthService.getAccessToken();
      if (token != null && user.id != null && user.id!.isNotEmpty) {
        final payload = parseJwt(token);
        print('Parsed JWT payload: $payload');
        if (payload != null && payload['email'] != null) {
          socketProvider.emit('email', [payload['email'], payload['role']]);
        }
      }

      List<Packet> userPackets = [];
      if (user.role == 'delivery') {
        userPackets = await UserService.getAllPackets();
      } else {
        for (final packetId in user.packetsIds) {
          print('Buscando paquete con ID: $packetId');
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

  Future<void> _optimizarRuta() async {
    if (currentUser == null) return;
    try {
      final optimizedPackets = await UserService.getOptimizedRoute(
        currentUser!,
      );
      // Actualiza la cola en el backend
      await UserService.updateDeliveryQueue(
        currentUser!.id!,
        optimizedPackets.map((p) => p.id!).toList(),
      );
      setState(() {
        packets = [
          ...packets.where((p) => p.status.toLowerCase() == 'almacén'),
          ...optimizedPackets,
          ...packets.where((p) => p.status.toLowerCase() == 'entregado'),
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta optimizada y cola actualizada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al optimizar ruta: $e')));
    }
  }

  Future<void> _asignarPaqueteAlRepartidor(String packetId) async {
    print('Intentando asignar paquete $packetId al usuario ${currentUser!.id}');
    try {
      await UserService.assignPacketToDelivery(currentUser!.id!, packetId);
      // Cambia el estado del paquete a "en reparto"
      await UserService.updatePacketStatus(packetId, "en reparto");
      print(
        'Asignación y actualización de estado exitosa, recargando paquetes...',
      );
      await _loadUserAndPackets(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paquete asignado correctamente')),
      );
    } catch (e) {
      print('Error al asignar paquete: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar paquete: $e')));
    }
  }

  void _startReorder(List<Packet> assignedPackets) {
    setState(() {
      reorderQueue = List.from(assignedPackets);
      isReordering = true;
    });
  }

  Future<void> _saveReorder() async {
    if (currentUser == null) return;
    try {
      await UserService.updateDeliveryQueue(
        currentUser!.id!,
        reorderQueue.map((p) => p.id!).toList(),
      );
      setState(() {
        isReordering = false;
        packets = [
          ...packets.where((p) => p.status.toLowerCase() == 'almacén'),
          ...reorderQueue,
          ...packets.where((p) => p.status.toLowerCase() == 'entregado'),
        ];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cola actualizada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar cola: $e')));
    }
  }

  void _cancelReorder() {
    setState(() {
      isReordering = false;
      reorderQueue = [];
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSocketAndLoadData();
  }

  Future<void> _initializeSocketAndLoadData() async {
    try {
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);

      // Connect the socket and wait for it to initialize
      await socketProvider.connect();

      // Listen for socket events
      socketProvider.on('unseen_messages', (data) {
        print('Unseen messages data: $data');
        if (data is List && data.isNotEmpty) {
          _showUnseenMessagesNotification(data.length);
        }
      });

      socketProvider.on('packet_assigned', (data) {
        _showNotification();
      });

      // Load user and packets after socket connection is established
      await _loadUserAndPackets(context);
    } catch (e) {
      print('Error initializing socket or loading data: $e');
    }
  }
  void _showNotification() {
    if (!mounted) return;
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
              child: Text(
                '¡Tienes un nuevo paquete asignado!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _showUnseenMessagesNotification(int count) {
    if (!mounted) return;
    final message = count == 1
        ? 'Tienes 1 mensaje sin leer.'
        : 'Tienes $count mensajes sin leer.';

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
              Icons.mail_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes sin leer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '¡Bienvenido, ${currentUser!.name}!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestiona tus paquetes y optimiza tu ruta de reparto.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _sectionCard(
                    context,
                    icon: Icons.store,
                    title: 'En almacén',
                    child: _buildPacketColumn(
                      context,
                      '',
                      almacenPackets,
                      false,
                      showAddButton: true,
                      centerContent: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    context,
                    icon: Icons.assignment_turned_in,
                    title: 'Asignados a ti',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isReordering)
                              FilledButton.icon(
                                onPressed: () => _startReorder(assignedPackets),
                                icon: const Icon(Icons.reorder),
                                label: const Text('Reordenar cola'),
                              ),
                            if (isReordering) ...[
                              FilledButton.icon(
                                onPressed: _saveReorder,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: _cancelReorder,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isReordering)
                          Column(
                            children: List.generate(reorderQueue.length, (index) {
                              final packet = reorderQueue[index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 0,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    packet.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(packet.description),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_upward),
                                        onPressed: index == 0
                                            ? null
                                            : () {
                                                setState(() {
                                                  final temp =
                                                      reorderQueue[index - 1];
                                                  reorderQueue[index - 1] =
                                                      reorderQueue[index];
                                                  reorderQueue[index] = temp;
                                                });
                                              },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_downward),
                                        onPressed: index == reorderQueue.length - 1
                                            ? null
                                            : () {
                                                setState(() {
                                                  final temp =
                                                      reorderQueue[index + 1];
                                                  reorderQueue[index + 1] =
                                                      reorderQueue[index];
                                                  reorderQueue[index] = temp;
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          )
                        else
                          _buildPacketColumn(
                            context,
                            '',
                            assignedPackets,
                            false,
                            centerContent: true,
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                await _optimizarRuta();
                              },
                              icon: const Icon(Icons.auto_graph),
                              label: const Text('Optimizar Ruta'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: assignedPackets.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _showRouteMap = true;
                                      });
                                    },
                              icon: const Icon(Icons.map),
                              label: const Text('Ver Ruta'),
                            ),
                          ],
                        ),
                        if (_showRouteMap)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    RouteMapWidget(
                                      queue: assignedPackets,
                                      startLocation: currentUser?.location,
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _showRouteMap = false;
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                      label: const Text('Cerrar Ruta'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    context,
                    icon: Icons.check_circle,
                    title: 'Entregados por ti',
                    child: _buildPacketColumn(
                      context,
                      '',
                      deliveredPackets,
                      false,
                      centerContent: true,
                    ),
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

    final almacenPackets =
        packets
            .where((packet) => packet.status.toLowerCase() == 'almacén')
            .toList();

    final repartoPackets =
        packets
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
                      current:
                          selectedPacket!.location != null
                              ? _toLatLng(selectedPacket!.location)
                              : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      )
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
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    packet.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  if (showRouteButton)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // 1. Busca el repartidor de este paquete
                          final deliveryUser =
                              await UserService.getDeliveryForPacket(packet.id);
                          if (deliveryUser != null) {
                            // 2. Muestra el mapa en un diálogo
                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text('Ruta de tu paquete'),
                                    content: SizedBox(
                                      width: 500,
                                      child: UserPacketRouteMapWidget(
                                        deliveryUser: deliveryUser,
                                        allPackets: packets, // tu lista de todos los paquetes
                                        packetId: packet.id,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se encontró repartidor para este paquete',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ver ruta'),
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
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Añadir paquete'),
                                  content: const Text(
                                    '¿Añadir este paquete a tu cola?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text('Sí'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmed == true) {
                            await _asignarPaqueteAlRepartidor(packet.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Añadir a mi cola'),
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

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}