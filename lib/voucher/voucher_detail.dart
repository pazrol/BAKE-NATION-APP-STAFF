import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class VoucherDetailPage extends StatefulWidget {
  static const String routeName = '/voucherDetail';

  final String voucherId;

  const VoucherDetailPage({super.key, required this.voucherId});

  @override
  _VoucherDetailPageState createState() => _VoucherDetailPageState();
}

class _VoucherDetailPageState extends State<VoucherDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _redeemLimitController = TextEditingController();
  final TextEditingController _pointsRedemptionController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("vouchers");
  File? _image;
  String? _imageUrl;
  int _redeemLimit = 0; // Updated variable to hold redeemLimit value

  DateTime? _startDate;
  DateTime? _endDate;
  String _voucherStatus = "active"; // Default voucher status

  @override
  void initState() {
    super.initState();
    _fetchVoucherData(); // Fetch voucher data when page loads
  }

  Future<void> _fetchVoucherData() async {
    final snapshot = await _dbRef.child(widget.voucherId).get();
    if (snapshot.exists) {
      final voucherData = snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        _titleController.text = voucherData['title'] ?? '';
        _descriptionController.text = voucherData['description'] ?? '';
        _pointsRedemptionController.text =
            voucherData['pointsRedemption']?.toString() ?? '';
        _redeemLimit =
            voucherData['redeemLimit'] ?? 0; // Fetch redeemLimit here
        _redeemLimitController.text =
            _redeemLimit.toString(); // Display redeemLimit
        _startDateController.text = voucherData['startDate'] ?? '';
        _endDateController.text = voucherData['endDate'] ?? '';
        _imageUrl = voucherData['image_url'];
        _voucherStatus = voucherData['status'] ?? 'active'; // Fetch status
      });
    }
  }

  Future<void> _toggleVoucherStatus() async {
    try {
      // Toggle the status between "ended" and "active"
      final newStatus = _voucherStatus == "active" ? "ended" : "active";

      await _dbRef.child(widget.voucherId).update({'status': newStatus});

      setState(() {
        _voucherStatus = newStatus;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Voucher status updated to ${newStatus == "active" ? "Active" : "Ended"}'),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update voucher status: $e')),
      );
    }
  }

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

  Future<void> _updateVoucher() async {
    try {
      // Upload image if a new one is selected
      String? uploadedImageUrl = await _uploadImage();

      // Prepare the updated data
      final updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pointsRedemption': int.tryParse(_pointsRedemptionController.text) ?? 0,
        'redeemLimit': int.tryParse(_redeemLimitController.text) ?? 0,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
      };

      // If there's a new image URL, include it in the update
      if (uploadedImageUrl != null) {
        updatedData['image_url'] = uploadedImageUrl;
      }

      // Update the database
      await _dbRef.child(widget.voucherId).update(updatedData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher updated successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update voucher: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null; // If no new image, skip upload

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voucher_images/${widget.voucherId}.jpg');
      final uploadTask = await storageRef.putFile(_image!);
      return await uploadTask.ref
          .getDownloadURL(); // Return the uploaded image URL
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

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

  Future<void> _deleteVoucher() async {
    try {
      // Delete the image from Firebase Storage
      if (_imageUrl != null) {
        final storageRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
        await storageRef.delete();
      }

      // Delete the voucher data from Firebase Database
      await _dbRef.child(widget.voucherId).remove();

      // Navigate back and show success message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher deleted successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete voucher: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voucher Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _image != null
                      ? Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : _imageUrl != null
                          ? Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : const Column(
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
                            ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    "Available Redemption Left: $_redeemLimit",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              ElevatedButton(
                onPressed: _updateVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _toggleVoucherStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _voucherStatus == "active"
                      ? 'End this Voucher'
                      : 'Activate this Voucher',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Delete Voucher',
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
