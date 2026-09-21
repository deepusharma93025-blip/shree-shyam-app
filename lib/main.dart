import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (e) {}
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jai Shree Shyam Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFD32F2F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F), primary: const Color(0xFFD32F2F)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  final Map<String, Map<String, dynamic>> cart = {};

  void addToCart(String id, String name, int price) {
    setState(() {
      if (cart.containsKey(id)) {
      } else {
        cart[id] = {'id': id, 'name': name, 'price': price, 'qty': 1};
      }
    });
  }

  void removeFromCart(String id) {
    setState(() {
      if (cart.containsKey(id)) {
        } else {
          cart.remove(id);
        }
      }
    });
  }

  void clearCart() => setState(() => cart.clear());

  @override
  Widget build(BuildContext context) {
    final screens = [
      MenuScreen(cart: cart, onAdd: addToCart, onRemove: removeFromCart, onGoToCart: () => setState(() => _currentIndex = 1)),
      CartScreen(cart: cart, onAdd: addToCart, onRemove: removeFromCart, onClear: clearCart, onGoToTrack: () => setState(() => _currentIndex = 3)),
      const TableBookingScreen(),
      const OrdersTrackScreen(),
    ];
    final totalCount = cart.values.fold(0, (sum, i) => sum + (i['qty'] as int));

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Badge(isLabelVisible: totalCount > 0, label: Text('$totalCount'), child: const Icon(Icons.shopping_bag_outlined)), label: 'Cart'),
          const NavigationDestination(icon: Icon(Icons.table_restaurant_outlined), label: 'Table Book'),
          const NavigationDestination(icon: Icon(Icons.delivery_dining_outlined), label: 'Orders'),
        ],
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;
  final Function(String, String, int) onAdd;
  final Function(String) onRemove;
  final VoidCallback onGoToCart;
  const MenuScreen({super.key, required this.cart, required this.onAdd, required this.onRemove, required this.onGoToCart});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String cat = 'All';
  final cats = ['All', 'Sabzi', 'Chawal', 'Roti / Paratha', 'Papad', 'Chai', 'Pey Padarth'];

  void openAdmin(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access PIN'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(hintText: 'PIN (Default: 1234)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              if (ctrl.text.trim() == '1234') {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              }
            },
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.cart.values.fold(0, (sum, i) => sum + (i['qty'] as int));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text('Jai Shree Shyam Restaurant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.white), onPressed: () => openAdmin(context))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(label: Text(cats[i]), selected: cat == cats[i], onSelected: (_) => setState(() => cat = cats[i])),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snap) {
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final name = d['name'] ?? '';
                    final price = int.tryParse(d['price'].toString()) ?? 0;
                    final q = widget.cart[id]?['qty'] ?? 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 14),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('₹$price'),
                        trailing: q == 0
                            ? ElevatedButton(onPressed: () => widget.onAdd(id, name, price), child: const Text('ADD'))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.remove), onPressed: () => widget.onRemove(id)),
                                Text('$q', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => widget.onAdd(id, name, price)),
                              ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: totalCount > 0 ? ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)), onPressed: widget.onGoToCart, child: Text('View Cart ($totalCount items)', style: const TextStyle(color: Colors.white))) : null,
    );
  }
}

class CartScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;
  final Function(String, String, int) onAdd;
  final Function(String) onRemove;
  final VoidCallback onClear;
  final VoidCallback onGoToTrack;
  const CartScreen({super.key, required this.cart, required this.onAdd, required this.onRemove, required this.onClear, required this.onGoToTrack});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final total = widget.cart.values.fold(0, (sum, i) => sum + ((i['price'] as int) * (i['qty'] as int)));
    return Scaffold(
      appBar: AppBar(title: const Text('Cart & Checkout', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...widget.cart.values.map((i) => ListTile(title: Text(i['name']), subtitle: Text('₹${i['price']} x ${i['qty']} = ₹${i['price'] * i['qty']}'))),
          const Divider(),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Address / Table No.', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Text('Total: ₹$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () async {
              if (name.text.isEmpty || phone.text.isEmpty) return;
              final orderId = '#SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
              await FirebaseFirestore.instance.collection('orders').add({
                'orderId': orderId,
                'customerName': name.text,
                'phone': phone.text,
                'address': address.text,
                'items': widget.cart.values.toList(),
                'totalAmount': total,
                'status': 'Received',
                'createdAt': FieldValue.serverTimestamp(),
              });
              widget.onClear();
              widget.onGoToTrack();
            },
            child: const Text('Confirm Order', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

class TableBookingScreen extends StatelessWidget {
  const TableBookingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final name = TextEditingController();
    final phone = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Table Booking', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              onPressed: () async {
                if (name.text.isEmpty || phone.text.isEmpty) return;
                await FirebaseFirestore.instance.collection('table_bookings').add({'customerName': name.text, 'phone': phone.text, 'createdAt': FieldValue.serverTimestamp()});
                name.clear(); phone.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Table Booked!')));
              },
              child: const Text('Book Table', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}

class OrdersTrackScreen extends StatelessWidget {
  const OrdersTrackScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Orders', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text('${d['orderId']} • ₹${d['totalAmount']}'),
                  subtitle: Text('Status: ${d['status']} | ${d['customerName']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text('${d['orderId']} (${d['status']})'),
                  subtitle: Text('${d['customerName']} - ₹${d['totalAmount']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (st) => FirebaseFirestore.instance.collection('orders').doc(docs[i].id).update({'status': st}),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'Preparing', child: Text('🍳 Cooking')),
                      const PopupMenuItem(value: 'Ready / Out', child: Text('📦 Out')),
                      const PopupMenuItem(value: 'Delivered', child: Text('✅ Delivered')),
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
