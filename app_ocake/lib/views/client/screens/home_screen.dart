// File: home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- SỬA LẠI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI DỰ ÁN CỦA BẠN ---
import 'package:app_ocake/models/product.dart';
import 'package:app_ocake/models/category.dart'; // Đảm bảo Category model được import
import 'package:app_ocake/models/branch.dart';
import 'package:app_ocake/models/promotion.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';
import '../widgets/product_cart.dart';
// === THÊM IMPORT MỚI: ===
import 'product_list_screen.dart'; // Import màn hình danh sách sản phẩm
// -------------------------------------------------------------

// ... (class HomeScreen, _HomeScreenState giữ nguyên như bạn đã cập nhật gần đây) ...
// Đảm bảo _HomeScreenState không còn chứa AppBar hay thanh tìm kiếm.

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _selectHomeTab() {
    setState(() {
      _currentIndex = 0;
    });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(),
      CartScreen(onNavigateToHomeTab: _selectHomeTab),
      OrderHistoryScreen(onNavigateToHomeTab: _selectHomeTab),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFBC132C),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        elevation: 8.0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}


// ===================================================================================
// Widget HomeContent: Chứa nội dung chính của tab Trang chủ
// ===================================================================================

// Giữ nguyên _HomeContentState là StatefulWidget
class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Branch? _selectedBranchObject;
  List<Branch> _branchesFromDb = [];
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      QuerySnapshot branchSnapshot =
          await FirebaseFirestore.instance
              .collection('branches')
              .orderBy('name')
              .get();

      List<Branch> loadedBranches =
          branchSnapshot.docs.map((doc) => Branch.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _branchesFromDb = loadedBranches;
          if (_branchesFromDb.isNotEmpty) {
            _selectedBranchObject = _branchesFromDb.first;
          }
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách chi nhánh trong HomeContent: $e");
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  Widget _buildLoadingIndicator() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: CircularProgressIndicator(),
    ),
  );
  Widget _buildErrorWidget(String sectionName, String errorDetails) {
    print("Firestore Error (Section: $sectionName): $errorDetails");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Lỗi tải $sectionName. Vui lòng thử lại.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(message, style: TextStyle(color: Colors.grey[600])),
    ),
  );

  Future<List<Product>> _fetchProductsWithPromotions(
    QuerySnapshot productSnapshot,
  ) async {
    List<Product> productsWithDetails = [];
    if (productSnapshot.docs.isEmpty) return productsWithDetails;

    for (var doc in productSnapshot.docs) {
      Product product = Product.fromFirestore(doc);
      if (product.promotionIds != null && product.promotionIds!.isNotEmpty) {
        String promoId = product.promotionIds!.trim().replaceAll(
          RegExp(r'[\[\]"\s]'),
          '',
        ); // Xử lý nếu có ký tự thừa
        if (promoId.isNotEmpty) {
          try {
            DocumentSnapshot promoDoc =
                await FirebaseFirestore.instance
                    .collection('promotions')
                    .doc(promoId)
                    .get();
            if (promoDoc.exists) {
              Promotion promotion = Promotion.fromFirestore(promoDoc);
              product.calculateAndSetDiscountPrice(promotion);
            } else {
              product.calculateAndSetDiscountPrice(null);
              print(
                "Warning: Promotion ID '$promoId' for product '${product.name}' not found.",
              );
            }
          } catch (e) {
            print(
              "Error fetching promotion '$promoId' for product '${product.name}': $e",
            );
            product.calculateAndSetDiscountPrice(null);
          }
        } else {
          product.calculateAndSetDiscountPrice(null);
        }
      } else {
        product.calculateAndSetDiscountPrice(null);
      }
      productsWithDetails.add(product);
    }
    return productsWithDetails;
  }

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final categoriesRef = FirebaseFirestore.instance.collection('categories');

    return Scaffold(
      appBar: AppBar( // APPBAR CHO RIÊNG MÀN HÌNH HOME
        backgroundColor: Color(0xFFBC132C),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child:
                  _isLoadingBranches
                      ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                      : (_branchesFromDb.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            child: Text(
                              'Không có chi nhánh',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          )
                          : DropdownButtonHideUnderline(
                            child: DropdownButton<Branch>(
                              value: _selectedBranchObject,
                              isExpanded: true,
                              dropdownColor: Color(0xFFBC132C),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                              selectedItemBuilder: (BuildContext context) {
                                return _branchesFromDb.map<Widget>((
                                  Branch branch,
                                ) {
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    height: kToolbarHeight,
                                    child: Text(
                                      _selectedBranchObject?.name ??
                                          'Chọn chi nhánh',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList();
                              },
                              onChanged: (Branch? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedBranchObject = newValue;
                                  });
                                  print('Đã chọn chi nhánh: ${newValue.name}');
                                }
                              },
                              items:
                                  _branchesFromDb.map<DropdownMenuItem<Branch>>(
                                    (branch) {
                                      return DropdownMenuItem<Branch>(
                                        value: branch,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2.0,
                                            horizontal: 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                branch.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (branch.address.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    branch.address,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.85),
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                            ),
                          )),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container( // Thanh tìm kiếm
              color: Color(0xFFBC132C),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Bạn đang thèm món bánh gì?',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                  ),
                  onSubmitted: (value) {
                    // === ĐIỀU HƯỚNG ĐẾN ProductListScreen KHI TÌM KIẾM ===
                    if (value.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(
                            searchQuery: value,
                          ),
                        ),
                      );
                    }
                    // ===============================================
                  },
                ),
              ),
            ),
            // Phần banner "Hot"
            _buildSectionTitle('Hot'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 2048 / 748,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                      'assets/images/banner_tiec-nhe.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Danh mục sản phẩm'),
            Container(
              height: 125,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: categoriesRef.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return _buildLoadingIndicator();
                  if (snapshot.hasError)
                    return _buildErrorWidget(
                      'Danh mục',
                      snapshot.error.toString(),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget('Không có danh mục nào');
                  final categoriesFromDb =
                      snapshot.data!.docs
                          .map((doc) => Category.fromFirestore(doc))
                          .toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoriesFromDb.length,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final category = categoriesFromDb[index];
                      return Container(
                        width: 90,
                        margin: EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            // === ĐIỀU HƯỚNG ĐẾN ProductListScreen KHI CHỌN DANH MỤC ===
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  categoryId: category.id,
                                  categoryName: category.name,
                                ),
                              ),
                            );
                            // ================================================
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  shape: BoxShape.circle,
                                  image:
                                      category.imageAssetPath.isNotEmpty
                                          ? DecorationImage(
                                            image: AssetImage(
                                              category.imageAssetPath,
                                            ),
                                            fit: BoxFit.cover,
                                            onError: (e, s) {},
                                          )
                                          : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child:
                                    category.imageAssetPath.isEmpty
                                        ? Icon(
                                          Icons.category_rounded,
                                          color: Color(0xFFBC132C),
                                          size: 35,
                                        )
                                        : null,
                              ),
                              SizedBox(height: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Sản phẩm bán chạy'),
            Container(
              height: 270,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    productsRef
                        .where('isAvailable', isEqualTo: true)
                        .where('isBestSeller', isEqualTo: true)
                        .limit(6)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return _buildLoadingIndicator();
                  if (snapshot.hasError)
                    return _buildErrorWidget(
                      'Sản phẩm bán chạy',
                      snapshot.error.toString(),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget('Chưa có sản phẩm bán chạy');

                  return FutureBuilder<List<Product>>(
                    future: _fetchProductsWithPromotions(snapshot.data!),
                    builder: (context, processedSnapshot) {
                      if (processedSnapshot.connectionState ==
                          ConnectionState.waiting)
                        return _buildLoadingIndicator();
                      if (processedSnapshot.hasError)
                        return _buildErrorWidget(
                          'Sản phẩm bán chạy (promotions)',
                          processedSnapshot.error.toString(),
                        );
                      if (!processedSnapshot.hasData ||
                          processedSnapshot.data!.isEmpty)
                        return _buildEmptyWidget('Chưa có sản phẩm bán chạy');

                      final bestSellingProducts = processedSnapshot.data!;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: bestSellingProducts.length,
                        itemBuilder: (context, index) {
                          final product = bestSellingProducts[index];
                          return Container(
                            width: 165,
                            margin: EdgeInsets.only(right: 12),
                            child: ProductCart(
                              product: product,
                              onTap: () => _navigateToDetail(context, product),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Khám phá thêm'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: productsRef.orderBy('name').snapshots(),
                builder: (context, processedSnapshot) {
                  if (processedSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: 6,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.70,
                      ),
                      itemBuilder:
                          (context, index) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                    );
                  }
                  if (processedSnapshot.hasError)
                    return _buildErrorWidget(
                      'Tất cả sản phẩm ',
                      processedSnapshot.error.toString(),
                    );
                  if (!processedSnapshot.hasData ||
                      processedSnapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget('Không có sản phẩm để khám phá');

                  final allProducts = processedSnapshot.data!.docs;
                  return GridView.builder(
                    shrinkWrap: true,
                    itemCount: allProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    itemBuilder: (context, index) {
                      final product = Product.fromFirestore(allProducts[index]);
                      return ProductCart(
                        product: product,
                        onTap: () => _navigateToDetail(context, product),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}