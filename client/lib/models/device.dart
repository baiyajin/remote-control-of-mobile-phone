class Device {
  final String id;
  final String name;
  final String type; // windows, android, ios, macos, linux
  final String? ipAddress;
  final int lastSeen;
  final List<String> capabilities;
  final bool online;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.ipAddress,
    required this.lastSeen,
    required this.capabilities,
    required this.online,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      ipAddress: json['ip_address'] as String?,
      lastSeen: json['last_seen'] as int,
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      online: json['online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ip_address': ipAddress,
      'last_seen': lastSeen,
      'capabilities': capabilities,
      'online': online,
    };
  }
}

