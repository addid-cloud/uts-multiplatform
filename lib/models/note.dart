class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({this.id, required this.title, required this.content, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory Note.fromMap(Map<String, Object?> m) => Note(
        id: m['id'] as int?,
        title: m['title'] as String,
        content: m['content'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
