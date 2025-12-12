import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/network_cubit.dart';

class NetworkPeersDialog extends StatelessWidget {
  const NetworkPeersDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connected Peers'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<NetworkCubit, NetworkState>(
          builder: (context, state) {
            if (state is NetworkInitial || state is NetworkDisabled) {
              return const Text('Discovery not active.');
            }
            if (state is NetworkScanning) {
              if (state.peers.isEmpty) {
                return const Text('Scanning... No peers found yet.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: state.peers.length,
                itemBuilder: (context, index) {
                  final peer = state.peers[index];
                  return ListTile(
                    leading: Icon(
                      peer['role'] == 'Teacher' ? Icons.school : Icons.person,
                      color: peer['role'] == 'Teacher'
                          ? Colors.purple
                          : Colors.blue,
                    ),
                    title: Text(peer['name'] ?? 'Unknown'),
                    subtitle: Text('${peer['role']} • ${peer['host']}'),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
