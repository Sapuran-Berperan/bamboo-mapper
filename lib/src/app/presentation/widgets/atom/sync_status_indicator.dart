import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/sync_state.dart';
import '../../../../core/sync/sync_service.dart';

/// Widget that displays the current sync status
class SyncStatusIndicator extends StatelessWidget {
  /// Whether to show the label text
  final bool showLabel;

  /// Size of the indicator icon
  final double iconSize;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncBlocState>(
      builder: (context, state) {
        return _buildIndicator(context, state);
      },
    );
  }

  Widget _buildIndicator(BuildContext context, SyncBlocState state) {
    final IconData icon;
    final Color color;
    final String label;
    final bool isAnimated;

    // Determine icon and color based on state
    if (state.syncState == SyncState.syncing) {
      icon = Icons.sync;
      color = Colors.blue;
      label = 'Menyinkronkan...';
      isAnimated = true;
    } else if (!state.isOnline) {
      icon = Icons.cloud_off;
      color = Colors.grey;
      label = 'Offline';
      isAnimated = false;
    } else if (state.hasPendingChanges) {
      icon = Icons.cloud_upload;
      color = Colors.orange;
      label = '${state.pendingCount} menunggu';
      isAnimated = false;
    } else if (state.syncState == SyncState.error) {
      icon = Icons.cloud_off;
      color = Colors.red;
      label = 'Error';
      isAnimated = false;
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      label = 'Tersinkronisasi';
      isAnimated = false;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAnimated)
          _AnimatedSyncIcon(icon: icon, color: color, size: iconSize)
        else
          Icon(icon, color: color, size: iconSize),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated rotating sync icon
class _AnimatedSyncIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedSyncIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// Compact sync status chip for app bar
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncBlocState>(
      builder: (context, state) {
        // Only show chip if there's something notable
        if (state.isOnline &&
            !state.hasPendingChanges &&
            state.syncState == SyncState.idle) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getBackgroundColor(state),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SyncStatusIndicator(
            showLabel: true,
            iconSize: 14,
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(SyncBlocState state) {
    if (state.syncState == SyncState.syncing) {
      return Colors.blue.withValues(alpha: 0.1);
    } else if (!state.isOnline) {
      return Colors.grey.withValues(alpha: 0.1);
    } else if (state.hasPendingChanges) {
      return Colors.orange.withValues(alpha: 0.1);
    } else if (state.syncState == SyncState.error) {
      return Colors.red.withValues(alpha: 0.1);
    }
    return Colors.green.withValues(alpha: 0.1);
  }
}

/// Network status banner shown at top when offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncBlocState>(
      builder: (context, state) {
        if (state.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.grey[800],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Mode Offline - Perubahan akan disinkronkan saat online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              if (state.hasPendingChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Sync button that triggers manual sync
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncBlocState>(
      builder: (context, state) {
        final bool canSync = state.isOnline && !state.isSyncing;

        return IconButton(
          onPressed: canSync
              ? () => context.read<SyncBloc>().add(SyncTrigger())
              : null,
          icon: state.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.sync,
                  color: canSync ? null : Colors.grey,
                ),
          tooltip: state.isSyncing
              ? 'Menyinkronkan...'
              : (canSync ? 'Sinkronkan' : 'Offline'),
        );
      },
    );
  }
}
