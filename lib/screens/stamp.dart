import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_appbar.dart';

class DigitalStampsScreen extends StatefulWidget {
  const DigitalStampsScreen({super.key});

  @override
  State<DigitalStampsScreen> createState() => _DigitalStampsScreenState();
}

class _DigitalStampsScreenState extends State<DigitalStampsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  final Map<String, TextEditingController> _bioControllers = {};
  final Map<String, bool> _editingBio = {};

  // Update rating for a user
  Future<void> _rateUser(String userId, double rating) async {
    if (currentUser == null) return;

    final userDoc = _firestore.collection('users').doc(userId);

    await userDoc.set({
      'ratings': {currentUser!.uid: rating},
    }, SetOptions(merge: true));
  }

  // Save updated biography for current user
  Future<void> _saveBiography(String userId) async {
    final controller = _bioControllers[userId];
    if (controller == null) return;

    await _firestore.collection('users').doc(userId).update({
      'biography': controller.text.trim(),
    });

    setState(() {
      _editingBio[userId] = false;
    });
  }

  // Calculate average rating from ratings map
  double _calculateAverageRating(Map<String, dynamic>? ratingsMap) {
    if (ratingsMap == null || ratingsMap.isEmpty) return 0.0;

    final ratings = ratingsMap.values.map((e) => e is num ? e.toDouble() : 0.0);
    final total = ratings.fold(0.0, (a, b) => a + b);
    return total / ratings.length;
  }

  // Determine badge info based on likesCount
  Map<String, dynamic>? _getBadge(int likesCount) {
    if (likesCount >= 10) {
      return {
        'name': 'Gold Supporter',
        'icon': Icons.emoji_events,
        'color': Colors.amber[700],
      };
    } else if (likesCount >= 5) {
      return {
        'name': 'Silver Supporter',
        'icon': Icons.emoji_events,
        'color': Colors.grey[400],
      };
    } else if (likesCount >= 1) {
      return {
        'name': 'Bronze Supporter',
        'icon': Icons.emoji_events,
        'color': Colors.brown[400],
      };
    } else {
      return null;
    }
  }

  // Extract first name from displayName or email if no displayName
  String _getFirstName(Map<String, dynamic> data) {
    final displayName = data['displayName'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim().split(' ').first;
    }
    // fallback: try email username part
    final email = data['email'] as String? ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context, "Digital Stamps"),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load users'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userId = userDoc.id;
              final data = userDoc.data() as Map<String, dynamic>;

              final displayName = _getFirstName(data);
              final biography = data['biography'] ?? 'No biography available.';
              final digitalStamps = data['digitalStamps'] ?? 0;

              final ratingsMap = Map<String, dynamic>.from(
                data['ratings'] ?? {},
              );
              final avgRating = _calculateAverageRating(ratingsMap);

              final likesCount = data['likesCount'] ?? 0;

              // Current user's rating for this user (if any)
              final myRating = currentUser != null
                  ? (ratingsMap[currentUser!.uid] ?? 0.0)
                  : 0.0;

              // Init controller for biography if not exists
              if (!_bioControllers.containsKey(userId)) {
                _bioControllers[userId] = TextEditingController(text: biography);
              }

              final isCurrentUser = currentUser != null && currentUser!.uid == userId;
              final isEditing = _editingBio[userId] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name, Digital Stamps & Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Row(
                            children: [
                              Chip(
                                label: Text('$digitalStamps Stamps'),
                                backgroundColor: Colors.blue.shade100,
                              ),
                              if (_getBadge(likesCount) != null) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: _getBadge(likesCount)!['name'],
                                  child: Icon(
                                    _getBadge(likesCount)!['icon'],
                                    color: _getBadge(likesCount)!['color'],
                                    size: 28,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Biography editable only for current user
                      if (isCurrentUser) ...[
                        isEditing
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _bioControllers[userId],
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Edit your biography',
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingBio[userId] = false;
                                      // Reset text to saved biography on cancel
                                      _bioControllers[userId]!.text = biography;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _saveBiography(userId),
                                  child: const Text('Save'),
                                ),
                              ],
                            )
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                biography,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _editingBio[userId] = true;
                                });
                              },
                              child: const Text('Edit'),
                            )
                          ],
                        ),
                      ] else ...[
                        // For other users: just display biography text
                        Text(
                          biography,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Likes count display
                      Text('Likes Received: $likesCount'),

                      const SizedBox(height: 8),

                      // Average rating display
                      Row(
                        children: [
                          _buildStarDisplay(avgRating),
                          const SizedBox(width: 8),
                          Text(
                            avgRating > 0
                                ? avgRating.toStringAsFixed(1)
                                : "No ratings",
                          ),
                        ],
                      ),

                      // Rating input if logged in and not rating self
                      if (currentUser != null && currentUser!.uid != userId)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildRatingBar(userId, myRating),
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

  // Display stars for average rating (read-only)
  Widget _buildStarDisplay(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    List<Widget> stars = [];

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }

    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }

    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }

    return Row(children: stars);
  }

  // Build rating bar to let current user rate this user
  Widget _buildRatingBar(String userId, double currentRating) {
    return Row(
      children: List.generate(5, (index) {
        int starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= currentRating ? Icons.star : Icons.star_border,
            color: Colors.blue,
          ),
          onPressed: () => _rateUser(userId, starIndex.toDouble()),
          splashRadius: 20,
        );
      }),
    );
  }
}
