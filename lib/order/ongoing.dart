import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OngoingOrdersPage extends StatefulWidget {
  const OngoingOrdersPage({super.key});

  @override
  _OngoingOrdersPageState createState() => _OngoingOrdersPageState();
}

class _OngoingOrdersPageState extends State<OngoingOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchOrders(bool isCompleted) async {
    final DatabaseReference ordersRef = _database.child('orders');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    List<Map<String, dynamic>> orders = [];
    if (data != null) {
      data.forEach((userId, userOrders) {
        if (userOrders is Map) {
          final userOrderDetails =
              userOrders['order_details'] as Map<dynamic, dynamic>?;
          if (userOrderDetails != null) {
            userOrderDetails.forEach((orderId, orderData) {
              String orderStatus = orderData['orderStatus'] ?? 'unknown';
              String shippingTypes = orderData['shippingTypes'] ??
                  'unknown'; // Fetch shippingTypes here
              if ((isCompleted &&
                      (orderStatus == 'completed' ||
                          orderStatus == 'cancelled')) ||
                  (!isCompleted && orderStatus == 'placed') ||
                  (!isCompleted && orderStatus == 'Processing') ||
                  (!isCompleted && orderStatus == 'out_for_delivery') ||
                  (!isCompleted && orderStatus == 'ready_to_pickup') ||
                  (!isCompleted && orderStatus == 'shipped_out')) {
                orders.add({
                  'userId': userId,
                  'orderId': orderId,
                  'orderStatus': orderStatus,
                  'shippingType': shippingTypes, // Use shippingTypes field
                  'cartItems': orderData['cartItems'] ?? [],
                  'subtotal': orderData['subtotal'] ?? 'N/A',
                  'sst': orderData['sst'] ?? 'N/A',
                  'processingFee': orderData['processingFee'] ?? 'N/A',
                  'totalPayment': orderData['totalPayment'] ?? 'N/A',
                });
              }
            });
          }
        }
      });
    }
    return orders;
  }

  Color _getShippingColor(String shippingType) {
    switch (shippingType) {
      case 'PICKUP':
        return Colors.yellow;
      case 'COD':
        return Colors.blue;
      case 'POSTAGE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Reject order and open WhatsApp with customer phone number
  void rejectOrder(String orderId, String userId) async {
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      // Fetch the phone number from addressDetail
      String phoneNumber = data['addressDetail']['phoneNumber'] ?? '';

      // Define a cancellation reason
      String cancellationReason =
          "Hi, we're from Bake Nation Team\n\nYour Order had need to cancel.\n\nOrder ID: $orderId\nReason for Cancellation: \n\n We will refund money back. Please fill in refund details below.\n\nSorry for Inconvenience ";

      if (phoneNumber.isNotEmpty) {
        // Open WhatsApp with the phone number and include the cancellation message
        final String whatsappUrl =
            'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(cancellationReason)}';

        if (await canLaunch(whatsappUrl)) {
          await launch(whatsappUrl); // Launch WhatsApp with the custom message
        } else {
          // If unable to launch WhatsApp, show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open WhatsApp')),
          );
        }
      } else {
        // Show a message if phone number is empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is not available')),
        );
      }

      // Update the order status to 'cancelled'
      await ordersRef.update({'orderStatus': 'cancelled'});
    }
  }

  // function to add tracking number and update status order for postage
  void updateOrderPostage(
    String orderId,
    String userId,
    String trackingNumber,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'shipped_out'});
    }

    // push tracking number
    final orderData = {
      'tracking_number': trackingNumber,
    };

    await ordersRef.update(orderData);
  }

  final trackingNumberController = TextEditingController();

  // Function to show the dialog
  void _showTrackingDialog(
    BuildContext context,
    String orderId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Darker red shade to match image
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Please Enter Tracking Number :',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: trackingNumberController,
              decoration: const InputDecoration(
                hintText: 'Enter tracking number',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.all(10.0),
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(
                onPressed: () {
                  updateOrderPostage(
                      orderId, userId, trackingNumberController.text);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // if order accept
  void acceptOrder(
    List<String> productID,
    List<int> quantity,
    String orderId,
    String userId,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'Processing'});
    }

    // update stock
    for (var i = 0; i < productID.length; i++) {
      final DatabaseReference ordersRef =
          _database.child('products/${productID[i]}');
      final event = await ordersRef.once();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final resultData = data;
        final updateStock = resultData['stock'] - quantity[i];
        await ordersRef.update({'stock': updateStock});
      }
    }
  }

  // ready to delivery
  void readyToDeliver(
    String orderId,
    String userId,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'out_for_delivery'});
    }
  }

  // ready to pickup
  void readyToPickup(
    String orderId,
    String userId,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'ready_to_pickup'});
    }
  }

  // order completed
  void orderCompleted(
    String orderId,
    String userId,
  ) async {
    // update status customer order
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      await ordersRef.update({'orderStatus': 'completed'});
    }
  }

  // ready to delivery

  void sendTelegramNotification(String orderId) {
    // Function to send Telegram notification
    print("Telegram notification for Order ID: $orderId");
  }

  //Whatsapp Function
  // Function to send a WhatsApp message
  void sendWhatsAppMessage(String orderId, String userId) async {
    // Reference to the specific order in the database
    final DatabaseReference ordersRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await ordersRef.once();
    final data = event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      // Fetch the phone number from the addressDetail
      String phoneNumber = data['addressDetail']['phoneNumber'] ?? '';

      // Define the message to send to the customer
      String message =
          "Hello, we are from Bake Nation Team. We are processing your order.\n\nOrder ID: $orderId\n\nThank you for your order!";

      // Check if the phone number is not empty
      if (phoneNumber.isNotEmpty) {
        // Define the WhatsApp URL with the phone number and the message
        final String whatsappUrl =
            'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

        // Check if WhatsApp can be launched and open it
        if (await canLaunch(whatsappUrl)) {
          await launch(whatsappUrl); // Launch WhatsApp with the custom message
        } else {
          // If unable to launch WhatsApp, show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open WhatsApp')),
          );
        }
      } else {
        // Show a message if the phone number is empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is not available')),
        );
      }
    }
  }

