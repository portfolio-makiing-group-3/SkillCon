import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> recognizeTextFromFile(File file) async {
  // For images only (camera or file images like jpg/png)
  final inputImage = InputImage.fromFile(file);

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(
    inputImage,
  );
  await textRecognizer.close();

  String text = recognizedText.text;

  // If you want to support PDF, you'd need additional code to parse PDF text
  // (MLKit does not directly support PDF text recognition).

  return text;
}
