import 'package:flutter/material.dart';
import 'client_page.dart';
import 'server_page.dart';

void main() {
  runApp(const BlipboardApp());
}

class BlipboardApp extends StatelessWidget {
  const BlipboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Blipboard",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0082FC)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_searching,
              size: 100,
              color: Color(0xFF0082FC),
            ),
            const SizedBox(height:20),
            const Text(
              "Blipboard",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Cross-device clipboard sync via Bluetooth",
              style: TextStyle(color:Colors.grey),
            ),
            const SizedBox(height:40),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=>const ServerPage())
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Start as Server"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF0082FC)
                ),
              ),
            ),
            const SizedBox(height:15),
            SizedBox(
              width: 250,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)=>const ClientPage())
                  );
                },
                icon: const Icon(Icons.upload),
                label: const Text("Start as Client"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color:Color(0xff0082fc)),
                )
              ),
            )
          ]
        )
      ),
    );
  }
}

