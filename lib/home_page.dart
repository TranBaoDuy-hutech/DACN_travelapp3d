import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:travelapp/tours3d_page.dart';
import 'dart:math' as math;
import 'account_page.dart';
import 'globals.dart' as globals;
import 'header.dart';
import 'feature_grid.dart';
import 'promo_banner.dart';
import 'tours_page.dart';
import 'news_page.dart';
import 'quick_categories_widget.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  int _hoveredIndex = -1;

  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) => _animationController.reverse());
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final isMedium = screenWidth > 600 && screenWidth <= 900;

    final List<Widget> pages = [
      const HomeContent(),
      const ToursPage(),
      const Tours3DPage(),
      const NewsPage(),
      ChatPage(customerId: globals.currentCustomer?.customerID ?? 0),
      const AccountPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // Side Navigation for Web
          if (isWeb || isMedium) _buildSideNav(isWeb),

          // Main Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
      // Bottom Navigation for Mobile
      bottomNavigationBar: (isWeb || isMedium) ? null : _buildMobileBottomNav(),
    );
  }

  Widget _buildSideNav(bool isExpanded) {
    return Container(
      width: isExpanded ? 280 : 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: oceanBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: EdgeInsets.all(isExpanded ? 24 : 16),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [deepOcean, oceanBlue, lightOcean],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/logo3.jpg",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Việt Lữ Travel",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: oceanBlue,
                          ),
                        ),
                        Text(
                          "Việt Nam & Lữ Hành",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(color: Colors.grey[200], height: 1),

          const SizedBox(height: 16),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSideNavItem(
                  icon: Icons.home_rounded,
                  label: "Trang chủ",
                  index: 0,
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  icon: Icons.explore_rounded,
                  label: "Tours",
                  index: 1,
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  icon: Icons.threed_rotation_rounded,
                  label: "Tour 3D",
                  index: 2,
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  icon: Icons.article_rounded,
                  label: "Tin tức",
                  index: 3,
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: "Chat",
                  index: 4,
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey[200], height: 1),

          // Account Section
          _buildSideNavItem(
            icon: Icons.person_rounded,
            label: "Tài khoản",
            index: 5,
            isExpanded: isExpanded,
            isBottom: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isExpanded,
    bool isBottom = false,
  }) {
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: isBottom ? 12 : 0,
          vertical: isBottom ? 8 : 0,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [oceanBlue, lightOcean],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected
                    ? null
                    : (isHovered ? Colors.grey[100] : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: oceanBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Colors.white
                        : (isHovered ? oceanBlue : Colors.grey[600]),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isHovered ? oceanBlue : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: oceanBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMobileNavItem(Icons.home_rounded, "Trang chủ", 0),
            _buildMobileNavItem(Icons.explore_rounded, "Tour", 1),
            _buildMobileNavItem(Icons.threed_rotation_rounded, "3D", 2),
            _buildMobileNavItem(Icons.article_rounded, "Tin", 3),
            _buildMobileNavItem(Icons.chat_bubble_rounded, "Chat", 4),
            _buildMobileNavItem(Icons.person_rounded, "Tài khoản", 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [oceanBlue.withOpacity(0.2), lightOcean.withOpacity(0.2)],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? oceanBlue : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? oceanBlue : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final maxWidth = screenWidth > 1400 ? 1200.0 : (isWeb ? screenWidth * 0.85 : screenWidth);
    final horizontalPadding = isWeb ? 60.0 : 20.0;

    return Stack(
      children: [
        // Animated background
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF8F9FA),
                    oceanBlue.withOpacity(0.03),
                    const Color(0xFFF8F9FA),
                  ],
                  stops: [
                    0.0,
                    0.3 + (_floatingController.value * 0.2),
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),

        // Floating decorations
        if (isWeb) ...[
          Positioned(
            top: -100 + (_scrollOffset * 0.3),
            right: -50,
            child: _buildFloatingCircle(250, oceanBlue.withOpacity(0.05)),
          ),
          Positioned(
            top: 200 - (_scrollOffset * 0.2),
            left: -80,
            child: _buildFloatingCircle(180, lightOcean.withOpacity(0.05)),
          ),
        ],

        // Main content
        SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: Offset(0, _scrollOffset * 0.5),
                      child: Opacity(
                        opacity: (1 - (_scrollOffset / 200)).clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
                          child: const HeaderWidget(),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isWeb ? 32 : 24),

                          // Premium Banner
                          _AnimatedSection(
                            delay: 100,
                            child: _buildPremiumBanner(isWeb),
                          ),

                          SizedBox(height: isWeb ? 48 : 32),

                          // Feature Grid
                          _AnimatedSection(
                            delay: 200,
                            child: _buildSection(
                              context,
                              title: "Khám phá nổi bật",
                              icon: Icons.auto_awesome_rounded,
                              child: const FeatureGridWidget(),
                              isWeb: isWeb,
                            ),
                          ),

                          SizedBox(height: isWeb ? 48 : 32),

                          // Quick Categories
                          _AnimatedSection(
                            delay: 300,
                            child: _buildSection(
                              context,
                              title: "Danh mục nhanh",
                              icon: Icons.apps_rounded,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: oceanBlue.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: QuickCategoriesWidget(
                                      onCategoryTap: (category) {
                                        HapticFeedback.selectionClick();
                                        debugPrint("Chọn danh mục: $category");
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              isWeb: isWeb,
                            ),
                          ),

                          SizedBox(height: isWeb ? 80 : 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(_floatingController.value * 2 * math.pi) * 10,
            math.cos(_floatingController.value * 2 * math.pi) * 10,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumBanner(bool isWeb) {
    return Hero(
      tag: 'promo_banner',
      child: Container(
        height: isWeb ? 280 : 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: oceanBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: const PromoBannerWidget(),
            ),
            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            // Shine effect
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3 * _floatingController.value),
                          Colors.transparent,
                          Colors.white.withOpacity(0.3 * (1 - _floatingController.value)),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget child,
        required bool isWeb,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [deepOcean, oceanBlue, lightOcean],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: oceanBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isWeb ? 28 : 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: isWeb ? 24 : 20),
        child,
      ],
    );
  }
}

class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedSection({
    required this.child,
    this.delay = 0,
  });

  @override
  _AnimatedSectionState createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}