import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'transactions_page.dart';
import 'card_page.dart';
import 'rewards_page.dart';
import 'additional_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const HomePage({super.key, required this.customer});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    final url =
        'http://10.0.2.2:3000/customers/${widget.customer['customer_id']}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final updatedCustomer = json.decode(response.body);
        setState(() {
          widget.customer['points_balance'] =
              updatedCustomer['customer']['points_balance'];
        });
      } else {
        // Handle errors if needed
      }
    } catch (e) {
      // Handle exceptions if needed
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _fetchCustomerData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget getPage(int index) {
      switch (index) {
        case 1:
          return TransactionsPage(customerId: widget.customer['customer_id']);
        case 2:
          return CardPage(customer: widget.customer);
        case 3:
          return RewardsPage(customer: widget.customer);
        case 4:
          return AdditionalPage(customer: widget.customer);
        default:
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/pumpwallpaper.png'), // ใช้ชื่อไฟล์ภาพ
                    fit: BoxFit.cover, // ปรับภาพให้เต็มพื้นที่
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [

                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.customer['first_name']} ${widget.customer['last_name']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Customer ID: ${widget.customer['customer_id']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 30, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Phone: ${widget.customer['phone_number']}',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 30, color: Color.fromARGB(255, 166, 27, 27)),
                        const SizedBox(width: 10),
                        Text(
                          'แต้มสะสมของคุณ : ${widget.customer['points_balance']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
      }
    }

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text('Welcome ${widget.customer['first_name']}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchCustomerData,
                ),
              ],
              backgroundColor: Colors.green,
            )
          : null,
      body: getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'รายการ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'บัตร',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.redeem),
            label: 'แลกรางวัล',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'เพิ่มเติม',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 42, 216, 181),
        unselectedItemColor: const Color.fromARGB(255, 253, 253, 253),
        backgroundColor: const Color.fromARGB(255, 54, 124, 56),
        onTap: _onItemTapped,
      ),
    );
  }
}
