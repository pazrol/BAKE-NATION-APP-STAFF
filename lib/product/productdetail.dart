import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String imageUrl;

  const ProductDetailPage({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.imageUrl,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSize = '250g'; // Default size
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/bn_logo.png', // Adjust the logo path here
          height: 160,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              // Cart action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: Image.network(
                widget.imageUrl, // Use widget.imageUrl instead of a placeholder
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Product Name and Price
            Text(
              widget.productName, // Use widget.productName
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.productPrice, // Use widget.productPrice
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Size Selector
            Row(
              children: [
                const Text(
                  'Size',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: _selectedSize,
                  onChanged: (String? newSize) {
                    setState(() {
                      _selectedSize = newSize!;
                    });
                  },
                  items: <String>['250g', '500g', '1kg']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity Selector
            Row(
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decrementQuantity,
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _incrementQuantity,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add to Cart Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add to cart action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                ),
                child: const Text(
                  'ADD TO CART',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
