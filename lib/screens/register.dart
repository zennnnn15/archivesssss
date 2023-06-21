import 'package:flutter/material.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'loginScreen.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Add this line to avoid bottom inset
      body: Container(
        width: double.infinity,
        child: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.0),
                Container(
                  height: 200.0,
                  width: 200.0,
                  child: Image.asset('assets/1.png'),
                ),
                SizedBox(height: 30.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlueAccent.withOpacity(0.3),
                      hintText: 'Username',
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlueAccent.withOpacity(0.3),
                      hintText: 'Email',
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlueAccent.withOpacity(0.3),
                      hintText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: retypePasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlueAccent.withOpacity(0.3),
                      hintText: 'Retype Password',
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      FirebaseAuth auth = FirebaseAuth.instance;
                      UserCredential userCredential =
                      await auth.createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      // Store user data in Firestore
                      CollectionReference users =
                      FirebaseFirestore.instance.collection('users');
                      await users.doc(userCredential.user!.uid).set({
                        'username': usernameController.text,
                        'email': emailController.text,
                      });

                      // Show success alert
                      CoolAlert.show(
                        context: context,
                        type: CoolAlertType.success,
                        text: 'Registration Successful!',
                        confirmBtnText: 'OK',
                        onConfirmBtnTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                        },
                      );



                    } catch (e) {
                      print('Error: $e');
                      // Show error alert
                      CoolAlert.show(
                        context: context,
                        type: CoolAlertType.error,
                        text: 'Registration Error',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.lightBlueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Color(0xFF527DAA),
                      fontSize: 16.0,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
