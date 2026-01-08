import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/image_snippet.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/info_window_data.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/submit_button.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/modal_bottom_sheet.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomInfoWindow extends StatefulWidget {
  final MarkerStateBloc markerStateBloc;
  final String markerId;
  final String markerName;

  const CustomInfoWindow({
    super.key,
    required this.markerId,
    required this.markerName,
    required this.markerStateBloc,
  });

  @override
  State<CustomInfoWindow> createState() => _CustomInfoWindowState();
}

class _CustomInfoWindowState extends State<CustomInfoWindow> {
  late Future<EntitiesMarker> _markerFuture;

  @override
  void initState() {
    super.initState();
    _markerFuture = ServiceMarker().fetchMarker(widget.markerId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<EntitiesMarker>(
        future: _markerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(context);
          } else if (snapshot.hasError) {
            return _buildError(context, snapshot.error.toString());
          } else if (snapshot.hasData) {
            return _buildContent(context, snapshot.data!);
          }
          return _buildError(context, 'Data tidak ditemukan');
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.markerName,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.05.sh),
        const CircularProgressIndicator(),
        SizedBox(height: 0.02.sh),
        Text(
          'Memuat detail...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 0.03.sh),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        SizedBox(height: 0.02.sh),
        Text(
          'Gagal memuat detail',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 0.01.sh),
        Text(
          error,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.02.sh),
        SubmitButton(
          onTap: () => Navigator.pop(context),
          text: 'Tutup',
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, EntitiesMarker marker) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          marker.name,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.025.sh),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              flex: 3,
              child: marker.strain.isNotEmpty
                  ? InfoWindowData(
                      header: 'Jenis',
                      data: marker.strain,
                      half: true,
                    )
                  : const InfoWindowData(
                      header: 'Jenis',
                      data: '-',
                      half: true,
                    ),
            ),
            Padding(padding: EdgeInsets.only(left: 0.05.sw)),
            Flexible(
              flex: 1,
              child: InfoWindowData(
                header: 'Quantity',
                data: marker.quantity.toString(),
                half: true,
              ),
            ),
          ],
        ),
        marker.description.isNotEmpty
            ? InfoWindowData(header: 'Description', data: marker.description)
            : const SizedBox(),
        marker.ownerName.isNotEmpty
            ? InfoWindowData(
                header: 'Owner Contact',
                data: '${marker.ownerName} (${marker.ownerContact})')
            : const SizedBox(),
        ImageSnippet(imageUrl: marker.imageUrl),
        SizedBox(height: 0.025.sh),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SubmitButton(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext modalContext) => ModalBottomSheet(
                  parentContext: context,
                  markerId: marker.id,
                ),
              ),
              text: 'Update',
            ),
            SubmitButton(
              onTap: () => Navigator.pop(context),
              text: 'Close',
            ),
          ],
        ),
      ],
    );
  }
}
