import 'package:flutter/material.dart';
import 'package:bakenation_staff/product/editproduct.dart';
import 'package:firebase_database/firebase_database.dart';

class Product {
  final String name;
  final double price;
  final int stock;
  final String imageUrl;
  final String productID;

  Product({
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.productID,
  });

  // Factory method to create a Product from a Firebase snapshot map
  factory Product.fromMap(Map<dynamic, dynamic> map, String productID) {
    return Product(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      imageUrl: map['image_url'] ?? 'https://via.placeholder.com/100x100',
      productID: productID,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference productDatabaseRef =
      FirebaseDatabase.instance.ref('products');
  final DatabaseReference adDatabaseRef =
      FirebaseDatabase.instance.ref('advertisements');
  List<Product> products = [];
  List<Map<String, dynamic>> ads = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchAdvertisements();
  }

  // Fetch advertisements from Firebase
  Future<void> fetchAdvertisements() async {
    adDatabaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          ads = data.entries.map((entry) {
            final adData = entry.value as Map<dynamic, dynamic>;
            return {
              'adId': entry.key, // unique ad ID
              'imageUrl':
                  adData['image_url'] ?? 'https://via.placeholder.com/100x100',
            };
          }).toList();
        });
      } else {
        setState(() {
          ads = [];
        });
      }
    });
  }

  // Fetch products from Firebase and limit to top 10
  Future<void> fetchProducts() async {
    productDatabaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          products = data.entries
              .map((entry) {
                final productData = entry.value as Map<dynamic, dynamic>;
                return Product.fromMap(productData, entry.key);
              })
              .toList()
              .take(10)
              .toList(); // Limit to top 10 products
        });
      } else {
        setState(() {
          products = []; // No products found
        });
      }
    });
  }

  // Delete advertisement from Firebase using its unique ID
  Future<void> deleteAdvertisement(String adId) async {
    try {
      await adDatabaseRef.child(adId).remove(); // Delete the advertisement
      setState(() {
        ads.removeWhere(
            (ad) => ad['adId'] == adId); // Remove the ad from the list
      });
    } catch (e) {
      print('Error deleting advertisement: $e');
    }
  }

  // Show confirmation dialog when ad is tapped
  void showDeleteDialog(String adId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Advertisement'),
          content:
              const Text('Are you sure you want to delete this advertisement?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteAdvertisement(adId); // Delete the ad
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Slide Ads Section with 16:9 Aspect Ratio
            AspectRatio(
              aspectRatio: 16 / 9, // Set the aspect ratio to 16:9
              child: ads.isEmpty
                  ? const Center(
                      child: Text(
                        'No advertisements available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : PageView.builder(
                      itemCount: ads.length,
                      itemBuilder: (context, index) {
                        String adId =
                            ads[index]['adId']; // Get the unique ad ID
                        return GestureDetector(
                          onTap: () {
                            showDeleteDialog(adId); // Show delete dialog
                          },
                          child: Image.network(
                            ads[index]['imageUrl'], // Use the ad's image URL
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 30),

            // Product Catalog
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Premium Products',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  products.isEmpty
                      ? const Center(
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProductPage(
                                        productId: product.productID),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        height: 150,
                                        width: double.infinity,
                                        child: Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(7.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'RM${product.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: product.stock <= 20
                                                        ? Colors.red.shade100
                                                        : Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  child: Text(
                                                    'Stock: ${product.stock}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: product.stock <= 20
                                                          ? Colors.red
                                                          : Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
