import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _showDishDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = isEdit ? (doc.data() as Map<String, dynamic>) : null;

    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final priceCtrl = TextEditingController(text: data != null ? data['price'].toString() : '');
    final catCtrl = TextEditingController(text: data?['category'] ?? 'Sabzi');

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
                decoration: const InputDecoration(labelText: 'Dish Ka Naam (e.g. Shahi Paneer)', isDense: true),
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
                decoration: const InputDecoration(labelText: 'Category (Sabzi, Roti, Rice, Thali, Chai)', isDense: true),
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
              final cat = catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim();

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

  void _addDefaultMenu(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    final defaultDishes = [
      {'name': 'Dal Makhani', 'price': 140, 'category': 'Sabzi'},
      {'name': 'Shahi Paneer', 'price': 170, 'category': 'Sabzi'},
      {'name': 'Butter Roti', 'price': 15, 'category': 'Roti'},
      {'name': 'Jeera Rice', 'price': 110, 'category': 'Rice'},
      {'name': 'Special Shyam Thali', 'price': 220, 'category': 'Thali'},
      {'name': 'Special Chai', 'price': 20, 'category': 'Chai'},
    ];

    for (var dish in defaultDishes) {
      final doc = FirebaseFirestore.instance.collection('menu').doc();
      batch.set(doc, {
        ...dish,
        'isVeg': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo menu add ho gaya!')));
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

            // MENU TAB WITH ADD / EDIT / DELETE
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Abhi koi dish add nahi hai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60B244), foregroundColor: Colors.white),
                            icon: const Icon(Icons.fastfood),
                            label: const Text('Load Demo Menu Items'),
                            onPressed: () => _addDefaultMenu(context),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final doc = items[idx];
                      final d = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 14),
                        title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("₹${d['price']} | Category: ${d['category'] ?? 'General'}"),
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
