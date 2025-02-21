import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/advanced_settings.dart';

/// A status bar widget that displays the current state of the avatar system,
/// including connection status, speech recognition status, and any active processes.
/// This provides users with immediate visual feedback about the system's state.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main status indicators row
              Row(
                children: [
                  _buildStatusIndicator(
                    context: context,
                    icon: Icons.wifi,
                    label: 'Connection',
                    isActive: appState.isSessionActive,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
                    tooltip: appState.isSessionActive 
                        ? 'Connected to avatar service'
                        : 'Not connected',
                  ),
                  const SizedBox(width: 16),
                  _buildStatusIndicator(
                    context: context,
                    icon: Icons.mic,
                    label: 'Speech Recognition',
                    isActive: appState.config.continuousConversation,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                    tooltip: appState.config.continuousConversation
                        ? 'Listening for speech input'
                        : 'Speech recognition inactive',
                  ),
                  const SizedBox(width: 16),
                  _buildStatusIndicator(
                    context: context,
                    icon: Icons.record_voice_over,
                    label: 'Speaking',
                    isActive: appState.isSpeaking,
                    activeColor: Colors.orange,
                    inactiveColor: Colors.grey,
                    tooltip: appState.isSpeaking
                        ? 'Avatar is speaking'
                        : 'Avatar is silent',
                  ),
                  const Spacer(),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Open Settings',
                    onPressed: () => _showSettings(context),
                  ),
                ],
              ),
              
              // Live transcript display
              if (appState.config.continuousConversation && 
                  appState.currentTranscript.isNotEmpty)
                _buildTranscriptDisplay(context, appState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : inactiveColor,
              boxShadow: isActive ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ] : null,
            ),
          ),
          Icon(
            icon,
            size: 20,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptDisplay(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Transcript',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.currentTranscript,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Show settings panel in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Sheet handle indicator
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Settings content
                const SettingsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}