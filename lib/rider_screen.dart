import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderDashboardScreen extends StatelessWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF60B244),
        foregroundColor: Colors.white,
        title: const Text('Rider Delivery Portal'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs.where((d) {
            final st = (d.data() as Map<String, dynamic>)['status'] ?? '';
            return st != 'Delivered' && st != 'Cancelled';
          }).toList();

          if (orders.isEmpty) return const Center(child: Text('Abhi koi active delivery nahi hai!'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final doc = orders[idx];
              final d = doc.data() as Map<String, dynamic>;
              final orderId = d['orderId'] ?? '';
              final name = d['customerName'] ?? '';
              final phone = d['phone'] ?? '';
              final address = d['address'] ?? 'No Address';
              final status = d['status'] ?? 'Pending';
              final total = d['total'] ?? 0;
              final eta = d['etaMinutes'] ?? 15;

              return Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#$orderId - $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == 'Out for Delivery' ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Out for Delivery' ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Address: $address', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Phone: $phone', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      Text('Total: ₹$total | ${d["paymentMethod"] ?? "COD"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFC8019))),
                      if (status == 'Out for Delivery')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('ETA Customer ko dikh raha hai: $eta Mins', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (status != 'Out for Delivery')
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('orders').doc(doc.id).update({
                                    'status': 'Out for Delivery',
                                    'etaMinutes': 12,
                                    'riderStatus': 'Rider is on the way with your food',
                                  });
                                },
                                child: const Text('Pick Delivery'),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60B244), foregroundColor: Colors.white),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('orders').doc(doc.id).update({
                                  'status': 'Delivered',
                                  'etaMinutes': 0,
                                  'riderStatus': 'Delivered successfully',
                                });
                              },
                              child: const Text('Delivered ✅'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
