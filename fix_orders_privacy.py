with open("lib/main.dart", "r") as f:
    text = f.read()

# 1. Update Cart Screen to store order item breakdown neatly
cart_old = """      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'total': widget.total,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });"""

cart_new = """      List<Map<String, dynamic>> itemsList = widget.cart.values.map((item) {
        return {
          'name': item['name'],
          'qty': item['qty'],
          'price': item['price'],
        };
      }).toList();

      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'total': widget.total,
        'items': itemsList,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });"""

if cart_old in text:
    text = text.replace(cart_old, cart_new)

# 2. Update Admin Orders List to display items breakdown
admin_card_old = """            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${data['orderId'] ?? ''} • ${data['customerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${data['status'] ?? 'Pending'} | ₹${data['total'] ?? 0}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) {
                    FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': val});
                  },
                  itemBuilder: (ctx) => [
                    'Pending',
                    'Preparing',
                    'Ready / Out',
                    'Delivered',
                    'Cancelled'
                  ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                ),
              ),
            );"""

admin_card_new = """            List items = data['items'] as List? ?? [];
            String itemsSummary = items.map((i) => "${i['name']} x${i['qty']}").join(", ");
            if (itemsSummary.isEmpty) itemsSummary = "Item details nahi mili";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          itemBuilder: (ctx) => [
                            'Pending',
                            'Preparing',
                            'Ready / Out',
                            'Delivered',
                            'Cancelled'
                          ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Phone: ${data['phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                    if ((data['address'] ?? '').toString().isNotEmpty)
                      Text('Address/Note: ${data['address']}', style: const TextStyle(color: Colors.black54)),
                    const Divider(),
                    Text('Ordered Items:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 2),
                    Text(itemsSummary, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${data['status'] ?? 'Pending'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('Total: ₹${data['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                      ],
                    ),
                  ],
                ),
              ),
            );"""

if admin_card_old in text:
    text = text.replace(admin_card_old, admin_card_new)

# 3. Remove "Live Orders" tab completely from Customer Bottom Navigation
nav_old = """      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.table_restaurant), label: 'Table Book'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Orders'),
        ],
      ),"""

nav_new = """      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.table_restaurant), label: 'Table Book'),
        ],
      ),"""

if nav_old in text:
    text = text.replace(nav_old, nav_new)

# Update screens list length to match (3 tabs instead of 4)
screen_list_old = """    final screens = [
      MenuScreen(onAddToCart: addToCart),
      CartScreen(cart: cart, onClear: clearCart),
      const TableBookingScreen(),
      const OrdersTrackingScreen(),
    ];"""

screen_list_new = """    final screens = [
      MenuScreen(onAddToCart: addToCart),
      CartScreen(cart: cart, onClear: clearCart),
      const TableBookingScreen(),
    ];"""

if screen_list_old in text:
    text = text.replace(screen_list_old, screen_list_new)

with open("lib/main.dart", "w") as f:
    f.write(text)

print("ORDER_PRIVACY_AND_DETAILS_APPLIED")
