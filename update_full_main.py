with open("lib/main.dart", "r") as f:
    text = f.read()

# Fix the broken data getters in AdminDashboardScreen/Orders
import re

# Remove buggy injected subtitle blocks if any
pattern_broken = r"subtitle:\s*Column\([\s\S]*?Text\('Items: '[\s\S]*?\),\s*\),"
text = re.sub(pattern_broken, "subtitle: Text('Status: ${data[\"status\"]} | Total: ₹${data[\"total\"]}'),", text)

# Properly inject items array inside cart submission
old_cart_add = """      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'customerName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'total': widget.total,"""

new_cart_add = """      List<Map<String, dynamic>> itemsList = widget.cart.values.map((item) {
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
        'items': itemsList,"""

if old_cart_add in text and "'items': itemsList" not in text:
    text = text.replace(old_cart_add, new_cart_add)

# In Admin Orders tab, replace order item card properly
admin_order_tile = """            final data = doc.data() as Map<String, dynamic>;
            final items = (data['items'] as List?) ?? [];
            final itemsText = items.map((i) => "${i['name']} x${i['qty']}").join(", ");

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${data['orderId'] ?? ''} • ${data['customerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${data['status'] ?? 'Pending'} | ₹${data['total'] ?? 0}'),
                    if ((data['phone'] ?? '').toString().isNotEmpty)
                      Text('Phone: ${data['phone']}', style: const TextStyle(fontSize: 12)),
                    if ((data['address'] ?? '').toString().isNotEmpty)
                      Text('Note: ${data['address']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Items: ${itemsText.isEmpty ? "Nahi mila" : itemsText}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                  ],
                ),
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

old_admin_tile_pattern = r"final data = doc\.data\(\) as Map<String, dynamic>;[\s\S]*?return Card\([\s\S]*?itemBuilder: \(ctx\) => \[\s*'Pending'[\s\S]*?\),\s*\);\s*\);"
text = re.sub(old_admin_tile_pattern, admin_order_tile + "\n          );", text)

# Ensure Bottom Navigation has only 3 tabs (Menu, Cart, Table Book)
nav_bar_code = """      bottomNavigationBar: BottomNavigationBar(
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

text = re.sub(r"bottomNavigationBar:\s*BottomNavigationBar\([\s\S]*?items:\s*const\s*\[[\s\S]*?\],\s*\),", nav_bar_code, text)

# Ensure screens array matches 3 tabs
screens_code = """    final screens = [
      MenuScreen(onAddToCart: addToCart),
      CartScreen(cart: cart, onClear: clearCart),
      const TableBookingScreen(),
    ];"""

text = re.sub(r"final screens = \[[\s\S]*?\];", screens_code, text)

with open("lib/main.dart", "w") as f:
    f.write(text)

print("FIX_APPLIED_SUCCESSFULLY")
