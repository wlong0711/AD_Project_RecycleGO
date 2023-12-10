import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVoucherPage extends StatefulWidget {
  const AddVoucherPage({super.key});

  @override
  _AddVoucherPageState createState() => _AddVoucherPageState();
}

class _AddVoucherPageState extends State<AddVoucherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _voucherIDController = TextEditingController();
  final TextEditingController _voucherNameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _voucherIDController.dispose();
    _voucherNameController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addVoucher() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('vouchers').add({
          'voucherID': _voucherIDController.text.trim(),
          'voucherName': _voucherNameController.text.trim(),
          'expiredDate': _selectedDate,
        });
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
              content: Text('Voucher added successfully!'),
              backgroundColor: Colors.green, 
            ),
        );
        _voucherIDController.clear();
        _voucherNameController.clear();
        setState(() {
          _selectedDate = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add voucher: $e'),
             backgroundColor: Colors.red,
            ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
              TextFormField(
                controller: _voucherIDController,
                decoration: const InputDecoration(labelText: 'Voucher ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter voucher ID';
                  }
                  return null;
                },
              ),
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
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Pick Expiry Date'
                    : 'Expiry Date: ${_selectedDate!.toLocal()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
