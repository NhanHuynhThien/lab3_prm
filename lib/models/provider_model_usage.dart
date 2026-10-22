class ProviderModelUsage {
  const ProviderModelUsage({
    required this.model,
    required this.totalTokens,
    this.inputTokens,
    this.outputTokens,
    this.estimatedCostMicros,
  });
  final String model;
  final int totalTokens;
  final int? inputTokens, outputTokens, estimatedCostMicros;

  factory ProviderModelUsage.fromJson(Map<String, dynamic> json) {
    final model = json['model'];
    if (model is! String ||
        !RegExp(r'^[a-zA-Z0-9._:/-]{1,128}$').hasMatch(model)) {
      throw const FormatException('Model nguồn không hợp lệ.');
    }
    return ProviderModelUsage(
      model: model,
      totalTokens:
          count(json['totalTokens']) ??
          (throw const FormatException('Thiếu token model.')),
      inputTokens: count(json['inputTokens']),
      outputTokens: count(json['outputTokens']),
      estimatedCostMicros: count(json['estimatedCostMicros']),
    );
  }

  static int? count(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0 || value > 9007199254740991) {
      throw const FormatException('Số liệu model không hợp lệ.');
    }
    return value;
  }
}
