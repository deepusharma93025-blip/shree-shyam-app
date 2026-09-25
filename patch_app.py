with open('lib/main.dart', 'r', encoding='utf-8') as f:
    s = f.read()

# 1. Orders tab aur screen list hatana (Privacy)
s = s.replace("BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Orders'),", "")
s = s.replace("const OrdersTrackingScreen(),", "")

# 2. Cart order me items array save karna
old_add = "'total': widget.total,"
new_add = "'total': widget.total, 'items': widget.cart.values.map((e) => {'name': e['name'], 'qty': e['qty'], 'price': e['price']}).toList(),"
if old_add in s:
    s = s.replace(old_add, new_add, 1)

# 3. Admin Panel order card me items details dikhana
old_sub = "subtitle: Text('Status: ${data['status']} | ₹${data['total']}'),"
new_sub = """subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${data["status"]} | ₹${data["total"]}'),
                    if ((data['phone'] ?? '').toString().isNotEmpty)
                      Text('Phone: ${data["phone"]}', style: const TextStyle(fontSize: 12)),
                    if ((data['address'] ?? '').toString().isNotEmpty)
                      Text('Note: ${data["address"]}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Items: ' + ((data['items'] as List?)?.map((i) => "${i['name']} x${i['qty']}").join(', ') ?? 'Nahi mila'),
                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                  ],
                ),"""
if old_sub in s:
    s = s.replace(old_sub, new_sub, 1)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(s)
print('PATCH_SUCCESSFUL')
