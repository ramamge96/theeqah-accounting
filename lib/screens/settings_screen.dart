import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionCard(theme: theme, icon: Icons.business_rounded, title: 'معلومات الشركة', children: [
                    _buildTextField(label: 'اسم الشركة', initialValue: settings.companyName, onSaved: (v) => provider.updateCompanyName(v)),
                    _buildTextField(label: 'رقم الهاتف', initialValue: settings.phoneNumber, onSaved: (v) => provider.updatePhoneNumber(v)),
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('رفع الشعار'),
                      subtitle: Text(settings.logoPath ?? 'لم يتم رفع شعار بعد'),
                      trailing: const Icon(Icons.upload),
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(theme: theme, icon: Icons.receipt_long_rounded, title: 'إعدادات الفواتير والسندات', children: [
                    _buildTextField(label: 'العملة الافتراضية', initialValue: settings.defaultCurrency, onSaved: (v) { settings.defaultCurrency = v ?? 'SAR'; provider.saveSettings(settings); }),
                    _buildTextField(label: 'نسبة الضريبة الافتراضية (%)', initialValue: settings.defaultTaxRate.toString(), keyboardType: TextInputType.number, onSaved: (v) => provider.updateTaxRate(double.tryParse(v ?? '15') ?? 15.0)),
                    _buildTextField(label: 'بادئة رقم الفاتورة', initialValue: settings.invoicePrefix, onSaved: (v) => provider.updateInvoicePrefix(v)),
                    SwitchListTile(title: const Text('إظهار ترويسة الفاتورة'), value: settings.showHeaderOnInvoice, onChanged: (v) { settings.showHeaderOnInvoice = v; provider.saveSettings(settings); }),
                    SwitchListTile(title: const Text('إظهار تذييل الفاتورة'), value: settings.showFooterOnInvoice, onChanged: (v) { settings.showFooterOnInvoice = v; provider.saveSettings(settings); }),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(theme: theme, icon: Icons.lock_rounded, title: 'الأمان', children: [
                    _buildTextField(label: 'كلمة السر الجديدة', obscureText: true, onSaved: (v) => provider.updatePassword(v)),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(theme: theme, icon: Icons.backup_rounded, title: 'النسخ الاحتياطي واستعادة البيانات', children: [
                    ListTile(leading: const Icon(Icons.cloud_upload), title: const Text('إنشاء نسخة احتياطية'), subtitle: const Text('حفظ قاعدة البيانات في ملف'), onTap: () {}),
                    ListTile(leading: const Icon(Icons.cloud_download), title: const Text('استعادة نسخة احتياطية'), subtitle: const Text('تحميل قاعدة بيانات من ملف'), onTap: () {}),
                  ]),
                  const SizedBox(height: 12),
                  _buildSectionCard(theme: theme, icon: Icons.print_rounded, title: 'الطباعة والمشاركة', children: [
                    DropdownButtonFormField<String>(
                      value: settings.paperSize,
                      decoration: const InputDecoration(labelText: 'حجم الورق', border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'A4', child: Text('A4')), DropdownMenuItem(value: 'Letter', child: Text('Letter'))],
                      onChanged: (v) { if (v != null) { settings.paperSize = v; provider.saveSettings(settings); } },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: settings.exportFormat,
                      decoration: const InputDecoration(labelText: 'صيغة التصدير', border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: 'PDF', child: Text('PDF')), DropdownMenuItem(value: 'Image', child: Text('صورة'))],
                      onChanged: (v) { if (v != null) { settings.exportFormat = v; provider.saveSettings(settings); } },
                    ),
                  ]),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionCard({required ThemeData theme, required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: theme.colorScheme.primary, size: 22), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.primary))]),
          const Divider(),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildTextField({required String label, String? initialValue, bool obscureText = false, TextInputType? keyboardType, required void Function(String?) onSaved}) {
    final controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller, obscureText: obscureText, keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        onEditingComplete: () => onSaved(controller.text),
      ),
    );
  }
}