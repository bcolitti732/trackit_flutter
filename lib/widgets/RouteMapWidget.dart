import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/packet.dart';

class RouteMapWidget extends StatefulWidget {
  final List<Packet> queue;
  final String? startLocation;

  const RouteMapWidget({
    super.key,
    required this.queue,
    required this.startLocation,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
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
    final points = <LatLng>[];
    if (widget.startLocation != null && widget.startLocation!.isNotEmpty) {
      points.add(_toLatLng(widget.startLocation));
    }
    for (final packet in widget.queue) {
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

    // Construye la URL de OSRM con todos los puntos
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
    final points = <LatLng>[];
    if (widget.startLocation != null && widget.startLocation!.isNotEmpty) {
      points.add(_toLatLng(widget.startLocation));
    }
    for (final packet in widget.queue) {
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
          .map(
            (p) => Marker(
              point: p,
              width: 40,
              height: 40,
              child: const Icon(Icons.flag, color: Colors.red),
            ),
          ),
    ];

    return loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            SizedBox(
              height: 300,
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
