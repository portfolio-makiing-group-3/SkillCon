import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
// Import the model here
import 'package:skillcon/screens/resume.dart';
import 'package:skillcon/screens/resume_analysis_result.dart';
import 'package:skillcon/widgets/custom_appbar.dart';

class ResumeAnalyzerScreen extends StatefulWidget {
  @override
  _ResumeAnalyzerScreenState createState() => _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends State<ResumeAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = Colors.blue.shade700;

  bool _loading = false;
  String _analysisText = '';
  ResumeAnalysisResult? _analysisResult;

  late AnimationController _animationController;
  late Animation<double> _skillsAnim;
  late Animation<double> _workExpAnim;
  late Animation<double> _jobAlignAnim;
  late Animation<double> _overallAnim;

  final String _apiKey =
      'AIzaSyCpwrfw4KoMaCyuykTUT3Zcrh1KkeZ1ltg'; // Replace with your actual key

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _skillsAnim = Tween<double>(begin: 0, end: 0).animate(_animationController);
    _workExpAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
    _jobAlignAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
    _overallAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final inputImage = InputImage.fromFilePath(file.path);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      _textController.text = recognizedText.text;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Extracted text from image')));
  }

  Future<void> _saveAnalysisToFirestore(ResumeAnalysisResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save your analysis')),
      );
      return;
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final analysisCollection = userDoc.collection('resume_analyses');

    try {
      await analysisCollection.add(result.toMap());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analysis saved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save analysis: $e')));
    }
  }

  Future<void> _analyzeResume() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _analysisText = '';
      _analysisResult = null;
    });

    final model = GenerativeModel(
      model: 'models/gemini-2.5-flash',
      apiKey: _apiKey,
    );

    const String resumeAnalysisPromptTemplate = '''
Analyze the following resume text for the given categories:

A paragraph summary:
Key strengths:
Key weaknesses:
Overall recommendation:
Skills match:
Work experience relevance:
Job requirement alignment:

Resume text:
{resume_text}
''';

    final prompt = resumeAnalysisPromptTemplate.replaceAll(
      '{resume_text}',
      text,
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final apiText = response.text ?? 'No response from API.';

      final result = ResumeAnalysisResult.fromRawText(apiText);

      _skillsAnim = Tween<double>(begin: 0, end: result.skillsMatch / 100)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _workExpAnim =
          Tween<double>(
            begin: 0,
            end: result.workExperienceRelevance / 100,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _jobAlignAnim =
          Tween<double>(
            begin: 0,
            end: result.jobRequirementAlignment / 100,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _overallAnim = Tween<double>(begin: 0, end: result.overallScore / 100)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );

      setState(() {
        _analysisText = apiText;
        _analysisResult = result;
      });

      _animationController.forward(from: 0);

      // Save the analysis to Firestore
      await _saveAnalysisToFirestore(result);
    } catch (e) {
      setState(() {
        _analysisText = 'Error analyzing resume: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildProgressBar(
    String label,
    Animation<double> animation, {
    MaterialColor color = Colors.blue,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = (animation.value * 100).round();
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: $value%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: color.shade700,
                  ),
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: animation.value,
                    color: color,
                    backgroundColor: color.withOpacity(0.3),
                    minHeight: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsultationSection() {
    if (_analysisResult == null) return SizedBox.shrink();

    String advice = '';
    final overall = _analysisResult!.overallScore;

    if (overall >= 85) {
      advice =
          "Your resume looks great! You are well-aligned with the job requirements. Keep highlighting your strengths and consider applying confidently.";
    } else if (overall >= 60) {
      advice =
          "Your resume is decent but there’s room for improvement. Focus on tailoring your skills and experience to match the job better.";
    } else {
      advice =
          "Consider revising your resume to better showcase relevant skills and experience. You might want to seek professional help or use templates.";
    }

    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.symmetric(vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Consultation & Advice",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 12),
            Text(
              advice,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, 'Resume Analyzer'),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _textController,
                    maxLines: 12,
                    decoration: InputDecoration(
                      hintText: 'Paste resume text here or pick an image',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.photo_library),
                      label: Text('Pick Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: _loading ? null : _pickImage,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.analytics),
                      label: Text('Analyze Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: _loading || _textController.text.trim().isEmpty
                          ? null
                          : _analyzeResume,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              if (_loading)
                Center(child: CircularProgressIndicator(color: primaryColor)),
              if (_analysisText.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Analysis Result:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    _analysisText,
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
                SizedBox(height: 32),
              ],
              if (_analysisResult != null) ...[
                _buildProgressBar(
                  'Skills Match',
                  _skillsAnim,
                  color: Colors.blue,
                ),
                _buildProgressBar(
                  'Work Experience',
                  _workExpAnim,
                  color: Colors.green,
                ),
                _buildProgressBar(
                  'Job Alignment',
                  _jobAlignAnim,
                  color: Colors.orange,
                ),
                _buildProgressBar(
                  'Overall Recommendation',
                  _overallAnim,
                  color: Colors.purple,
                ),
                _buildConsultationSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
