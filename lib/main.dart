import 'menu_data.dart';
import 'admin_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'tracking_screen.dart';
import 'rider_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ShreeShyamApp());
}

class ShreeShyamApp extends StatelessWidget {
  const ShreeShyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jai Shree Shyam Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC8019),
          primary: const Color(0xFFFC8019),
          secondary: const Color(0xFF60B244),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF282C3F),
          elevation: 0,
        ),
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
  final Map<String, Map<String, dynamic>> _cart = {};

  void _addToCart(String id, String name, int price) {
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['qty'] = (_cart[id]!['qty'] as int) + 1;
      } else {
        _cart[id] = {'name': name, 'price': price, 'qty': 1};
      }
    });
  }

  void _removeFromCart(String id) {
    setState(() {
      if (_cart.containsKey(id)) {
        int q = _cart[id]!['qty'] as int;
        if (q > 1) {
          _cart[id]!['qty'] = q - 1;
        } else {
          _cart.remove(id);
        }
      }
    });
  }

  int get _cartTotal => _cart.values.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)));
  int get _cartCount => _cart.values.fold(0, (sum, item) => sum + (item['qty'] as int));

  
  void _openRiderLogin(BuildContext context) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery Partner Login'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter Secret PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60B244), foregroundColor: Colors.white),
            onPressed: () {
              if (pinCtrl.text.trim() == '5678') {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Rider PIN!')));
              }
            },
            child: const Text('Login'),
          )
        ],
      ),
    );
  }

  void _openAdminLogin(BuildContext context) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter Secret PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
            onPressed: () {
              if (pinCtrl.text.trim() == '1234') {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN!')));
              }
            },
            child: const Text('Login'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Jai Shree Shyam Restaurant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF282C3F))),
            Text('Pure Veg Bhojanalaya', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Color(0xFFFC8019), size: 26),
            tooltip: 'Track Live Order',
            onPressed: () {
              final idCtrl = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Track Your Order'),
                  content: TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(hintText: 'Enter Order ID (e.g. SS-963714)'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
                      onPressed: () {
                        if (idCtrl.text.trim().isNotEmpty) {
                          final cleanId = idCtrl.text.trim().replaceAll('#', '');
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerTrackingScreen(orderDocId: cleanId)));
                        }
                      },
                      child: const Text('Track Live'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delivery_dining, color: Color(0xFF60B244), size: 28),
            tooltip: 'Rider Portal',
            onPressed: () => _openRiderLogin(context),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => _openAdminLogin(context),
          )
        ],
      ),
      body: Stack(
        children: [
          _currentIndex == 0
              ? MenuScreen(cart: _cart, onAdd: _addToCart, onRemove: _removeFromCart)
              : CartScreen(
                  cart: _cart,
                  onAdd: _addToCart,
                  onRemove: _removeFromCart,
                  onClear: () => setState(() => _cart.clear()),
                ),
          if (_cartCount > 0 && _currentIndex == 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60B244),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_cartCount Items | ₹$_cartTotal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const Row(
                        children: [
                          Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(
            icon: Badge(
              label: Text('$_cartCount'),
              isLabelVisible: _cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Cart',
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

  const MenuScreen({super.key, required this.cart, required this.onAdd, required this.onRemove});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('menu').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final cats = <String>{'All'};
            for (var d in docs) {
              final cat = (d.data() as Map<String, dynamic>)['category'] as String?;
              if (cat != null && cat.isNotEmpty) cats.add(cat);
            }
            return Container(
              color: Colors.white,
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: cats.map((c) {
                  final isSel = c == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: isSel,
                      selectedColor: const Color(0xFFFC8019),
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = c);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menu').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final list = docs.where((d) {
                if (_selectedCategory == 'All') return true;
                return (d.data() as Map<String, dynamic>)['category'] == _selectedCategory;
              }).toList();

              if (list.isEmpty) return const Center(child: Text('Abhi koi dish uplabdh nahi hai'));

              return ListView.separated(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 80),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = list[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = data['name'] ?? 'Dish';
                  final price = (data['price'] ?? 0) as int;
                  final qty = (widget.cart[id]?['qty'] ?? 0) as int;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 10, color: Color(0xFF0F8A65)),
                            const SizedBox(height: 4),
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                          ],
                        ),
                        qty == 0
                            ? OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF60B244)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => widget.onAdd(id, name, price),
                                child: const Text('ADD', style: TextStyle(color: Color(0xFF60B244), fontWeight: FontWeight.bold)),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF60B244)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      iconSize: 16,
                                      icon: const Icon(Icons.remove, color: Color(0xFF60B244)),
                                      onPressed: () => widget.onRemove(id),
                                    ),
                                    Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF60B244))),
                                    IconButton(
                                      iconSize: 16,
                                      icon: const Icon(Icons.add, color: Color(0xFF60B244)),
                                      onPressed: () => widget.onAdd(id, name, price),
                                    ),
                                  ],
                                ),
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
    );
  }
}

class CartScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;
  final Function(String, String, int) onAdd;
  final Function(String) onRemove;
  final VoidCallback onClear;

  const CartScreen({super.key, required this.cart, required this.onAdd, required this.onRemove, required this.onClear});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  double? _custLat;
  double? _custLng;
  bool _fetchingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS permission allow kijiye')));
        setState(() => _fetchingLocation = false);
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _custLat = pos.latitude;
        _custLng = pos.longitude;
        if (_addrCtrl.text.isEmpty) {
          _addrCtrl.text = 'GPS: ' + pos.latitude.toStringAsFixed(5) + ', ' + pos.longitude.toStringAsFixed(5);
        }
        _fetchingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Live GPS Location fetch ho gayi!')));
    } catch (e) {
      setState(() => _fetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Error: ' + e.toString())));
    }
  }
  String _paymentMode = 'Cash on Delivery';
  bool _isOrdering = false;

  int get _total => widget.cart.values.fold(0, (sum, i) => sum + ((i['price'] as int) * (i['qty'] as int)));

  void _confirmOrder() {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kripya Name aur Phone bharein')));
      return;
    }

    if (_paymentMode == 'Online UPI') {
      final upiUrl = 'upi://pay?pa=9302578837-9@axl&pn=ShreeShyam&am=$_total&cu=INR&tn=FoodOrder';
      final qr = 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(upiUrl)}';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan & Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Total Payable: ₹$_total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF60B244))),
              const SizedBox(height: 12),
              Image.network(qr, height: 180, width: 180),
              const SizedBox(height: 8),
              const Text('UPI ID: 9302578837-9@axl', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveOrderToFirebase();
                  },
                  child: const Text('I Have Completed Payment'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _saveOrderToFirebase();
  }

  void _saveOrderToFirebase() async {
    setState(() => _isOrdering = true);
    final orderId = 'SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'paymentMethod': _paymentMode,
        'total': _total,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'items': widget.cart.values.map((i) => {'name': i['name'], 'qty': i['qty'], 'price': i['price']}).toList(),
      });

      setState(() => _isOrdering = false);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF60B244)),
              SizedBox(width: 8),
              Text('Order Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(child: Text('Jai Shree Shyam Restaurant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFC8019)))),
                const Divider(),
                Text('Order ID: #$orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Customer: ${_nameCtrl.text.trim()}'),
                Text('Mobile: ${_phoneCtrl.text.trim()}'),
                if (_addrCtrl.text.trim().isNotEmpty) Text('Table/Note: ${_addrCtrl.text.trim()}'),
                Text('Payment: $_paymentMode', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...widget.cart.values.map((item) {
                  final q = item['qty'] as int;
                  final p = item['price'] as int;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['name']} x$q'),
                      Text('₹${p * q}'),
                    ],
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₹$_total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFC8019))),
                  ],
                ),
                const SizedBox(height: 10),
                const Center(child: Text('Receipt ka screenshot le lein!', style: TextStyle(fontSize: 11, color: Colors.grey))),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.location_on, color: Color(0xFFFC8019)),
              label: const Text('Track Live Delivery', style: TextStyle(color: Color(0xFFFC8019), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerTrackingScreen(orderDocId: orderId)));
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onClear();
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _addrCtrl.clear();
              },
              child: const Text('OK Done'),
            )
          ],
        ),
      );
    } catch (e) {
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return const Center(child: Text('Aapka cart khali hai. Menu se dish add karein.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              ...widget.cart.entries.map((e) {
                final item = e.value;
                final q = item['qty'] as int;
                final p = item['price'] as int;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['name']} x$q', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('₹${p * q}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Table No. / Address', isDense: true)),
              const SizedBox(height: 12),
              const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFFC8019),
                title: const Text('Cash on Delivery (COD)'),
                value: 'Cash on Delivery',
                groupValue: _paymentMode,
                onChanged: (v) => setState(() => _paymentMode = v!),
              ),
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFFC8019),
                title: const Text('Online UPI / QR (Scan & Pay)'),
                value: 'Online UPI',
                groupValue: _paymentMode,
                onChanged: (v) => setState(() => _paymentMode = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('To Pay:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹$_total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFFC8019))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFC8019),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isOrdering ? null : _confirmOrder,
          child: _isOrdering
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('CONFIRM ORDER • ₹$_total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}

