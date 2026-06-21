import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/invoice.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      final provider = context.read<DashboardProvider>();
      await provider.loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم المالية والتحليلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          elevation: 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'الإعدادات',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل البيانات...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            if (_hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('تعذر تحميل البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_errorMessage.isEmpty ? 'خطأ غير معروف' : _errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(theme),
                    const SizedBox(height: 16),
                    _buildQuickActions(context, theme),
                    const SizedBox(height: 16),
                    _buildKPIsGrid(provider, theme),
                    const SizedBox(height: 24),
                    _buildRevenueBarChart(provider, theme),
                    const SizedBox(height: 24),
                    _buildRecentInvoicesList(provider, theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_rounded, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('التقرير المالي اللحظي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 4),
        Text('متابعة شاملة للميزانية العمومية والتدفقات النقدية.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: [
        _quickCard(Icons.payments_outlined, 'سند قبض', Colors.green),
        _quickCard(Icons.receipt_outlined, 'سند صرف', Colors.red),
        _quickCard(Icons.shopping_cart_outlined, 'فاتورة بيع', Colors.blue),
        _quickCard(Icons.add_shopping_cart_outlined, 'فاتورة شراء', Colors.orange),
      ],
    );
  }

  Widget _quickCard(IconData icon, String label, Color color) {
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIsGrid(DashboardProvider provider, ThemeData theme) {
    final assets = provider.totalAssets;
    final liabilities = provider.totalLiabilities;
    final equity = provider.totalEquity;
    final profit = provider.netProfitOrLoss;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _kpi('الأصول', assets),
        _kpi('الخصوم', liabilities),
        _kpi('الملكية', equity),
        _kpi('صافي الربح', profit),
      ],
    );
  }

  Widget _kpi(String title, double? value) {
    final safeValue = value ?? 0.0;
    return Card(
      child: Center(
        child: Text('$title\n${safeValue.toStringAsFixed(2)}', textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildRevenueBarChart(DashboardProvider provider, ThemeData theme) {
    final monthlyData = [
      {'month': 'يناير', 'revenue': 0.0},
      {'month': 'فبراير', 'revenue': 0.0},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('تحليل الإيرادات', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('عدد الأشهر: ${monthlyData.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoicesList(DashboardProvider provider, ThemeData theme) {
    final List<Invoice> list = provider.lastInvoices;

    if (list.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('لا توجد فواتير')),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final invoice = list[index];
        final contactName = provider.contactNames[invoice.contactId] ?? 'عميل غير معروف';

        return ListTile(
          title: Text(invoice.invoiceNumber),
          subtitle: Text(contactName),
          trailing: Text(invoice.totalAmount.toStringAsFixed(2)),
        );
      },
    );
  }
}