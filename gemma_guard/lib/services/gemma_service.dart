import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';

/// GemmaGuard system prompt for structured cybersecurity analysis.
const String _systemPrompt = '''You are GemmaGuard, an expert Blue Team cybersecurity analyst powered by Gemma 4. Your role is to analyze network diagrams, log snippets, configurations, and security-related text/images to provide structured defensive assessments.

## Your Capabilities
- Analyze network topology diagrams for segmentation gaps, single points of failure, and defense-in-depth weaknesses.
- Review log entries for suspicious patterns, IoCs (Indicators of Compromise), and anomalous behavior.
- Assess security configurations against industry best practices (NIST, CIS Benchmarks).
- Identify attack surface exposure and recommend hardening measures.
- Detect common misconfigurations in cloud, on-prem, and hybrid environments.

## Response Format (MUST follow exactly)
Respond with a structured JSON object ONLY, no other text:

{
  "threat_level": "LOW|MEDIUM|HIGH|CRITICAL",
  "summary": "Brief 2-3 sentence summary of the overall assessment.",
  "key_findings": [
    "Finding 1 with specific detail",
    "Finding 2 with specific detail",
    "Finding 3 with specific detail"
  ],
  "mitigations": [
    "Actionable mitigation step 1",
    "Actionable mitigation step 2",
    "Actionable mitigation step 3"
  ]
}

## Threat Level Guidelines
- LOW: Minor findings, good security posture overall.
- MEDIUM: Notable gaps that should be addressed within weeks.
- HIGH: Significant vulnerabilities requiring prompt attention (days).
- CRITICAL: Active threat indicators or severe vulnerabilities needing immediate action.

## Important Rules
- Always provide at least 2 key findings and 2 mitigations.
- Be specific and actionable — never use vague recommendations.
- If the input is not security-related, respond with threat_level "LOW", a summary explaining this is outside scope, and empty arrays for key_findings and mitigations.
- For images: thoroughly analyze visible network topology, IP addresses, port numbers, protocols, and any annotations.
- Do NOT include any text before or after the JSON object.''';

class GemmaService {
  static final GemmaService _instance = GemmaService._();
  factory GemmaService() => _instance;
  GemmaService._();

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _modelStatus;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String get modelStatus => _modelStatus ?? 'Not Initialized';

  Future<void> initialize({
    void Function(String status)? onStatus,
  }) async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      onStatus?.call('Initializing FlutterGemma...');

      await FlutterGemma.initialize();

      if (!FlutterGemma.hasActiveModel()) {
        onStatus?.call('Downloading Gemma 4 model...');

        // Attempt network download of Gemma 4 E2B task model.
        // Replace URL with Gemma 4 E4B URL for the larger variant.
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.task,
        )
            .fromNetwork(
              'https://www.kaggle.com/api/v1/models/google/gemma-4/flutterGemma/2B-it-gemma4-cpu-int8/download',
            )
            .withProgress((progress) {
              onStatus?.call('Downloading: ${progress.toStringAsFixed(0)}%');
            })
            .install();

        onStatus?.call('Model installed successfully.');
      }

      onStatus?.call('Loading model...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        supportImage: true,
      );

      _chat = await _model!.createChat(
        supportImage: true,
        systemInstruction: _systemPrompt,
        modelType: ModelType.gemma4,
      );

      _isInitialized = true;
      _modelStatus = 'Gemma 4 Ready';
      onStatus?.call(_modelStatus!);
    } catch (e) {
      _modelStatus = 'Error: ${e.toString().split('\n').first}';
      onStatus?.call(_modelStatus!);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<String> generateResponse(
    String prompt, {
    Uint8List? imageBytes,
  }) async {
    if (!_isInitialized || _chat == null) {
      throw StateError('GemmaService not initialized. Call initialize() first.');
    }

    final message = imageBytes != null
        ? Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true)
        : Message.text(text: prompt, isUser: true);

    await _chat!.addQuery(message);
    final response = await _chat!.generateChatResponse();
    if (response is TextResponse) return response.token;
    return response.toString();
  }

  Future<void> dispose() async {
    await _chat?.close();
    await _model?.close();
    _chat = null;
    _model = null;
    _isInitialized = false;
    _modelStatus = 'Disposed';
  }
}
