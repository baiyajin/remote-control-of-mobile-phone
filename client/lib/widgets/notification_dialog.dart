import 'package:flutter/material.dart';

class NotificationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? action;
  final Function(bool)? onResponse;

  const NotificationDialog({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onResponse,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? action,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationDialog(
        title: title,
        message: message,
        action: action,
        onResponse: (accepted) {
          Navigator.of(context).pop(accepted);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (action == 'accept')
          TextButton(
            onPressed: () {
              onResponse?.call(false);
              Navigator.of(context).pop(false);
            },
            child: const Text('拒绝'),
          ),
        TextButton(
          onPressed: () {
            onResponse?.call(action == 'accept');
            Navigator.of(context).pop(action == 'accept');
          },
          child: Text(action == 'accept' ? '接受' : '确定'),
        ),
      ],
    );
  }
}

