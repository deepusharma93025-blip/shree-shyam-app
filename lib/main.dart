import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase: $e");
  }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          primary: const Color(0xFFD32F2F),
        ),
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
        cart[id]!['qty'] = (cart[id]!['qty'] as int) + 1;
      } else {
        cart[id] = {'id': id, 'name': name, 'price': price, 'qty': 1};
      }
    });
  }

  void removeFromCart(String id) {
    setState(() {
      if (cart.containsKey(id)) {
        if ((cart[id]!['qty'] as int) > 1) {
          cart[id]!['qty'] = (cart[id]!['qty'] as int) - 1;
        } else {
          cart.remove(id);
        }
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MenuScreen(
        cart: cart,
        onAdd: addToCart,
        onRemove: removeFromCart,
        onGoToCart: () => setState(() => _currentIndex = 1),
      ),
      CartScreen(
        cart: cart,
        onAdd: addToCart,
        onRemove: removeFromCart,
        onClear: clearCart,
        onGoToTrack: () => setState(() => _currentIndex = 3),
      ),
      const TableBookingScreen(),
      const OrdersTrackScreen(),
    ];

    final totalCartCount = cart.values.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: totalCartCount > 0,
              label: Text('$totalCartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            label: 'Table Book',
          ),
          const NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            label: 'Orders',
          ),
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

  const MenuScreen({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onGoToCart,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Sabzi',
    'Chawal',
    'Roti / Paratha',
    'Papad',
    'Chai',
    'Pey Padarth'
  ];

  void openAdminLogin(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'PIN darj karein (Default: 1234)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              if (pinController.text.trim() == '1234') {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Galat PIN! Sahi PIN dalein.')),
                );
              }
            },
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCartCount = widget.cart.values.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text(
          'Jai Shree Shyam Restaurant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Admin Panel',
            onPressed: () => openAdminLogin(context),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selectedColor: const Color(0xFFD32F2F),
                    backgroundColor: const Color(0xFFF1F3F5),
                    onSelected: (val) => setState(() => selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedCategory == 'All') return true;
                  return (data['category'] ?? '').toString().trim().toLowerCase() == selectedCategory.trim().toLowerCase();
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Item';
                    final price = (data['price'] ?? 0) is int ? data['price'] : int.tryParse(data['price'].toString()) ?? 0;
                    final cat = data['category'] ?? '';
                    final count = widget.cart[doc.id]?['qty'] ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF0F8A65), width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 10),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('₹$price  •  $cat', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                              ],
                            ),
                          ),
                          count == 0
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                                  onPressed: () => widget.onAdd(doc.id, name, price),
                                  child: const Text('ADD', style: TextStyle(color: Colors.white)),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Color(0xFFD32F2F)),
                                      onPressed: () => widget.onRemove(doc.id),
                                    ),
                                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: Color(0xFFD32F2F)),
                                      onPressed: () => widget.onAdd(doc.id, name, price),
                                    ),
                                  ],
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
      bottomNavigationBar: totalCartCount > 0
          ? Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: widget.onGoToCart,
                child: Text('View Cart ($totalCartCount items)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }
}

class CartScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;
  final Function(String, String, int) onAdd;
  final Function(String) onRemove;
  final VoidCallback onClear;
  final VoidCallback onGoToTrack;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onClear,
    required this.onGoToTrack,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool isPlacing = false;

  int calculateTotal() {
    return widget.cart.values.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)));
  }

  void placeOrder() async {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam aur Phone Number bharein!')));
      return;
    }
    setState(() => isPlacing = true);

    try {
      final itemsList = widget.cart.values.map((e) => {
        'name': e['name'],
        'price': e['price'],
        'qty': e['qty'],
      }).toList();

      final orderId = '#SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'items': itemsList,
        'totalAmount': calculateTotal(),
        'status': 'Received',
        'createdAt': FieldValue.serverTimestamp(),
      });

      widget.onClear();
      setState(() => isPlacing = false);
      widget.onGoToTrack();
    } catch (e) {
      setState(() => isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
        body: const Center(child: Text('Aapka cart khali hai.')),
      );
    }

    final total = calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Cart', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...widget.cart.values.map((item) {
              return Card(
                child: ListTile(
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${item['price']} x ${item['qty']} = ₹${item['price'] * item['qty']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () => widget.onRemove(item['id'])),
                      Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => widget.onAdd(item['id'], item['name'], item['price'])),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Aapka Naam *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Table Number', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Text('Total: ₹$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: isPlacing ? null : placeOrder,
                child: isPlacing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TableBookingScreen extends StatefulWidget {
  const TableBookingScreen({super.key});

  @override
  State<TableBookingScreen> createState() => _TableBookingScreenState();
}

class _TableBookingScreenState extends State<TableBookingScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  int guests = 2;
  bool isBooking = false;

  void bookTable() async {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam aur Phone darj karein!')));
      return;
    }
    setState(() => isBooking = true);
    try {
      await FirebaseFirestore.instance.collection('table_bookings').add({
        'customerName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'guests': guests,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => isBooking = false);
      nameCtrl.clear();
      phoneCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Table Booked Successfully!')));
      }
    } catch (e) {
      setState(() => isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Table Booking', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Aapka Naam *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Guests:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: guests,
                  items: [1, 2, 4, 6, 8, 10].map((e) => DropdownMenuItem(value: e, child: Text('$e Persons'))).toList(),
                  onChanged: (v) => setState(() => guests = v ?? 2),
                ),
              ],
            ),
                        const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: isBooking ? null : bookTable,
                child: const Text('Book Table', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
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
      appBar: AppBar(title: const Text('Live Orders', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) return const Center(child: Text('Abhi koi order nahi hai.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final d = orders[index].data() as Map<String, dynamic>;
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

  void updateOrderStatus(String docId, String nextStatus) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': nextStatus});
  }

  void openAddDishDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Sabzi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Pure Veg Dish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Dish Name')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                items: ['Sabzi', 'Chawal', 'Roti / Paratha', 'Papad', 'Chai', 'Pey Padarth']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => category = v);
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                  FirebaseFirestore.instance.collection('menu').add({
                    'name': nameCtrl.text.trim(),
                    'price': int.tryParse(priceCtrl.text.trim()) ?? 100,
                    'category': category,
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void openEditPriceDialog(BuildContext context, String docId, String name, int price) {
    final priceCtrl = TextEditingController(text: '$price');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price: $name'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Naya Price (₹)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              final newP = int.tryParse(priceCtrl.text.trim());
              if (newP != null) {
                FirebaseFirestore.instance.collection('menu').doc(docId).update({'price': newP});
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F),
          title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Menu Rates'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => openAddDishDialog(context),
            )
          ],
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!.docs;
                if (orders.isEmpty) return const Center(child: Text('Koi order nahi hai.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text('${d['orderId']} • ${d['customerName']}'),
                        subtitle: Text('Status: ${d['status']} | ₹${d['totalAmount']}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (st) => updateOrderStatus(doc.id, st),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'Preparing', child: Text('🍳 Cooking')),
                            PopupMenuItem(value: 'Ready / Out', child: Text('📦 Out')),
                            PopupMenuItem(value: 'Delivered', child: Text('✅ Delivered')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final items = snapshot.data!.docs;
                if (items.isEmpty) return const Center(child: Text('Menu me items nahi hain.'));

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final price = (data['price'] ?? 0) is int ? data['price'] : int.tryParse(data['price'].toString()) ?? 0;

                    return ListTile(
                      leading: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 14),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('₹$price | ${data['category'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openEditPriceDialog(context, doc.id, name, price),
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
          ],
        ),
      ),
    );
  }
}
