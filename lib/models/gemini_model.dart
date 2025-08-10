// lib/models/gemini_model.dart

const String resumeAnalysisPromptTemplate = '''
You are an expert recruiter analyzing a resume against job requirements.

Resume Data:
{resume_text}

Analyze the skills, work experience relevance, and job requirement alignment.

Provide:

- A paragraph summary.
- Key strengths.
- Key weaknesses.
- Overall recommendation.
- Then give scores (1-100%) with these exact labels, NO markdown or asterisks, just plain text:

Skills match: [score]%
Work experience relevance: [score]%
Job requirement alignment: [score]%
Overall recommendation: [score]%

Make sure the output is clean, well formatted, and easy to parse.
''';
