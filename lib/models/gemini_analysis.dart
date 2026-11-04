class GeminiAnalysis {
  GeminiAnalysis(Map<String, dynamic> data)
    : id = data['id'] as String,
      summary = (data['result'] as Map)['summary'] as String,
      findings = List<String>.from((data['result'] as Map)['findings'] as List),
      recommendations = List<String>.from(
        (data['result'] as Map)['recommendations'] as List,
      ),
      limitations = List<String>.from(
        (data['result'] as Map)['limitations'] as List,
      ),
      model = data['model'] as String,
      elapsedMs = data['elapsedMs'] as int,
      usage = Map<String, dynamic>.from(data['usage'] as Map),
      periodStart = DateTime.parse(data['periodStart'] as String),
      periodEnd = DateTime.parse(data['periodEnd'] as String),
      sampleSessions = data['sampleSessions'] as int;
  final String id, summary, model;
  final List<String> findings, recommendations, limitations;
  final int elapsedMs;
  final Map<String, dynamic> usage;
  final DateTime periodStart, periodEnd;
  final int sampleSessions;
}
