import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/packet.dart';
import '../models/user.dart';

class UserPacketRouteMapWidget extends StatefulWidget {
  final User deliveryUser;
  final List<Packet> allPackets;
  final String packetId; // El paquete del usuario

  const UserPacketRouteMapWidget({
    super.key,
    required this.deliveryUser,
    required this.allPackets,
    required this.packetId,
  });

  @override
  State<UserPacketRouteMapWidget> createState() =>
      _UserPacketRouteMapWidgetState();
}

class _UserPacketRouteMapWidgetState extends State<UserPacketRouteMapWidget> {
  List<LatLng> routePoints = [];
  double totalDistance = 0;
  double totalDuration = 0;
  bool loading = true;

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

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  Future<void> _getRoute() async {
    // 1. Obtén la cola de paquetes del repartidor
    final assignedIds = List<String>.from(
      widget.deliveryUser.deliveryProfile?['assignedPacket'] ?? [],
    );
    // 2. Filtra los paquetes hasta el tuyo (incluido)
    final List<Packet> queue = [];
    for (final id in assignedIds) {
      final found = widget.allPackets.where((pkt) => pkt.id == id);
      if (found.isNotEmpty) queue.add(found.first);
      if (id == widget.packetId) break;
    }
    // 3. Construye los puntos
    final points = <LatLng>[];
    if (widget.deliveryUser.location != null &&
        widget.deliveryUser.location!.isNotEmpty) {
      points.add(_toLatLng(widget.deliveryUser.location));
    }
    for (final packet in queue) {
      if (packet.destination != null) {
        points.add(_toLatLng(packet.destination));
      }
    }
    if (points.length < 2) {
      setState(() {
        loading = false;
      });
      return;
    }
    // 4. Llama a OSRM
    final coordsStr = points
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final url =
        'https://router.project-osrm.org/route/v1/driving/$coordsStr?overview=full&geometries=geojson';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      final distance = data['routes'][0]['distance'] as num;
      final duration = data['routes'][0]['duration'] as num;
      setState(() {
        routePoints =
            coords
                .map(
                  (point) => LatLng(point[1].toDouble(), point[0].toDouble()),
                )
                .toList();
        totalDistance = distance.toDouble();
        totalDuration = duration.toDouble();
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstruye los puntos para los marcadores
    final assignedIds = List<String>.from(
      widget.deliveryUser.deliveryProfile?['assignedPacket'] ?? [],
    );
    final List<Packet> queue = [];
    for (final id in assignedIds) {
      final found = widget.allPackets.where((pkt) => pkt.id == id);
      if (found.isNotEmpty) queue.add(found.first);
      if (id == widget.packetId) break;
    }
    final points = <LatLng>[];
    if (widget.deliveryUser.location != null &&
        widget.deliveryUser.location!.isNotEmpty) {
      points.add(_toLatLng(widget.deliveryUser.location));
    }
    for (final packet in queue) {
      if (packet.destination != null) {
        points.add(_toLatLng(packet.destination));
      }
    }

    final markers = <Marker>[
      if (points.isNotEmpty)
        Marker(
          point: points.first,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.directions_car,
            color: Colors.black,
            size: 40,
          ),
        ),
      ...points
          .skip(1)
          .mapIndexed(
            (i, p) => Marker(
              point: p,
              width: 40,
              height: 40,
              child:
                  (i == points.length - 2)
                      ? const Icon(
                        Icons.inventory_2,
                        color: Colors.amber,
                        size: 36,
                      ) // Tu paquete
                      : const Icon(Icons.flag, color: Colors.red),
            ),
          ),
    ];

    return loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            SizedBox(
              height: 420,
              child: FlutterMap(
                options: MapOptions(
                  center:
                      points.isNotEmpty
                          ? points.first
                          : LatLng(40.4168, -3.7038),
                  zoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      if (routePoints.isNotEmpty)
                        Polyline(
                          points: routePoints,
                          color: Colors.blue,
                          strokeWidth: 4.0,
                        ),
                    ],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Distancia total: ${(totalDistance / 1000).toStringAsFixed(2)} km',
                    ),
                    Text(
                      'Tiempo estimado: ${(totalDuration / 60).round()} min',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

// Helper para mapIndexed (puedes ponerlo en un utils.dart)
extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}
