class ResumeAnalysisResult {
  final String summary;
  final String keyStrengths;
  final String keyWeaknesses;
  final String recommendation;
  final double skillsMatch;
  final double workExperienceRelevance;
  final double jobRequirementAlignment;
  final double overallScore;

  ResumeAnalysisResult({
    required this.summary,
    required this.keyStrengths,
    required this.keyWeaknesses,
    required this.recommendation,
    required this.skillsMatch,
    required this.workExperienceRelevance,
    required this.jobRequirementAlignment,
    required this.overallScore,
  });

  /// Converts the analysis result to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'keyStrengths': keyStrengths,
      'keyWeaknesses': keyWeaknesses,
      'recommendation': recommendation,
      'skillsMatch': skillsMatch,
      'workExperienceRelevance': workExperienceRelevance,
      'jobRequirementAlignment': jobRequirementAlignment,
      'overallScore': overallScore,
      'uploadedAt': DateTime.now(),
    };
  }

  /// Factory to parse API raw text into ResumeAnalysisResult
  static ResumeAnalysisResult fromRawText(String rawText) {
    // You can improve this parsing depending on your API response format
    return ResumeAnalysisResult(
      summary: _extractSection(rawText, "A paragraph summary:"),
      keyStrengths: _extractSection(rawText, "Key strengths:"),
      keyWeaknesses: _extractSection(rawText, "Key weaknesses:"),
      recommendation: _extractSection(rawText, "Overall recommendation:"),
      skillsMatch: _extractPercentage(rawText, "Skills match:"),
      workExperienceRelevance: _extractPercentage(
        rawText,
        "Work experience relevance:",
      ),
      jobRequirementAlignment: _extractPercentage(
        rawText,
        "Job requirement alignment:",
      ),
      overallScore: _calculateOverallScore(rawText),
    );
  }

  static String _extractSection(String text, String label) {
    final pattern = RegExp('$label(.*?)(?:\\n|\\Z)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match != null ? match.group(1)!.trim() : '';
  }

  static double _extractPercentage(String text, String label) {
    final pattern = RegExp('$label\\s*(\\d+)', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  static double _calculateOverallScore(String text) {
    final scores = [
      _extractPercentage(text, "Skills match:"),
      _extractPercentage(text, "Work experience relevance:"),
      _extractPercentage(text, "Job requirement alignment:"),
    ];
    return scores.isNotEmpty
        ? scores.reduce((a, b) => a + b) / scores.length
        : 0;
  }
}
