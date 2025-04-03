import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knowtocook/pages/welcome_back_page.dart';

class AccountCreationPage extends StatefulWidget {
  @override
  _AccountCreationPageState createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  String _profileImageUrl = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // method to get an image URL from the user
  Future<void> _pickImageUrl() async {
    String? imageUrl = await _showImageUrlDialog(context);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  // method to store user details in the db
  Future<void> _saveUserData() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a username.")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;

      String profileImageUrl = _profileImageUrl.isNotEmpty ? _profileImageUrl : '';

      await _firestore.collection('users').doc(userId).set({
        'name': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImage': profileImageUrl,
        'recipes': 0,
        'following': 0,
        'followers': 0,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeBackPage(userId: userId)),
      );
    } catch (e) {
      print("Error saving user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


//  final FirebaseStorage _storage = FirebaseStorage.instance; - needed when firebase access is granted

  // method to select an image from the gallery
  /* Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // method to store the profile pic - requires firebase storage access, therefore we have use online images for our app.
 Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      TaskSnapshot uploadTask = await _storage
          .ref('profile_images/$userId.jpg')
          .putFile(_profileImage!);

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageUrl,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : const AssetImage("assets/default_avatar.png") as ImageProvider,
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_usernameController, "Username", Icons.person),
            _buildTextField(_bioController, "Bio", Icons.info, maxLines: 2),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveUserData,
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int? maxLines}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // Method to show a dialog for entering an image URL
  Future<String?> _showImageUrlDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Image URL"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "https://example.com/image.jpg"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}

