class StorageTip {
  const StorageTip({
    required this.title,
    required this.summary,
    required this.tag,
    this.source,
  });

  final String title;
  final String summary;
  final String tag;
  final String? source;
}
