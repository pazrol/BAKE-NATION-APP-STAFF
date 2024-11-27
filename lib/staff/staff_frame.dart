import 'package:flutter/material.dart';
import 'package:bakenation_staff/staff/homepage.dart';
import 'package:bakenation_staff/staff/profile.dart';
import 'package:bakenation_staff/product/product.dart';
import 'package:bakenation_staff/order/ongoing.dart';
import 'package:bakenation_staff/product/uploadproduct.dart';
import 'package:bakenation_staff/staff/advertise.dart';
import 'package:bakenation_staff/voucher/voucher.dart';

class StaffFramePage extends StatefulWidget {
  const StaffFramePage({super.key});

  @override
  _StaffFramePageState createState() => _StaffFramePageState();
}

class _StaffFramePageState extends State<StaffFramePage> {
  Widget indextwo = const AdvertisePage();
  int _selectedIndex = 0;

  // List of pages to navigate to based on the index
  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const ProductPage(),
    const UploadProductPage(),
    const OngoingOrdersPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Show bottom sheet with options
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Upload Product'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    indextwo = const UploadProductPage();
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign),
                title: const Text('Advertise'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    indextwo = const AdvertisePage();
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Voucher'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    indextwo = const VoucherPage();
                    _selectedIndex = 2;
                  });
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          title: Center(
            child: Image.asset(
              'assets/bn_logo.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      body: _selectedIndex == 2 ? indextwo : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              foregroundImage: AssetImage('assets/plus_button.png'),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(163, 25, 25, 1),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
