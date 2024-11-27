import 'package:bakenation_staff/product/editproduct.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Product {
  final String name;
  final double price;
  final int stock;
  final String category;
  final String imageUrl;
  final String productID;

  Product(
      {required this.name,
      required this.price,
      required this.stock,
      required this.category,
      required this.imageUrl,
      required this.productID});

  factory Product.fromMap(Map<dynamic, dynamic> map, String productID) {
    return Product(
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        stock: map['stock'] as int,
        category: map['category'] as String,
        imageUrl: map['image_url'] as String? ??
            'https://via.placeholder.com/100x100',
        productID: productID);
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String selectedCategory = 'All Products';
  final List<String> categories = [
    'All Products',
    'Flavorings',
    'Tougheners',
    'Moisteners',
    'Driers'
  ];
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref('products');
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_applyCategoryAndSearchFilter);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          allProducts = data.entries.map((entry) {
            final productId = entry.key;
            final productData = entry.value as Map<dynamic, dynamic>;

            return Product.fromMap(productData, productId);
          }).toList();
          _applyCategoryAndSearchFilter(); // Apply initial filters
        });
      }
    });
  }

  void _applyCategoryAndSearchFilter() {
    final query = searchController.text.toLowerCase();

    setState(() {
      displayedProducts = allProducts.where((product) {
        final matchesCategory = selectedCategory == 'All Products' ||
            product.category == selectedCategory;
        final matchesSearch = product.name.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> refreshData() async {
    // Fetch products and reapply filters
    await fetchProducts();
    _applyCategoryAndSearchFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search products',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show dropdown menu as a modal bottom sheet
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                color: Colors.white,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: categories.map((String category) {
                                    return ListTile(
                                      title: Center(
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: selectedCategory == category
                                                ? Colors.black
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      tileColor: selectedCategory == category
                                          ? Colors.red
                                          : Colors.white,
                                      onTap: () {
                                        setState(() {
                                          selectedCategory = category;
                                        });
                                        Navigator.pop(context);
                                        _applyCategoryAndSearchFilter();
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(163, 25, 25, 1),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 0, 0, 0)
                                    .withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedCategory == 'All Products'
                                    ? 'Category'
                                    : selectedCategory,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Space between dropdown and catalog

              // Product Catalog or No Products Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: displayedProducts.isEmpty
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
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductPage(
                                    productId: product.productID,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
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
                                    padding: const EdgeInsets.all(8.0),
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
                                                  color: Colors.black),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: product.stock <= 20
                                                    ? Colors.red.shade100
                                                    : Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                'Stock: ${product.stock}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: product.stock <= 20
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
