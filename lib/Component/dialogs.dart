import 'package:flutter/material.dart';

void showSuccessDialog(BuildContext context, String message, VoidCallback onConfirm) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Icon(Icons.check_circle_outline, color: Colors.green, size: 75,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Success!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            const SizedBox(height: 15),
            Text(message),
          ],
        ),
        actions: <Widget>[
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                onConfirm(); // Execute the callback
              },
            ),
          ),
        ],
      );
    },
  );
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Icon(Icons.error_outline, color: Colors.red, size: 75,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Error!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            const SizedBox(height: 15),
            Text(message),
          ],
        ),
        actions: <Widget>[
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ],
      );
    },
  );
}
