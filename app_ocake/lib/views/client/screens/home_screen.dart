import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:carousel_slider/carousel_slider.dart' as carousel_pkg; // Bỏ nếu không dùng Carousel Slider

// --- ĐẢM BẢO CÁC IMPORT NÀY CHÍNH XÁC VỚI CẤU TRÚC DỰ ÁN CỦA BẠN ---
import 'package:app_ocake/models/product.dart';
import 'package:app_ocake/models/category.dart';
import 'package:app_ocake/models/branch.dart';
import 'package:app_ocake/models/promotion.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';
import '../widgets/product_cart.dart'; // Widget cho cuộn ngang (Sản phẩm bán chạy)
import 'product_list_screen.dart';
import 'package:intl/intl.dart'; // Để format tiền tệ
// -------------------------------------------------------------------

// HomeScreen: Chỉ quản lý các tab và BottomNavigationBar
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
       // Sử dụng IndexedStack trực tiếp trong body để tránh Column không cần thiết
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFBC132C),
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
// HomeContent: Chứa toàn bộ nội dung và AppBar của tab Trang chủ
// ===================================================================================

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Branch? _selectedBranchObject;
  List<Branch> _branchesFromDb = [];
  bool _isLoadingBranches = true;
  int _currentCategoryFilterIndex = 0; // NEW: Biến trạng thái cho filter danh mục (0 = Tất cả)
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);


  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
     if (!mounted) return;
    setState(() => _isLoadingBranches = true);
    try {
      QuerySnapshot branchSnapshot = await FirebaseFirestore.instance
          .collection('branches')
          .orderBy('name')
          .get();

      List<Branch> loadedBranches =
          branchSnapshot.docs.map((doc) => Branch.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _branchesFromDb = loadedBranches;
           // Set default branch only if list is not empty and no branch is selected yet
          if (_branchesFromDb.isNotEmpty && _selectedBranchObject == null) {
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
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
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

  Widget _buildLoadingIndicator() => const Center(
    child: Padding(
      padding: EdgeInsets.all(32.0),
      child: CircularProgressIndicator(color: Color(0xFFBC132C)),
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
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(message, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center,),
    ),
  );

  // Giữ nguyên hàm này, mặc dù ProductListItem không dùng discountPrice nữa
  // ProductCart vẫn có thể dùng nếu bạn muốn hiển thị giảm giá ở đó
  Future<List<Product>> _fetchProductsWithPromotions(
    QuerySnapshot productSnapshot,
  ) async {
    List<Product> productsWithDetails = [];
     // FIX: Trả về list rỗng ngay nếu snapshot trống
    if (productSnapshot.docs.isEmpty) return productsWithDetails; 

    // Tối ưu: Lấy tất cả promotionIds cần thiết trước
    Set<String> allPromoIds = {};
     for (var doc in productSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        String? promoId = data?['promotionIds']?.toString().trim().replaceAll(RegExp(r'[\[\]"\s]'), '');
         if (promoId != null && promoId.isNotEmpty) {
           allPromoIds.add(promoId);
         }
     }

    Map<String, Promotion> promotionCache = {};
    if (allPromoIds.isNotEmpty) {
        try {
           // Chỉ query những promotions thực sự cần
           final promoQuery = await FirebaseFirestore.instance
                .collection('promotions')
                .where(FieldPath.documentId, whereIn: allPromoIds.toList())
                .get();
            for(var promoDoc in promoQuery.docs){
               promotionCache[promoDoc.id] = Promotion.fromFirestore(promoDoc);
            }
        } catch (e) {
             print("Error fetching promotions batch: $e");
        }
    }


    for (var doc in productSnapshot.docs) {
      Product product = Product.fromFirestore(doc);
       Promotion? promotion;
       if (product.promotionIds != null && product.promotionIds!.isNotEmpty) {
          String promoId = product.promotionIds!.trim().replaceAll( RegExp(r'[\[\]"\s]'),'',);
           if(promoId.isNotEmpty){
              promotion = promotionCache[promoId]; // Lấy từ cache
               if(promotion == null && allPromoIds.contains(promoId)){
                   print("Warning: Promotion ID '$promoId' for product '${product.name}' not found in cache/db.");
               }
           }
       }
        // Vẫn tính toán giá khuyến mãi, dù ProductListItem không hiển thị
        // ProductCart (cho Sản phẩm bán chạy) vẫn có thể dùng.
        product.calculateAndSetDiscountPrice(promotion); 
        productsWithDetails.add(product);
    }
    return productsWithDetails;
  }

 @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final categoriesRef = FirebaseFirestore.instance.collection('categories');

    final String bannerImage = 'assets/images/banner_tiec-nhe.jpg';

    return Scaffold(
       // Sử dụng SafeArea để tránh bị che bởi status bar/notch
      body: SafeArea( 
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
             // flexibleSpace: FlexibleSpaceBar(), // Có thể thêm để có hiệu ứng co giãn
              backgroundColor: const Color(0xFFBC132C),
              elevation: 4.0, // Thêm shadow nhẹ
              floating: true, // Cho phép AppBar nổi lên khi cuộn lên
              pinned: true, // Ghim AppBar khi cuộn xuống
              snap: false, // Kết hợp với floating
              expandedHeight: kToolbarHeight + 70, // Tăng chiều cao một chút
              // Xóa title, thay bằng bottom
              bottom: PreferredSize(
                 preferredSize: const Size.fromHeight(kToolbarHeight + 60), // Điều chỉnh chiều cao
                  child: Container(
                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      color: const Color(0xFFBC132C),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                         children: [
                            // Dropdown chọn chi nhánh
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
                               children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _isLoadingBranches
                                      ? const SizedBox( width: 20, height: 20, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2))
                                      : (_branchesFromDb.isEmpty
                                          ? const Text('Không có chi nhánh', style: TextStyle( color: Colors.white, fontSize: 16))
                                          : DropdownButtonHideUnderline(
                                              child: DropdownButton<Branch>(
                                                 // Key để rebuild khi _selectedBranchObject thay đổi
                                                key: ValueKey(_selectedBranchObject?.id), 
                                                value: _selectedBranchObject,
                                                isExpanded: true,
                                                dropdownColor: const Color(0xFFBC132C).withOpacity(0.95),
                                                icon: const Icon( Icons.keyboard_arrow_down, color: Colors.white),
                                                 style: const TextStyle( // Style chung cho cả selected và items
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                 ),
                                                 // Tối ưu selectedItemBuilder: chỉ hiển thị Text đơn giản
                                                 selectedItemBuilder: (BuildContext context) {
                                                   return _branchesFromDb.map<Widget>((Branch branch) {
                                                      return Align( // Dùng Align
                                                         alignment: Alignment.centerLeft,
                                                          child: Text(
                                                            branch.name,
                                                            overflow: TextOverflow.ellipsis,
                                                             maxLines: 1,
                                                          ),
                                                      );
                                                   }).toList();
                                                 },
                                                onChanged: (Branch? newValue) {
                                                  if (newValue != null && mounted) {
                                                    setState(() {
                                                      _selectedBranchObject = newValue;
                                                    });
                                                    print('Đã chọn chi nhánh: ${newValue.name}');
                                                  }
                                                },
                                                items: _branchesFromDb.map<DropdownMenuItem<Branch>>((branch) {
                                                  return DropdownMenuItem<Branch>(
                                                    value: branch,
                                                     // Layout phức tạp hơn cho từng item trong dropdown list
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min, // Quan trọng
                                                          children: [
                                                            Text( branch.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                             if (branch.address.isNotEmpty)
                                                               Text(
                                                                 branch.address,
                                                                  style: TextStyle( color: Colors.white.withOpacity(0.8), fontSize: 12),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                               ),
                                                          ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )),
                                ),
                              ],
                            ),
                             const SizedBox(height: 12), // Tăng khoảng cách
                            // Thanh tìm kiếm
                            Container(
                              height: 42, // Giảm chiều cao một chút
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25), // Bo tròn hơn
                                 boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              ),
                              child: TextField(
                                 textInputAction: TextInputAction.search, // Icon search trên bàn phím
                                decoration: InputDecoration(
                                  hintText: 'Bạn đang thèm món bánh gì?',
                                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15), // Chữ nhỏ hơn
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 22), // Icon đậm hơn
                                  border: InputBorder.none,
                                   // Căn chỉnh padding để text và icon nằm giữa
                                  contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0), 
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) { // Dùng trim()
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductListScreen(
                                          searchQuery: value.trim(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                         ],
                      )
                  )
              ),
            ),

          // --- BANNER ---
            SliverToBoxAdapter(
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     _buildSectionTitle('Hot'),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(15.0),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.15), // Giảm opacity
                               blurRadius: 8,
                               offset: const Offset(0, 4),
                             ),
                           ],
                         ),
                         child: AspectRatio(
                           aspectRatio: 2048 / 748, // Tỷ lệ ảnh banner gốc
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(15.0),
                             child: Image.asset(
                               bannerImage,
                               fit: BoxFit.cover,
                               errorBuilder: (context, error, stackTrace) {
                                 print("Error loading banner image: $error");
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
                 ],
              )
            ),

           // --- DANH MỤC ---
            SliverToBoxAdapter(
               child: StreamBuilder<QuerySnapshot>(
                  stream: categoriesRef.orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       // Hiển thị placeholder thay vì loading indicator lớn
                       return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              _buildSectionTitle('Danh mục sản phẩm'),
                               Container(
                                 height: 120,
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ListView.separated(
                                     scrollDirection: Axis.horizontal,
                                      itemCount: 5,
                                      separatorBuilder: (_,__) => const SizedBox(width: 12),
                                      itemBuilder: (_,__) => Container( width: 90, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)))
                                  ),
                               )
                           ]
                       );
                    }
                    if (snapshot.hasError)  return _buildErrorWidget('Danh mục', snapshot.error.toString());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyWidget('Không có danh mục nào');
                    
                    final List<Category> categoriesFromDb = snapshot.data!.docs
                        .map((doc) => Category.fromFirestore(doc))
                        .toList();

                    final List<Map<String, dynamic>> filterItems = [
                      {'id': 'all', 'name': 'Tất cả', 'imageAssetPath': ''}, // Mục "Tất cả"
                      ...categoriesFromDb.map((cat) => cat.toJsonWithId()),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Danh mục sản phẩm'),
                        Container(
                          height: 120, // Giữ chiều cao cố định
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filterItems.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final itemData = filterItems[index];
                              final bool isSelected = _currentCategoryFilterIndex == index;
                               final String? imagePath = itemData['imageAssetPath'];

                                // Tạo biến cho image widget để dùng errorBuilder
                                Widget categoryImage;
                                 if (imagePath != null && imagePath.isNotEmpty) {
                                   if (imagePath.startsWith('http')) {
                                      categoryImage = Image.network(
                                        imagePath, fit: BoxFit.cover,
                                         errorBuilder: (_,__,___) => Icon(Icons.cake_outlined, color: isSelected ? Colors.white : const Color(0xFFBC132C), size: 28),
                                       );
                                   } else {
                                      categoryImage = Image.asset(
                                        imagePath, fit: BoxFit.cover,
                                         errorBuilder: (_,__,___) => Icon(Icons.cake_outlined, color: isSelected ? Colors.white : const Color(0xFFBC132C), size: 28),
                                       );
                                   }
                                 } else {
                                     categoryImage = Icon(
                                         itemData['id'] == 'all' ? Icons.apps : Icons.cake_outlined,
                                         color: isSelected ? Colors.white : const Color(0xFFBC132C),
                                         size: 28,
                                     );
                                 }


                              return GestureDetector(
                                onTap: () {
                                  if(mounted) setState(() => _currentCategoryFilterIndex = index);
                                  Navigator.push( context, MaterialPageRoute(
                                      builder: (context) => ProductListScreen(
                                          categoryId: itemData['id'] == 'all' ? null : itemData['id'],
                                          categoryName: itemData['id'] == 'all' ? 'Tất cả sản phẩm' : itemData['name'],
                                      ),
                                  ));
                                },
                                child: Container(
                                  width: 90,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(vertical: 8), // Thêm padding
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFBC132C) : Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1),
                                    boxShadow: [ BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.2 : 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                     mainAxisSize: MainAxisSize.min, // Để Column co lại
                                    children: [
                                      Container(
                                        height: 50, width: 50,
                                         padding: const EdgeInsets.all(4), // Padding bên trong circle
                                        decoration: BoxDecoration(
                                           color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                                           shape: BoxShape.circle,
                                        ),
                                         child: ClipOval(child: categoryImage), // Dùng ClipOval
                                      ),
                                      const SizedBox(height: 6), // Giảm khoảng cách
                                       // Dùng Expanded và Container để căn giữa text khi bị ngắt dòng
                                      Expanded(
                                         child: Container(
                                            alignment: Alignment.center,
                                             padding: const EdgeInsets.symmetric(horizontal: 4), // Padding ngang
                                             child: Text(
                                                itemData['name'],
                                                style: TextStyle(
                                                   fontSize: 12, // Giảm font
                                                   color: isSelected ? Colors.white : Colors.black87,
                                                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                         ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
             ),


            // --- SẢN PHẨM BÁN CHẠY (GIỮ NGUYÊN CUỘN NGANG) ---
            SliverToBoxAdapter(
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   _buildSectionTitle('Sản phẩm bán chạy'),
                    Container(
                       height: 290, // Tăng chiều cao một chút để tránh overflow nếu ProductCart cao
                       child: StreamBuilder<QuerySnapshot>(
                         stream: productsRef
                            .where('isAvailable', isEqualTo: true)
                            .where('isBestSeller', isEqualTo: true)
                            .limit(8) // Tăng limit
                            .snapshots(),
                         builder: (context, snapshot) {
                           if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingIndicator();
                           if (snapshot.hasError) return _buildErrorWidget('Sản phẩm bán chạy', snapshot.error.toString());
                           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyWidget('Chưa có sản phẩm bán chạy');

                           return FutureBuilder<List<Product>>(
                             future: _fetchProductsWithPromotions(snapshot.data!),
                             builder: (context, processedSnapshot) {
                               if (processedSnapshot.connectionState == ConnectionState.waiting) return _buildLoadingIndicator();
                               if (processedSnapshot.hasError) return _buildErrorWidget('Sản phẩm bán chạy (promotions)', processedSnapshot.error.toString());
                               if (!processedSnapshot.hasData || processedSnapshot.data!.isEmpty) return _buildEmptyWidget('Chưa có sản phẩm bán chạy');

                               final bestSellingProducts = processedSnapshot.data!;
                               // *** GIỮ NGUYÊN ListView.builder CUỘN NGANG & ProductCart ***
                               return ListView.builder( 
                                 scrollDirection: Axis.horizontal,
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 itemCount: bestSellingProducts.length,
                                 itemBuilder: (context, index) {
                                   final product = bestSellingProducts[index];
                                   return Container(
                                     width: 170,
                                     margin: const EdgeInsets.only(right: 16),
                                     // *** VẪN DÙNG ProductCart ***
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
                  ],
               )
             ),


           // --- KHÁM PHÁ THÊM (THAY ĐỔI THÀNH DANH SÁCH DỌC) ---
            SliverToBoxAdapter(child: _buildSectionTitle('Khám phá thêm')),
            // Bọc StreamBuilder trong SliverPadding để có khoảng cách lề
             SliverPadding( 
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0), // Padding dưới cùng 30
                 sliver: StreamBuilder<QuerySnapshot>(
                   // stream: productsRef.orderBy('nameLowercase').snapshots(), // Lấy tất cả
                    stream: productsRef.orderBy('nameLowercase').limit(10).snapshots(), // Giới hạn để tăng performance
                    builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return SliverToBoxAdapter(child: _buildLoadingIndicator());
                         if (snapshot.hasError) return SliverToBoxAdapter(child: _buildErrorWidget('Khám phá thêm', snapshot.error.toString()));
                         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SliverToBoxAdapter(child: _buildEmptyWidget('Không có sản phẩm để khám phá'));

                        // THÊM: FutureBuilder để lấy giá khuyến mãi
                        return FutureBuilder<List<Product>>(
                           future: _fetchProductsWithPromotions(snapshot.data!),
                           builder: (context, processedSnapshot) {
                               if (processedSnapshot.connectionState == ConnectionState.waiting) return SliverToBoxAdapter(child: _buildLoadingIndicator());
                               if (processedSnapshot.hasError) return SliverToBoxAdapter(child: _buildErrorWidget('Khám phá thêm (promotions)', processedSnapshot.error.toString()));
                               if (!processedSnapshot.hasData || processedSnapshot.data!.isEmpty) return SliverToBoxAdapter(child:_buildEmptyWidget('Không có sản phẩm để khám phá'));
                              
                               final allProducts = processedSnapshot.data!;
                               
                               // THAY ĐỔI: Dùng SliverList thay cho GridView.builder trong SliverToBoxAdapter
                               return SliverList(
                                 delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                       final product = allProducts[index];
                                       // THAY ĐỔI: Dùng ProductListItem mới
                                       return ProductListItem( 
                                          product: product,
                                          onTap: () => _navigateToDetail(context, product),
                                          currencyFormat: currencyFormat,
                                       );
                                    },
                                    childCount: allProducts.length,
                                 ),
                               );
                           }
                        );
                    },
                 ),
             ),
            // SliverToBoxAdapter(child: const SizedBox(height: 30)), // Không cần nữa vì đã có padding bottom
          ],
        ),
      ),
    );
  }
}


//=====================================================================
// NEW WIDGET: Dùng cho danh sách dọc "Khám phá thêm"
//=====================================================================
class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final NumberFormat currencyFormat;


  const ProductListItem({
    Key? key,
    required this.product,
    required this.onTap,
     required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
     String imageUrl = product.imageAssetPath.isNotEmpty ? product.imageAssetPath : '';
     // Loại bỏ logic hasDiscount, originalPrice
     final String displayPrice = currencyFormat.format(product.price);
     // final String? originalPrice = hasDiscount ? currencyFormat.format(product.price) : null; // Dòng này không cần nữa

    // Widget hiển thị lỗi/placeholder cho ảnh
     Widget imagePlaceholder = Container(
        width: 90,
        height: 90,
        color: Colors.grey[200],
        child: Icon(Icons.cake_outlined, color: Colors.grey[500], size: 40), // Icon bánh
     );

    return Card(
       margin: const EdgeInsets.symmetric(vertical: 8.0), // Khoảng cách trên dưới giữa các item
       elevation: 2,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       clipBehavior: Clip.antiAlias, // Cắt nội dung theo border radius
       child: InkWell(
         onTap: onTap,
         child: Padding(
           padding: const EdgeInsets.all(10.0),
           child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn đỉnh
              children: [
                 // --- ẢNH ---
                 ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: imageUrl.isNotEmpty && (imageUrl.startsWith('http') || imageUrl.startsWith('https'))
                       ? Image.network(
                           imageUrl,
                           width: 90, height: 90, fit: BoxFit.cover,
                           errorBuilder: (c, e, s) => imagePlaceholder,
                          )
                       : (imageUrl.isNotEmpty // Giả sử đường dẫn khác là asset
                           ? Image.asset(
                               imageUrl,
                                width: 90, height: 90, fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => imagePlaceholder,
                              )
                           : imagePlaceholder // Nếu không có URL/asset nào
                       )
                 ),
                 const SizedBox(width: 12),

                 // --- THÔNG TIN ---
                 Expanded( // Cho phép cột thông tin chiếm hết không gian còn lại
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.start, // Căn nội dung lên đầu
                       children: [
                          Text(
                             product.name,
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                          ),
                           SizedBox(height: product.description.isNotEmpty ? 4: 8),
                           if(product.description.isNotEmpty)
                             Text(
                               product.description,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                             ),
                           const SizedBox(height: 8),
                          // Giá
                           Text(
                              displayPrice,
                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFBC132C)),
                           ),
                           const SizedBox(height: 8), // Khoảng cách giữa giá và các chip

                           // --- Các thông tin "chip" mới ---
                           Row(
                             children: [
                               _buildInfoChip(
                                 text: 'Nhận ngay',
                                 backgroundColor: Colors.orange.shade50,
                                 textColor: Colors.orange.shade800,
                                 icon: Icons.access_time_outlined, // Icon đồng hồ
                               ),
                               const SizedBox(width: 8), // Khoảng cách giữa các chip
                               _buildInfoChip(
                                 text: 'Freeship',
                                 backgroundColor: Colors.lightGreen.shade50,
                                 textColor: Colors.lightGreen.shade800,
                                 icon: Icons.delivery_dining, // Icon xe giao hàng
                               ),
                             ],
                           ),
                       ],
                    ),
                 ),
                  const SizedBox(width: 8),
                 // --- NÚT/ICON (Giữ nguyên mũi tên) ---
                  const Align(
                     alignment: Alignment.centerRight,
                     child:  Icon(Icons.chevron_right, color: Colors.grey),
                  )
              ],
           ),
         )
       ),
    );
  }

  // Hàm tiện ích để xây dựng một chip thông tin
  Widget _buildInfoChip({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}