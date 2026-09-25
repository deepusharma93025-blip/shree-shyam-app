import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _showDishDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = isEdit ? (doc.data() as Map<String, dynamic>) : null;

    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final priceCtrl = TextEditingController(text: data != null ? data['price'].toString() : '');
    final catCtrl = TextEditingController(text: data?['category'] ?? 'सब्जी');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Dish Edit Karein' : 'Nayi Dish Add Karein', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Dish Ka Naam', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹)', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Category (सब्जी, चावल, पापड़, रोटी / पराठा)', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              final cat = catCtrl.text.trim().isEmpty ? 'अन्य' : catCtrl.text.trim();

              if (name.isEmpty || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sahi Naam aur Price bharein')));
                return;
              }

              if (isEdit) {
                await FirebaseFirestore.instance.collection('menu').doc(doc.id).update({
                  'name': name,
                  'price': price,
                  'category': cat,
                });
              } else {
                await FirebaseFirestore.instance.collection('menu').add({
                  'name': name,
                  'price': price,
                  'category': cat,
                  'isVeg': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Update' : 'Add Dish'),
          ),
        ],
      ),
    );
  }

  void _loadCompleteOfficialMenu(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();

    final officialMenu = [
      // सब्जी
      {'name': 'दाल फ्राई', 'price': 80, 'category': 'सब्जी'},
      {'name': 'दाल तड़का', 'price': 100, 'category': 'सब्जी'},
      {'name': 'सेव भाजी', 'price': 80, 'category': 'सब्जी'},
      {'name': 'सेव टमाटर', 'price': 80, 'category': 'सब्जी'},
      {'name': 'दम आलू', 'price': 100, 'category': 'सब्जी'},
      {'name': 'आलू गोभी', 'price': 80, 'category': 'सब्जी'},
      {'name': 'आलू मटर', 'price': 80, 'category': 'सब्जी'},
      {'name': 'आलू टमाटर', 'price': 80, 'category': 'सब्जी'},
      {'name': 'आलू छोले', 'price': 80, 'category': 'सब्जी'},
      {'name': 'मिक्स वेज', 'price': 100, 'category': 'सब्जी'},
      {'name': 'मटर मसाला', 'price': 110, 'category': 'सब्जी'},
      {'name': 'मटर पनीर', 'price': 120, 'category': 'सब्जी'},
      {'name': 'शाही पनीर', 'price': 140, 'category': 'सब्जी'},
      {'name': 'छोले पनीर', 'price': 140, 'category': 'सब्जी'},
      {'name': 'खोआ पनीर', 'price': 140, 'category': 'सब्जी'},
      {'name': 'बटर पनीर मसाला', 'price': 170, 'category': 'सब्जी'},
      {'name': 'मलाई कोफ्ता', 'price': 170, 'category': 'सब्जी'},
      {'name': 'कढ़ाई पनीर', 'price': 180, 'category': 'सब्जी'},
      {'name': 'काजू पनीर', 'price': 210, 'category': 'सब्जी'},
      {'name': 'काजू कढ़ी', 'price': 180, 'category': 'सब्जी'},
      {'name': 'चना रोस्ट', 'price': 100, 'category': 'सब्जी'},
      {'name': 'चना मसाला', 'price': 100, 'category': 'सब्जी'},
      {'name': 'रायता बूंदी', 'price': 70, 'category': 'सब्जी'},

      // चावल
      {'name': 'सादा पुलाव', 'price': 60, 'category': 'चावल'},
      {'name': 'जीरा पुलाव', 'price': 70, 'category': 'चावल'},
      {'name': 'मटर पुलाव', 'price': 70, 'category': 'चावल'},
      {'name': 'वेज पुलाव', 'price': 90, 'category': 'चावल'},
      {'name': 'पनीर पुलाव', 'price': 90, 'category': 'चावल'},

      // पापड़
      {'name': 'सादा पापड़', 'price': 10, 'category': 'पापड़'},
      {'name': 'फ्राई पापड़', 'price': 30, 'category': 'पापड़'},
      {'name': 'मसाला पापड़', 'price': 50, 'category': 'पापड़'},

      // रोटी / पराठा एवं अन्य
      {'name': 'लच्छा पराठा', 'price': 50, 'category': 'रोटी / पराठा'},
      {'name': 'आलू पराठा', 'price': 50, 'category': 'रोटी / पराठा'},
      {'name': 'पनीर पराठा', 'price': 80, 'category': 'रोटी / पराठा'},
      {'name': 'मिस्सी रोटी', 'price': 10, 'category': 'रोटी / पराठा'},
      {'name': 'सादा रोटी', 'price': 5, 'category': 'रोटी / पराठा'},
      {'name': 'अमूल मक्खन', 'price': 15, 'category': 'रोटी / पराठा'},
      {'name': 'चाय', 'price': 10, 'category': 'रोटी / पराठा'},
      {'name': 'पानी बोतल', 'price': 20, 'category': 'रोटी / पराठा'},
      {'name': 'ग्रीन सलाद', 'price': 40, 'category': 'रोटी / पराठा'},
    ];

    for (var item in officialMenu) {
      final doc = FirebaseFirestore.instance.collection('menu').doc();
      batch.set(doc, {
        ...item,
        'isVeg': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Shree Shyam ka pura official menu load ho gaya!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF282C3F),
          foregroundColor: Colors.white,
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFC8019),
            labelColor: Color(0xFFFC8019),
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Orders'), Tab(text: 'Menu')],
          ),
        ),
        body: TabBarView(
          children: [
            // ORDERS TAB
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!.docs;
                if (orders.isEmpty) return const Center(child: Text('Abhi koi order nahi hai'));

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final doc = orders[idx];
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text("${d['orderId'] ?? ''} • ${d['customerName'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("₹${d['total'] ?? 0} | Status: ${d['status'] ?? 'Pending'}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) => FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': val}),
                          itemBuilder: (_) => ['Pending', 'Preparing', 'Out for Delivery', 'Delivered', 'Cancelled']
                              .map((s) => PopupMenuItem(value: s, child: Text(s)))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // MENU TAB
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: const Color(0xFFFC8019),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Dish'),
                onPressed: () => _showDishDialog(context),
              ),
              body: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('menu').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data?.docs ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('Menu khali hai!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Shree Shyam ka pura official menu ek click mein add karein:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF60B244),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Load Shree Shyam Full Menu (39 Items)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _loadCompleteOfficialMenu(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: Colors.orange.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Dishes: ${items.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFC8019))),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 18, color: Colors.red),
                              label: const Text('Reload Full Menu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _loadCompleteOfficialMenu(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 80),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final doc = items[idx];
                            final d = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 14),
                              title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text("₹${d['price']} | श्रेणी: ${d['category'] ?? 'अन्य'}", style: const TextStyle(color: Colors.black87)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showDishDialog(context, doc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => FirebaseFirestore.instance.collection('menu').doc(doc.id).delete(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
