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
    required this.quantityInStock
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
  _InvoiceCreatorScreenState createState() => _InvoiceCreatorScreenState();
}

class _InvoiceCreatorScreenState extends State<InvoiceCreatorScreen> {
  final List<Contact> _contacts = [
    Contact(id: 1, name: "البنك الأهلي التجاري (عميل)", phone: "0501112223"),
    Contact(id: 2, name: "شركة التوريدات الرقمية (عميل آجل)", phone: "0559998887"),
    Contact(id: 3, name: "الشركة الوطنية للوجستيات (عميل)", phone: "0543334445"),
  ];

  final List<InventoryItem> _items = [
    InventoryItem(id: 101, name: "جهاز كمبيوتر محمول Intel i9", salePrice: 4500.0, purchasePrice: 3500.0, quantityInStock: 25),
    InventoryItem(id: 102, name: "شاشة عرض ذكية 4K OLED", salePrice: 3200.0, purchasePrice: 2400.0, quantityInStock: 15),
    InventoryItem(id: 103, name: "لوحة مفاتيح لاسلكية ميكانيكية", salePrice: 450.0, purchasePrice: 300.0, quantityInStock: 40),
  ];

  Contact? _selectedContact;
  String _paymentType = "CASH";
  double _discountPercent = 0.0;
  final double _taxRate = 15.0;

  final List<TempLineItem> _invoiceLines = [];

  InventoryItem? _selectedItemForAdd;
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _priceController = TextEditingController();

  double get _subtotal => _invoiceLines.fold(0.0, (sum, element) => sum + element.total);
  double get _discountAmount => _subtotal * (_discountPercent / 100.0);
  double get _taxableAmount => (_subtotal - _discountAmount) > 0.0 ? (_subtotal - _discountAmount) : 0.0;
  double get _taxAmount => _taxableAmount * (_taxRate / 100.0);
  double get _totalAmount => _taxableAmount + _taxAmount;

  double get _estimatedCOGS => _invoiceLines.fold(0.0, (sum, element) => sum + (element.quantity * element.item.purchasePrice));

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addInvoiceLine() {
    if (_selectedItemForAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار السلعة من المخزن أولاً!", textDirection: TextDirection.rtl))
      );
      return;
    }

