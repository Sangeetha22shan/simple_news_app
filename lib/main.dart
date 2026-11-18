import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/news/repositories/news_repository.dart';
import 'features/news/views/news_list_screen.dart';
import 'features/news/viewmodels/news_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SimpleNewsApp());
}

class SimpleNewsApp extends StatelessWidget {
  const SimpleNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NewsViewModel(repository: NewsRepository(apiClient: ApiClient()))
            ..fetchNews(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const NewsListScreen(),
      ),
    );
  }
}
