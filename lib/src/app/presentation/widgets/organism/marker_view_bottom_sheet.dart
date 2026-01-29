import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/modal_bottom_sheet.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MarkerViewBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String markerId;
  final String markerName;
  final MarkerStateBloc markerStateBloc;

  const MarkerViewBottomSheet({
    super.key,
    required this.parentContext,
    required this.markerId,
    required this.markerName,
    required this.markerStateBloc,
  });

  @override
  State<MarkerViewBottomSheet> createState() => _MarkerViewBottomSheetState();
}

class _MarkerViewBottomSheetState extends State<MarkerViewBottomSheet> {
  late Future<EntitiesMarker> _markerFuture;

  @override
  void initState() {
    super.initState();
    _markerFuture = ServiceMarker().fetchMarker(widget.markerId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(-10, 4),
              ),
            ],
          ),
          child: FutureBuilder<EntitiesMarker>(
            future: _markerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading(context, scrollController);
              } else if (snapshot.hasError) {
                return _buildError(context, scrollController, snapshot.error.toString());
              } else if (snapshot.hasData) {
                return _buildContent(context, scrollController, snapshot.data!);
              }
              return _buildError(context, scrollController, 'Data tidak ditemukan');
            },
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildDragHandle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.05.sw),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.markerName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 0.05.sh),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A148)),
                  ),
                ),
                SizedBox(height: 0.02.sh),
                const Center(
                  child: Text(
                    'Memuat detail...',
                    style: TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ScrollController scrollController, String error) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildDragHandle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.05.sw),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 0.02.sh),
                const Text(
                  'Gagal memuat detail',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 0.01.sh),
                Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF616161),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 0.02.sh),
                _buildEditButton(context, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController, EntitiesMarker marker) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildDragHandle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.05.sw),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  marker.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 0.015.sh),

                // Image (tap to view full size)
                GestureDetector(
                  onTap: marker.imageUrl.isNotEmpty
                      ? () => _showImagePopup(context, marker.imageUrl)
                      : null,
                  child: _buildImageSection(marker),
                ),
                SizedBox(height: 0.015.sh),

                // Latitude & Longitude
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Latitude',
                        marker.location.latitude.toStringAsFixed(6),
                        isRequired: true,
                      ),
                    ),
                    SizedBox(width: 0.04.sw),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Longitude',
                        marker.location.longitude.toStringAsFixed(6),
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.015.sh),

                // Jenis Bambu & Jumlah
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Jenis Bambu',
                        marker.strain.isNotEmpty ? marker.strain : '-',
                        isRequired: true,
                      ),
                    ),
                    SizedBox(width: 0.04.sw),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Jumlah',
                        marker.quantity > 0 ? marker.quantity.toString() : '-',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.015.sh),

                // Description
                _buildReadOnlyField(
                  'Deskripsi',
                  marker.description.isNotEmpty ? marker.description : '-',
                ),
                SizedBox(height: 0.015.sh),

                // Owner Name & Contact
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        'Nama Pemilik',
                        marker.ownerName.isNotEmpty ? marker.ownerName : '-',
                      ),
                    ),
                    SizedBox(width: 0.04.sw),
                    Expanded(
                      child: _buildReadOnlyField(
                        'Kontak Pemilik',
                        marker.ownerContact.isNotEmpty ? marker.ownerContact : '-',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.02.sh),

                // Edit Data Button
                _buildEditButton(context, marker),
                SizedBox(height: 0.02.sh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(EntitiesMarker marker) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF375DFB).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: marker.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: marker.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A148)),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Color(0xFF9E9E9E),
                ),
              ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, EntitiesMarker? marker) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: marker == null
            ? () => Navigator.pop(context)
            : () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: widget.parentContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext modalContext) => ModalBottomSheet(
                    parentContext: widget.parentContext,
                    markerId: marker.id,
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF62A148),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF253EA7).withValues(alpha: 0.48),
        ),
        child: Text(
          marker == null ? 'Tutup' : 'Edit Data',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                    maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
