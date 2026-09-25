with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Swiggy Orange & Veg Green Color Theme
text = text.replace(
    "seedColor: const Color(0xFFD32F2F)",
    "seedColor: const Color(0xFFFC8019), primary: const Color(0xFFFC8019), secondary: const Color(0xFF60B244)"
)
text = text.replace("Color(0xFFD32F2F)", "Color(0xFFFC8019)")

# 2. Fix Grey Screen Dialog (widget.cart error fix)
text = text.replace("widget.cart", "cart")

# 3. Dynamic UPI Payment bottomsheet integration
if "void _showUpiSheet" not in text:
    old_target = "setState(() => _isOrdering = true);"
    new_method = """if (_paymentMethod == 'Online UPI') {
      final amount = total;
      final upiUrl = 'upi://pay?pa=9302578837-9@axl&pn=JaiShreeShyam&am=\$amount&cu=INR&tn=FoodOrder';
      final qr = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=' + Uri.encodeComponent(upiUrl);
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
              Text('Payable: ₹\$amount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF60B244))),
              const SizedBox(height: 12),
              Image.network(qr, height: 180, width: 180),
              const SizedBox(height: 8),
              const Text('UPI ID: 9302578837-9@axl', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019), foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _finishOrder(orderId, total);
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
    _finishOrder(orderId, total);
  }

  void _finishOrder(String orderId, int total) async {
    setState(() => _isOrdering = true);"""
    
    # Replace first occurrence
    text = text.replace(old_target, new_method, 1)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)

print("UPDATE_APPLIED_SUCCESSFULLY")
