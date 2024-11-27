import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Product {
  final String code;
  final String name;
  final String category;
  final int stock;
  final String size;
  final int price;

  Product({
    required this.code,
    required this.name,
    required this.category,
    required this.stock,
    required this.size,
    required this.price,
  });

  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      code: map['product_code'].toString(),
      name: map['name'].toString(),
      category: map['category'].toString(),
      stock: map['stock'] as int,
      size: map['size'][0].toString(),
      price: map['price'] as int,
    );
  }
}

class StockInventoryPage extends StatefulWidget {
  const StockInventoryPage({super.key});

  @override
  _StockInventoryPageState createState() => _StockInventoryPageState();
}

class _StockInventoryPageState extends State<StockInventoryPage> {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref('products');
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(() {
      filterProducts();
    });
  }

  Future<void> fetchProducts() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          allProducts = data.values.toList();
          filteredProducts =
              List.from(allProducts); // Initialize filteredProducts
        });
      }
    });
  }

  void filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
        final productCode = product['product_code'].toString().toLowerCase();
        final productName = product['name'].toString().toLowerCase();
        return productCode.contains(query) || productName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              width: 330,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or code',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final stockInt = product['stock'] as int;
                  final isLowStock = stockInt <= 20;

                  return Card(
                    color: isLowStock ? Colors.red : Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Code    : ${product['product_code']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Item Name    : ${product['name']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Category     : ${product['category']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Stock        : ${product['stock']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Size         : ${product['size']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Price        : ${product['price']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
