import 'package:bamboo_app/src/app/blocs/map_type_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FloatingMapButton extends StatefulWidget {
  const FloatingMapButton({
    super.key,
    required MapController controller,
    this.currentLocation,
  }) : _controller = controller;

  final MapController _controller;
  final LatLng? currentLocation;

  @override
  State<FloatingMapButton> createState() => _FloatingMapButtonState();
}

class _FloatingMapButtonState extends State<FloatingMapButton>
    with SingleTickerProviderStateMixin {
  bool _isMapTilesExpanded = false;
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
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMapTiles() {
    setState(() {
      _isMapTilesExpanded = !_isMapTilesExpanded;
      if (_isMapTilesExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapTypeBloc, MapTypeState>(
      builder: (context, mapTypeState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Map Tiles Menu (animated)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return _isMapTilesExpanded || _animationController.isAnimating
                    ? Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildMapTileOption(
                                context,
                                icon: Icons.map_outlined,
                                label: 'OpenStreetMap',
                                mapType: MapType.openStreetMap,
                                isSelected: mapTypeState.currentType == MapType.openStreetMap,
                              ),
                              const SizedBox(height: 8),
                              _buildMapTileOption(
                                context,
                                icon: Icons.satellite_alt,
                                label: 'Satelit',
                                mapType: MapType.satellite,
                                isSelected: mapTypeState.currentType == MapType.satellite,
                              ),
                              const SizedBox(height: 8),
                              _buildMapTileOption(
                                context,
                                icon: Icons.terrain,
                                label: 'Terrain',
                                mapType: MapType.terrain,
                                isSelected: mapTypeState.currentType == MapType.terrain,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            // Map Tiles Toggle Button
            _buildFabButton(
              heroTag: 'mapTilesBtn',
              onPressed: _toggleMapTiles,
              backgroundColor: _isMapTilesExpanded
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white,
              child: Icon(
                _isMapTilesExpanded ? Icons.close : Icons.layers_outlined,
                color: _isMapTilesExpanded ? Colors.white : const Color(0xFF49454F),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            // My Location Button
            _buildFabButton(
              heroTag: 'myLocationBtn',
              onPressed: () {
                if (widget.currentLocation != null) {
                  widget._controller.move(widget.currentLocation!, 17);
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF49454F),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            // Add Location Button
            _buildFabButton(
              heroTag: 'addMarkerBtn',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext modalContext) =>
                    ModalBottomSheet(parentContext: context),
              ),
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF49454F),
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFabButton({
    required String heroTag,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildMapTileOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required MapType mapType,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<MapTypeBloc>().add(ChangeMapType(mapType));
        _toggleMapTiles();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8DEF8) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1D1B20) : const Color(0xFF49454F),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF1D1B20) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
