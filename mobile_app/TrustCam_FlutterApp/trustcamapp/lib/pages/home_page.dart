import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference devicesRef =
  FirebaseFirestore.instance.collection('devices');

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    final ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("➕ Add new device"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: "Device name"),
            ),
            TextField(
              controller: ipController,
              decoration:
              const InputDecoration(labelText: "IP Address"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  ipController.text.isNotEmpty) {
                await devicesRef.add({
                  'name': nameController.text.trim(),
                  'ip': ipController.text.trim(),
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2575FC),
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "TrustCam Devices",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: devicesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                        CircularProgressIndicator(color: Color(0xFF2575FC)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No devices found",
                        style:
                        TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    );
                  }
                  final devices = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (ctx, i) {
                      final doc = devices[i];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const Icon(Icons.videocam,
                              color: Color(0xFF2575FC)),
                          title: Text(doc['name']),
                          subtitle: Text("IP: ${doc['ip']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => devicesRef.doc(doc.id).delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeviceDialog,
        backgroundColor: const Color(0xFF2575FC),
        label: const Text("Add Device"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
