import 'package:flutter/material.dart';
import 'package:skillcon/screens/login_screen.dart';

PreferredSizeWidget buildCustomAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
    title: Image.asset(
      'lib/assets/branding.png',
      height: 130,
      fit: BoxFit.contain,
    ),
    leading: IconButton(
      icon: const Icon(Icons.menu, color: Colors.black),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Allow full height control
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.6, // 60% of screen height
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Menu', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      onTap: () {
                        Navigator.pop(context); // close bottom sheet
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                    ),
                    // Add more menu items here if needed
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
