import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TransactionsPage extends StatefulWidget {
  final int customerId;

  const TransactionsPage({super.key, required this.customerId});

  @override
  TransactionsPageState createState() => TransactionsPageState();
}

class TransactionsPageState extends State<TransactionsPage> {
  List<dynamic> _transactions = [];
  List<dynamic> _redeemedRewards = [];
  int _totalPoints = 0;
  double _totalDividend = 0.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null).then((_) {
      _fetchCustomerData(); // ดึงข้อมูลลูกค้า
      _fetchTransactions();
      _fetchRedeemedRewards();
    });
  }

  Future<void> _fetchCustomerData() async {
    final url = 'http://10.0.2.2:3000/customer/${widget.customerId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final customerData = json.decode(response.body);
        setState(() {
          _totalPoints = customerData['customer']
              ['points_balance']; // ดึงคะแนนสะสมจากฐานข้อมูล
          _totalDividend = _totalPoints * 0.01; // คำนวณปันผลจากคะแนนสะสม
        });
      } else {
        setState(() {
          _totalPoints = 0; // ถ้าดึงข้อมูลไม่ได้ให้คะแนนเป็น 0
          _totalDividend = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _totalPoints = 0; // ถ้าพบข้อผิดพลาดให้คะแนนเป็น 0
        _totalDividend = 0.0;
      });
    }
  }

  Future<void> _fetchTransactions({int page = 1}) async {
    final url =
        'http://10.0.2.2:3000/transactions/${widget.customerId}?page=$page';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          if (page == 1) {
            _transactions = data;
          } else {
            _transactions.addAll(data);
          }

          // จัดเรียงตามวันที่ของธุรกรรม
          _transactions.sort((a, b) => DateTime.parse(b['transaction_date'])
              .compareTo(DateTime.parse(a['transaction_date'])));
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _fetchRedeemedRewards() async {
    final url = 'http://10.0.2.2:3000/redeemed/${widget.customerId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _redeemedRewards = data;
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  List<dynamic> _mergeTransactionsAndRewards() {
    final mergedList =
        List<Map<String, dynamic>>.from(_transactions.map((t) => {
              'type': 'transaction',
              'transaction_id': t['transaction_id'],
              'fuel_type_name': t['fuel_type_name'],
              'transaction_date': t['transaction_date'],
              'points_earned': t['points_earned'],
              'points_used': null,
            }));

    mergedList
        .addAll(List<Map<String, dynamic>>.from(_redeemedRewards.map((r) => {
              'type': 'reward',
              'reward_id': r['reward_id'],
              'reward_name': r['reward_name'],
              'redemption_date': r['redemption_date'],
              'points_used': r['points_used'],
              'transaction_id': null,
            })));
            

    mergedList.sort((a, b) =>
        DateTime.parse(b['transaction_date'] ?? b['redemption_date']).compareTo(
            DateTime.parse(a['transaction_date'] ?? a['redemption_date'])));

    return mergedList;
  }

  String _formatDateTime(String dateTimeString) {
    DateTime utcDateTime = DateTime.parse(dateTimeString);
    DateTime thailandDateTime = utcDateTime.add(const Duration(hours: 7));
    int buddhistYear = thailandDateTime.year + 543;

    // สร้างแผนที่เพื่อแสดงตัวย่อของเดือน
    const monthAbbreviations = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];

    String formattedDate =
        '${thailandDateTime.day} ${monthAbbreviations[thailandDateTime.month - 1]} $buddhistYear';
    String formattedTime =
        '${thailandDateTime.hour}:${thailandDateTime.minute.toString().padLeft(2, '0')}';

    return '$formattedDate $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    final mergedItems = _mergeTransactionsAndRewards();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // สีพื้นหลังอ่อน
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('ประวัติการทำรายการ'),
            backgroundColor: Colors.green[700], // เปลี่ยนสี AppBar
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _fetchTransactions();
                  _fetchRedeemedRewards();
                },
              ),
            ],
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green[800]!,
                            Colors.green[600]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.yellow[300]), // ไอคอนคะแนน
                              const SizedBox(width: 8.0),
                              const Text(
                                'แต้มสะสมทั้งหมด',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '$_totalPoints',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green[800]!,
                            Colors.green[600]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.money, color: Colors.orangeAccent), // ไอคอนเงิน
                              SizedBox(width: 8.0),
                              Text(
                                'ปันผล(บาท)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            _totalDividend.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 8.0),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = mergedItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: item['type'] == 'transaction'
                        ? Text('ธุรกรรม: ${item['fuel_type_name']}')
                        : Text('รางวัล: ${item['reward_name']}'),
                    subtitle: Text(item['type'] == 'transaction'
                        ? 'วันที่: ${_formatDateTime(item['transaction_date'])} - แต้มที่ได้: ${item['points_earned']}'
                        : 'วันที่: ${_formatDateTime(item['redemption_date'])} - แต้มที่ใช้: ${item['points_used']}'),
                    trailing: Icon(
                      item['type'] == 'transaction'
                          ? Icons.local_gas_station
                          : Icons.redeem,
                      color: item['type'] == 'transaction'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                );
              },
              childCount: mergedItems.length,
            ),
          ),
        ],
      ),
    );
  }
}
