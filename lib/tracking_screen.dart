import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerTrackingScreen extends StatelessWidget {
  final String orderDocId;
  const CustomerTrackingScreen({super.key, required this.orderDocId});

  @override
  Widget build(BuildContext context) {
    final cleanId = orderDocId.trim().replaceAll('#', '');

    Query query = FirebaseFirestore.instance.collection('orders');
    if (cleanId.isNotEmpty) {
      query = query.where('orderId', isEqualTo: cleanId);
    } else {
      query = query.orderBy('createdAt', descending: true).limit(1);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        backgroundColor: const Color(0xFFFC8019),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Order ID "#$cleanId" nahi mila.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text('Kripya sahi Order ID daalein (jaise SS-963714).', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final currentOrderId = data['orderId'] ?? cleanId;
          final status = data['status'] ?? 'Pending';
          final eta = data['etaMinutes'] ?? (status == 'Out for Delivery' ? 12 : 25);
          final riderMsg = data['riderStatus'] ??
              (status == 'Out for Delivery'
                  ? 'Rider aapke ghar ke raste par hai!'
                  : 'Kitchen mein aapka fresh khana ban raha hai');

          final isCooking = status == 'Preparing' || status == 'Out for Delivery' || status == 'Delivered';
          final isOut = status == 'Out for Delivery' || status == 'Delivered';
          final isDelivered = status == 'Delivered';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFC8019)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 40, color: Color(0xFFFC8019)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #$currentOrderId', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              isDelivered ? 'Pahunch Gaya ✅' : '$eta Mins Mein Delivery',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFC8019)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Live Delivery Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _stepTile('Order Received in Kitchen', true),
                _stepTile('Cooking Fresh Food', isCooking),
                _stepTile('Rider Picked & On the Way', isOut),
                _stepTile('Delivered Safely to Home', isDelivered),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isOut ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining, color: isOut ? const Color(0xFFFC8019) : const Color(0xFF60B244), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          riderMsg,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stepTile(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF60B244) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
              color: isDone ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
