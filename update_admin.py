with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Cart submit me items list Firestore me save hona confirm karna
old_cart = "'total': total,"
new_cart = "'total': total, 'items': cart.values.map((e) => {'name': e['name'], 'qty': e['qty'], 'price': e['price']}).toList(),"
if old_cart in text and "'items': cart.values" not in text:
    text = text.replace(old_cart, new_cart, 1)

# 2. Orders StreamBuilder ko wrap karna Daily Sales Summary, Delete Old Orders aur Item Breakdown ke sath
marker_start = "StreamBuilder<QuerySnapshot>(\n            stream: FirebaseFirestore.instance.collection('orders')"
if marker_start not in text:
    marker_start = "StreamBuilder<QuerySnapshot>(\n            stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),"

# Pura block replace karte hain
old_stream_code = """StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final orders = snapshot.data!.docs;
              if (orders.isEmpty) return const Center(child: Text('Abhi koi order nahi hai.'));"""

new_stream_code = """StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final allOrders = snapshot.data!.docs;
              if (allOrders.isEmpty) return const Center(child: Text('Abhi koi order nahi hai.'));

              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);

              int todaySales = 0;
              int todayOrdersCount = 0;

              for (var d in allOrders) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (ts != null && ts.toDate().isAfter(startOfToday)) {
                  todayOrdersCount++;
                  todaySales += ((data['total'] ?? 0) as num).toInt();
                }
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Aaj Ka Hissab (Today)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD32F2F))),
                            const SizedBox(height: 2),
                            Text('$todayOrdersCount Orders • ₹$todaySales Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, elevation: 0),
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete Old', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            final batch = FirebaseFirestore.instance.batch();
                            int count = 0;
                            for (var d in allOrders) {
                              final data = d.data() as Map<String, dynamic>;
                              if (data['status'] == 'Delivered' || data['status'] == 'Cancelled') {
                                batch.delete(d.reference);
                                count++;
                              }
                            }
                            if (count > 0) {
                              await batch.commit();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count delivered/cancelled orders delete ho gaye.')));
                            } else {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koi purana delivered order nahi mila.')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: allOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = allOrders[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final items = (data['items'] as List?) ?? [];
                        final itemsText = items.map((i) => "${i['name']} x${i['qty']}").join(", ");

                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${data['orderId'] ?? ''} • ${data['customerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) => updateOrderStatus(doc.id, val),
                                      itemBuilder: (_) => [
                                        'Pending',
                                        'Preparing',
                                        'Ready / Out',
                                        'Delivered',
                                        'Cancelled',
                                      ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                                    ),
                                  ],
                                ),
                                Text('Phone: ${data['phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                if ((data['address'] ?? '').toString().isNotEmpty)
                                  Text('Note/Table: ${data['address']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                const Divider(),
                                const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(itemsText.isEmpty ? "Purana order (Item list nahi thi)" : itemsText,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Status: ${data['status'] ?? 'Pending'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    Text('Total: ₹${data['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );"""

# Replace the orders list block
idx1 = text.find("StreamBuilder<QuerySnapshot>(\n            stream: FirebaseFirestore.instance.collection('orders')")
idx2 = text.find("StreamBuilder<QuerySnapshot>(\n            stream: FirebaseFirestore.instance.collection('menu')", idx1)

if idx1 != -1 and idx2 != -1:
    # Check closing of first StreamBuilder before menu
    part_before = text[:idx1]
    part_after = text[idx2:]
    text = part_before + new_stream_code + "\n          },\n        ),\n        " + part_after
    print("SUCCESSFULLY_UPDATED_ADMIN_VIEW")
else:
    print("INDEX_NOT_MATCHED", idx1, idx2)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
