import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bakenation_staff/voucher/voucher_detail.dart'; // Ensure the correct import path

class VoucherListPage extends StatefulWidget {
  const VoucherListPage({super.key});

  @override
  _VoucherListPageState createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('vouchers');
  List<Map<String, dynamic>> _activeVouchers = [];
  List<Map<String, dynamic>> _endedVouchers = [];

  @override
  void initState() {
    super.initState();
    _fetchVouchers(); // Fetch vouchers on initialization
  }

  // Fetch vouchers from Firebase Realtime Database
  void _fetchVouchers() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final List<Map<String, dynamic>> activeVouchers = [];
        final List<Map<String, dynamic>> endedVouchers = [];

        data.forEach((key, value) {
          final voucher = {
            'id': key,
            'image_url': value['image_url'] ?? '',
            'status': value['status'] ?? '',
          };

          if (voucher['status'] == 'active') {
            activeVouchers.add(voucher);
          } else if (voucher['status'] == 'ended') {
            endedVouchers.add(voucher);
          }
        });

        setState(() {
          _activeVouchers = activeVouchers;
          _endedVouchers = endedVouchers;
        });
      }
    });
  }

  // Build a voucher card (without title, only the image)
  Widget buildVoucherCard(Map<String, dynamic> voucher) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoucherDetailPage(voucherId: voucher['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: voucher['image_url'].isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(voucher['image_url']),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Voucher List",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          bottom: const TabBar(
            indicatorColor:
                Color.fromRGBO(163, 25, 25, 1), // Set indicator color
            labelColor: Color.fromRGBO(
                163, 25, 25, 1), // Set text color for selected tab
            unselectedLabelColor:
                Colors.black, // Optional: Set text color for unselected tab
            tabs: [
              Tab(
                text: 'Active Voucher',
              ),
              Tab(text: 'Ended Voucher'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _activeVouchers.isNotEmpty
                ? ListView(
                    children: _activeVouchers.map((voucher) {
                      return buildVoucherCard(voucher);
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'No active Vouchers',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            _endedVouchers.isNotEmpty
                ? ListView(
                    children: _endedVouchers.map((voucher) {
                      return buildVoucherCard(voucher);
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'No Voucher History',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
