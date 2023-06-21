import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late List<Map<String, dynamic>> _favoriteImages;

  @override
  void initState() {
    super.initState();
    _favoriteImages = [];
    _fetchFavoriteImages();
  }

  Future<void> _fetchFavoriteImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in
      return;
    }

    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('images');

    final querySnapshot = await collectionRef.where('isfav', isEqualTo: true).orderBy('timestamp').get();

    final favoriteImages = querySnapshot.docs.map((docSnapshot) {
      final imageUrl = docSnapshot.get('imageUrl');
      final timestamp = docSnapshot.get('timestamp').toDate();
      return {
        'imageUrl': imageUrl,
        'timestamp': timestamp,
      };
    }).toList();

    setState(() {
      _favoriteImages = favoriteImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Images'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: _favoriteImages.length,
        itemBuilder: (context, index) {
          final imageUrl = _favoriteImages[index]['imageUrl'];
          final timestamp = _favoriteImages[index]['timestamp'];
          final formattedDate = DateFormat('MMM dd, yyyy').format(timestamp);

          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.white70,
                    content: Image.network(imageUrl),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.0,
                  left: 8.0,
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