//Print Invoice Function
  void printInvoice(String orderId, String userId) async {
    // Fetch order details from the Firebase database
    final DatabaseReference orderRef =
        _database.child('orders/$userId/order_details/$orderId');
    final event = await orderRef.once();
    final orderData = event.snapshot.value as Map<dynamic, dynamic>?;

    if (orderData != null) {
      // Fetch customer details
      String customerName = orderData['addressDetail']['name'] ?? 'N/A';
      String phoneNumber = orderData['addressDetail']['phoneNumber'] ?? 'N/A';
      String address = orderData['addressDetail']['address'] ?? 'N/A';

      // Fetch shipping details
      String shippingType = orderData['shippingTypes'] ?? 'N/A';
      String subtotal = orderData['subtotal'].toString() ?? 'N/A';
      String sst = orderData['sst'].toString() ?? 'N/A';
      String processingFee = orderData['processingFee'].toString() ?? 'N/A';
      String totalAmount = orderData['totalPayment'].toString() ?? 'N/A';

      // Fetch order items
      List<dynamic> cartItems = orderData['cartItems'] ?? [];

      // Generate PDF document
      final pdf = pw.Document();
      // Helper function to create rows in the Payment Summary table
      pw.TableRow buildPaymentRow(String label, String amount,
          {bool isBold = false}) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontWeight:
                          isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(amount,
                  style: pw.TextStyle(
                      fontWeight:
                          isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ),
          ],
        );
      }

      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section
              pw.Text(
                '--------------------------------------------------------------',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'THE BAKE NATION',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
              pw.Text(
                '--------------------------------------------------------------',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              // Customer Information Section
              pw.SizedBox(height: 10),
              pw.Text('Customer Information',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Text('Name: $customerName'),
              pw.Text('Phone Number: $phoneNumber'),
              pw.Text('Address: $address'),
              pw.Text('Shipping Type: $shippingType'),
              pw.Text(
                '--------------------------------------------------------------',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              // Order Details Section
              pw.SizedBox(height: 10),
              pw.Text('Order Details',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(
                      200), // Product Name & Quantity column width
                  1: const pw.FixedColumnWidth(100), // Price column width
                },
                children: [
                  ...cartItems.map<pw.TableRow>((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                              '${item['productName']} x ${item['quantity']}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text('RM${item['productPrice']}'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.Text(
                '--------------------------------------------------------------',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              // Payment Summary Section
              pw.SizedBox(height: 10),
              pw.Text('Payment Summary',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 5),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(200), // Label column width
                  1: const pw.FixedColumnWidth(100), // Amount column width
                },
                children: [
                  buildPaymentRow('Subtotal', 'RM$subtotal'),
                  buildPaymentRow('SST (6%)', 'RM$sst'),
                  buildPaymentRow('Processing Fee', 'RM$processingFee'),
                  buildPaymentRow('Total Amount', 'RM$totalAmount',
                      isBold: true),
                ],
              ),
              pw.Text(
                '--------------------------------------------------------------',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ));

      // Show the invoice dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Invoice',
              style: TextStyle(color: Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with separators and title
                  const Text(
                    '---------------------------------------------',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'THE BAKE NATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    '---------------------------------------------',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Customer Information section
                  const Text('Customer Information',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Name: $customerName'),
                  Text('Phone Number: $phoneNumber'),
                  Text('Address: $address'),
                  Text('Shipping Type: $shippingType'),
                  const SizedBox(height: 10),

                  // Divider for the order details section
                  const Text(
                    '---------------------------------------------',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Order Details',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ...cartItems.map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['productName']} x ${item['quantity']}'),
                          Text('RM${item['productPrice']}'),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Divider for payment summary section
                  const Text(
                    '---------------------------------------------',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Payment Summary',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('RM$subtotal'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SST (6%)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('RM$sst'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Processing Fee',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('RM$processingFee'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('RM$totalAmount'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '---------------------------------------------',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              // Close Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:
                    const Text('Close', style: TextStyle(color: Colors.black)),
              ),
              // Print Button to download PDF
              TextButton(
                onPressed: () async {
                  // Save the generated PDF
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdf.save(),
                  );
                  Navigator.of(context).pop();
                },
                child:
                    const Text('Print', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      );
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order, bool isCompleted) {
    String shippingType = order['shippingType'];
    Color typeColor = _getShippingColor(shippingType);
    List<dynamic> cartItems = order['cartItems'] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Shipping Type inline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order['orderId']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shippingType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Order Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            ...cartItems.map<Widget>((item) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${item['productName'] ?? 'Unknown Item'} x ${item['quantity']}'),
                  Text('RM${item['productPrice'] ?? 'N/A'}'),
                ],
              );
            }),
            const SizedBox(height: 5),
            const Divider(),
            // Display subtotal, SST, and processing fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('RM${order['subtotal']}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SST (6%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('RM${order['sst']}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Processing Fee',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('RM${order['processingFee']}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'RM${order['totalPayment']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons with Print and Telegram Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    printInvoice(order['orderId'], order['userId']);
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.telegram),
                  onPressed: () {
                    sendWhatsAppMessage(order['orderId'], order['userId']);
                  },
                ),
                // Status or Action Buttons
                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: order['orderStatus'] == 'completed'
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['orderStatus'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // button for COD if processing
                if (!isCompleted &&
                    order['orderStatus'] == 'Processing' &&
                    order['shippingType'] == 'COD')
                  ElevatedButton(
                    onPressed: () {
                      // Add your ready to ship logic here

                      final orderID = order['orderId'];
                      final userID = order['userId'];

                      readyToDeliver(orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Ready to Deliver',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                // button for POSTAGE if processing
                if (!isCompleted &&
                    order['orderStatus'] == 'Processing' &&
                    order['shippingType'] == 'POSTAGE')
                  ElevatedButton(
                    onPressed: () {
                      // Add your ready to ship logic here
                      final orderID = order['orderId'];
                      final userID = order['userId'];
                      _showTrackingDialog(context, orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Ready to ship',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                // button for PICKUP if processing
                if (!isCompleted &&
                    order['orderStatus'] == 'Processing' &&
                    order['shippingType'] == 'PICKUP')
                  ElevatedButton(
                    onPressed: () {
                      // Add your ready to ship logic here

                      final orderID = order['orderId'];
                      final userID = order['userId'];

                      readyToPickup(orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Ready to Pickup',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                // button for done completed order COD
                if (!isCompleted &&
                    order['orderStatus'] == 'out_for_delivery' &&
                    order['shippingType'] == 'COD')
                  const Text("Waiting for customer confirmation"),
                // button for done completed order POSTAGE
                if (!isCompleted &&
                    order['orderStatus'] == 'shipped_out' &&
                    order['shippingType'] == 'POSTAGE')
                  const Text("Waiting for customer confirmation"),
                // button for done completed order PICKUP
                if (!isCompleted &&
                    order['orderStatus'] == 'ready_to_pickup' &&
                    order['shippingType'] == 'PICKUP')
                  ElevatedButton(
                    onPressed: () {
                      // make the order complete
                      final orderID = order['orderId'];
                      final userID = order['userId'];

                      orderCompleted(orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Order Completed',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (!isCompleted && order['orderStatus'] == 'placed') ...[
                  ElevatedButton(
                    onPressed: () {
                      // Accept logic here

                      List<String> idProduct = [];
                      List<int> quantity = [];
                      for (var id in cartItems) {
                        idProduct.add(id['productId']);
                        quantity.add(id['quantity']);
                      }

                      final orderID = order['orderId'];
                      final userID = order['userId'];

                      acceptOrder(idProduct, quantity, orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Add your reject logic here

                      final orderID = order['orderId'];
                      final userID = order['userId'];

                      rejectOrder(orderID, userID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'REJECT',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: const Color.fromRGBO(163, 25, 25, 1),
            tabs: const [
              Tab(text: 'Ongoing Orders'),
              Tab(text: 'Completed Orders'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchOrders(false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Ongoing Orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return buildOrderCard(snapshot.data![index], false);
                      },
                    );
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchOrders(true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Completed Orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return buildOrderCard(snapshot.data![index], true);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
