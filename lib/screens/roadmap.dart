import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../widgets/custom_appbar.dart';

class ActiveRoadmapsScreen extends StatefulWidget {
  const ActiveRoadmapsScreen({super.key});

  @override
  State<ActiveRoadmapsScreen> createState() => _ActiveRoadmapsScreenState();
}

class _ActiveRoadmapsScreenState extends State<ActiveRoadmapsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> jobs = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    final String response = await rootBundle.loadString(
      'lib/dataset/job_dataset.json',
    );
    final data = json.decode(response);
    setState(() {
      jobs = data;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, "Active Roadmaps"),
      body: jobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isLeft = index % 2 == 0; // alternate sides for roadmap

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final animationValue = CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOut,
                    ).value;
                    return Transform.translate(
                      offset: Offset(
                        isLeft
                            ? -50 * (1 - animationValue)
                            : 50 * (1 - animationValue),
                        30 * (1 - animationValue),
                      ),
                      child: Opacity(
                        opacity: animationValue,
                        child: Stack(
                          children: [
                            // Roadmap vertical line
                            Positioned(
                              left: MediaQuery.of(context).size.width / 2 - 2,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            // Card + Dot
                            Padding(
                              padding: EdgeInsets.only(
                                left: isLeft
                                    ? 16
                                    : MediaQuery.of(context).size.width / 2 +
                                          20,
                                right: isLeft
                                    ? MediaQuery.of(context).size.width / 2 + 20
                                    : 16,
                                bottom: 40,
                              ),
                              child: GestureDetector(
                                onTapDown: (_) => setState(() {}),
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade50,
                                          Colors.blue.shade100,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job['job'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "📍 ${job['place']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          job['description'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: (job['skillset'] as List)
                                              .map(
                                                (skill) => Chip(
                                                  label: Text(skill),
                                                  backgroundColor:
                                                      Colors.blue.shade200,
                                                  labelStyle: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "💰 ${job['salary-range']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Roadmap dot
                            Positioned(
                              left: MediaQuery.of(context).size.width / 2 - 10,
                              top: 30,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
