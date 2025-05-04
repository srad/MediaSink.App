String? validateUrl(String? value) {
  if (value == null || value.isEmpty) return 'Required';
  if (Uri.tryParse(value) == null) return 'Invalid URL';
  return null;
}
