import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailsPage extends StatelessWidget {
  final String recipeId;

  RecipeDetailsPage({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recipe Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('recipes')
            .doc(recipeId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Recipe not found"));
          }

          var recipeData = snapshot.data!.data() as Map<String, dynamic>;
          String title = recipeData['foodName'] ?? 'No Title';
          String imageUrl = recipeData['imageUrl'] ?? '';
          String description = recipeData['description'] ?? 'No Description';
          String cookingDuration = recipeData['cookingDuration']?.toString() ?? 'N/A';
          List ingredients = recipeData['ingredients'] ?? [];
          List steps = recipeData['steps'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                )
                    : const Center(child: Icon(Icons.image_not_supported)),
                // Title
                Text(
                  title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 8),

                // Description
                Text(description),

                SizedBox(height: 16),

                // Cooking Duration
                Text(
                  "Cooking Duration: $cookingDuration minutes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 16),

                // Ingredients
                Text(
                  "Ingredients:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (var ingredient in ingredients) Text("- $ingredient"),

                SizedBox(height: 16),

                // Steps
                Text(
                  "Steps:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (var step in steps) Text("- $step"),

                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
