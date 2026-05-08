import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'logic/budget/budget_cubit.dart';
import 'logic/expense/expense_cubit.dart';
import 'logic/fixed_expense/fixed_expense_cubit.dart';
import 'logic/theme/theme_cubit.dart';
import 'services/database_service.dart';
import 'ui/navigation/app_navigation.dart';

/// Entry point — khởi tạo locale + Isar database trước khi chạy app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo locale tiếng Việt cho DateFormat (intl package)
  await initializeDateFormatting('vi_VN', null);

  // Khởi tạo database
  await DatabaseService.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    print('FLUTTER_ERROR: ${details.exception}');
    print('STACK_TRACE: ${details.stack}');
  };

  runApp(const MoneJourApp());
}

/// Root widget — cấu hình theme + BlocProviders + navigation.
class MoneJourApp extends StatelessWidget {
  const MoneJourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeCubit()..loadTheme(),
        ),
        BlocProvider(
          create: (_) => ExpenseCubit()..loadMonth(),
        ),
        BlocProvider(
          create: (_) => FixedExpenseCubit()..loadTemplates(),
        ),
        BlocProvider(
          create: (_) => BudgetCubit()..loadBudgets(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'MoneJour',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
            ],
            home: const AppNavigation(),
          );
        },
      ),
    );
  }
}
