extension TimeFormat on num {
  String toHHMMSS() {
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = (this % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
