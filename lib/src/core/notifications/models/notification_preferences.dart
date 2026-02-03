class NotificationPreferences {
  final bool email;
  final bool sms;
  final bool inApp;
  final bool whatsapp;

  NotificationPreferences({
    required this.email,
    required this.sms,
    required this.inApp,
    required this.whatsapp,
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'sms': sms,
        'inApp': inApp,
        'whatsapp': whatsapp,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NotificationPreferences(email: true, sms: false, inApp: true, whatsapp: false);
    return NotificationPreferences(
      email: map['email'] as bool? ?? true,
      sms: map['sms'] as bool? ?? false,
      inApp: map['inApp'] as bool? ?? true,
      whatsapp: map['whatsapp'] as bool? ?? false,
    );
  }
}