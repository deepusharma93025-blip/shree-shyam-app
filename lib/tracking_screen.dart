import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
                    Text('Order ID "#$cleanId" nahi mila.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              (status == 'Out for Delivery' ? 'Rider raste me hai, live location update ho rahi hai!' : 'Kitchen me prepare ho raha hai');

          final double restaurantLat = (data['restLat'] ?? 26.1360) as double;
          final double restaurantLng = (data['restLng'] ?? 77.6830) as double;

          final double riderLat = (data['riderLat'] ?? (restaurantLat + 0.0040)) as double;
          final double riderLng = (data['riderLng'] ?? (restaurantLng + 0.0035)) as double;

          final double customerLat = (data['custLat'] ?? (restaurantLat + 0.0090)) as double;
          final double customerLng = (data['custLng'] ?? (restaurantLng + 0.0075)) as double;

          final restaurantPoint = LatLng(restaurantLat, restaurantLng);
          final riderPoint = LatLng(riderLat, riderLng);
          final customerPoint = LatLng(customerLat, customerLng);

          return Column(
            children: [
              Expanded(
                flex: 4,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: status == 'Out for Delivery' ? riderPoint : restaurantPoint,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.restaurant',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [restaurantPoint, riderPoint, customerPoint],
                          strokeWidth: 4.0,
                          color: const Color(0xFFFC8019),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: restaurantPoint,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.store, color: Colors.red, size: 36),
                        ),
                        if (status == 'Out for Delivery')
                          Marker(
                            point: riderPoint,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.delivery_dining, color: Color(0xFFFC8019), size: 34),
                            ),
                          ),
                        Marker(
                          point: customerPoint,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.location_on, color: Color(0xFF60B244), size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$currentOrderId', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                status == 'Delivered' ? 'Pahunch Gaya ✅' : '$eta Mins Mein Delivery',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFC8019)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status == 'Out for Delivery' ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
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
                      const Divider(height: 18),
                      Row(
                        children: [
                          Icon(
                            status == 'Out for Delivery' ? Icons.directions_bike : Icons.restaurant,
                            color: const Color(0xFF60B244),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              riderMsg,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _mapLegend(Icons.store, Colors.red, 'Dukan'),
                          const SizedBox(width: 12),
                          _mapLegend(Icons.delivery_dining, const Color(0xFFFC8019), 'Rider'),
                          const SizedBox(width: 12),
                          _mapLegend(Icons.location_on, const Color(0xFF60B244), 'Customer'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapLegend(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}
