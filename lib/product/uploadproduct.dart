import 'package:bakenation_staff/staff/staff_frame.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UploadProductPage extends StatefulWidget {
  const UploadProductPage({super.key});

  @override
  _UploadProductPageState createState() => _UploadProductPageState();
}

class _UploadProductPageState extends State<UploadProductPage> {
  File? _image;

  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref('products');
  final FirebaseStorage storage = FirebaseStorage.instance;

  final TextEditingController productCodeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  List<String> categories = [
    'Flavorings',
    'Tougheners',
    'Moisteners',
    'Driers'
  ];
  String selectedCategory = '';

  Future<void> selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> uploadProduct() async {
    if (productCodeController.text.isEmpty ||
        nameController.text.isEmpty ||
        categoryController.text.isEmpty ||
        stockController.text.isEmpty ||
        priceController.text.isEmpty ||
        sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill out all the required details')),
      );
      return;
    }

    try {
      String? imageUrl;

      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = storage.ref().child('products/$fileName');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      DatabaseReference newProductRef = databaseRef.push();
      String productId = newProductRef.key!;

      await newProductRef.set({
        'product_code': productCodeController.text,
        'name': nameController.text,
        'category': selectedCategory,
        'stock': int.tryParse(stockController.text) ?? 0,
        'size': sizeController.text,
        'price': double.tryParse(priceController.text) ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'image_url': imageUrl,
      });

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
                  "The product is successfully uploaded.",
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
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const StaffFramePage()));
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              const SizedBox(height: 1),
              GestureDetector(
                onTap: selectImage,
                child: Container(
                  width: double.infinity,
                  height: 300, // Adjusted container height
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
                            Text(
                              '(8cm x 8cm)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : Image.file(
                          _image!,
                          height: 300, // Adjusted image height
                          width: double.infinity,
                          fit: BoxFit.cover, // Ensures image fits in the box
                        ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: productCodeController,
                decoration: const InputDecoration(
                  labelText: 'Product Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
                onTap: () async {
                  String? selected = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('Select Category'),
                        children: categories.map((String category) {
                          return SimpleDialogOption(
                            onPressed: () {
                              Navigator.pop(context, category);
                            },
                            child: Text(category),
                          );
                        }).toList(),
                      );
                    },
                  );
                  if (selected != null) {
                    setState(() {
                      selectedCategory = selected;
                      categoryController.text = selected;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size (e.g :500 Gram or 1 kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (RM)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(27)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Upload',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
