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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
    final List<Widget> pages = [
      const HomeContent(),
      const ToursPage(),
      const Tours3DPage(), // ✅ thêm trang Tour 3D
      const NewsPage(),
      ChatPage(customerId: globals.currentCustomer?.customerID ?? 0),
      const AccountPage(),
    ];


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
    );
  }

  Widget _buildPremiumBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, "Trang chủ", 0, 'Home'),
            _buildNavItem(Icons.explore_rounded, "Tour", 1, 'Tours'),
            _buildNavItem(
                Icons.threed_rotation_rounded, "Tour 3D", 2, '3D Tours'),
            _buildNavItem(Icons.article_rounded, "Tin tức", 3, 'News'),
            _buildNavItem(Icons.chat_bubble_rounded, "Chat", 4, 'Chat'),
            _buildNavItem(Icons.person_rounded, "Tài khoản", 5, 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      String semanticLabel) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        selected: isSelected,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme
              .of(context)
              .colorScheme
              .primary
              .withOpacity(0.2),
          highlightColor: Theme
              .of(context)
              .colorScheme
              .primary
              .withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: isSelected
                      ? _scaleAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Theme
                        .of(context)
                        .colorScheme
                        .primary
                        : Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme
                      .of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme
                        .of(context)
                        .colorScheme
                        .primary
                        : Theme
                        .of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    return Stack(
      children: [
        // Animated background gradient
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
                    Theme.of(context).colorScheme.primary.withOpacity(0.03),
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
        // Floating circles decoration
        Positioned(
          top: -100 + (_scrollOffset * 0.3),
          right: -50,
          child: _buildFloatingCircle(200, Colors.blue.withOpacity(0.05)),
        ),
        Positioned(
          top: 200 - (_scrollOffset * 0.2),
          left: -80,
          child: _buildFloatingCircle(150, Colors.purple.withOpacity(0.05)),
        ),
        // Main content
        SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with parallax effect
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, _scrollOffset * 0.5),
                  child: Opacity(
                    opacity: (1 - (_scrollOffset / 200)).clamp(0.0, 1.0),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: HeaderWidget(),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Premium Banner with glassmorphism
                      _AnimatedSection(
                        delay: 100,
                        child: _buildPremiumBanner(),
                      ),

                      const SizedBox(height: 32),

                      // Feature Grid Section
                      _AnimatedSection(
                        delay: 200,
                        child: _buildSection(
                          context,
                          title: "Khám phá nổi bật",
                          icon: Icons.auto_awesome_rounded,
                          child: const FeatureGridWidget(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick Categories Section
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
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: QuickCategoriesWidget(
                                  onCategoryTap: (category) {
                                    HapticFeedback.selectionClick();
                                    debugPrint("Chọn danh mục: $category");
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildPremiumBanner() {
    return Hero(
      tag: 'promo_banner',
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: const PromoBannerWidget(),
            ),
            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
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
                      borderRadius: BorderRadius.circular(28),
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
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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