class StorageTip {
  const StorageTip({
    required this.title,
    required this.summary,
    required this.tag,
    this.storageMethod,
    this.expiryGuide,
    this.consumeTip,
    this.source,
  });

  final String title;
  final String summary;
  final String tag;
  final String? storageMethod;
  final String? expiryGuide;
  final String? consumeTip;
  final String? source;
}
