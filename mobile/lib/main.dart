import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'core/config/env_config.dart';
import 'data/repositories/audio_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'logic/audio_list_cubit/audio_list_cubit.dart';
import 'logic/chat_cubit/chat_cubit.dart';
import 'logic/auth_cubit/auth_cubit.dart';
import 'logic/auth_cubit/auth_state.dart';
import 'logic/ingest_cubit/ingest_cubit.dart';
import 'logic/player_cubit/player_cubit.dart';
import 'services/storage/telegram_storage_provider.dart';
import 'services/supabase_service.dart';
import 'services/theme_notifier.dart';
import 'services/youtube_service.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load biến môi trường từ .env
  await EnvConfig.load();
  EnvConfig.validate();

  // 2. Khởi tạo Supabase client
  await SupabaseService().initialize();

  runApp(const PMKAApp());
}

/// Bảng màu chính — lấy từ design reference
class AppColors {
  static const deepPurple = Color(0xFF3D1B6F);
  static const midPurple = Color(0xFF6B3FA0);
  static const softPurple = Color(0xFF9B6FCF);
  static const lightLavender = Color(0xFFD4BEF0);
  static const paleBackground = Color(0xFFF0E6FF);

  // ── Dark theme colors ──
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF252540);
  static const darkText = Color(0xFFE8E0F0);

  // Gradient chính cho background
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B4FAF),
      Color(0xFFB48AD8),
      Color(0xFFDCC8F0),
    ],
  );

  // Gradient cho card audio
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B59D0),
      Color(0xFF6FA3E8),
      Color(0xFFE88BA7),
    ],
  );

  // Gradient cho full player
  static const playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF6B3FA0),
      Color(0xFF9B6FCF),
      Color(0xFFBE97DB),
    ],
  );

  // Gradient dark player
  static const playerGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF2D1B4E),
      Color(0xFF3D2B5E),
    ],
  );
}

class PMKAApp extends StatelessWidget {
  const PMKAApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Khởi tạo Dependencies ──
    final supabaseClient = SupabaseService().client;

    // Repositories
    final audioRepo = AudioRepository(supabaseClient);
    final chatRepo = ChatRepository(supabaseClient);

    // Services
    final telegramStorage = TelegramStorageProvider();
    final youtubeService = YouTubeService();
    final audioPlayer = AudioPlayer();

    final themeNotifier = ThemeNotifier();

    // ── MultiBlocProvider: cung cấp tất cả Cubits cho toàn bộ widget tree ──
    return MultiBlocProvider(
      providers: [
        // Auth phải đứng đầu — các Cubit khác có thể cần userId
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(client: supabaseClient)..checkSession(),
        ),
        BlocProvider<AudioListCubit>(
          create: (_) => AudioListCubit(audioRepo: audioRepo),
        ),
        BlocProvider<PlayerCubit>(
          create: (_) => PlayerCubit(
            audioPlayer: audioPlayer,
            storage: telegramStorage,
          ),
        ),
        BlocProvider<IngestCubit>(
          create: (_) => IngestCubit(
            youtubeService: youtubeService,
            audioRepo: audioRepo,
          ),
        ),
        BlocProvider<ChatCubit>(
          create: (_) => ChatCubit(
            chatRepo: chatRepo,
            currentUsername: 'User',
          ),
        ),
      ],
      child: ListenableBuilder(
        listenable: themeNotifier,
        builder: (context, _) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeNotifier.isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'PMKA',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.mode,

            // ── Light theme ──
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: const Color(0xFF7B4FAF),
              fontFamily: 'Segoe UI',
              scaffoldBackgroundColor: AppColors.paleBackground,
              cardColor: Colors.white,
              popupMenuTheme: const PopupMenuThemeData(
                color: Colors.white,
              ),
            ),

            // ── Dark theme ──
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF7B4FAF),
              fontFamily: 'Segoe UI',
              scaffoldBackgroundColor: AppColors.darkSurface,
              cardColor: AppColors.darkCard,
              popupMenuTheme: PopupMenuThemeData(
                color: AppColors.darkCard,
              ),
            ),

            // Kiểm tra auth session → hiển thị đúng màn hình
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  // Đã đăng nhập → load data + vào Home
                  context.read<AudioListCubit>().loadInitial();
                  context.read<ChatCubit>().updateUsername(
                    authState.email.split('@').first,
                  );
                  return const HomeScreen();
                }
                if (authState is AuthInitial) {
                  // Đang check session → splash loading
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                // Chưa đăng nhập hoặc lỗi → AuthScreen
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
