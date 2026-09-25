import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shree Shyam Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFD32F2F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Map<String, Map<String, dynamic>> _cart = {};

  void _addToCart(String id, String name, int price) {
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['qty'] = (_cart[id]!['qty'] as int) + 1;
      } else {
        _cart[id] = {'id': id, 'name': name, 'price': price, 'qty': 1};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name cart me add ho gaya!'), duration: const Duration(seconds: 1)),
    );
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MenuScreen(onAdd: _addToCart),
      CartScreen(cart: _cart, onClear: _clearCart),
      const TableBookingScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shree Shyam Restaurant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPinScreen()));
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.table_restaurant), label: 'Table Book'),
        ],
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  final Function(String id, String name, int price) onAdd;
  const MenuScreen({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('menu').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Menu load nahi hua'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Menu abhi khali hai. Admin Panel se dishes add karein.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Dish';
            final price = (data['price'] ?? 0) as int;
            final category = data['category'] ?? 'General';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.fastfood, color: Color(0xFFD32F2F)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$category • ₹$price'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                  onPressed: () => onAdd(doc.id, name, price),
                  child: const Text('Add'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CartScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;
  final VoidCallback onClear;
  const CartScreen({super.key, required this.cart, required this.onClear});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSubmitting = false;

  int get _totalAmount {
    int total = 0;
    for (var item in widget.cart.values) {
      total += ((item['price'] as int) * (item['qty'] as int));
    }
    return total;
  }

  void _placeOrder() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart khali hai!')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kripya apna naam aur phone number daalein.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderId = 'SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final itemsList = widget.cart.values.map((item) {
        return {
          'name': item['name'],
          'qty': item['qty'],
          'price': item['price'],
        };
      }).toList();

      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'total': _totalAmount,
        'items': itemsList,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      widget.onClear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _addressCtrl.clear();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Placed!'),
          content: Text('Aapka Order (#$orderId) safaltapoorvak place ho gaya hai.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return const Center(child: Text('Aapka cart khali hai'));
    }

    final items = widget.cart.values.toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return ListTile(
                title: Text(it['name']),
                subtitle: Text('₹${it['price']} x ${it['qty']}'),
                trailing: Text('₹${(it['price'] as int) * (it['qty'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Column(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Table No / Delivery Note', isDense: true)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('₹$_totalAmount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSubmitting ? null : _placeOrder,
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Order', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TableBookingScreen extends StatefulWidget {
  const TableBookingScreen({super.key});

  @override
  State<TableBookingScreen> createState() => _TableBookingScreenState();
}

class _TableBookingScreenState extends State<TableBookingScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  bool _loading = false;

  void _bookTable() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kripya naam aur phone bharein')));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('table_bookings').add({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'guests': _guestsCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _guestsCtrl.clear();
      _timeCtrl.clear();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Table Booked!'),
          content: const Text('Aapki table booking request submit ho gayi hai.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Book a Table', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Aapka Naam', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _guestsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kitne Log (Guests)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Samay (e.g. 8:00 PM)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _loading ? null : _bookTable,
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reserve Table', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  final _pinCtrl = TextEditingController();

  void _verifyPin() {
    if (_pinCtrl.text.trim() == '1234') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Galat PIN! Dubara koshish karein.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              const Text('Enter 4-Digit Admin PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                onPressed: _verifyPin,
                child: const Text('Login to Admin Panel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFD32F2F),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Menu Rates'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOrdersTab(),
            AdminMenuTab(),
          ],
        ),
      ),
    );
  }
}

class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Abhi koi orders nahi hain'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final items = (data['items'] as List?) ?? [];
            final itemsText = items.map((i) => "${i['name']} x${i['qty']}").join(", ");

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      Text('Note/Table: ${data['address']}', style: const TextStyle(color: Colors.black54)),
                    const Divider(),
                    const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 2),
                    Text(itemsText.isEmpty ? "Purana order (Items list recorded nahi)" : itemsText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${data['status'] ?? 'Pending'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text('Total: ₹${data['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                      ],
                    ),
                  ],
                         ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  void _showAddEditDish(BuildContext context, [DocumentSnapshot? doc]) {
    final nameCtrl = TextEditingController(text: doc != null ? (doc.data() as Map<String, dynamic>)['name'] : '');
    final priceCtrl = TextEditingController(text: doc != null ? (doc.data() as Map<String, dynamic>)['price'].toString() : '');
    final categoryCtrl = TextEditingController(text: doc != null ? (doc.data() as Map<String, dynamic>)['category'] : 'Main Course');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? 'Add New Dish' : 'Edit Dish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Dish Name')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category (e.g. Sabji, Roti, Thali)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              final cat = categoryCtrl.text.trim();

              if (name.isNotEmpty && price > 0) {
                if (doc == null) {
                  await FirebaseFirestore.instance.collection('menu').add({'name': name, 'price': price, 'category': cat});
                } else {
                  await FirebaseFirestore.instance.collection('menu').doc(doc.id).update({'name': name, 'price': price, 'category': cat});
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDish(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Menu me koi dish nahi hai. + daba kar add karein.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final data = d.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('${data['category'] ?? ''} • ₹${data['price'] ?? 0}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditDish(context, d)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('menu').doc(d.id).delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