    final int qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الكمية يجب أن تكون أكبر من الصفر", textDirection: TextDirection.rtl))
      );
      return;
    }

    if (qty > _selectedItemForAdd!.quantityInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الكمية المطلوبة تفوق مخزن المستودع الحالي (${_selectedItemForAdd!.quantityInStock})!", textDirection: TextDirection.rtl))
      );
      return;
    }

    final double price = double.tryParse(_priceController.text) ?? _selectedItemForAdd!.salePrice;

    setState(() {
      _invoiceLines.add(TempLineItem(
        item: _selectedItemForAdd!,
        quantity: qty,
        customPrice: price,
      ));
      _selectedItemForAdd = null;
      _qtyController.text = "1";
      _priceController.clear();
    });
  }

  void _submitInvoice() {
    if (_invoiceLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الفاتورة فارغة! أضف صنف واحد على الأقل.", textDirection: TextDirection.rtl))
      );
      return;
    }

    if (_paymentType == "CREDITOR" && _selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("للبيع الآجل، يرجى اختيار العميل من القائمة لتسجيل الذمم المباشرة!", textDirection: TextDirection.rtl))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الفاتورة والترحيل الآلي", textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("رقم الفاتورة: INV-${DateTime.now().millisecondsSinceEpoch ~/ 1000}", textAlign: TextAlign.right),
              Text("العميل: ${_selectedContact?.name ?? "عميل نقدي افتراضي"}", textAlign: TextAlign.right),
              Text("المبلغ الصافي: ${_totalAmount.toStringAsFixed(2)} ر.س", textAlign: TextAlign.right),
              const Divider(),
              const Text("القيد المحاسبي المزدوج التلقائي المقترح:", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
              const SizedBox(height: 8),
              _buildJournalLinePreview("قيد السيولة (مدين +)", _paymentType == "CASH" ? "1101 - الصندوق" : _paymentType == "BANK" ? "1102 - بنك الراجحي" : "1103 - حساب العملاء", _totalAmount, true),
              _buildJournalLinePreview("حساب المبيعات (دائن -)", "4101 - إيرادات المبيعات", _taxableAmount, false),
              if (_taxAmount > 0) _buildJournalLinePreview("الضرائب (دائن -)", "2101 - ضريبة القيمة المضافة المستحقة", _taxAmount, false),
              _buildJournalLinePreview("إثبات تكلفة البضاعة المباعة (مدين +)", "5101 - تكلفة البضاعة المباعة", _estimatedCOGS, true),
              _buildJournalLinePreview("أصل المخزن (دائن -)", "1104 - مخزن المستودع الرئيسي", _estimatedCOGS, false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("تعديل")
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _invoiceLines.clear();
                _selectedContact = null;
                _paymentType = "CASH";
                _discountPercent = 0.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم ترحيل الفاتورة وتناقص البضائع وتحديث الحسابات بنجاح!", textDirection: TextDirection.rtl))
              );
            },
            child: const Text("ترحيل وحفظ")
          )
        ],
      ),
    );
  }

  Widget _buildJournalLinePreview(String direction, String account, double amt, bool isDebit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${amt.toStringAsFixed(2)} ر.س", style: TextStyle(color: isDebit ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold)),
          Expanded(child: Text(account, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
          Text(isDebit ? "[مدين]" : "[دائن]", style: TextStyle(fontSize: 10, color: isDebit ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء فاتورة بيع جديدة", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. العميل والمحاسبة المالية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Contact>(
                        decoration: const InputDecoration(
                          labelText: "اختر العميل المستلم",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedContact,
                        items: _contacts.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedContact = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text("طريقة سداد الفاتورة:"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ChoiceChip(
                            label: const Text("نقدي (الصندوق)"),
                            selected: _paymentType == "CASH",
                            onSelected: (val) {
                              if (val) setState(() => _paymentType = "CASH");
                            },
                          ),
                          ChoiceChip(
                            label: const Text("بنكي (الراجحي)"),
                            selected: _paymentType == "BANK",
                            onSelected: (val) {
                              if (val) setState(() => _paymentType = "BANK");
                            },
                          ),
                          ChoiceChip(
                            label: const Text("آجل (ذمم مدينون)"),
                            selected: _paymentType == "CREDITOR",
                            onSelected: (val) {
                              if (val) setState(() => _paymentType = "CREDITOR");
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("2. تداول ومبيعات السلع البضائعية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<InventoryItem>(
                        decoration: const InputDecoration(
                          labelText: "اختر صنف المخزن",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedItemForAdd,
                        items: _items.map((it) => DropdownMenuItem(
                          value: it,
                          child: Text("${it.name} (المتوفر: ${it.quantityInStock} وحدة)"),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedItemForAdd = val;
                            if (val != null) {
                              _priceController.text = val.salePrice.toString();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _qtyController,
                              decoration: const InputDecoration(labelText: "الكمية المطلوبة", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: "سعر البيع المقترح", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.teal,
                        ),
                        onPressed: _addInvoiceLine,
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                        label: const Text("إدراج الصنف في الفاتورة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_invoiceLines.isNotEmpty) ...[
                const Text("الأصناف والخدمات في الفاتورة الحالية:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoiceLines.length,
                  itemBuilder: (context, index) {
                    final line = _invoiceLines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(line.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("الكمية: ${line.quantity} × ${line.customPrice.toStringAsFixed(2)} ر.س"),
                        trailing: Text(
                          "${line.total.toStringAsFixed(2)} ر.س",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800]),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _invoiceLines.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              Card(
                elevation: 3,
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("إجمالي السعر قبل الضريبة:"),
                          Text("${_subtotal.toStringAsFixed(2)} ر.س"),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Text("الخصم التجاري الممنوح:"),
                          Expanded(
                            child: Slider(
                              value: _discountPercent,
                              min: 0,
                              max: 50,
                              divisions: 10,
                              label: "%${_discountPercent.toInt()}",
                              onChanged: (val) {
                                setState(() {
                                  _discountPercent = val;
                                });
                              },
                            ),
                          ),
                          Text("%${_discountPercent.toInt()}"),
                        ],
                      ),
                      const Divider(),
                      _buildSummaryRow("قيمة الخصم التجاري", "- ${_discountAmount.toStringAsFixed(2)} ر.س"),
                      _buildSummaryRow("الوعاء المالي الخاضع للضريبة", "${_taxableAmount.toStringAsFixed(2)} ر.س"),
                      _buildSummaryRow("ضريبة القيمة المضافة (15% VAT)", "${_taxAmount.toStringAsFixed(2)} ر.س"),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("الصافي المستحق والمرحل محاسبياً:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          Text("${_totalAmount.toStringAsFixed(2)} ر.س", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: Colors.teal[800],
                ),
                onPressed: _submitInvoice,
                child: const Text("ترحيل وحفظ المستند المالي للدفاتر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}