import 'package:flutter/material.dart';
import 'package:spectre/components/primary_button.dart';

import 'components/device_status.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DeviceStatus(),
                PrimaryButton(text: "Initialize Camera", onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
