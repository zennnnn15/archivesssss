import 'dart:io';
import 'package:archives/screens/favScreen.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'loginScreen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<String> _selectedEvents = [];

  List<File> _selectedImages = [];
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_selectedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });

    _fetchImageUrlsForDay(selectedDay).then((imageUrls) {
      setState(() {
        _imageUrls = imageUrls ?? [];
      });
    });
  }

  BoxDecoration _buildEventIndicator(bool isSelectedDay, String imageUrl) {
    final BoxDecoration defaultDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.red,
    );

    if (isSelectedDay) {
      return defaultDecoration.copyWith(color: Colors.white);
    } else {
      return defaultDecoration;
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    // Implement your logic to fetch events for the selected day
    return [];
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage(
      imageQuality: 80, // Set the image quality as needed
      maxWidth: 800, // Set the maximum width of the image as needed
    );
    if (pickedImages != null) {
      for (final pickedImage in pickedImages) {
        final selectedImage = File(pickedImage.path);
        setState(() {
          _selectedImages.add(selectedImage);
        });
        await _uploadImageToStorage(selectedImage);
      }
    }
  }

  Future<void> _uploadImageToStorage(File selectedImage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in
      return;
    }

    final storage = FirebaseStorage.instance;
    final fileName =
        '${user.uid}/${DateFormat('yyyy-MM-dd').format(_selectedDay)}_${_selectedImages.length}.jpg';
    final ref = storage.ref().child('images/$fileName');
    final uploadTask = ref.putFile(selectedImage);

    final snapshot = await uploadTask.whenComplete(() {});
    final imageUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      _imageUrls.add(imageUrl);
    });

    // Store the image URL and timestamp in Cloud Firestore
    final timestamp = Timestamp.now();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('images')
        .add({
      'imageUrl': imageUrl,
      'timestamp': _selectedDay,
      'isfav': false
    });

    // Show success message
    CoolAlert.show(
      context: context,
      type: CoolAlertType.success,
      text: 'Image uploaded successfully!',
    );
  }
  Future<List<String>?> _fetchImageUrlsForDay(DateTime day) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in
      return null;
    }

    final folderName = '${user.uid}/${DateFormat('yyyy-MM-dd').format(day)}';
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('images');

    final querySnapshot = await collectionRef.get();
    final imageUrls = <String>[];

    for (final docSnapshot in querySnapshot.docs) {
      final imageUrl = docSnapshot.get('imageUrl');
      final timestamp = docSnapshot.get('timestamp');
      final imageDay = DateTime.fromMicrosecondsSinceEpoch(timestamp.microsecondsSinceEpoch).toLocal();

      if (isSameDay(imageDay, day)) {
        imageUrls.add(imageUrl);
      }
    }

    return imageUrls.isNotEmpty ? imageUrls : null;
  }

  void _deleteImage(String imageUrl) async {
    final storage = FirebaseStorage.instance;
    try {
      await storage.refFromURL(imageUrl).delete();
      setState(() {
        _imageUrls.remove(imageUrl);
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not logged in
        return;
      }

      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('images');

      final querySnapshot = await collectionRef.where('imageUrl', isEqualTo: imageUrl).get();
      for (final docSnapshot in querySnapshot.docs) {
        await docSnapshot.reference.delete();
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while deleting the image.'),
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
    }
    CoolAlert.show(
      context: context,
      type: CoolAlertType.success,
      text: 'Image deleted succesfully!!',
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context); // Close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final humanReadableDate = DateFormat('EEEE').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Archive Calendar'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[200],
              ),
              child: Image.asset('assets/1.png'),
            ),
            ListTile(
              leading: Icon(Icons.favorite,color: Colors.red,),
              title: Text('Favorite'),
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FavoriteScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _onDaySelected,
              ),
              SizedBox(height: 16.0),
              Text(
                'Archives on: $humanReadableDate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _imageUrls[index];
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
                          top: 8.0,
                          right: 8.0,
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .collection('images')
                                .where('imageUrl', isEqualTo: imageUrl)
                                .snapshots()
                                .map((snapshot) => snapshot.docs.first),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox();
                              }
                              final isFavorite = snapshot.data!.get('isfav') ?? false;
                              return IconButton(
                                icon: Icon(Icons.favorite),
                                color: isFavorite ? Colors.red : null,
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    // User not logged in
                                    return;
                                  }
                                  final collectionRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('images');
                                  final querySnapshot = await collectionRef
                                      .where('imageUrl', isEqualTo: imageUrl)
                                      .get();
                                  for (final docSnapshot in querySnapshot.docs) {
                                    final isFavorite = docSnapshot.get('isfav') ?? false;
                                    await docSnapshot.reference.update({'isfav': !isFavorite});
                                  }
                                  CoolAlert.show(
                                    context: context,
                                    type: CoolAlertType.success,
                                    text: 'Image added/remove on Favorites!',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 8.0,
                          right: 8.0,
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.white,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Delete Image'),
                                    content: Text('Are you sure you want to delete this image?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Delete'),
                                        onPressed: () {
                                          _deleteImage(imageUrl);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadImage,
        child: Icon(Icons.add),
      ),
    );
  }
}
