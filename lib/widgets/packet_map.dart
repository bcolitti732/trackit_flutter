import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class PacketMap extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final LatLng? current;

  const PacketMap({
    super.key,
    required this.origin,
    required this.destination,
    this.current,
  });

  @override
  State<PacketMap> createState() => _PacketMapState();
}

class _PacketMapState extends State<PacketMap> {
  List<LatLng> routePoints = [];
  String? eta;

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  Future<void> _getRoute() async {
    final start = widget.current ?? widget.origin;
    final end = widget.destination;
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        routePoints = coords
            .map((point) => LatLng(point[1].toDouble(), point[0].toDouble()))
            .toList();
        if (data['routes'][0]['duration'] != null) {
          final duration = data['routes'][0]['duration'];
          final etaDate = DateTime.now().add(Duration(seconds: duration.round()));
          eta = "${etaDate.hour.toString().padLeft(2, '0')}:${etaDate.minute.toString().padLeft(2, '0')}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: widget.origin,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.green),
      ),
      Marker(
        point: widget.destination,
        width: 40,
        height: 40,
        child: const Icon(Icons.flag, color: Colors.red),
      ),
      if (widget.current != null)
        Marker(
          point: widget.current!,
          width: 40,
          height: 40,
          child: const Icon(Icons.directions_car, color: Colors.blue),
        ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: FlutterMap(
            options: MapOptions(
              center: widget.current ?? widget.origin,
              zoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: [
                  if (routePoints.isNotEmpty)
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                ],
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        if (eta != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Hora estimada de llegada: $eta', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}