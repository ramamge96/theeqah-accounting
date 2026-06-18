import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/accounts_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/journal_entries_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chart_of_accounts_screen.dart';
import 'screens/journal_entries_screen.dart';
import 'screens/invoice_creator_screen.dart';
import 'screens/financial_reports_screen.dart';

void main() {
  runApp(const TheeqahAccountingApp());
}

class TheeqahAccountingApp extends StatelessWidget {
  const TheeqahAccountingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => JournalEntriesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // تمت الإضافة
      ],
      child: MaterialApp(
        title: 'نظام ثقة المحاسبي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        theme: ThemeData(
          fontFamily: 'Cairo',
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChartOfAccountsScreen(),
    const InvoiceCreatorScreen(),
    const JournalEntriesScreen(),
    const FinancialReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar( // تم التغيير إلى BottomNavigationBar
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_outlined),
              activeIcon: Icon(Icons.account_tree_rounded),
              label: 'الحسابات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'فاتورة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book_rounded),
              label: 'القيود',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'تقارير',
            ),
          ],
        ),
      ),
    );
  }
}