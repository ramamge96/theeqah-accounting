import 'dart:async';
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

Future<void> main() async {
  // تأكد من تهيئة Flutter قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  // لالتقاط أي خطأ غير متوقع في إطار العمل
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error: ${details.exception}");
    debugPrint("Stack: ${details.stack}");
  };

  // لالتقاط أي خطأ غير مرئي (Async)
  runZonedGuarded(() {
    runApp(const TheeqahAccountingApp());
  }, (error, stack) {
    debugPrint("Unhandled Error: $error");
    debugPrint("$stack");
  });
}

class TheeqahAccountingApp extends StatelessWidget {
  const TheeqahAccountingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // شاشة الخطأ المخصصة
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 70, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text("حدث خطأ غير متوقع", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(details.exception.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    };

    return MultiProvider(
      providers: [
        // تمت إضافة try-catch لإنشاء آمن لكل Provider
        ChangeNotifierProvider<AccountsProvider>(create: (_) { try { return AccountsProvider(); } catch (e) { debugPrint("AccountsProvider Error: $e"); return AccountsProvider(); } }),
        ChangeNotifierProvider<DashboardProvider>(create: (_) { try { return DashboardProvider(); } catch (e) { debugPrint("DashboardProvider Error: $e"); return DashboardProvider(); } }),
        ChangeNotifierProvider<JournalEntriesProvider>(create: (_) { try { return JournalEntriesProvider(); } catch (e) { debugPrint("JournalEntriesProvider Error: $e"); return JournalEntriesProvider(); } }),
        ChangeNotifierProvider<SettingsProvider>(create: (_) { try { return SettingsProvider(); } catch (e) { debugPrint("SettingsProvider Error: $e"); return SettingsProvider(); } }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'نظام ثقة المحاسبي',
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        localizationsDelegates: const [DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
        theme: ThemeData(
          fontFamily: 'Cairo',
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
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

  // بناء شاشة واحدة فقط في كل مرة (بدلاً من IndexedStack الذي يبني الكل)
  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0: return const DashboardScreen();
      case 1: return const ChartOfAccountsScreen();
      case 2: return const InvoiceCreatorScreen();
      case 3: return const JournalEntriesScreen();
      case 4: return const FinancialReportsScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(child: _getCurrentScreen()),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (!mounted) return;
            setState(() { _currentIndex = index; });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), activeIcon: Icon(Icons.account_tree_rounded), label: 'الحسابات'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'فاتورة'),
            BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book_rounded), label: 'القيود'),
            BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment_rounded), label: 'تقارير'),
          ],
        ),
      ),
    );
  }
}