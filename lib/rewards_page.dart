import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RewardsPage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const RewardsPage({super.key, required this.customer});

  @override
  RewardsPageState createState() => RewardsPageState();
}

class RewardsPageState extends State<RewardsPage> {
  List<Map<String, dynamic>> rewards = [];
  List<Map<String, dynamic>> redeemedRewards = []; // รายการรางวัลที่แลกไป

  @override
  void initState() {
    super.initState();
    fetchRewards();
    fetchRedeemedRewards(); // ดึงข้อมูลรางวัลที่แลก
  }

  Future<void> fetchRewards() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/rewards'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            rewards =
                data.map((reward) => reward as Map<String, dynamic>).toList();
          });
        }
      } else {
        if (mounted) {
          showErrorSnackBar('ไม่สามารถดึงข้อมูลรางวัลได้');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  Future<void> fetchRedeemedRewards() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/redeemed/${widget.customer['customer_id']}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          // เรียงข้อมูลรางวัลที่แลกจากล่าสุดไปเก่าสุด
          data.sort((a, b) => DateTime.parse(b['redemption_date'])
              .compareTo(DateTime.parse(a['redemption_date'])));

          setState(() {
            redeemedRewards =
                data.map((reward) => reward as Map<String, dynamic>).toList();
          });
        }
      } else {
        if (mounted) {
          showErrorSnackBar('ไม่สามารถดึงข้อมูลรางวัลที่แลกได้');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  Future<void> fetchCustomerData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/customers/${widget.customer['customer_id']}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            widget.customer['points_balance'] =
                data['points_balance']; // อัปเดตแต้มทั้งหมด
          });
        }
      }
      // ลบข้อความไม่สามารถดึงข้อมูลลูกค้าได้
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  Future<void> redeemReward(int rewardId, int pointsUsed) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/redeem'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'customer_id': widget.customer['customer_id'],
          'reward_id': rewardId,
          'points_used': pointsUsed,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แลกของรางวัลสำเร็จ')),
          );

          // เรียก fetch ใหม่ทั้งหมดเพื่อรีเฟรชข้อมูล
          await fetchCustomerData(); // ดึงข้อมูลลูกค้าใหม่
          await fetchRewards(); // Refresh rewards after redemption
          await fetchRedeemedRewards(); // Refresh redeemed rewards after redemption
        }
      } else {
        if (mounted) {
          showErrorSnackBar('มีข้อผิดพลาดในการแลกของรางวัล');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('เกิดข้อผิดพลาด: $e');
      }
    }
  }

  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showRewardDetails(Map<String, dynamic> reward) {
    final int totalPoints = widget.customer['points_balance'];
    final int pointsRequired = reward['points_required'];

    if (!mounted) return; // Add a mounted check before showing the dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('รายละเอียดของรางวัล: ${reward['reward_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward['description']),
              const SizedBox(height: 16),
              Text('แต้มทั้งหมดของคุณ: $totalPoints'),
              Text('แต้มที่ใช้แลก: $pointsRequired'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิดหน้าต่าง
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                // เรียกฟังก์ชัน redeemReward
                redeemReward(reward['reward_id'], pointsRequired);
                if (mounted) {
                  Navigator.of(context).pop(); // ปิดหน้าต่าง
                }
              },
              child: const Text('ยืนยันการแลก'),
            ),
          ],
        );
      },
    );
  }

  void _showRedeemedRewards() async {
    await fetchRedeemedRewards();
    if (!mounted) return; // Add a mounted check before showing the dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'รางวัลที่แลก',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.green, // เพิ่มสีเขียวให้หัวข้อ
            ),
          ),
          content: redeemedRewards.isEmpty
              ? const Text(
                  'คุณยังไม่ได้แลกรางวัลใดๆ',
                  style: TextStyle(fontSize: 18), // เพิ่มขนาดตัวอักษร
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    itemCount: redeemedRewards.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey, // สีของเส้นคั่น
                      thickness: 1.0, // ความหนาของเส้นคั่น
                    ),
                    itemBuilder: (context, index) {
                      final redeemedReward = redeemedRewards[index];
                      final DateTime redemptionDate =
                          DateTime.parse(redeemedReward['redemption_date']).add(
                              const Duration(
                                  hours: 7)); // เพิ่ม 7 ชั่วโมงสำหรับเวลาไทย
                      final String formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm').format(redemptionDate);

                      return Card(
                        elevation: 4, // เพิ่มเงาให้การ์ด
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // มุมโค้งมน
                        ),
                        color: Colors.white, // สีพื้นหลังของการ์ด
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.card_giftcard,
                            color: Colors.orange, // เปลี่ยนสีไอคอน
                            size: 40, // ขนาดไอคอน
                          ),
                          title: Text(
                            redeemedReward['reward_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // เพิ่มขนาดตัวอักษรหัวข้อ
                              color: Colors.black87, // สีข้อความหัวข้อ
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID: ${redeemedReward['redemption_id']}',
                                  style: const TextStyle(
                                    color: Colors.blueGrey, // สีข้อความ ID
                                    fontSize: 14,
                                    fontStyle:
                                        FontStyle.italic, // เพิ่มสไตล์ตัวเอียง
                                  ),
                                ),
                                const SizedBox(
                                    height: 4), // ระยะห่างระหว่างบรรทัด
                                Text(redeemedReward['description']),
                                const SizedBox(height: 4),
                                Text(
                                  'เวลา: $formattedDate',
                                  style: const TextStyle(
                                    color: Colors.green, // สีข้อความเวลา
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'สถานะ: ${redeemedReward['status']}',
                                  style: TextStyle(
                                    color: redeemedReward['status'] == 'สำเร็จ'
                                        ? Colors.green // สีเขียวถ้าสำเร็จ
                                        : Colors.red, // สีแดงถ้าล้มเหลว
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'ปิด',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green, // สีปุ่มปิด
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแลกของรางวัล'),
        backgroundColor: Colors.green,
      ),
      body: rewards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward['reward_name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(reward['description']),
                            const SizedBox(height: 8),
                            Text(
                              'Points Required: ${reward['points_required']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                _showRewardDetails(
                                    reward); // แสดงรายละเอียดของรางวัล
                              },
                              child: const Text('รายละเอียด / แลก'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 27, 168, 72),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.star, color: Colors.white),
                      onPressed:
                          _showRedeemedRewards, // แสดงข้อมูลรางวัลที่แลกเมื่อกด
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
