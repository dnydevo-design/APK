import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/device_info.dart';
import '../../../domain/entities/transfer_task.dart';
import '../../bloc/discovery/discovery_bloc.dart';
import '../../bloc/transfer/transfer_bloc.dart';
import '../../bloc/transfer/transfer_event.dart';
import '../../bloc/transfer/transfer_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shake_detector.dart';

/// Main home screen with Individual/Group mode tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TransferBloc>().add(const LoadTransfersEvent());
    context.read<DiscoveryBloc>().add(const StartDiscoveryEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShakeDetector(
      onShake: () {
        // Trigger discovery on shake
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🤝 Shake detected! Searching for devices...'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.read<DiscoveryBloc>().add(const StartDiscoveryEvent());
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildModeSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIndividualMode(),
                    _buildGroupMode(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // App logo with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Fast Share',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Shake hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.vibration_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  'Shake',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: AppTextStyles.labelLarge,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Individual'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Group'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovered devices section
          _buildSectionHeader('Nearby Devices', Icons.radar_rounded),
          const SizedBox(height: 12),
          _buildDeviceList(),
          const SizedBox(height: 24),
          // Active transfers
          _buildSectionHeader('Active Transfers', Icons.swap_vert_rounded),
          const SizedBox(height: 12),
          _buildTransferList(),
          const SizedBox(height: 24),
          // Quick actions
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Send',
                  icon: Icons.upload_rounded,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: 'Receive',
                  icon: Icons.download_rounded,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.8),
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group info card
          GlassmorphicCard(
            child: Column(
              children: [
                const Icon(
                  Icons.group_work_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Group Sharing',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share files with multiple devices at once.\nCreate a group or join an existing one.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: 'Create Group',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () {
                          context.read<DiscoveryBloc>().add(
                                const CreateGroupEvent(),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: 'Join Group',
                        icon: Icons.login_rounded,
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, Color(0xFF00CEC9)],
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Group Members', Icons.people_rounded),
          const SizedBox(height: 12),
          _buildDeviceList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        if (state is DiscoveryScanning) {
          return _buildScanningIndicator();
        }

        if (state is DiscoveryFound) {
          return Column(
            children: state.devices.map((d) => _buildDeviceCard(d)).toList(),
          );
        }

        return _buildEmptyDevices();
      },
    );
  }

  Widget _buildScanningIndicator() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedConnectionIndicator(
            isActive: true,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Scanning for devices...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDevices() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.devices_other_rounded,
            size: 40,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No devices found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Shake your device or tap scan to search',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceInfo device) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    device.host,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const AnimatedConnectionIndicator(
              isActive: true,
              size: 8,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                context.read<DiscoveryBloc>().add(
                      ConnectToDeviceEvent(device.id),
                    );
              },
              icon: const Icon(Icons.link_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferList() {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, state) {
        List<TransferTask> transfers = [];

        if (state is TransferLoaded) {
          transfers = state.activeTransfers;
        } else if (state is TransferInProgress) {
          transfers = [state.task];
        }

        if (transfers.isEmpty) {
          return GlassmorphicCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No active transfers',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        return Column(
          children: transfers.map((t) => _buildTransferCard(t)).toList(),
        );
      },
    );
  }

  Widget _buildTransferCard(TransferTask task) {
    final progressColor = switch (task.status) {
      TransferStatus.transferring => AppColors.progressActive,
      TransferStatus.paused => AppColors.progressPaused,
      TransferStatus.completed => AppColors.progressComplete,
      TransferStatus.failed => AppColors.progressFailed,
      _ => AppColors.primary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  task.direction == TransferDirection.send
                      ? Icons.upload_rounded
                      : Icons.download_rounded,
                  color: progressColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.fileName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${FileUtils.formatFileSize(task.fileSize)} • ${task.peerName}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Speed indicator
                if (task.status == TransferStatus.transferring)
                  Text(
                    '${FileUtils.formatFileSize(task.speedBytesPerSec.toInt())}/s',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 8),
                // Pause/Resume button
                if (task.status == TransferStatus.transferring)
                  IconButton(
                    onPressed: () {
                      context
                          .read<TransferBloc>()
                          .add(PauseTransferEvent(task.id));
                    },
                    icon: const Icon(Icons.pause_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.warning.withValues(alpha: 0.1),
                      foregroundColor: AppColors.warning,
                    ),
                  ),
                if (task.status == TransferStatus.paused)
                  IconButton(
                    onPressed: () {
                      context
                          .read<TransferBloc>()
                          .add(ResumeTransferEvent(task.id));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.success.withValues(alpha: 0.1),
                      foregroundColor: AppColors.success,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: progressColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(task.progress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${task.completedChunks}/${task.totalChunks} chunks',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
