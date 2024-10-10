import 'package:costumer/home_page_customer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  CustomerLoginPageState createState() => CustomerLoginPageState();
}

class CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isLoading = false;

  // ฟังก์ชันสำหรับการ Login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:3000/login/customer'); // URL API ที่จะเรียกใช้งาน
    final body = jsonEncode({
      'customer_id': _customerIdController.text,
      'phone_number': _phoneNumberController.text, // ใช้ phone_number เป็น password
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ตรวจสอบว่าหน้ายังถูก mount อยู่หรือไม่
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login สำเร็จ')),
        );

        // หลังจาก login สำเร็จ อาจพาไปหน้าหลัก
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(customer: data['customer'])),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ข้อมูลล็อกอินไม่ถูกต้อง')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('มีข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Login'),
        backgroundColor: Colors.green, // สีเขียวสำหรับ AppBar
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/pumpwallpaper.png'), // ใส่ path ของภาพพื้นหลัง
            fit: BoxFit.cover, // ให้ภาพขยายเต็มพื้นหลัง
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // เพิ่มความโปร่งใสให้พื้นหลังภายใน
              borderRadius: BorderRadius.circular(16), // ขอบโค้งมน
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // เงาสีเทา
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // ตำแหน่งเงา
                ),
              ],
              border: Border.all(
                color: Colors.green, // กรอบสีเขียว
                width: 2, // ความหนาของกรอบ
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customerIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'เลขสมาชิกสหกรณ์',
                    labelStyle: TextStyle(color: Colors.green), // สีเขียวสำหรับ Label
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // ขอบสีเขียวเมื่อโฟกัส
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    labelStyle: TextStyle(color: Colors.green), // สีเขียวสำหรับ Label
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green), // ขอบสีเขียวเมื่อโฟกัส
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // สีเขียวสำหรับ Progress Indicator
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // พื้นหลังสีเขียว
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // ปุ่มโค้งมน
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.white), // สีขาวสำหรับข้อความในปุ่ม
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
