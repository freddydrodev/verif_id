import 'package:flutter/material.dart';
import 'package:verif_id/verif_id.dart';

void main() {
  runApp(const VerifIdExampleApp());
}

class VerifIdExampleApp extends StatelessWidget {
  const VerifIdExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VerifID Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VerifIdDemoPage(),
    );
  }
}

class VerifIdDemoPage extends StatelessWidget {
  const VerifIdDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Demo: VerifID KYC")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: VerifId(
          sessionId: "demo-session-123",
          onSubmit: (data) async {
            // Handle the final KYC submission (send to server, etc.)
            debugPrint("KYC Data submitted: $data");

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("KYC submission complete ✅")),
              );
            }
          },
        ),
      ),
    );
  }
}
