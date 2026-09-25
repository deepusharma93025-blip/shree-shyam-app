with open("lib/main.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Update Theme to Royal Maroon & Gold
old_theme = "colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),"
new_theme = """colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
          primary: const Color(0xFF8B0000),
          secondary: const Color(0xFFD4AF37),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),"""

if old_theme in code:
    code = code.replace(old_theme, new_theme)

# 2. Cart Screen me Payment Selector aur Receipt Dialog inject karna
cart_anchor = "class _CartScreenState extends State<CartScreen> {"
cart_patch = """class _CartScreenState extends State<CartScreen> {
  String _paymentMethod = 'Cash on Delivery'; // COD or Online UPI
"""
if cart_anchor in code and "String _paymentMethod =" not in code:
    code = code.replace(cart_anchor, cart_patch, 1)

# Payment method Firestore payload me jodna
old_order_dict = "'items': cart.values.map"
new_order_dict = "'paymentMethod': _paymentMethod, 'items': cart.values.map"
if old_order_dict in code and "'paymentMethod':" not in code:
    code = code.replace(old_order_dict, new_order_dict, 1)

# Order placed dialog ko receipt modal mein convert karna
old_receipt_dialog = "title: const Text('Order Placed!'),"
new_receipt_dialog = """title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Order Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(child: Text('Jai Shree Shyam Restaurant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B0000)))),
                const Divider(),
                Text('Order ID: #$orderId', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Customer: ${_nameCtrl.text.trim()}'),
                Text('Mobile: ${_phoneCtrl.text.trim()}'),
                if (_addressCtrl.text.trim().isNotEmpty) Text('Table/Note: ${_addressCtrl.text.trim()}'),
                Text('Payment: $_paymentMethod', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const Divider(),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...widget.cart.values.map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['name']} x${item['qty']}'),
                    Text('₹${(item['price'] as int) * (item['qty'] as int)}'),
                  ],
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('₹$_totalAmount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B0000))),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Dhanyawad! Kripya receipt ka screenshot le lein.', style: TextStyle(fontSize: 11, color: Colors.grey))),
              ],
            ),
          ),"""

if old_receipt_dialog in code:
    code = code.replace(old_receipt_dialog, new_receipt_dialog, 1)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(code)
print("FEATURES_PATCHED_SUCCESSFULLY")
