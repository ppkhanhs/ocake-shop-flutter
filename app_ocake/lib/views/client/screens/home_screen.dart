import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//   //   }
import 'package:app_ocake/models/product.dart';
import 'package:app_ocake/models/category.dart';
import 'package:app_ocake/models/branch.dart';
import 'package:app_ocake/models/promotion.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';
import '../widgets/product_cart.dart';
// -------------------------------------------------------------

// ... (các import và các class khác giữ nguyên) ...

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Loại bỏ các biến trạng thái liên quan đến chi nhánh, chúng sẽ di chuyển vào HomeContent
  // Branch? _selectedBranchObject;
  // List<Branch> _branchesFromDb = [];
  // bool _isLoadingBranches = true;

  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeContent(), // HomeContent sẽ tự quản lý AppBar và tìm kiếm của nó
    CartScreen(), // CartScreen đã có AppBar riêng
    OrderHistoryScreen(), // Đảm bảo OrderHistoryScreen cũng có AppBar riêng
    ProfileScreen(), // ProfileScreen đã có AppBar riêng
  ];

  @override
  void initState() {
    super.initState();
    // Loại bỏ hàm _loadBranches() khỏi đây
    // _loadBranches();
  }

  // Loại bỏ hàm _loadBranches() khỏi đây
  // Future<void> _loadBranches() async { ... }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === BƯỚC 1A: XÓA TOÀN BỘ APPBAR KHỎI ĐÂY ===
      // appBar: AppBar( ... ),

      body: IndexedStack( // === BƯỚC 1B: BODY GIỜ CHỈ CÓ IndexedStack ===
        index: _currentIndex,
        children: _screens,
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
class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // BƯỚC 2B: CHUYỂN CÁC BIẾN STATE VÀ HÀM TẢI CHI NHÁNH TỪ _HomeScreenState SANG ĐÂY
  Branch? _selectedBranchObject;
  List<Branch> _branchesFromDb = [];
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _loadBranches(); // Tải chi nhánh khi HomeContent được khởi tạo
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

    // BƯỚC 2C: HomeContent TRẢ VỀ Scaffold RIÊNG
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
            Container( // BƯỚC 2D: CHUYỂN CONTAINER TÌM KIẾM VÀO ĐÂY (VÀO BODY CỦA HomeContent)
              color: Color(0xFFBC132C), // Đảm bảo màu sắc khớp với AppBar
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
                    print('Tìm kiếm: $value');
                  },
                ),
              ),
            ),
            _buildSectionTitle('Deal hot mỗi ngày'),
            Container(
              height: 270,
              child: StreamBuilder<QuerySnapshot>(
                  stream:
                      productsRef
                          .where('isAvailable', isEqualTo: true)
                          .where(
                            'promotionIds',
                            isNotEqualTo: null,
                          )
                          .where(
                            'promotionIds',
                            isNotEqualTo: "",
                          )
                          .limit(
                            10,
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return _buildLoadingIndicator();
                    if (snapshot.hasError)
                      return _buildErrorWidget(
                        'Deal Hot',
                        snapshot.error.toString(),
                      );
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return _buildEmptyWidget('Chưa có deal hot nào');

                    return FutureBuilder<List<Product>>(
                      future: _fetchProductsWithPromotions(snapshot.data!),
                      builder: (context, processedSnapshot) {
                        if (processedSnapshot.connectionState ==
                            ConnectionState.waiting)
                          return _buildLoadingIndicator();
                        if (processedSnapshot.hasError)
                          return _buildErrorWidget(
                            'Deal Hot (promotions)',
                            processedSnapshot.error.toString(),
                          );

                        final hotDealProducts =
                            processedSnapshot.data
                                ?.where(
                                  (p) =>
                                      p.calculatedDiscountPrice != null &&
                                      p.calculatedDiscountPrice! < p.price,
                                )
                                .take(6)
                                .toList() ??
                            [];

                        if (hotDealProducts.isEmpty)
                          return _buildEmptyWidget(
                            'Chưa có deal hot nào hấp dẫn',
                          );

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemCount: hotDealProducts.length,
                          itemBuilder: (context, index) {
                            final product = hotDealProducts[index];
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
            SizedBox(height: 20),

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
                            print(
                              'Đã chọn danh mục: ${category.name} (ID: ${category.id})',
                            );
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
            SizedBox(height: 20),

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
            SizedBox(height: 20),

            _buildSectionTitle('Khám phá thêm'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: productsRef.orderBy('name').snapshots(),
                builder: (context, processedSnapshot) {
                  if (processedSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return GridView.builder(
                      // Đảm bảo physics: NeverScrollableScrollPhysics() đã được xóa như lần sửa trước
                      shrinkWrap: true,
                      itemCount: 6, // Số lượng placeholder
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Số cột
                        mainAxisSpacing: 12, // Khoảng cách dọc
                        crossAxisSpacing: 12, // Khoảng cách ngang
                        childAspectRatio: 0.70, // Tỉ lệ của item
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
                    // Đảm bảo physics: NeverScrollableScrollPhysics() đã được xóa như lần sửa trước
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
            SizedBox(height: 30),
        ],
      ),
    ),
    );
  }
}