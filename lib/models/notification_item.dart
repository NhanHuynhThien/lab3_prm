class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.route,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final String? route;
  final Map<String, String> data;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    String? route,
    Map<String, String>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toUtc().toIso8601String(),
      'isRead': isRead,
      if (route != null) 'route': route,
      'data': data,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Thông báo',
      body: map['body'] as String? ?? '',
      receivedAt:
          DateTime.tryParse(map['receivedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      route: map['route'] as String?,
      data:
          (map['data'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
    );
  }
}
