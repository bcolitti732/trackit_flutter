import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../provider/users_provider.dart';
import '../models/packet.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/packet_map.dart';
import 'package:seminari_flutter/services/UserService.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Packet? selectedPacket;
  List<Packet> packets = [];
  User? currentUser;
  bool _isDataLoaded = false; // Variable para controlar si los datos ya se cargaron

  Future<void> _loadUserAndPackets(BuildContext context) async {
    try {
      // Llama a getCurrentUser para obtener los datos del usuario
      final user = await UserService.getCurrentUser();

      setState(() {
        currentUser = user;
      });

      // Carga los detalles de los paquetes usando los identificadores
      final List<Packet> userPackets = [];
      for (final packetId in user.packetsIds) {
        final packet = await UserService.getPacketById(packetId);
        userPackets.add(packet);
      }

      setState(() {
        packets = userPackets;
        _isDataLoaded = true; // Marca los datos como cargados
      });
    } catch (e) {
      throw Exception('Error al cargar los datos del usuario o los paquetes: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Llama a _loadUserAndPackets solo una vez al inicializar el estado
    _loadUserAndPackets(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return const Center(
        child: Text('No se pudo cargar el usuario.'),
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
                    ),
                    _buildPacketColumn(
                      context,
                      AppLocalizations.of(context)!.packagesInDelivery,
                      repartoPackets,
                      true,
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
    bool showRouteButton,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          ...packets.map((packet) => _buildPacketCard(context, packet, showRouteButton)),
        ],
      ),
    );
  }

  Widget _buildPacketCard(BuildContext context, Packet packet, bool showRouteButton) {
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              packet.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            if (showRouteButton)
              ElevatedButton(
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
          ],
        ),
      ),
    );
  }

  LatLng _toLatLng(dynamic coords) {
    if (coords is List && coords.length == 2) {
      return LatLng(coords[0].toDouble(), coords[1].toDouble());
    }
    if (coords is String) {
      final parts = coords.split(',').map((e) => double.tryParse(e.trim())).toList();
      if (parts.length == 2 && parts[0] != null && parts[1] != null) {
        return LatLng(parts[0]!, parts[1]!);
      }
    }
    return const LatLng(40.4168, -3.7038); // Madrid por defecto
  }
}
