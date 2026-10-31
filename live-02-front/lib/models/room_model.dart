class RoomModel {
  final String id;
  final String name;
  final String hostId;
  final List<String> clientIds;

  RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.clientIds = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      name: json['name'],
      hostId: json['host_id'],
      clientIds: List<String>.from(json['client_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host_id': hostId,
    'client_ids': clientIds,
  };
}
