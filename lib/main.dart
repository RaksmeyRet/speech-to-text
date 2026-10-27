import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'constants/app_constants.dart';
import 'screens/chat_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor)
            .copyWith(
              primary: AppColors.primaryColor,
              secondary: AppColors.secondaryColor,
              surface: AppColors.whiteColor,
              error: AppColors.redColor,
            ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.whiteColor,
          foregroundColor: AppColors.primaryColor,
          surfaceTintColor: AppColors.whiteColor,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
