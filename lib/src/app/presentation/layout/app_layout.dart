import 'package:bamboo_app/src/app/blocs/map_type_state.dart';
import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:bamboo_app/utils/util_excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  bool _isSidebarExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeSidebar() {
    if (_isSidebarExpanded) {
      _toggleSidebar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MarkerStateBloc>(
          create: (context) => MarkerStateBloc(),
        ),
        BlocProvider<MapTypeBloc>(
          create: (context) => MapTypeBloc(),
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            widget.child,
            // Overlay to close sidebar when tapped
            if (_isSidebarExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSidebar,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            // Menu button and sidebar
            Positioned(
              top: 40,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu toggle button
                  _buildMenuButton(),
                  // Animated sidebar menu
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return _isSidebarExpanded || _animationController.isAnimating
                          ? Opacity(
                              opacity: _fadeAnimation.value,
                              child: Transform.translate(
                                offset: Offset(_slideAnimation.value, 0),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildSidebarMenu(context),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _isSidebarExpanded
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleSidebar,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              _isSidebarExpanded ? Icons.close : Icons.menu,
              color: _isSidebarExpanded ? Colors.white : const Color(0xFF49454F),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarMenu(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download CSV option
          _buildMenuItem(
            icon: Icons.download_outlined,
            label: 'Download CSV',
            onTap: () async {
              _closeSidebar();
              await UtilExcel().createExcel(
                await ServiceMarker().fetchListMarker(),
              );
            },
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
          // Logout option
          _buildMenuItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () async {
              final userBloc = context.read<UserLoggedStateBloc>();
              _closeSidebar();
              await AuthController(userBloc: userBloc).logout();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFDC3545) : const Color(0xFF49454F);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
