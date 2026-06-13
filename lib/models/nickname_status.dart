class NicknameStatus {
  const NicknameStatus({this.nickname, this.changedAt, this.nextChangeAt});

  final String? nickname;
  final DateTime? changedAt;
  final DateTime? nextChangeAt;

  bool get hasNickname => nickname?.trim().isNotEmpty == true;

  bool get canChange {
    if (!hasNickname || nextChangeAt == null) return true;
    return !DateTime.now().isBefore(nextChangeAt!);
  }
}
