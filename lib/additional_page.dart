import 'package:flutter/material.dart';

class AdditionalPage extends StatelessWidget {
  final Map<String, dynamic> customer;

  const AdditionalPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลเพิ่มเติม'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลลูกค้า:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'ชื่อ: ${customer['first_name']} ${customer['last_name']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'หมายเลขโทรศัพท์: ${customer['phone_number']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Customer ID: ${customer['customer_id']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'แต้มสะสม: ${customer['points_balance']}',
              style: const TextStyle(fontSize: 18),
            ),
            // เพิ่มข้อมูลเพิ่มเติมที่คุณต้องการแสดง
          ],
        ),
      ),
    );
  }
}
