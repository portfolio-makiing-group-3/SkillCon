import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillcon/widgets/custom_appbar.dart';

class ResumeHistoryScreen extends StatelessWidget {
  const ResumeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: buildCustomAppBar(context, "My Resume History"),
        body: const Center(
          child: Text("Please log in to view your resume history."),
        ),
      );
    }

    return Scaffold(
      appBar: buildCustomAppBar(context, "My Resume History"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('resume_analyses')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No resumes analyzed yet."));
          }

          final resumes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              final data = resumes[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['summary'] ?? 'No summary'),
                  subtitle: Text(
                    "Skills: ${data['skillsMatch'] ?? '-'}% | "
                    "Work Exp: ${data['workExperienceRelevance'] ?? '-'}%",
                  ),
                  onTap: () {
                    // Optional: open detailed view
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
