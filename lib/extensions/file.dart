extension ByteSizeFormat on int {
  String toGB() {
    final gb = this / 1024 / 1024 / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
