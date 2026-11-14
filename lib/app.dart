import 'themes/dark_mode.dart';
import 'package:flutter/material.dart';
import 'collection/collection_page.dart';
import 'home/home_page.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkMode,
      home: StartPage()
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  int _currentIndex = 0;

  List<Widget> pages = [
    HomePage(),
    CollectionPage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      appBar: AppBar(
        title: Text("SPECTRE"),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_outlined),
            activeIcon: Icon(Icons.collections),
            label: "Collection"
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        ),
    );
  }
}