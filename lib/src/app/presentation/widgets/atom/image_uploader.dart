import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ImageUploader extends StatefulWidget {
  final void Function(File)? onImageSelected;
  const ImageUploader({super.key, this.onImageSelected});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  /// Compresses the image and fixes EXIF orientation.
  /// Camera images often have incorrect rotation due to EXIF metadata not being
  /// applied. flutter_image_compress automatically handles EXIF rotation.
  Future<File?> _compressAndFixOrientation(File file) async {
    final dir = p.dirname(file.path);
    final ext = p.extension(file.path);
    final targetPath = p.join(dir, '${p.basenameWithoutExtension(file.path)}_compressed$ext');

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      autoCorrectionAngle: true,
      keepExif: false, // Remove EXIF after applying rotation
    );

    if (result != null) {
      return File(result.path);
    }
    return null;
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (pickedFile != null) {
        final File? compressedImage = await _compressAndFixOrientation(File(pickedFile.path));
        final File image = compressedImage ?? File(pickedFile.path);
        setState(() {
          _image = image;
        });
        widget.onImageSelected?.call(image);
        debugPrint('Image captured and processed: ${image.path}');
      } else {
        debugPrint('No image captured');
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _pickImageFromFileExplorer() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File image = File(pickedFile.path);
        setState(() {
          _image = image;
        });
        widget.onImageSelected?.call(image);
        debugPrint('Image selected from gallery: ${image.path}');
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickImageFromCamera, // Open camera on tap
          child: Container(
            width: 0.125.sw,
            height: 0.1.sw,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.camera_alt,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
        ),
        SizedBox(width: 0.025.sw),
        GestureDetector(
          onTap: _pickImageFromFileExplorer, // Open gallery/file explorer
          child: Container(
            width: 0.65.sw,
            height: 0.1.sw,
            padding: EdgeInsets.symmetric(
              horizontal: 0.025.sw,
              vertical: 0.01.sw,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Text(
                _image == null ? 'Upload Image' : _image!.path,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
