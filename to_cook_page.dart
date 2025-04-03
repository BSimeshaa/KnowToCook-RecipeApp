import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ToCookPage extends StatefulWidget {
  final String recipeId;  // Passing recipeId as a string

  const ToCookPage({Key? key, required this.recipeId}) : super(key: key);

  @override
  _ToCookPageState createState() => _ToCookPageState();
}

class _ToCookPageState extends State<ToCookPage> {
  List<String> ingredients = [];
  List<bool> ingredientChecked = [];
  String recipeName = "Loading...";
  String recipeImageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadRecipeIngredients();
  }

  // Load the recipe data from Firestore using the document ID 'recipeId'
  Future<void> _loadRecipeIngredients() async {
    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)  // Fetch the recipe using the document ID (recipeId)
          .get();

      if (recipeDoc.exists) {
        setState(() {
          recipeName = recipeDoc['foodName'] ?? 'Unknown Recipe';
          recipeImageUrl = recipeDoc['imageUrl'] ?? '';  // Fallback to empty string if null
          ingredients = List<String>.from(recipeDoc['ingredients'] ?? []);
          ingredientChecked = List<bool>.filled(ingredients.length, false);  // Initialize all checkboxes as unchecked
        });
      }
    } catch (e) {
      print("Error loading recipe ingredients: $e");
    }
  }

  // Handle checkbox state change
  void _onIngredientChecked(int index, bool value) {
    setState(() {
      ingredientChecked[index] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Cook - Ingredients"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // Navigate back to the homepage
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image (Placeholder if missing)
              recipeImageUrl.isNotEmpty
                  ? Image.network(
                recipeImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
              SizedBox(height: 16),

              // Recipe Name
              Text(
                recipeName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Ingredients List with Checkboxes
              ListView.builder(
                itemCount: ingredients.length,
                shrinkWrap: true,  // Prevent overflow errors if the list is too long
                physics: NeverScrollableScrollPhysics(),  // Prevent scrolling inside the list
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      ingredients[index],
                      style: TextStyle(
                        decoration: ingredientChecked[index]
                            ? TextDecoration.lineThrough  // Cross out the ingredient if checked
                            : null,
                      ),
                    ),
                    trailing: Checkbox(
                      value: ingredientChecked[index],
                      onChanged: (bool? value) {
                        _onIngredientChecked(index, value!);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
