import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knowtocook/pages/admin_login_page.dart';
import 'package:knowtocook/pages/notifications_page.dart';
import 'package:knowtocook/pages/post_creation.dart';
import 'package:knowtocook/pages/search_page.dart';
import 'package:knowtocook/pages/to_cook_page.dart';
import 'package:knowtocook/pages/user_profile.dart';

class HomePage extends StatefulWidget {
  final String userId;


  const HomePage({super.key, required this.userId,});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;


  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      _buildHomePage(),
      SearchPage(),
      RecipeCreationPage(userId: widget.userId),
      NotificationsPage( currentUserID:  widget.userId,),
      UserProfilePage(
        userId: widget.userId,
        currentUserId: widget.userId,
        targetUserId: widget.userId,
      ),
    ]);
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text("KnowToCook 🧑‍🍳",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.admin_panel_settings), // Admin icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminLoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No recipes available"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var recipe = snapshot.data!.docs[index];
                      return RecipeCard(recipe: recipe);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onIconClicked(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onIconClicked,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  const RecipeCard({required this.recipe});

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;
  bool _isLiked = false;
  late int _likesCount;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var data = widget.recipe.data() as Map<String, dynamic>;
    _likesCount = data['likes'].length;
    _isLiked = data['likes'].contains(FirebaseAuth.instance.currentUser!
        .uid);
  }

  Future<void> _toggleLike() async {
    var data = widget.recipe.data() as Map<String, dynamic>;
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (_isLiked) {
      await FirebaseFirestore.instance.collection('recipes').doc(
          widget.recipe.id).update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
      setState(() {
        _likesCount--;
        _isLiked = false;
      });
    } else {
      await FirebaseFirestore.instance.collection('recipes').doc(
          widget.recipe.id).update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
      setState(() {
        _likesCount++;
        _isLiked = true;
      });
    }
  }

  Future<void> _addComment() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String commentText = _commentController.text.trim();

    if (commentText.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('recipes')
          .doc(widget.recipe.id)
          .collection('comments')
          .add({
        'userId': userId,
        'commentText': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Comment added")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add comment: $e")));
    }
  }


  @override
  Widget build(BuildContext context) {
    var data = widget.recipe.data() as Map<String, dynamic>;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(data['userID']).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error fetching user data: ${userSnapshot.error}'));
              }
              String userName = userSnapshot.data?.get('name') ?? 'Unknown User';
              String profileImageUrl = userSnapshot.data?.get('profileImage') ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: data['userID'],
                        currentUserId: FirebaseAuth.instance.currentUser!.uid,
                        targetUserId: data['userID'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [

                      CircleAvatar(
                        radius: 20,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      SizedBox(width: 8),
                      Text(
                        userName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              data['imageUrl'] ?? '',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['foodName'] ?? 'Unknown', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                    data['description'] ?? '', maxLines: _isExpanded ? null : 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Text(
                    "⏳ ${data['cookingDuration']} | 🍽 Ingredients: ${data['ingredients']
                        .length}"),
                if (_isExpanded) ...[
                  SizedBox(height: 8),
                  Text("Ingredients: ${data['ingredients'].join(', ')}"),
                  SizedBox(height: 8),
                  Text("Steps:\n${data['steps'].join('\n')}"),
                ],
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(_isExpanded ? "View Less" : "View More"),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null),
                      onPressed: _toggleLike,
                    ),
                    Text("$_likesCount likes"),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Add a Comment"),
                              content: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: "Write your comment...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _addComment();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Post"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .doc(widget.recipe.id)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var commentDocs = snapshot.data?.docs ?? [];
                    if (commentDocs.isEmpty) {
                      return Center(child: Text("No comments yet"));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: commentDocs.length,
                      itemBuilder: (context, index) {
                        var comment = commentDocs[index];
                        String userId = comment['userId'];
                        String commentText = comment['commentText'];
                        Timestamp timestamp = comment['timestamp'];
                        DateTime dateTime = timestamp.toDate();

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (userSnapshot.hasError) {
                              return Center(child: Text('Error fetching user data: ${userSnapshot.error}'));
                            }

                            String userName = userSnapshot.data?.get('name') ?? 'Unknown User';

                            return ListTile(
                              leading: Icon(Icons.account_circle),
                              title: Text(userName),
                              subtitle: Text(commentText),
                              trailing: Text("${dateTime.hour}:${dateTime.minute}"),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ToCookPage(recipeId: widget.recipe.id),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "To Cook",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5), // Spacing between text and icon
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );

  }
}