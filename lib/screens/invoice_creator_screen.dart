import 'package:flutter/material.dart';

class Contact {
  final int id;
  final String name;
  final String phone;
  Contact({required this.id, required this.name, required this.phone});
}

class InventoryItem {
  final int id;
  final String name;
  final double salePrice;
  final double purchasePrice;
  int quantityInStock;
  InventoryItem({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.purchasePrice,
    required this.quantityInStock,
  });
}

class TempLineItem {
  final InventoryItem item;
  int quantity;
  double customPrice;
  TempLineItem({required this.item, required this.quantity, required this.customPrice});
  double get total => quantity * customPrice;
}

class InvoiceCreatorScreen extends StatefulWidget {
  const InvoiceCreatorScreen({Key? key}) : super(key: key);
  @override
  State<InvoiceCreatorScreen> createState() => _InvoiceCreatorScreenState();
}

class _InvoiceCreatorScreenState extends State<InvoiceCreatorScreen> {
  final List<Contact> _contacts = [
    Contact(id: 1, name: "البنك الأهلي التجاري (عميل)", phone: "0501112223"),
    Contact(id: 2, name: "شركة التوريدات الرقمية", phone: "0559998887"),
    Contact(id: 3, name: "الشركة الوطنية", phone: "0543334445"),
  ];

  final List<InventoryItem> _items = [
    InventoryItem(id: 101, name: "جهاز كمبيوتر محمول", salePrice: 4500, purchasePrice: 3500, quantityInStock: 25),
    InventoryItem(id: 102, name: "شاشة عرض", salePrice: 3200, purchasePrice: 2400, quantityInStock: 15),
  ];

  Contact? _selectedContact;
  InventoryItem? _selectedItemForAdd;
  String _paymentType = "CASH";
  double _discountPercent = 0;
  final double _taxRate = 15;
  final List<TempLineItem> _invoiceLines = [];
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _priceController = TextEditingController();

  double get _subtotal => _invoiceLines.fold(0.0, (sum, item) => sum + item.total);
  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _taxableAmount {
    final value = _subtotal - _discountAmount;
    return value > 0 ? value : 0;
  }
  double get _taxAmount => _taxableAmount * (_taxRate / 100);
  double get _totalAmount => _taxableAmount + _taxAmount;
  double get _estimatedCOGS => _invoiceLines.fold(0.0, (sum, item) => sum + (item.quantity * item.item.purchasePrice));

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, textDirection: TextDirection.rtl)));
  }

  void _addInvoiceLine() {
    final selectedItem = _selectedItemForAdd;
    if (selectedItem == null) { _showSnack("اختر الصنف أولاً"); return; }
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) { _showSnack("الكمية يجب أن تكون أكبر من صفر"); return; }
    if (qty > selectedItem.quantityInStock) { _showSnack("الكمية أكبر من المخزون"); return; }
    final price = double.tryParse(_priceController.text) ?? selectedItem.salePrice;
    if (!mounted) return;
    setState(() {
      _invoiceLines.add(TempLineItem(item: selectedItem, quantity: qty, customPrice: price));
      _selectedItemForAdd = null;
      _qtyController.text = "1";
      _priceController.clear();
    });
  }

  void _submitInvoice() {
    if (_invoiceLines.isEmpty) { _showSnack("الفاتورة فارغة"); return; }
    if (_paymentType == "CREDITOR" && _selectedContact == null) { _showSnack("اختر العميل للبيع الآجل"); return; }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("تأكيد الفاتورة", textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("الإجمالي: ${_totalAmount.toStringAsFixed(2)}"),
                const Divider(),
                _buildJournalLinePreview("السيولة", "1101", _totalAmount, true),
                _buildJournalLinePreview("المبيعات", "4101", _taxableAmount, false),
                if (_taxAmount > 0) _buildJournalLinePreview("الضريبة", "2101", _taxAmount, false),
                _buildJournalLinePreview("تكلفة البضاعة", "5101", _estimatedCOGS, true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {
                  _invoiceLines.clear();
                  _selectedContact = null;
                  _selectedItemForAdd = null;
                  _paymentType = "CASH";
                  _discountPercent = 0;
                  _qtyController.text = "1";
                  _priceController.clear();
                });
                _showSnack("تم حفظ الفاتورة");
              },
              child: const Text("حفظ"),
            )
          ],
        );
      },
    );
  }

  Widget _buildJournalLinePreview(String direction, String account, double amt, bool isDebit) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(color: Colors.grey.shade100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(amt.toStringAsFixed(2), style: TextStyle(color: isDebit ? Colors.green : Colors.red)),
          Text(account),
          Text(isDebit ? "مدين" : "دائن"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء فاتورة"), backgroundColor: Colors.teal),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<Contact>(
                value: _contacts.contains(_selectedContact) ? _selectedContact : null,
                decoration: const InputDecoration(labelText: "العميل", border: OutlineInputBorder()),
                items: _contacts.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) { if (!mounted) return; setState(() { _selectedContact = v; }); },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<InventoryItem>(
                value: _items.contains(_selectedItemForAdd) ? _selectedItemForAdd : null,
                decoration: const InputDecoration(labelText: "الصنف", border: OutlineInputBorder()),
                items: _items.map((item) => DropdownMenuItem(value: item, child: Text("${item.name} (${item.quantityInStock})"))).toList(),
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() {
                    _selectedItemForAdd = v;
                    if (v != null) { _priceController.text = v.salePrice.toString(); } else { _priceController.clear(); }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "الكمية", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              ElevatedButton(onPressed: _addInvoiceLine, child: const Text("إضافة صنف")),
              const SizedBox(height: 20),
              if (_invoiceLines.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoiceLines.length,
                  itemBuilder: (context, index) {
                    final line = _invoiceLines[index];
                    return ListTile(
                      title: Text(line.item.name),
                      subtitle: Text("${line.quantity} × ${line.customPrice}"),
                      trailing: Text(line.total.toStringAsFixed(2)),
                    );
                  },
                ),
              const SizedBox(height: 20),
              _buildSummaryRow("Subtotal", _subtotal.toStringAsFixed(2)),
              _buildSummaryRow("Discount", _discountAmount.toStringAsFixed(2)),
              _buildSummaryRow("Tax", _taxAmount.toStringAsFixed(2)),
              _buildSummaryRow("Total", _totalAmount.toStringAsFixed(2)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitInvoice, child: const Text("حفظ الفاتورة")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value)]),
    );
  }
}