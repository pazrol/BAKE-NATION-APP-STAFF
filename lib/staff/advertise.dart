import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdvertisePage extends StatefulWidget {
  const AdvertisePage({super.key});

  @override
  _AdvertisePageState createState() => _AdvertisePageState();
}

class _AdvertisePageState extends State<AdvertisePage> {
  File? _imageFile;
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child("advertisements");
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Check image aspect ratio (16:9)
      final decodedImage =
          await decodeImageFromList(imageFile.readAsBytesSync());
      final aspectRatio = decodedImage.width / decodedImage.height;

      if ((aspectRatio - (16 / 9)).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select an image with a 51cm x 29cm.")),
        );
        return;
      }

      setState(() {
        _imageFile = imageFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image selected successfully!")),
      );
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    try {
      // Upload image to Firebase Storage
      String filePath =
          'advertisements/advertise_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(filePath);
      await storageRef.putFile(_imageFile!);

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();

      // Store image URL in Firebase Realtime Database
      await _databaseRef.push().set({
        'image_url': downloadUrl,
        'timestamp': DateTime.now().toString(),
        'keyword': 'advertise',
      });

      // Show success pop-up dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Color.fromRGBO(163, 25, 25, 1), size: 120),
                const SizedBox(height: 15),
                const Text(
                  "Successful!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "The advertisement is successfully uploaded.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                    minimumSize: const Size(230, 50),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    setState(() {
                      _imageFile = null; // Clear the selected image
                    });
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Show failure pop-up dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 120),
                const SizedBox(height: 15),
                const Text(
                  "Upload Failed!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Failed to upload advertisement. Please try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.red,
                    minimumSize: const Size(230, 50),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 16 / 9, // 16:9 aspect ratio
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                                size: 50,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to upload image',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '(51cm x 29cm)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImageToFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Advertise',
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
