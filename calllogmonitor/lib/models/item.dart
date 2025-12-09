class CallLogItem {
  final String number;
  final String name;
  final String type;
  final String date;
  final String duration;
  final String simSlot;

  CallLogItem({
    required this.number,
    required this.name,
    required this.type,
    required this.date,
    required this.duration,
    required this.simSlot,
  });

  factory CallLogItem.fromMap(Map<String, dynamic> map) {
    return CallLogItem(
      number: map['number'] ?? '',
      name: map['name'] ?? '',
      type: _parseType(map['type']),
      date: map['date'] ?? '',
      duration: map['duration'] ?? '',
      simSlot: _parseSim(map['sim_id']),
    );
  }

  static String _parseType(dynamic type) {
    final raw = type?.toString() ?? '';
    String label;

    switch (raw) {
      case "1":
        label = "Incoming";
        break;
      case "2":
        label = "Outgoing";
        break;
      case "3":
        label = "Missed";
        break;
      case "4":
        label = "Voicemail";
        break;
      case "5":
        label = "Rejected";
        break;
      case "6":
        label = "Blocked";
        break;
      case "7":
        label = "Answered Externally";
        break;
      case "100":
        label = "Outgoing (custom)";
        break;
      case "101":
        label = "Incoming (custom)";
        break;
      case "27":
        label = "Blocked (custom)";
        break;
      default:
        label = "Unknown";
    }

    return raw.isNotEmpty ? '$raw ($label)' : label;
  }

  static String _parseSim(dynamic sim) {
    if (sim == null || sim == "unknown") return "SIM Unknown";
    if (sim == "1") return "SIM 1";
    if (sim == "2") return "SIM 2";
    if (sim.toString() == "1") return "SIM 1";
    if (sim.toString() == "2") return "SIM 2";
    return "SIM Unknown";
  }
}