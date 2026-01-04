import 'dart:io';

import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/auth_text_field.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/delete_button.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/header_auth.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/image_uploader.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/submit_button.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/app/use_cases/gps_controller.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:bamboo_app/utils/textfield_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  void _onImageChanged(File? image) => _image = image;

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

  // Validate required fields
  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      ModalSnackbar(context).showError('Nama lokasi harus diisi');
      return false;
    }
    if (_qtyController.text.trim().isEmpty) {
      ModalSnackbar(context).showError('Jumlah harus diisi');
      return false;
    }
    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty < 0) {
      ModalSnackbar(context).showError('Jumlah harus berupa angka valid');
      return false;
    }
    return true;
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Data'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _handleSubmit(EntitiesMarker? marker) async {
    if (!_validateForm()) return;
    if (_isSubmitting) return; // Prevent double-tap

    // Store BLoC reference before async operation
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
    if (_isSubmitting) return; // Prevent double-tap

    // Store BLoC reference before async operation
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<MarkerStateBloc>(widget.parentContext),
      child: BlocConsumer<MarkerStateBloc, MarkerState>(
        listener: _handleStateChange,
        builder: (context, state) {
          return Stack(
            children: [
              FutureBuilder<EntitiesMarker>(
                future: _markerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 0.5.sh,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SizedBox(
                      height: 0.3.sh,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Gagal memuat data'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => router.pop(),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    return _buildContent(context, snapshot.data!);
                  }
                  return _buildContent(context, null);
                },
              ),
              if (_isSubmitting)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                _getLoadingMessage(),
                                style: Theme.of(context).textTheme.bodyMedium,
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, EntitiesMarker? marker) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 0.1.sw),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              HeaderAuth(
                heading: _isEditMode ? 'Edit Data' : 'Tambah Data',
                subheading: _isEditMode
                    ? 'Perbarui informasi lokasi'
                    : 'Tambahkan data lokasi baru',
              ),
              SizedBox(height: 0.02.sh),
              _buildTextFields(),
              SizedBox(height: 0.02.sh),
              _buildActionButtons(marker),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return IgnorePointer(
      ignoring: _isSubmitting,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSubmitting ? 0.5 : 1.0,
        child: Column(
          children: [
            AuthTextField(
              controller: _nameController,
              hintText: 'Nama Lokasi *',
              label: 'Nama Lokasi',
              validator: TextfieldValidator.name,
            ),
            SizedBox(height: 0.012.sh),
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
                Padding(padding: EdgeInsets.only(left: 0.02.sw)),
                Flexible(
                  flex: 1,
                  child: AuthTextField(
                    controller: _qtyController,
                    hintText: 'Jumlah *',
                    label: 'Jumlah',
                    validator: TextfieldValidator.name,
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.012.sh),
            AuthTextField(
              controller: _descriptionController,
              hintText: 'Deskripsi',
              label: 'Deskripsi',
              optional: true,
            ),
            SizedBox(height: 0.012.sh),
            AuthTextField(
              controller: _ownerNameController,
              hintText: 'Nama Pemilik',
              label: 'Nama Pemilik',
              optional: true,
            ),
            SizedBox(height: 0.012.sh),
            AuthTextField(
              controller: _ownerContactController,
              hintText: 'Nomor Pemilik',
              label: 'Nomor Pemilik',
              optional: true,
              type: TextInputType.phone,
            ),
            SizedBox(height: 0.012.sh),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: AuthTextField(
                    controller: _latitudeController,
                    hintText: 'Latitude',
                    label: 'Latitude',
                    optional: true,
                    type: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 0.02.sw)),
                Flexible(
                  flex: 1,
                  child: AuthTextField(
                    controller: _longitudeController,
                    hintText: 'Longitude',
                    label: 'Longitude',
                    optional: true,
                    type: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.012.sh),
            ImageUploader(onImageSelected: _onImageChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(EntitiesMarker? marker) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => router.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 12),
          // Submit button
          Expanded(
            flex: 2,
            child: SubmitButton(
              onTap: _isSubmitting ? null : () => _handleSubmit(marker),
              text: _isEditMode ? 'Simpan Perubahan' : 'Simpan Data',
            ),
          ),
          // Delete button (only in edit mode)
          if (_isEditMode) ...[
            const SizedBox(width: 12),
            DeleteButton(
              onTap: _isSubmitting ? null : () => _handleDelete(marker!),
            ),
          ],
        ],
      ),
    );
  }
}
