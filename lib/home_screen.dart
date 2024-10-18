import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String role;

  HomeScreen({required this.role});

  void _addPhoneData(BuildContext context) async {
    String model = '';
    String specs = '';

    // Show the dialog to add phone data
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Phone Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Phone Model'),
                onChanged: (value) {
                  model = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Specifications'),
                onChanged: (value) {
                  specs = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (model.isNotEmpty && specs.isNotEmpty) {
                  CollectionReference phones = FirebaseFirestore.instance.collection('phone_specs');
                  await phones.add({
                    'model': model,
                    'specs': specs,
                  }).then((value) {
                    print("Phone Data Added");
                  }).catchError((error) {
                    print("Failed to add phone data: $error");
                  });
                }
                Navigator.of(context).pop(); // Close the dialog after saving
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deletePhoneData(String id) async {
    CollectionReference phones = FirebaseFirestore.instance.collection('phone_specs');
    await phones.doc(id).delete().then((value) {
      print("Phone Data Deleted");
    }).catchError((error) {
      print("Failed to delete phone data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (role == 'Admin') ...[
            ElevatedButton(
              onPressed: () => _addPhoneData(context),
              child: Text('Add Phone Data'),
            ),
          ],
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('phone_specs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final phones = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: phones.length,
                  itemBuilder: (context, index) {
                    final phone = phones[index];
                    return ListTile(
                      title: Text(phone['model']),
                      subtitle: Text(phone['specs']),
                      trailing: role == 'Admin'
                          ? IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deletePhoneData(phone.id),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
