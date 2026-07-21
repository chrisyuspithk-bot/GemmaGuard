import 'dart:typed_data';

enum ThreatLevel { low, medium, high, critical, unknown }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  final AnalysisResult? analysis;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.imageBytes,
    DateTime? timestamp,
    this.analysis,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasImage => imageBytes != null;
}

class AnalysisResult {
  final ThreatLevel threatLevel;
  final String summary;
  final List<String> keyFindings;
  final List<String> mitigations;
  final String? rawResponse;

  const AnalysisResult({
    required this.threatLevel,
    required this.summary,
    required this.keyFindings,
    required this.mitigations,
    this.rawResponse,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      threatLevel: _parseThreatLevel(json['threat_level'] as String? ?? ''),
      summary: json['summary'] as String? ?? '',
      keyFindings: List<String>.from(json['key_findings'] as List? ?? []),
      mitigations: List<String>.from(json['mitigations'] as List? ?? []),
    );
  }

  factory AnalysisResult.fromRawText(String text) {
    final threatLevel = _extractThreatLevel(text);
    final summary = _extractSection(text, 'Summary', 'Key Findings');
    final keyFindings = _extractBullets(text, 'Key Findings', 'Mitigations');
    final mitigations = _extractBullets(text, 'Mitigations', null);

    return AnalysisResult(
      threatLevel: threatLevel,
      summary: summary,
      keyFindings: keyFindings,
      mitigations: mitigations,
      rawResponse: text,
    );
  }

  static ThreatLevel _parseThreatLevel(String level) {
    switch (level.toUpperCase()) {
      case 'LOW':
        return ThreatLevel.low;
      case 'MEDIUM':
        return ThreatLevel.medium;
      case 'HIGH':
        return ThreatLevel.high;
      case 'CRITICAL':
        return ThreatLevel.critical;
      default:
        return ThreatLevel.unknown;
    }
  }

  static ThreatLevel _extractThreatLevel(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('CRITICAL') || upper.contains('THREAT LEVEL: CRITICAL')) {
      return ThreatLevel.critical;
    } else if (upper.contains('HIGH') || upper.contains('THREAT LEVEL: HIGH')) {
      return ThreatLevel.high;
    } else if (upper.contains('MEDIUM') || upper.contains('THREAT LEVEL: MEDIUM')) {
      return ThreatLevel.medium;
    } else if (upper.contains('LOW') || upper.contains('THREAT LEVEL: LOW')) {
      return ThreatLevel.low;
    }
    return ThreatLevel.unknown;
  }

  static String _extractSection(String text, String startTag, String? endTag) {
    final startIdx = text.indexOf(startTag);
    if (startIdx == -1) return text;
    final contentIdx = text.indexOf('\n', startIdx);
    if (contentIdx == -1) return text.substring(startIdx);
    if (endTag != null) {
      final endIdx = text.indexOf(endTag, contentIdx);
      if (endIdx != -1) {
        return text.substring(contentIdx, endIdx).trim();
      }
    }
    return text.substring(contentIdx).trim();
  }

  static List<String> _extractBullets(
      String text, String startTag, String? endTag) {
    final startIdx = text.indexOf(startTag);
    if (startIdx == -1) return [];
    final contentIdx = text.indexOf('\n', startIdx);
    if (contentIdx == -1) return [];
    final endIdx =
        endTag != null ? text.indexOf(endTag, contentIdx) : text.length;
    final section = text.substring(contentIdx, endIdx == -1 ? text.length : endIdx);

    return section
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^[\s•\-*]+\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

extension ThreatLevelExtension on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.low:
        return 'LOW';
      case ThreatLevel.medium:
        return 'MEDIUM';
      case ThreatLevel.high:
        return 'HIGH';
      case ThreatLevel.critical:
        return 'CRITICAL';
      case ThreatLevel.unknown:
        return 'UNKNOWN';
    }
  }
}
