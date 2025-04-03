import 'package:flutter/material.dart';
import 'package:knowtocook/pages/login_page.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 50), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildImage("https://wallpapers.com/images/hd/aesthetic-food-pictures-2000-x-2667-5tup8wdyceiymfuo.jpg/?food,1", 140),
                Positioned(top: 50, left: 50, child: _buildImage("https://i.pinimg.com/736x/14/78/6c/14786ca26882aac52cae64ce3c5831cd.jpg?food,2", 80)),
                Positioned(top: 150, right: 50, child: _buildImage("https://i.pinimg.com/736x/28/d6/4c/28d64c914cc605e6673e1a091a70befb.jpg?food,3", 100)),
                Positioned(bottom: 140, left: 50, child: _buildImage("https://i.pinimg.com/736x/0f/0b/aa/0f0baaa4146c215f481057daaef77687.jpg?food,4", 90)),
                Positioned(bottom: 40, right: 50, child: _buildImage("https://i.pinimg.com/736x/09/3b/68/093b68de8bf36cac4d681601409d6789.jpg?food,5", 60)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Start Cooking",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          const Text(
            "Let's join our community\nto cook better food!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImage(String url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
