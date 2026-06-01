class StorageTip {
  const StorageTip({
    required this.title,
    required this.tag,
    this.summary,
    this.storageMethod,
    this.expiryGuide,
    this.consumeTip,
    this.source,
  });

  final String title;
  final String? summary;
  final String tag;
  final String? storageMethod;
  final String? expiryGuide;
  final String? consumeTip;
  final String? source;

  factory StorageTip.fromFirestoreSearch({
    required Map<String, Object?> ingredient,
    required Map<String, Object?> rule,
    Map<String, Object?>? source,
  }) {
    final title = ingredient['nameKo'] as String? ?? '';
    final storageType = rule['storageType'] as String? ?? '보관';
    final periodText = rule['periodText'] as String?;
    final periodMinDays = (rule['periodMinDays'] as num?)?.toInt();
    final periodMaxDays = (rule['periodMaxDays'] as num?)?.toInt();
    final storageMethod = rule['storageMethod'] as String?;
    final caution = rule['caution'] as String?;
    final sourceName = source?['sourceName'] as String?;

    return StorageTip(
      title: title,
      tag: storageType,
      summary: storageMethod,
      storageMethod: storageMethod,
      expiryGuide:
          periodText ??
          _formatPeriodGuide(
            periodMinDays: periodMinDays,
            periodMaxDays: periodMaxDays,
          ),
      consumeTip: caution,
      source: sourceName,
    );
  }

  static String? _formatPeriodGuide({
    required int? periodMinDays,
    required int? periodMaxDays,
  }) {
    if (periodMinDays == null && periodMaxDays == null) {
      return null;
    }
    if (periodMinDays != null && periodMinDays == periodMaxDays) {
      return '$periodMinDays일 기준';
    }
    if (periodMinDays != null && periodMaxDays != null) {
      return '$periodMinDays~$periodMaxDays일 기준';
    }
    return '${periodMinDays ?? periodMaxDays}일 기준';
  }
}
