import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/login_page.dart';
import 'package:knowtocook/pages/home_page.dart';
import 'package:knowtocook/pages/recipe_details_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String targetUserId;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  bool _isFollowing = false;
  int _followersCount = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = "";
  String bio = "";
  String profileImageUrl = "";
  int recipes = 0;
  int following = 0;
  int followers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkIfFollowing();
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        print("User data fetched: ${userDoc.data()}");
        setState(() {
          username = userDoc['name'] ?? '';
          bio = userDoc['bio'] ?? '';
          profileImageUrl = userDoc['profileImage'] ?? '';
          recipes = userDoc['recipes'] ?? 0;
          following = userDoc['following'] ?? 0;
          followers = userDoc['followers'] ?? 0;
          isLoading = false;
        });
      } else {
        print("No user data found for userId: ${widget.userId}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkIfFollowing() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.targetUserId)
        .get();

    List<dynamic> followers = userDoc['followers'] ?? [];

    setState(() {
      _isFollowing = followers.contains(widget.currentUserId);
      _followersCount = followers.length;
    });
  }

  Future<void> _toggleFollow() async {
    String currentUserId = widget.currentUserId;
    String targetUserId = widget.targetUserId;


    if (_isFollowing) {
      // Unfollow the user
      await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      setState(() {
        _isFollowing = false;
        _followersCount--;
      });
    } else {
      await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });
      setState(() {
        _isFollowing = true;
        _followersCount++;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _updateProfilePicture(String imageUrl) async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'profileImage': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
      });
    } catch (e) {
      print("Error updating profile picture: $e");
    }
  }

  Future<String?> _showImageUrlDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Image URL"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "https://example.com/image.jpg"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(userId: widget.userId)),
    );
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipe deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
              onPressed: _navigateToHomePage,
            ),
            Text("Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      String? imageUrl = await _showImageUrlDialog(context);
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        _updateProfilePicture(imageUrl);
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                      radius: 50,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(bio, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Follower Count with Clickable Text
                      GestureDetector(
                        onTap: _showFollowersList,
                        child: Text(
                          'Followers: $_followersCount',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: "Recipes"),
                      Tab(text: "Liked"),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        buildUserRecipesList(context),
                        _buildLikedRecipes(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowersList() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.targetUserId)
        .get();

    List<dynamic> followerIds = userDoc['followers'] ?? [];

    List<String> followerNames = [];
    for (var followerId in followerIds) {
      DocumentSnapshot followerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(followerId)
          .get();
      if (followerDoc.exists) {
        followerNames.add(followerDoc['name'] ?? 'Unknown');
      }
    }
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: followerNames.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(followerNames[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(DocumentSnapshot recipe, String recipeId) {
    String title = recipe['foodName'] ?? 'No Title';
    String imageUrl = recipe['imageUrl'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageUrl.isNotEmpty
              ? Image.network(
            imageUrl,
            width: double.infinity,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          )
              : const Center(child: Icon(Icons.image_not_supported)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _deleteRecipe(recipeId),
                  child: const Text("Delete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(70, 30),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailsPage(recipeId: recipeId),
                      ),
                    );
                  },
                  child: const Text("View"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(70, 30),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserRecipesList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('recipes')
          .where('userID', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recipes found."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var recipe = snapshot.data!.docs[index];
            String recipeId = recipe.id;

            return _buildRecipeCard(recipe, recipeId);
          },
        );
      },
    );
  }

  Widget _buildLikedRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('likes', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No liked recipes found."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var recipe = snapshot.data!.docs[index];
            return _buildRecipeCard01(recipe);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard01(QueryDocumentSnapshot recipe) {
    var data = recipe.data() as Map<String, dynamic>;

    String title = data['foodName'] ?? 'No Title';
    String imageUrl = data['imageUrl'] ?? '';
    String recipeId = recipe.id;

    bool isLiked = data['likes'].contains(FirebaseAuth.instance.currentUser!.uid);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageUrl.isNotEmpty
              ? Container(
            height: 70,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error));
              },
            ),
          )
              : const Center(child: Icon(Icons.image_not_supported)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          if (isLiked) ...[
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsPage(recipeId: recipeId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(100, 40),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                ),
                child: Text("Cook"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}