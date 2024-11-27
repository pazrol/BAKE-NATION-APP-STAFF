import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bakenation_staff/staff/add_staff.dart';

class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  _StaffListPageState createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('staff_database');
  List<Map<String, dynamic>> staffData = [];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  void _loadStaffData() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          staffData = [];
          data.forEach((userId, userData) {
            final staffDetail = userData['staff_detail'];
            if (staffDetail != null) {
              staffData.add({
                "Name": staffDetail['Name'] ?? '',
                "Staff ID": staffDetail['Staff ID'] ?? '',
              });
            }
          });
        });
      }
    });
  }

  void _addStaff(String userId, Map<String, dynamic> staffDetail) {
    _dbRef.child(userId).child('staff_detail').set(staffDetail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/bn_logo.png',
          height: 160,
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Staff List',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddStaffPage()),
                    );
                  },
                  label: const Text(
                    'Add Staff',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: Colors.grey, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
              },
              children: [
                // Table header
                const TableRow(
                  decoration:
                      BoxDecoration(color: Color.fromRGBO(163, 25, 25, 1)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Name',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Staff ID',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Table rows
                ...staffData.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  Map<String, dynamic> staff = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          index.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          staff["Name"]!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(staff["Staff ID"]!),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {
                                // Edit logic here
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
