import 'package:flutter/material.dart';

/// Placeholder until the Messaging feature owns this branch.
class AdminMessagesPlaceholderScreen extends StatelessWidget {
  const AdminMessagesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Messages — admin\n(owned by Messaging feature)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
