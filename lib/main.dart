import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init: $e");
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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const MenuHomeScreen(),
    );
  }
}

class MenuHomeScreen extends StatefulWidget {
  const MenuHomeScreen({super.key});

  @override
  State<MenuHomeScreen> createState() => _MenuHomeScreenState();
}

class _MenuHomeScreenState extends State<MenuHomeScreen> {
  String selectedCategory = 'All';
  final Map<String, int> cart = {};

  final List<String> categories = [
    'All',
    'Sabzi',
    'Chawal',
    'Roti / Paratha',
    'Papad',
    'Chai',
    'Pey Padarth'
  ];

  // 100% Shuddh Shakahari verified images mapping
  String getPureVegImage(String name, String category, String? customUrl) {
    if (customUrl != null && customUrl.trim().isNotEmpty) return customUrl;
    
    final n = name.toLowerCase();
    final c = category.toLowerCase();

    if (n.contains('kaju paneer') || n.contains('shahi paneer') || n.contains('paneer')) {
      return 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&q=80'; // Pure Indian Paneer Curry
    } else if (n.contains('dal')) {
      return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&q=80'; // Dal Tadka
    } else if (n.contains('thali')) {
      return 'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?w=400&q=80'; // Pure Veg Indian Thali
    } else if (n.contains('pulao') || n.contains('jeera') || n.contains('biryani') || c.contains('chawal')) {
      return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80'; // Veg Jeera Pulao / Biryani
    } else if (c.contains('roti') || n.contains('paratha')) {
      return 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=400&q=80'; // Tawa Roti / Paratha
    } else if (n.contains('lassi') || n.contains('chhachh') || n.contains('chhaachh')) {
      return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400&q=80'; // Desi Chaach / Lassi in Kulhad
    } else if (n.contains('chai') || c.contains('chai')) {
      return 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&q=80'; // Indian Masala Chai
    } else if (n.contains('paani') || n.contains('botal') || n.contains('bisleri')) {
      return 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=400&q=80'; // Pure Mineral Water
    } else if (c.contains('papad') || n.contains('papad')) {
      return 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&q=80'; // Roasted Papad
    }
    
    // Default fallback: Veg Indian Curry
    return 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = cart.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Jai Shree Shyam Restaurant',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '100% Shuddh Shakahari Bhojanalaya',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Category chips bar
          Container(
            color: Colors.white,
            height: 54,
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    selectedColor: const Color(0xFFD32F2F),
                    backgroundColor: const Color(0xFFF1F3F5),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (val) {
                      setState(() => selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          // Items List from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menu').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedCategory == 'All') return true;
                  return (data['category'] ?? '').toString().trim().toLowerCase() == selectedCategory.trim().toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Is category me koi item nahi mila', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Item';
                    final price = data['price'] ?? 0;
                    final category = data['category'] ?? '';
                    final customUrl = data['imageUrl'] as String?;
                    final imageUrl = getPureVegImage(name, category, customUrl);
                    final count = cart[name] ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Pure Veg Green Box Icon
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFF0F8A65), width: 1.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.circle, color: Color(0xFF0F8A65), size: 8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹$price',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, e, s) => Container(
                                    width: 100,
                                    height: 90,
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.restaurant, color: Colors.green),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -15),
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFD32F2F), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: count == 0
                                      ? TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 18),
                                          ),
                                          onPressed: () {
                                            setState(() => cart[name] = 1);
                                          },
                                          child: const Text(
                                            'ADD',
                                            style: TextStyle(
                                              color: Color(0xFFD32F2F),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              icon: const Icon(Icons.remove, color: Color(0xFFD32F2F)),
                                              onPressed: () {
                                                setState(() {
                                                  if (count > 1) {
                                                    cart[name] = count - 1;
                                                  } else {
                                                    cart.remove(name);
                                                  }
                                                });
                                              },
                                            ),
                                            Text(
                                              '$count',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              icon: const Icon(Icons.add, color: Color(0xFFD32F2F)),
                                              onPressed: () {
                                                setState(() => cart[name] = count + 1);
                                              },
                                            ),
                                          ],
                                        ),
                                ),
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
      bottomNavigationBar: totalItems > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: Text(
                  'View Cart ($totalItems items)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          : null,
    );
  }
}
