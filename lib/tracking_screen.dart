import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerTrackingScreen extends StatelessWidget {
  final String orderDocId;
  const CustomerTrackingScreen({super.key, required this.orderDocId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        backgroundColor: const Color(0xFFFC8019),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('orderId', isEqualTo: orderDocId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Order search ho raha hai...'));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';
          final eta = data['etaMinutes'] ?? (status == 'Out for Delivery' ? 12 : 25);
          final riderMsg = data['riderStatus'] ??
              (status == 'Out for Delivery'
                  ? 'Rider aapke ghar ke raste par hai!'
                  : 'Kitchen mein aapka fresh khana prepare ho raha hai');

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Arrival Time', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            status == 'Delivered' ? 'Pahunch Gaya ✅' : '$eta Mins Mein',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFC8019)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Live Delivery Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _stepTile('Order Received in Kitchen', true),
                _stepTile('Cooking Fresh Food', status == 'Preparing' || status == 'Out for Delivery' || status == 'Delivered'),
                _stepTile('Rider Picked & On the Way', status == 'Out for Delivery' || status == 'Delivered'),
                _stepTile('Delivered Safely to Home', status == 'Delivered'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.delivery_dining, color: Color(0xFF60B244), size: 36),
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
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? const Color(0xFF60B244) : Colors.grey),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
