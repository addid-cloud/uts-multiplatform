class Note {
  static const categories = ['Pribadi', 'Kuliah', 'Kerja', 'Ide'];
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String category;
  final int colorIndex;
  final bool isPinned;

  Note({
    this.id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    this.category = 'Pribadi',
    this.colorIndex = 0,
    this.isPinned = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'category': category,
    'color_index': colorIndex,
    'is_pinned': isPinned ? 1 : 0,
  };

  factory Note.fromMap(Map<String, Object?> m) => Note(
    id: m['id'] as int?,
    title: m['title'] as String,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    category: m['category'] as String? ?? 'Pribadi',
    colorIndex: m['color_index'] as int? ?? 0,
    isPinned: m['is_pinned'] == 1,
  );

  Note copyWith({bool? isPinned}) => Note(
    id: id,
    title: title,
    content: content,
    createdAt: createdAt,
    category: category,
    colorIndex: colorIndex,
    isPinned: isPinned ?? this.isPinned,
  );
}
