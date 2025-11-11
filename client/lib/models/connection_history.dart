class ConnectionHistory {
  final String id;
  final String controllerId;
  final String controlledId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // seconds
  final String status; // connected, disconnected, failed

  ConnectionHistory({
    required this.id,
    required this.controllerId,
    required this.controlledId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.status,
  });

  factory ConnectionHistory.fromJson(Map<String, dynamic> json) {
    return ConnectionHistory(
      id: json['id'] as String,
      controllerId: json['controller_id'] as String,
      controlledId: json['controlled_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      duration: json['duration'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
    );
  }
}

