import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({Key? key}) : super(key: key);

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final Set<String> _expandedAccountCodes = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expandedAccountCodes.addAll(['1', '11', '2', '21']);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasChildren(Account account, List<Account> allAccounts) {
    return allAccounts.any((acc) => acc.parentCode == account.accountCode);
  }

  List<Account> _buildHierarchicalList(List<Account> allAccounts, List<Account> filteredSource) {
    List<Account> visibleAccounts = [];
    Set<String> requiredParentCodes = {};

    for (var acc in filteredSource) {
      if (acc.parentCode != null && acc.parentCode!.isNotEmpty) {
        requiredParentCodes.add(acc.parentCode!);
      }
    }

    List<Account> extendedSource = List.from(filteredSource);
    for (var code in requiredParentCodes) {
      if (!extendedSource.any((acc) => acc.accountCode == code)) {
        final parent = allAccounts.firstWhere(
          (acc) => acc.accountCode == code,
          orElse: () => Account(
            accountCode: code,
            nameAr: '',
            nameEn: '',
            accountType: 'ASSET',
            isDebitNormal: true,
          ),
        );
        if (parent.nameAr.isNotEmpty) {
          extendedSource.add(parent);
        }
      }
    }

    List<Account> roots = extendedSource.where((acc) => acc.parentCode == null).toList();
    for (var root in roots) {
      _addAccountAndChildren(root, allAccounts, extendedSource, visibleAccounts);
    }

    return visibleAccounts;
  }

  void _addAccountAndChildren(
    Account current,
    List<Account> all,
    List<Account> filteredSource,
    List<Account> output,
  ) {
    output.add(current);

    if (_expandedAccountCodes.contains(current.accountCode)) {
      List<Account> children = all.where((acc) => acc.parentCode == current.accountCode).toList();
      children.sort((a, b) => a.accountCode.compareTo(b.accountCode));

      for (var child in children) {
        _addAccountAndChildren(child, all, filteredSource, output);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دليل الحسابات التفاعلي المزدوج (COA)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AccountsProvider>().loadAccounts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث دليل الحسابات')),
                );
              },
            ),
          ],
        ),
        body: Consumer<AccountsProvider>(
          builder: (context, provider, child) {
            final allAccounts = provider.accounts;
            final filteredSource = provider.filteredAccounts;
            final treeList = _buildHierarchicalList(allAccounts, filteredSource);

            return Column(
              children: [
                _buildSearchBar(provider, theme),
                _buildFilterChips(provider, theme),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : treeList.isEmpty
                          ? _buildEmptyState(theme)
                          : ListView.builder(
                              itemCount: treeList.length,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              itemBuilder: (context, index) {
                                final account = treeList[index];
                                final hasSubAccounts = _hasChildren(account, allAccounts);
                                final isExpanded = _expandedAccountCodes.contains(account.accountCode);

                                return _buildAccountTreeCard(
                                  account: account,
                                  hasChildren: hasSubAccounts,
                                  isExpanded: isExpanded,
                                  theme: theme,
                                  onToggle: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedAccountCodes.remove(account.accountCode);
                                      } else {
                                        _expandedAccountCodes.add(account.accountCode);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('إضافة حساب جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddAccountSheet(context, theme),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AccountsProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'ابحث برقم الحساب أو اسم الحساب...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AccountsProvider provider, ThemeData theme) {
    final filters = [
      {'label': 'الكل', 'value': null},
      {'label': 'أصول', 'value': 'ASSET'},
      {'label': 'خصوم', 'value': 'LIABILITY'},
      {'label': 'حقوق ملكية', 'value': 'EQUITY'},
      {'label': 'إيرادات', 'value': 'REVENUE'},
      {'label': 'مصروفات', 'value': 'EXPENSE'},
    ];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = provider.selectedTypeFilter == filter['value'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              onSelected: (selected) {
                provider.setTypeFilter(selected ? (filter['value'] as String?) : null);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountTreeCard({
    required Account account,
    required bool hasChildren,
    required bool isExpanded,
    required ThemeData theme,
    required VoidCallback onToggle,
  }) {
    final Color balanceColor = account.isDebitNormal ? Colors.green[700]! : theme.colorScheme.primary;
    final int indentLevel = account.level - 1;

    return Padding(
      padding: EdgeInsets.only(
        right: (indentLevel * 16.0).clamp(0.0, 80.0),
        top: 2,
        bottom: 2,
      ),
      child: Card(
        elevation: indentLevel == 0 ? 3 : 1,
        color: indentLevel == 0
            ? theme.colorScheme.primaryContainer.withOpacity(0.15)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: indentLevel == 0
              ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1)
              : BorderSide(color: theme.colorScheme.outline.withOpacity(0.08)),
        ),
        child: InkWell(
          onTap: hasChildren ? onToggle : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_left,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onToggle,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 12.0, right: 12.0),
                    child: Icon(Icons.subdirectory_arrow_left, size: 14, color: Colors.grey),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account.nameAr,
                            style: TextStyle(
                              fontWeight: indentLevel == 0 ? FontWeight.extrabold : FontWeight.bold,
                              fontSize: indentLevel == 0 ? 15 : 13.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (indentLevel == 0)
                            Badge(
                              label: Text(
                                _getTranslatedType(account.accountType),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: _getAccountTypeColor(account.accountType, theme),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'كود: ${account.accountCode} | طبيعة: ${account.isDebitNormal ? 'مدين 🟢' : 'دائن 🔴'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${account.balance.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: balanceColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      indentLevel == 0 ? 'رصيد إجمالي' : 'رصيد فرعي',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, ThemeData theme) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    String nameAr = '';
    String nameEn = '';
    String type = 'ASSET';
    bool isDebitNormal = true;
    double balance = 0.0;
    String? parentCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allAccounts = context.read<AccountsProvider>().accounts;
            final possibleParents = allAccounts.where((acc) => acc.level < 4).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'تعريف حساب مالي جديد بالدليل اليومي',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'الحساب الرئيسي (الأب)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_tree),
                          ),
                          value: parentCode,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('بدون أب (مستوى رئيسي أول)'),
                            ),
                            ...possibleParents.map((parent) {
                              return DropdownMenuItem(
                                value: parent.accountCode,
                                child: Text('[${parent.accountCode}] ${parent.nameAr}'),
                              );
                            }).toList()
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              parentCode = val;
                              if (val != null) {
                                final parent = allAccounts.firstWhere((acc) => acc.accountCode == val);
                                type = parent.accountType;
                                isDebitNormal = parent.isDebitNormal;
                                final siblingsCount = allAccounts.where((acc) => acc.parentCode == val).length;
                                final newCode = '$val${(siblingsCount + 1).toString().padLeft(2, '0')}';
                                codeController.text = newCode;
                              } else {
                                codeController.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'رقم الحساب المالي (الكود)',
                            hintText: 'مثال: 1105 أو 2103',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال رقم الحساب المالي';
                            }
                            if (allAccounts.any((acc) => acc.accountCode == value.trim())) {
                              return 'هذا الكود مسجل مسبقاً لحساب آخر!';
                            }
                            return null;
                          },
                          onSaved: (value) {},
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'اسم الحساب المالي (باللغة العربية)',
                            hintText: 'مثال: صندوق الفواتير الإضافي',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى كتابة الاسم العربي للحساب';
                            }
                            return null;
                          },
                          onSaved: (value) => nameAr = value!.trim(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'اسم الحساب باللغة الإنجليزية (اختياري)',
                            hintText: 'Example: Cash Drawer Two',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          onSaved: (value) => nameEn = value ?? '',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'نوع التصنيف الأساسي',
                            border: OutlineInputBorder(),
                          ),
                          value: type,
                          items: const [
                            DropdownMenuItem(value: 'ASSET', child: Text('أصول (Assets)')),
                            DropdownMenuItem(value: 'LIABILITY', child: Text('خصوم (Liabilities)')),
                            DropdownMenuItem(value: 'EQUITY', child: Text('حقوق الملكية (Equity)')),
                            DropdownMenuItem(value: 'REVENUE', child: Text('الإيرادات (Revenue)')),
                            DropdownMenuItem(value: 'EXPENSE', child: Text('المصروفات (Expense)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                type = val;
                                isDebitNormal = (val == 'ASSET' || val == 'EXPENSE');
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('طبيعة الحساب الافتراضية:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                const Text('دائن 🔴'),
                                Switch(
                                  value: isDebitNormal,
                                  onChanged: (val) {
                                    setModalState(() {
                                      isDebitNormal = val;
                                    });
                                  },
                                ),
                                const Text('مدين 🟢'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'الرصيد الافتتاحي (ر.س)',
                            hintText: '0.0',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monetization_on),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => balance = double.tryParse(value ?? '0') ?? 0.0,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    final code = codeController.text.trim();

                                    final success = await context.read<AccountsProvider>().addNewAccount(
                                      code: code,
                                      nameAr: nameAr,
                                      nameEn: nameEn,
                                      type: type,
                                      isDebitNormal: isDebitNormal,
                                      initialBalance: balance,
                                      parentCode: parentCode,
                                    );

                                    if (success) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تمت إضافة حساب ( $nameAr ) بنجاح!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('حدث خطأ أثناء حفظ معلومات الحساب')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('حفظ وربط الحساب ماليّاً', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getAccountTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'ASSET': return Colors.green[600]!;
      case 'LIABILITY': return Colors.red[600]!;
      case 'EQUITY': return Colors.orange[700]!;
      case 'REVENUE': return theme.colorScheme.primary;
      case 'EXPENSE': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String _getTranslatedType(String type) {
    switch (type) {
      case 'ASSET': return 'الموجودات';
      case 'LIABILITY': return 'المطلوبات';
      case 'EQUITY': return 'الملكية';
      case 'REVENUE': return 'إيرادات';
      case 'EXPENSE': return 'مصروفات';
      default: return type;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد حسابات مطابقة للتصفية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            const Text(
              'يرجى تغيير تصنيف الفرز أو محاولة البحث برقم حساب مالي آخر في الأعلى لتظهر الشجرة بنجاح.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
