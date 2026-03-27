import 'package:hive/hive.dart';

import '../models/memory_fact.dart';
import '../models/session_summary.dart';

class MemoryService {
  MemoryService._();
  static final MemoryService instance = MemoryService._();

  static const _maxFacts = 100;
  static const _maxSummaries = 30;
  static const _maxFactsPerCategory = 5;
  static const _maxTotalFactsInPrompt = 20;
  static const _maxSummariesInPrompt = 3;

  Box<MemoryFact> get _factsBox => Hive.box<MemoryFact>('memory_facts');
  Box<SessionSummary> get _summariesBox =>
      Hive.box<SessionSummary>('session_summaries');

  // === MemoryFact CRUD ===

  Future<void> addFact(MemoryFact fact) async {
    await cleanExpired();
    if (_factsBox.length >= _maxFacts) {
      final oldest = _factsBox.values.reduce(
        (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
      );
      await oldest.delete();
    }
    await _factsBox.put(fact.id, fact);
  }

  List<MemoryFact> getAllFacts() => _factsBox.values.toList();

  List<MemoryFact> getFactsByCategory(String category) =>
      _factsBox.values.where((f) => f.category == category).toList();

  Future<void> deleteFact(String id) async {
    await _factsBox.delete(id);
  }

  Future<void> updateFact(String id, {String? content, int? importance}) async {
    final existing = _factsBox.get(id);
    if (existing == null) return;
    final updated = MemoryFact(
      id: existing.id,
      category: existing.category,
      content: content ?? existing.content,
      createdAt: existing.createdAt,
      expiresAt: existing.expiresAt,
      importance: importance ?? existing.importance,
    );
    await _factsBox.put(id, updated);
  }

  // === SessionSummary CRUD ===

  Future<void> addSummary(SessionSummary summary) async {
    if (_summariesBox.length >= _maxSummaries) {
      final oldest = _summariesBox.values.reduce(
        (a, b) => a.date.isBefore(b.date) ? a : b,
      );
      await oldest.delete();
    }
    await _summariesBox.put(summary.id, summary);
  }

  List<SessionSummary> getAllSummaries() => _summariesBox.values.toList();

  // === Cleanup ===

  Future<void> cleanExpired() async {
    final expired = _factsBox.values.where((f) => f.isExpired).toList();
    for (final fact in expired) {
      await fact.delete();
    }
  }

  // === System prompt context builders ===

  String buildMemoryContext() {
    final allFacts = _factsBox.values.where((f) => !f.isExpired).toList()
      ..sort((a, b) {
        final impCmp = b.importance.compareTo(a.importance);
        if (impCmp != 0) return impCmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    // Group by category, capping each at _maxFactsPerCategory
    final grouped = <String, List<MemoryFact>>{};
    for (final fact in allFacts) {
      final bucket = grouped.putIfAbsent(fact.category, () => []);
      if (bucket.length < _maxFactsPerCategory) bucket.add(fact);
    }

    // Flatten respecting total cap
    final selected = <MemoryFact>[];
    for (final facts in grouped.values) {
      for (final f in facts) {
        if (selected.length >= _maxTotalFactsInPrompt) break;
        selected.add(f);
      }
      if (selected.length >= _maxTotalFactsInPrompt) break;
    }

    if (selected.isEmpty) return '';

    final categoryLabels = {
      'health': '健康档案',
      'preference': '偏好习惯',
      'habit': '日常习惯',
      'event': '重要事件',
      'reminder': '提醒事项',
    };

    final buffer = StringBuffer();
    for (final category in grouped.keys) {
      final factsInCategory =
          selected.where((f) => f.category == category).toList();
      if (factsInCategory.isEmpty) continue;
      final label = categoryLabels[category] ?? category;
      buffer.writeln('### $label');
      for (final f in factsInCategory) {
        final prefix = f.importance >= 4 ? '[重要] ' : '';
        buffer.writeln('- $prefix${f.content}');
      }
    }

    return buffer.toString().trimRight();
  }

  String buildSummaryContext() {
    final sorted = _summariesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recent = sorted.take(_maxSummariesInPrompt).toList();
    if (recent.isEmpty) return '';

    final buffer = StringBuffer();
    for (final s in recent) {
      final dateStr =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('[$dateStr] ${s.summary}');
    }
    return buffer.toString().trimRight();
  }
}
