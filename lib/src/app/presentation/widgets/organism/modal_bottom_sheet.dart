import 'dart:io';

import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/auth_text_field.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/presentation/widgets/molecule/location_picker.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/app/use_cases/gps_controller.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:bamboo_app/utils/textfield_validator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class ModalBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String? markerId;

  const ModalBottomSheet(
      {super.key, required this.parentContext, this.markerId});

  @override
  State<ModalBottomSheet> createState() => _ModalBottomSheetState();
}

class _ModalBottomSheetState extends State<ModalBottomSheet> {
  Future<EntitiesMarker>? _markerFuture;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qtyController = TextEditingController();
  final _strainController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _image;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _waitingForResponse = false;
  String? _pendingOperation;

  bool get _isEditMode => widget.markerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _markerFuture = ServiceMarker().fetchMarker(widget.markerId!);
      _markerFuture!.then((marker) {
        if (mounted) {
          setState(() {
            _nameController.text = marker.name;
            _descriptionController.text = marker.description;
            _qtyController.text = marker.quantity.toString();
            _strainController.text = marker.strain;
            _ownerNameController.text = marker.ownerName;
            _ownerContactController.text = marker.ownerContact;
            _latitudeController.text = marker.location.latitude.toString();
            _longitudeController.text = marker.location.longitude.toString();
            _existingImageUrl = marker.imageUrl;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _qtyController.dispose();
    _strainController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _getLoadingMessage() {
    if (_pendingOperation == 'add') return 'Menyimpan data baru...';
    if (_pendingOperation == 'update') return 'Menyimpan perubahan...';
    if (_pendingOperation == 'delete') return 'Menghapus data...';
    return 'Memproses...';
  }

  void _handleStateChange(BuildContext context, MarkerState state) {
    if (!_waitingForResponse) return;

    if (state.status == MarkerStatus.loaded) {
      _isSubmitting = false;
      _waitingForResponse = false;

      String message = 'Berhasil!';
      if (_pendingOperation == 'add') {
        message = 'Data berhasil ditambahkan';
      } else if (_pendingOperation == 'update') {
        message = 'Data berhasil diperbarui';
      } else if (_pendingOperation == 'delete') {
        message = 'Data berhasil dihapus';
      }

      _pendingOperation = null;
      ModalSnackbar(widget.parentContext).showSuccess(message);

      if (!_isEditMode) {
        router.pop();
      } else {
        router.pop();
      }
    } else if (state.hasError) {
      setState(() {
        _isSubmitting = false;
        _waitingForResponse = false;
        _pendingOperation = null;
      });
      ModalSnackbar(widget.parentContext).showError(state.errorMessage ?? 'Terjadi kesalahan');
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      ModalSnackbar(context).showError('Nama lokasi harus diisi');
      return false;
    }
    if (_qtyController.text.trim().isNotEmpty) {
      final qty = int.tryParse(_qtyController.text);
      if (qty == null || qty < 0) {
        ModalSnackbar(context).showError('Jumlah harus berupa angka valid');
        return false;
      }
    }
    return true;
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 280,
              maxWidth: 560,
            ),
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Hapus Data',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Apakah Anda yakin ingin menghapus data ini? Tindakan ini tidak dapat dibatalkan.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF49454F),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 24, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF62A148),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF10000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  Future<void> _handleSubmit(EntitiesMarker? marker) async {
    if (!_validateForm()) return;
    if (_isSubmitting) return;

    final markerBloc = BlocProvider.of<MarkerStateBloc>(widget.parentContext);

    setState(() {
      _isSubmitting = true;
      _pendingOperation = _isEditMode ? 'update' : 'add';
    });

    try {
      final position = await GpsController().getCurrentPosition();
      if (!mounted) return;

      LatLng currentPosition = LatLng(position.latitude, position.longitude);

      setState(() => _waitingForResponse = true);

      final now = DateTime.now();
      if (!_isEditMode) {
        markerBloc.add(
          AddMarkerData(
            marker: EntitiesMarker(
              id: '',
              shortCode: '',
              creatorId: '',
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              strain: _strainController.text.trim(),
              quantity: int.tryParse(_qtyController.text) ?? 0,
              imageUrl: _image?.path ?? '',
              ownerName: _ownerNameController.text.trim(),
              ownerContact: _ownerContactController.text.trim(),
              location: _getLocation(currentPosition),
              createdAt: now,
              updatedAt: now,
            ),
          ),
        );
      } else {
        markerBloc.add(
          UpdateMarkerData(
            marker: EntitiesMarker(
              id: marker!.id,
              shortCode: marker.shortCode,
              creatorId: marker.creatorId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              strain: _strainController.text.trim(),
              quantity: int.tryParse(_qtyController.text) ?? marker.quantity,
              imageUrl: _image == null ? 'NULL:${marker.imageUrl}' : _image!.path,
              ownerName: _ownerNameController.text.trim(),
              ownerContact: _ownerContactController.text.trim(),
              location: _getLocation(currentPosition),
              createdAt: marker.createdAt,
              updatedAt: now,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _waitingForResponse = false;
        _pendingOperation = null;
      });
      ModalSnackbar(context).showError('Gagal mendapatkan lokasi GPS');
    }
  }

  LatLng _getLocation(LatLng fallback) {
    if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
      final lat = double.tryParse(_latitudeController.text);
      final lng = double.tryParse(_longitudeController.text);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return fallback;
  }

  Future<void> _handleDelete(EntitiesMarker marker) async {
    if (_isSubmitting) return;

    final markerBloc = BlocProvider.of<MarkerStateBloc>(widget.parentContext);

    final confirmed = await _showDeleteConfirmation(context);
    if (!confirmed) return;
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _pendingOperation = 'delete';
      _waitingForResponse = true;
    });

    markerBloc.add(DeleteMarkerData(marker: marker));
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<MarkerStateBloc>(widget.parentContext),
      child: BlocConsumer<MarkerStateBloc, MarkerState>(
        listener: _handleStateChange,
        builder: (context, state) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Stack(
                children: [
                  Container(
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
                        if (_isEditMode && snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingState(scrollController);
                        } else if (_isEditMode && snapshot.hasError) {
                          return _buildErrorState(scrollController, snapshot.error.toString());
                        } else if (_isEditMode && snapshot.hasData) {
                          return _buildContent(context, scrollController, snapshot.data!);
                        }
                        return _buildContent(context, scrollController, null);
                      },
                    ),
                  ),
                  if (_isSubmitting)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A148)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getLoadingMessage(),
                                    style: const TextStyle(
                                      color: Color(0xFF1E1E1E),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 42,
      height: 5,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildLoadingState(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildDragHandle(),
          SizedBox(height: 0.2.sh),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A148)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat data...',
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ScrollController scrollController, String error) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          _buildDragHandle(),
          SizedBox(height: 0.1.sh),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => router.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF62A148),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController, EntitiesMarker? marker) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildDragHandle(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.06.sw),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _isEditMode ? 'Edit Data' : 'Tambah Data',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  SizedBox(height: 0.015.sh),

                  // Location Picker (Lat/Long + buttons)
                  LocationPicker(
                    latitudeController: _latitudeController,
                    longitudeController: _longitudeController,
                    enabled: !_isSubmitting,
                  ),
                  SizedBox(height: 0.015.sh),

                  // Nama Lokasi
                  AuthTextField(
                    controller: _nameController,
                    hintText: 'Nama Lokasi',
                    label: 'Nama Lokasi',
                    validator: TextfieldValidator.name,
                  ),
                  SizedBox(height: 0.015.sh),

                  // Jenis Bambu & Jumlah
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        fit: FlexFit.tight,
                        child: AuthTextField(
                          controller: _strainController,
                          hintText: 'Jenis Bambu',
                          label: 'Jenis Bambu',
                          optional: true,
                        ),
                      ),
                      SizedBox(width: 0.04.sw),
                      Flexible(
                        flex: 1,
                        child: AuthTextField(
                          controller: _qtyController,
                          hintText: 'Jumlah',
                          label: 'Jumlah',
                          optional: true,
                          type: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.015.sh),

                  // Deskripsi
                  AuthTextField(
                    controller: _descriptionController,
                    hintText: 'Deskripsi',
                    label: 'Deskripsi',
                    optional: true,
                  ),
                  SizedBox(height: 0.015.sh),

                  // Nama Pemilik
                  AuthTextField(
                    controller: _ownerNameController,
                    hintText: 'Nama Pemilik',
                    label: 'Nama Pemilik',
                    optional: true,
                  ),
                  SizedBox(height: 0.015.sh),

                  // Nomor Pemilik
                  AuthTextField(
                    controller: _ownerContactController,
                    hintText: 'Nomor Pemilik',
                    label: 'Nomor Pemilik',
                    optional: true,
                    type: TextInputType.phone,
                  ),
                  SizedBox(height: 0.015.sh),

                  // Image Upload Section
                  _buildImageUploadSection(),
                  SizedBox(height: 0.02.sh),

                  // Action Buttons
                  _buildActionButtons(marker),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final hasImage = _image != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF375DFB).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: hasImage
            ? _buildImagePreview()
            : GestureDetector(
                onTap: _showImagePickerOptions,
                child: Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image != null) {
      return GestureDetector(
        onTap: () => _showLocalImagePopup(context, _image!),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _image!,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _image = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tap untuk zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showNetworkImagePopup(context, _existingImageUrl!),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _existingImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A148)),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tap untuk zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ganti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1E1E1E)),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1E1E1E)),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(EntitiesMarker? marker) {
    return Row(
      children: [
        // Save button
        Expanded(
          flex: _isEditMode ? 3 : 1,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleSubmit(marker),
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
                'Simpan Data',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        // Delete button (only in edit mode)
        if (_isEditMode) ...[
          SizedBox(width: 0.06.sw),
          SizedBox(
            width: 63,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleDelete(marker!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE40000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: Color(0xFFF8F7FB),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showLocalImagePopup(BuildContext context, File imageFile) {
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
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.contain,
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

  void _showNetworkImagePopup(BuildContext context, String imageUrl) {
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
