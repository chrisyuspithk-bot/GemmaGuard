import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class AnalysisCard extends StatelessWidget {
  final AnalysisResult analysis;

  const AnalysisCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _threatColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(80), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _threatBadge(color, theme),
            const SizedBox(height: 12),
            if (analysis.summary.isNotEmpty) ...[
              _sectionHeader('SUMMARY', Icons.description, color),
              const SizedBox(height: 4),
              Text(analysis.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (analysis.keyFindings.isNotEmpty) ...[
              _sectionHeader('KEY FINDINGS', Icons.warning_amber, color),
              const SizedBox(height: 4),
              ...analysis.keyFindings.map((f) => _bulletItem(f, color)),
              const SizedBox(height: 12),
            ],
            if (analysis.mitigations.isNotEmpty) ...[
              _sectionHeader('MITIGATIONS', Icons.shield, color),
              const SizedBox(height: 4),
              ...analysis.mitigations.map((m) => _bulletItem(m, color)),
            ],
          ],
        ),
      ),
    );
  }

  Color get _threatColor {
    switch (analysis.threatLevel) {
      case ThreatLevel.critical:
        return Colors.red;
      case ThreatLevel.high:
        return Colors.orange;
      case ThreatLevel.medium:
        return Colors.amber;
      case ThreatLevel.low:
        return Colors.green;
      case ThreatLevel.unknown:
        return Colors.grey;
    }
  }

  Widget _threatBadge(Color color, ThemeData theme) {
    final label = analysis.threatLevel.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            'Threat Level: $label',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _bulletItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color.withAlpha(150),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
