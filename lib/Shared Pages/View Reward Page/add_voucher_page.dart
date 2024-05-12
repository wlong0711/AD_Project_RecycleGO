import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddVoucherPage extends StatefulWidget {
  final Function onVoucherAdded;

  const AddVoucherPage({super.key, required this.onVoucherAdded});

  @override
  _AddVoucherPageState createState() => _AddVoucherPageState();
}

class _AddVoucherPageState extends State<AddVoucherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _voucherIDController = TextEditingController();
  final TextEditingController _voucherNameController = TextEditingController();
  final TextEditingController _pointsNeededController = TextEditingController();
  DateTime? _selectedDate;
  String docId = "auYgaoMqo6x8BWNncTnj";
  String _nextVoucherId = '';
  StreamSubscription? _subscription;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _voucherIDController.dispose();
    _voucherNameController.dispose();
    _pointsNeededController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupVoucherIdListener();
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _selectedDate = finalDateTime;
        });
      }
    }
  }

  void _addVoucher() async {
    if (_formKey.currentState!.validate()) {

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please pick an expiry date and time.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Return early if no date has been selected
      }

      setState(() {
        _isSubmitting = true; // Start the loading indicator
      });

      try {
        // Start a Firestore transaction
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Your transaction code here...
          // Extracted from your provided snippet
          final DocumentReference counterRef = FirebaseFirestore.instance.collection('counters').doc(docId);
          DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
          int lastVoucherId = counterSnapshot.exists ? int.parse(counterSnapshot.get('lastVoucherId') as String) + 1 : 1;
          DocumentReference newVoucherRef = FirebaseFirestore.instance.collection('vouchers').doc();

          transaction.set(newVoucherRef, {
            'voucherID': 'V${lastVoucherId.toString().padLeft(4, '0')}',
            'voucherName': _voucherNameController.text.trim(),
            'pointsNeeded': int.parse(_pointsNeededController.text.trim()),
            'expiredDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          });

          transaction.update(counterRef, {'lastVoucherId': lastVoucherId.toString()});
        });

        // If the transaction completes successfully
        widget.onVoucherAdded(); // Invoke the callback
        Navigator.of(context).pop(); // Navigate back to the previous screen
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add voucher: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false; // Stop the loading indicator
        });
      }
    }
  }

  void _setupVoucherIdListener() {
    _subscription = FirebaseFirestore.instance.collection('counters').doc(docId)
      .snapshots().listen((snapshot) {
        if (mounted) { // Check if the state is still mounted
          if (snapshot.exists && snapshot.data()!.containsKey('lastVoucherId')) {
            String lastId = snapshot.get('lastVoucherId') as String;
            int nextId = int.parse(lastId) + 1;
            setState(() {
              _nextVoucherId = 'V${nextId.toString().padLeft(4, '0')}';
            });
          }
        }
    });
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        // Full screen semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5), // Semi-transparent grey color
          ),
        ),
        // Centered loading indicator
        Center(
          child: Container(
            width: 80, // Set the width of the overlay
            height: 80, // Set the height of the overlay
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // Semi-transparent black for the loading box
              borderRadius: BorderRadius.circular(10), // Rounded corners for the loading box
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
            onPressed: () => Navigator.of(context).pop(), // Go back on press
          ),
          title: const Text(
                  'Add Voucher',
                  style: TextStyle(color: Colors.white),
                ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            elevation: 10,
            shadowColor: Colors.greenAccent.withOpacity(0.5),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _addVoucher,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 10,),
                  Container(
                    padding: const EdgeInsets.all(8), // Add some padding inside the container
                    decoration: BoxDecoration(
                      color: Colors.green, // Background color of the box
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Use the minimum space that is needed by the child widgets
                      children: <Widget>[
                        const Icon(
                          Icons.discount, // The icon
                          color: Colors.white, // Icon color
                        ),
                        const SizedBox(width: 8), // A sized box for spacing
                        Text(
                          'Voucher ID: $_nextVoucherId', // The text
                          style: const TextStyle(
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold, // Make the text bold
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10,),
                  TextFormField(
                    controller: _voucherNameController,
                    decoration: const InputDecoration(labelText: 'Voucher Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter voucher name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _pointsNeededController,
                    decoration: const InputDecoration(labelText: 'Points Needed'),
                    keyboardType: TextInputType.number, // Ensure numeric input
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the points needed';
                      }
                      if(int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  ListTile(
                    title: Text(_selectedDate == null
                        ? 'Pick Expiry Date and Time'
                        : 'Expiry Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDate!.toLocal())}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: _buildLoadingOverlay(),
            ),
          ),
      ],
    );
  }
}