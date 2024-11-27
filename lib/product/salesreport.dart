import 'package:flutter/material.dart';
import 'dart:math';

class SalesReportPage extends StatelessWidget {
  SalesReportPage({super.key});

  // Define data for Total Sales, Monthly Sales, and Sales Percentage
  final Map<String, double> salesDataMap = {
    "Total Sales": 70,
    "Monthly Sales": 20,
    "Sales Percentage": 10,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Report',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Pie Chart Section
              const Center(
                child: Text(
                  'Sales Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: PieChartPainter(salesDataMap),
                ),
              ),
              const SizedBox(height: 20),
              // Details Section
              const Text(
                'Sales by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              buildSalesItem('1. Flavorings', '69%', Colors.red[800]!),
              buildSalesItem('2. Tougheners', '63%', Colors.red[800]!),
              buildSalesItem('3. Moisteners', '23%', Colors.red[800]!),
              buildSalesItem('4. Driers', '10%', Colors.red[800]!),
              const SizedBox(height: 20),
              const Text(
                'Sales by Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              buildSalesItem('1. Cream Cheese', '32%', Colors.red[800]!),
              buildSalesItem('2. Anchor Butter', '28%', Colors.red[800]!),
              buildSalesItem('3. Pistachio Paste', '23%', Colors.red[800]!),
              buildSalesItem('4. Chocolate Bar', '15%', Colors.red[800]!),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSalesItem(String title, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            percentage,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.values.reduce((a, b) => a + b);
    double startAngle = -pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [Colors.red, Colors.orange, Colors.blue];
    int colorIndex = 0;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;
      paint.color = colors[colorIndex % colors.length];
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
