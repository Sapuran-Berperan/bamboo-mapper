import 'package:bamboo_app/src/app/blocs/map_type_state.dart';
import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:bamboo_app/utils/default_user.dart';
import 'package:bamboo_app/utils/util_excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.dark:
        return Icons.dark_mode;
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
        drawer: BlocBuilder<MapTypeBloc, MapTypeState>(
          builder: (context, mapState) {
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: Text(
                      'Menu Tambahan',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  // Map Type Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Jenis Peta',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall!.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...MapType.values.map((type) {
                    final info = mapTypeConfigs[type]!;
                    final isSelected = mapState.currentType == type;
                    return ListTile(
                      title: Text(info.name),
                      leading: Icon(
                        _getMapTypeIcon(type),
                        color: isSelected ? Theme.of(context).colorScheme.secondary : null,
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.secondary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () {
                        context.read<MapTypeBloc>().add(ChangeMapType(type));
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  }),
                  const Divider(),
                  // Other menu items
                  ListTile(
                    title: const Text('Download CSV'),
                    leading: const Icon(Icons.download),
                    onTap: () async => UtilExcel().createExcel(
                        await ServiceMarker().fetchListMarker(defaultUser.uid)),
                  ),
                  ListTile(
                    title: const Text('Logout'),
                    leading: const Icon(Icons.logout),
                    onTap: () => router.go('/login'),
                  ),
                ],
              ),
            );
          },
        ),
        body: Stack(
          children: [
            child,
            Positioned(
              top: 40,
              left: 20,
              child: Builder(
                builder: (context) {
                  return FloatingActionButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: Icon(
                      Icons.menu,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
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
}
