import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final NewsViewModel? viewModel;

  const SimpleNewsApp({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple News App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const NewsListScreen(),
    );

    if (viewModel != null) {
      return BlocProvider.value(
        value: viewModel!,
        child: app,
      );
    }

    return BlocProvider(
      create: (_) =>
          NewsViewModel(repository: NewsRepository(apiClient: ApiClient()))
            ..fetchNews(),
      child: app,
    );
  }
}
