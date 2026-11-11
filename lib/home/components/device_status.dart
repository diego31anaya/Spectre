import 'package:flutter/material.dart';
import 'package:spectre/themes/dark_mode.dart';

class DeviceStatus extends StatefulWidget {
  const DeviceStatus({super.key});

  @override
  State<DeviceStatus> createState() => _DeviceStatusState();
}

class _DeviceStatusState extends State<DeviceStatus> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget statusRow(String label, String status, bool ready) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                color: darkMode.colorScheme.primary,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 20,
                color: darkMode.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Device Status",
          style: TextStyle(fontSize: 24, color: darkMode.colorScheme.primary),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101610),
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
             statusRow("Camera", "Ready", true),
             Divider(height: 1, color: colors.outline,),
             statusRow("Motion Tracking", "None", false),
             Divider(height: 1, color: colors.outline,),
             statusRow("Microphone", "Ready", true),
            ],
          ),
        ),
      ],
    );
  }
}
