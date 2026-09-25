import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Cart submission me items array save hona confirm karna
cart_target = "'total': total,"
cart_replace = "'total': total, 'items': cart.values.map((e) => {'name': e['name'], 'qty': e['qty'], 'price': e['price']}).toList(),"
if cart_target in text and "'items': cart.values" not in text:
    text = text.replace(cart_target, cart_replace, 1)

# 2. Orders tab ko fully feature-loaded banana (Daily summary + Delete old + Items breakdown)
new_orders_tab = """class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allDocs = snapshot.data?.docs ?? [];
        if (allDocs.isEmpty) return const Center(child: Text('Abhi koi orders nahi hain'));

        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);

        int todaySales = 0;
        int todayOrdersCount = 0;

        for (var d in allDocs) {
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
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const SizedBox(height: 3),
                      Text('$todayOrdersCount Orders • ₹$todaySales Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, elevation: 0),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Delete Old'),
                    onPressed: () async {
                      final batch = FirebaseFirestore.instance.batch();
                      int count = 0;
                      for (var d in allDocs) {
                        final data = d.data() as Map<String, dynamic>;
                        if (data['status'] == 'Delivered' || data['status'] == 'Cancelled') {
                          batch.delete(d.reference);
                          count++;
                        }
                      }
                      if (count > 0) {
                        await batch.commit();
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count puraane orders delete ho gaye.')));
                      } else {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koi Delivered / Cancelled order nahi mila.')));
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allDocs.length,
                itemBuilder: (context, index) {
                  final doc = allDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final items = (data['items'] as List?) ?? [];
                  final itemsText = items.map((i) => "${i['name']} x${i['qty']}").join(", ");

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${data['orderId'] ?? ''} • ${data['customerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (val) {
                                  FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': val});
                                },
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
                          Text('Phone: ${data['phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                          if ((data['address'] ?? '').toString().isNotEmpty)
                            Text('Table/Note: ${data['address']}', style: const TextStyle(color: Colors.black54)),
                          const Divider(),
                          const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          const SizedBox(height: 2),
                          Text(itemsText.isEmpty ? "Purana order (Item list save nahi thi)" : itemsText,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Status: ${data['status'] ?? 'Pending'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Total: ₹${data['total'] ?? 0}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
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
        );
      },
    );
  }
}"""

# Replace AdminOrdersTab block completely using regex
pattern = r"class AdminOrdersTab extends StatelessWidget\s*\{[\s\S]*?\n\}\s*\nclass AdminMenuTab"
if re.search(pattern, text):
    text = re.sub(pattern, new_orders_tab + "\n\nclass AdminMenuTab", text)
    print("ADMIN_TAB_REPLACED_SUCCESSFULLY")
else:
    print("ADMIN_TAB_PATTERN_NOT_FOUND")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
