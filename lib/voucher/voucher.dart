import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  _VoucherPageState createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _redeemLimitController = TextEditingController();
  final TextEditingController _pointsRedemptionController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("vouchers");
  File? _image;

  DateTime? _startDate;
  DateTime? _endDate;

  // Function to pick an image
  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to show date picker
  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text =
            "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}";
      });
    }
  }

  Future<void> _selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text =
            "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}";
      });
    }
  }

  // Function to upload the voucher along with the image
  Future<void> _uploadVoucher() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _redeemLimitController.text.isEmpty ||
        _pointsRedemptionController.text.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill out all the required fields')),
      );
      return;
    }

    try {
      String? imageUrl;

      // If there's an image selected, upload it to Firebase Storage
      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref =
            FirebaseStorage.instance.ref().child('vouchers/$fileName');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      // Create a new voucher entry
      final voucherData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pointsRedemption': _pointsRedemptionController.text,
        'redeemLimit': int.tryParse(_redeemLimitController.text) ?? 0,
        'startDate':
            "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
        'endDate': "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
        'image_url': imageUrl, // Save the image URL in the database
        'status': 'active', // Automatically set status to 'active'
      };

      // Push the voucher data to Firebase Realtime Database
      _dbRef.push().set(voucherData).then((_) {
        // Show pop-up dialog upon successful upload
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
                    "The voucher is successfully uploaded.",
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
                      _clearFields(); // Clear fields after closing dialog
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
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload voucher: $error')),
        );
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  // Function to clear all fields
  void _clearFields() {
    _titleController.clear();
    _descriptionController.clear();
    _redeemLimitController.clear();
    _pointsRedemptionController.clear();
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _image = null;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image upload section
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: double.infinity,
                  height: 200, // 16:9 ratio height
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _image == null
                      ? const Column(
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
                          ],
                        )
                      : Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Description input
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Points Redemption input
              TextField(
                controller: _pointsRedemptionController,
                decoration: const InputDecoration(
                  labelText: 'Points Redemption',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Redeem Limit input
              TextField(
                controller: _redeemLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Redeem Limit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Start Date input
              TextField(
                controller: _startDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
                onTap: _selectStartDate,
              ),
              const SizedBox(height: 10),

              // End Date input
              TextField(
                controller: _endDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
                onTap: _selectEndDate,
              ),
              const SizedBox(height: 20),

              // Upload button
              ElevatedButton(
                onPressed: _uploadVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Upload',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
