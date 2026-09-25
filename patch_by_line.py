with open("lib/main.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# 1. Cart submit me items array add karna
for idx, line in enumerate(lines):
    if "'total': total," in line and "'items':" not in line:
        lines[idx] = line.replace("'total': total,", "'total': total, 'items': cart.values.map((e) => {'name': e['name'], 'qty': e['qty'], 'price': e['price']}).toList(),")
        print("CART_ITEMS_ADDED at line", idx + 1)
        break

# 2. TabBarView ke andar orders stream ko replace karna
start_idx = None
end_idx = None

for i, l in enumerate(lines):
    if "body: TabBarView(" in l:
        # Iske theek baad orders StreamBuilder dhoondho
        for j in range(i, i + 30):
            if "collection('orders')" in lines[j]:
                # find start of StreamBuilder
                for k in range(j, i, -1):
                    if "StreamBuilder<QuerySnapshot>" in lines[k]:
                        start_idx = k
                        break
                break
        if start_idx:
            break

if start_idx:
    for j in range(start_idx, len(lines)):
        if "collection('menu')" in lines[j]:
            for k in range(j, start_idx, -1):
                if "StreamBuilder<QuerySnapshot>" in lines[k]:
                    end_idx = k
                    break
            break

print("FOUND INDICES:", start_idx, end_idx)

if start_idx and end_idx:
    replacement = [
        "            StreamBuilder<QuerySnapshot>(\n",
        "              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),\n",
        "              builder: (context, snapshot) {\n",
        "                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());\n",
        "                final allOrders = snapshot.data!.docs;\n",
        "                if (allOrders.isEmpty) return const Center(child: Text('Abhi koi order nahi hai.'));\n",
        "\n",
        "                final now = DateTime.now();\n",
        "                final startOfToday = DateTime(now.year, now.month, now.day);\n",
        "                int todaySales = 0;\n",
        "                int todayOrdersCount = 0;\n",
        "                for (var d in allOrders) {\n",
        "                  final data = d.data() as Map<String, dynamic>;\n",
        "                  final ts = data['createdAt'] as Timestamp?;\n",
        "                  if (ts != null && ts.toDate().isAfter(startOfToday)) {\n",
        "                    todayOrdersCount++;\n",
        "                    todaySales += ((data['total'] ?? 0) as num).toInt();\n",
        "                  }\n",
        "                }\n",
        "\n",
        "                return Column(\n",
        "                  children: [\n",
        "                    Container(\n",
        "                      margin: const EdgeInsets.all(10),\n",
        "                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),\n",
        "                      decoration: BoxDecoration(\n",
        "                        color: const Color(0xFFFFEBEE),\n",
        "                        borderRadius: BorderRadius.circular(12),\n",
        "                        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3)),\n",
        "                      ),\n",
        "                      child: Row(\n",
        "                        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n",
        "                        children: [\n",
        "                          Column(\n",
        "                            crossAxisAlignment: CrossAxisAlignment.start,\n",
        "                            children: [\n",
        "                              const Text('Aaj Ka Hissab (Today)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD32F2F))),\n",
        "                              const SizedBox(height: 2),\n",
        "                              Text('$todayOrdersCount Orders • ₹$todaySales Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),\n",
        "                            ],\n",
        "                          ),\n",
        "                          ElevatedButton.icon(\n",
        "                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, elevation: 0),\n",
        "                            icon: const Icon(Icons.delete_sweep, size: 18),\n",
        "                            label: const Text('Delete Old', style: TextStyle(fontSize: 12)),\n",
        "                            onPressed: () async {\n",
        "                              final batch = FirebaseFirestore.instance.batch();\n",
        "                              int count = 0;\n",
        "                              for (var d in allOrders) {\n",
        "                                final data = d.data() as Map<String, dynamic>;\n",
        "                                if (data['status'] == 'Delivered' || data['status'] == 'Cancelled') {\n",
        "                                  batch.delete(d.reference);\n",
        "                                  count++;\n",
        "                                }\n",
        "                              }\n",
        "                              if (count > 0) {\n",
        "                                await batch.commit();\n",
        "                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count delivered/cancelled orders delete ho gaye.')));\n",
        "                              } else {\n",
        "                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koi purana delivered order nahi mila.')));\n",
        "                              }\n",
        "                            },\n",
        "                          ),\n",
        "                        ],\n",
        "                      ),\n",
        "                    ),\n",
        "                    Expanded(\n",
        "                      child: ListView.separated(\n",
        "                        padding: const EdgeInsets.all(12),\n",
        "                        itemCount: allOrders.length,\n",
        "                        separatorBuilder: (_, __) => const SizedBox(height: 8),\n",
        "                        itemBuilder: (context, index) {\n",
        "                          final doc = allOrders[index];\n",
        "                          final data = doc.data() as Map<String, dynamic>;\n",
        "                          final items = (data['items'] as List?) ?? [];\n",
        "                          final itemsText = items.map((i) => \"${i['name']} x${i['qty']}\").join(', ');\n",
        "\n",
        "                          return Card(\n",
        "                            elevation: 2,\n",
        "                            child: Padding(\n",
        "                              padding: const EdgeInsets.all(12),\n",
        "                              child: Column(\n",
        "                                crossAxisAlignment: CrossAxisAlignment.start,\n",
        "                                children: [\n",
        "                                  Row(\n",
        "                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n",
        "                                    children: [\n",
        "                                      Text('${data['orderId'] ?? ''} • ${data['customerName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),\n",
        "                                      PopupMenuButton<String>(\n",
        "                                        icon: const Icon(Icons.more_vert),\n",
        "                                        onSelected: (val) => updateOrderStatus(doc.id, val),\n",
        "                                        itemBuilder: (_) => [\n",
        "                                          'Pending',\n",
        "                                          'Preparing',\n",
        "                                          'Ready / Out',\n",
        "                                          'Delivered',\n",
        "                                          'Cancelled',\n",
        "                                        ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),\n",
        "                                      ),\n",
        "                                    ],\n",
        "                                  ),\n",
        "                                  Text('Phone: ${data['phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87, fontSize: 13)),\n",
        "                                  if ((data['address'] ?? '').toString().isNotEmpty)\n",
        "                                    Text('Note/Table: ${data['address']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),\n",
        "                                  const Divider(),\n",
        "                                  const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),\n",
        "                                  const SizedBox(height: 2),\n",
        "                                  Text(itemsText.isEmpty ? 'Purana order (Item list nahi thi)' : itemsText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),\n",
        "                                  const Divider(),\n",
        "                                  Row(\n",
        "                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,\n",
        "                                    children: [\n",
        "                                      Text('Status: ${data['status'] ?? 'Pending'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),\n",
        "                                      Text('Total: ₹${data['total'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),\n",
        "                                    ],\n",
        "                                  ),\n",
        "                                ],\n",
        "                              ),\n",
        "                            ),\n",
        "                          );\n",
        "                        },\n",
        "                      ),\n",
        "                    ),\n",
        "                  ],\n",
        "                );\n",
        "              },\n",
        "            ),\n",
    ]
    new_lines = lines[:start_idx] + replacement + lines[end_idx:]
    with open("lib/main.dart", "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print("PATCH_APPLIED_SUCCESSFULLY")

