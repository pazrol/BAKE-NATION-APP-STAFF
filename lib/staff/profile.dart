import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:bakenation_staff/voucher/voucher_list.dart';
import 'package:bakenation_staff/product/stock.dart';
import 'package:bakenation_staff/product/salesreport.dart';
import 'package:bakenation_staff/staff/staffList.dart';
import 'package:bakenation_staff/staff/login.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final TextEditingController _aboutUsController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();

  Widget buildMenuOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color.fromRGBO(163, 25, 25, 1),
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Color.fromRGBO(163, 25, 25, 1),
      ),
      onTap: onTap,
    );
  }

  // Function to show the "About Us" input dialog
  void _showAboutUsDialog(BuildContext context) async {
    // Fetch the "About Us" text from Firebase
    DatabaseReference aboutUsRef =
        FirebaseDatabase.instance.ref('aboutUs/aboutUsText');
    DataSnapshot snapshot = await aboutUsRef.get();
    String aboutUsText = snapshot.value?.toString() ?? '';

    // Set the fetched data in the controller
    _aboutUsController.text = aboutUsText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          title: const Text("About Us"),
          content: SizedBox(
            width: 300, // Set the width of the dialog
            height: 200, // Set the height of the dialog
            child: TextField(
              controller: _aboutUsController,
              decoration: const InputDecoration(
                  hintText: 'Enter About store information'),
              minLines: 1,
              maxLines: 10,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Store the "About Us" information in Firebase
                String aboutUsText = _aboutUsController.text.trim();
                if (aboutUsText.isNotEmpty) {
                  DatabaseReference aboutUsRef =
                      FirebaseDatabase.instance.ref('aboutUs');
                  await aboutUsRef.set({'aboutUsText': aboutUsText});
                  // Clear the input field
                  _aboutUsController.clear();
                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('About Us information saved!')),
                  );
                } else {
                  // Show a message if no text is entered
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter some information!')),
                  );
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromRGBO(163, 25, 25, 1), // Button color
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show the "Contact Information" input dialog
  /*void _showContactInfoDialog(BuildContext context) async {
    // Fetch the existing contact information from Firebase
    DatabaseReference contactInfoRef =
        FirebaseDatabase.instance.ref('contactInfo/phoneNumber');
    DataSnapshot snapshot = await contactInfoRef.get();
    String contactInfo = snapshot.value?.toString() ?? '';

    // Set the fetched contact information in the controller
    _contactInfoController.text = contactInfo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          title: const Text("Contact Information"),
          content: Container(
            width: 350, // Set the width of the dialog
            height: 70, // Set the height of the dialog
            child: TextField(
              controller: _contactInfoController,
              decoration: const InputDecoration(
                hintText: 'Enter Contact Number (+60)',
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String contactInfo = _contactInfoController.text.trim();
                if (contactInfo.isNotEmpty && contactInfo.startsWith("+6")) {
                  // Store the updated contact info in Firebase
                  DatabaseReference contactInfoRef =
                      FirebaseDatabase.instance.ref('contactInfo');
                  await contactInfoRef.update({'phoneNumber': contactInfo});
                  // Clear the input field
                  _contactInfoController.clear();
                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Contact Information updated!')),
                  );
                } else {
                  // Show a message if the phone number is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid phone number!')),
                  );
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(163, 25, 25, 1), // Button color
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
          ],
        );
      },
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hello,',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Admin',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(163, 25, 25, 1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            buildMenuOption('Stock Inventory', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StockInventoryPage(),
                ),
              );
            }),
            buildMenuOption('Voucher List', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoucherListPage(),
                ),
              );
            }),
            const Divider(),
            /*ListTile(
              title: const Text(
                'Contact Information',
                style: TextStyle(
                  color: Color.fromRGBO(163, 25, 25, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Color.fromRGBO(163, 25, 25, 1),
              ),
              onTap: () {
                _showContactInfoDialog(context);
              },
            ),*/
            ListTile(
              title: const Text(
                'About Us',
                style: TextStyle(
                  color: Color.fromRGBO(163, 25, 25, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Color.fromRGBO(163, 25, 25, 1),
              ),
              onTap: () {
                _showAboutUsDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromRGBO(163, 25, 25, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.logout,
                color: Color.fromRGBO(163, 25, 25, 1),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
