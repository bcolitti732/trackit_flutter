class Packet {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final double size;
  final double weight;
  final String? deliveryId;
  final String? origin;
  final String? destination;
  final String? location;

  Packet({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    required this.size,
    required this.weight,
    this.deliveryId,
    this.origin,
    this.destination,
    this.location,
  });

  factory Packet.fromJson(Map<String, dynamic> json) {
    return Packet(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      size: (json['size'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      deliveryId: json['deliveryId'] as String?,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'size': size,
      'weight': weight,
      'deliveryId': deliveryId,
      'origin': origin,
      'destination': destination,
      'location': location,
    };
  }
}