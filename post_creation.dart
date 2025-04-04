import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:knowtocook/pages/home_page.dart';

class RecipeCreationPage extends StatefulWidget {
  final String userId;

  const RecipeCreationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _RecipeCreationPageState createState() => _RecipeCreationPageState();
}

class _RecipeCreationPageState extends State<RecipeCreationPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  double _cookingDuration = 30;

  List<TextEditingController> _ingredientControllers = [];
  List<TextEditingController> _stepControllers = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isUploading = false;

  Future<void> _uploadRecipe() async {
    if (_foodNameController.text.isEmpty || _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and provide an image URL")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String userId = widget.userId;
      String imageUrl = _imageUrlController.text;


      List<String> ingredients = _ingredientControllers.map((c) => c.text).toList();
      List<String> steps = _stepControllers.map((c) => c.text).toList();


      var postData = {
        'userID': userId,
        'foodName': _foodNameController.text,
        'description': _descriptionController.text,
        'cookingDuration': _cookingDuration,
        'ingredients': ingredients,
        'steps': steps,
        'imageUrl': imageUrl,
        'likes': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
      };


      await _firestore.collection('recipes').add(postData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recipe uploaded successfully!")),
      );


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(userId: widget.userId),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload recipe: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(userId: widget.userId)),
                );
              },
            ),
            Text("Create Recipe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(labelText: "Food Name"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 10),
            Text("Cooking Duration: ${_cookingDuration.toInt()} mins"),
            Slider(
              value: _cookingDuration,
              min: 10,
              max: 60,
              divisions: 5,
              label: "${_cookingDuration.toInt()} min",
              onChanged: (value) {
                setState(() {
                  _cookingDuration = value;
                });
              },
            ),
            SizedBox(height: 10),
            Text("Ingredients"),
            ..._ingredientControllers.map((controller) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: "Enter Ingredient"),
              ),
            )).toList(),
            ElevatedButton(onPressed: _addIngredient, child: Text("+ Add Ingredient")),
            SizedBox(height: 10),
            Text("Steps"),
            ..._stepControllers.map((controller) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: "Enter Step"),
              ),
            )).toList(),
            ElevatedButton(onPressed: _addStep, child: Text("+ Add Step")),
            SizedBox(height: 20),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: "Image URL"),
            ),

            // Upload Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadRecipe,
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Upload Recipe"),
            ),
          ],
        ),
      ),
    );
  }
}
