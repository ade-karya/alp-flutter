import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_cubit_v2.dart';
import '../../../core/auth/auth_cubit.dart';

/// Network Settings Screen with Connection Mode Selector
class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Settings')),
      body: BlocBuilder<NetworkCubitV2, NetworkState>(
        builder: (context, networkState) {
          final networkCubit = context.read<NetworkCubitV2>();
          final authCubit = context.read<AuthCubit>();
          final authState = authCubit.state;

          if (authState is! Authenticated) {
            return const Center(child: Text('Please login first'));
          }

          final user = authState.user;
          final scanningState = networkState is NetworkScanning
              ? networkState
              : null;
          final isEnabled = scanningState != null;
          final currentMode = scanningState?.mode ?? ConnectionMode.hybrid;
          final isFirebaseConnected =
              scanningState?.isFirebaseConnected ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Network Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isEnabled ? Icons.cloud_done : Icons.cloud_off,
                        color: isEnabled ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Network Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEnabled ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                color: isEnabled ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        onChanged: (value) {
                          networkCubit.toggleServer(value, user);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Connection Mode Selector
              Text(
                'Connection Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how devices connect',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Mode Selector Cards
              _ConnectionModeCard(
                mode: ConnectionMode.local,
                icon: Icons.wifi,
                title: 'Local Network',
                description: 'Connect via WiFi/LAN (Same network required)',
                isSelected: currentMode == ConnectionMode.local,
                isEnabled: isEnabled,
                onTap: () {
                  if (isEnabled) {
                    networkCubit.switchMode(ConnectionMode.local, user);
                  }
                },
              ),
              const SizedBox(height: 12),

              _ConnectionModeCard(
                mode: ConnectionMode.internet,
                icon: Icons.cloud,
                title: 'Internet',
                description: 'Connect from anywhere via Firebase',
                isSelected: currentMode == ConnectionMode.internet,
                isEnabled: isEnabled,
                statusWidget: isFirebaseConnected
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Connected',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                onTap: () {
                  if (isEnabled) {
                    networkCubit.switchMode(ConnectionMode.internet, user);
                  }
                },
              ),
              const SizedBox(height: 12),

              _ConnectionModeCard(
                mode: ConnectionMode.hybrid,
                icon: Icons.sync,
                title: 'Hybrid (Recommended)',
                description: 'Use both local and internet',
                isSelected: currentMode == ConnectionMode.hybrid,
                isEnabled: isEnabled,
                onTap: () {
                  if (isEnabled) {
                    networkCubit.switchMode(ConnectionMode.hybrid, user);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Peer List
              if (scanningState != null) ...[
                Text(
                  'Discovered Peers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildPeerList(context, scanningState.peers),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeerList(BuildContext context, List<Map<String, String>> peers) {
    if (peers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No peers discovered',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: peers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final peer = peers[index];
          final isTeacher = peer['role'] == 'teacher';
          final source = peer['source'] ?? 'local';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isTeacher ? Colors.blue : Colors.green,
              child: Icon(
                isTeacher ? Icons.school : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(peer['name'] ?? 'Unknown'),
            subtitle: Text(
              '${peer['host'] ?? ''} • $source',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Icon(
              source == 'internet' ? Icons.cloud : Icons.wifi,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}

/// Connection mode selection card widget
class _ConnectionModeCard extends StatelessWidget {
  final ConnectionMode mode;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final bool isEnabled;
  final Widget? statusWidget;
  final VoidCallback onTap;

  const _ConnectionModeCard({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.isEnabled,
    this.statusWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? selectedColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? selectedColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (statusWidget != null) ...[
                        const SizedBox(height: 8),
                        statusWidget!,
                      ],
                    ],
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: selectedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
