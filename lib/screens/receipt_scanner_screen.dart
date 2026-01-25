import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt_scan_result.dart';
import '../models/transaction.dart';
import '../services/receipt_scanner_service.dart';
import '../utils/constants.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final Function(Transaction) onSave;

  const ReceiptScannerScreen({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ReceiptScannerService _scannerService = ReceiptScannerService();
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  ReceiptScanResult? _scanResult;
  bool _typeOverridden = false;

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _taxController;
  late TextEditingController _notesController;
  late TextEditingController _currencyController;
  late TextEditingController _paymentMethodController;

  String _type = 'expense';
  String _category = AppConstants.expenseCategories.first;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();
    _taxController = TextEditingController();
    _notesController = TextEditingController();
    _currencyController = TextEditingController(text: 'PKR');
    _paymentMethodController = TextEditingController();
    _currencyController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    _currencyController.dispose();
    _paymentMethodController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return _type == 'expense'
        ? AppConstants.expenseCategories
        : AppConstants.incomeCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),
        title: Text(
          'Scan Receipt',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : _scanResult == null
              ? _buildScanOptionsView()
              : _buildReviewView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1B998B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFF1B998B)),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Processing Receipt...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Extracting information using OCR',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOptionsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B998B),
                    const Color(0xFF14786C),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B998B).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Scan Your Receipt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Use camera, gallery, or PDF to\nextract transaction details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 50),
            _buildScanButton(
              'Take Photo',
              Icons.camera_alt_rounded,
              Colors.blue,
              _scanFromCamera,
            ),
            const SizedBox(height: 15),
            _buildScanButton(
              'Choose from Gallery',
              Icons.photo_library_rounded,
              const Color(0xFF1B998B),
              _scanFromGallery,
            ),
            const SizedBox(height: 15),
            _buildScanButton(
              'Import PDF',
              Icons.picture_as_pdf_rounded,
              Colors.deepPurple,
              _scanFromPdf,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewView() {
    final result = _scanResult!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + bottomInset + 24,
        ),
        children: [
          if (result.receiptImagePath != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(result.receiptImagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (result.hasError) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.error ?? 'Scan had issues, please review fields.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildSectionCard(
            title: 'Classification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto classified as ${result.type.toUpperCase()} (${result.classificationReason})',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Income',
                        value: 'income',
                        icon: Icons.arrow_downward_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Expense',
                        value: 'expense',
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Merchant / Payer',
            child: TextFormField(
              controller: _merchantController,
              decoration: InputDecoration(
                hintText: 'Enter merchant or payer',
                prefixIcon: Icon(Icons.store_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a merchant or payer';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Amount',
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _type == 'income' ? Colors.green : Colors.red,
              ),
              decoration: InputDecoration(
                prefixText: '${_currencyController.text} ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Tax (Optional)',
            child: TextFormField(
              controller: _taxController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${_currencyController.text} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Currency',
            child: TextFormField(
              controller: _currencyController,
              decoration: InputDecoration(
                hintText: 'PKR, USD, EUR...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Payment Method (Optional)',
            child: TextFormField(
              controller: _paymentMethodController,
              decoration: InputDecoration(
                hintText: 'Cash, Visa, Bank Transfer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Category',
            child: DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Date & Time',
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: const Color(0xFF1B998B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: const Color(0xFF1B998B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: 'Notes (Optional)',
            child: TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B998B),
                  const Color(0xFF14786C),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B998B).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Save Transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = value;
          _typeOverridden = true;
          _category = _categories.first;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF4F7F8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    setState(() => _isProcessing = true);
    final result = await _scannerService.scanReceiptFromCamera();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result == null) return;
    _applyScanResult(result);
  }

  Future<void> _scanFromGallery() async {
    setState(() => _isProcessing = true);
    final result = await _scannerService.scanReceiptFromGallery();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result == null) return;
    _applyScanResult(result);
  }

  Future<void> _scanFromPdf() async {
    setState(() => _isProcessing = true);
    final result = await _scannerService.scanReceiptFromPdf();
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (result == null) return;
    _applyScanResult(result);
  }

  void _applyScanResult(ReceiptScanResult result) {
    setState(() {
      _scanResult = result;
      _type = result.type;
      _typeOverridden = false;
      _category = _categories.first;
      _merchantController.text = result.merchant;
      _amountController.text = result.total == 0 ? '' : result.total.toString();
      _taxController.text = result.tax == null ? '' : result.tax.toString();
      _currencyController.text = result.currency;
      _paymentMethodController.text = result.paymentMethod ?? '';
      _selectedDate = result.date;
      _selectedTime = TimeOfDay.fromDateTime(result.date);
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1B998B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1B998B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final amount = double.parse(_amountController.text);
    final taxValue = _taxController.text.isEmpty
        ? null
        : double.tryParse(_taxController.text);

    final reason = _typeOverridden && _scanResult != null
        ? 'manual override (auto: ${_scanResult!.type})'
        : (_scanResult?.classificationReason ?? 'manual entry');

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _merchantController.text,
      merchant: _merchantController.text,
      amount: amount,
      tax: taxValue,
      currency: _currencyController.text,
      paymentMethod: _paymentMethodController.text.isEmpty
          ? null
          : _paymentMethodController.text,
      category: _category,
      type: _type,
      date: dateTime,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      receiptImagePath: _scanResult?.receiptImagePath,
      receiptFilePath: _scanResult?.receiptFilePath,
      receiptSource: _scanResult?.receiptSource,
      rawText: _scanResult?.rawText,
      classificationReason: reason,
    );

    widget.onSave(transaction);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Transaction saved from receipt!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}


