# Simple News App

A Flutter app for browsing spaceflight news from the [Spaceflight News API](https://api.spaceflightnewsapi.net/v4/docs/). Discover articles in a responsive grid, search the feed, read article details, and open the original story in your browser.

## Features

- Browse paginated spaceflight news articles, including their images, sources, and publication dates.
- Search articles with a debounced search field.
- Pull to refresh the feed and load more articles as you scroll.
- Open an in-app article reader with swipe navigation, then follow the link to the original article.
- Show loading, empty, retry, and error states.
- Support light and dark themes based on the device setting.
- Adapt the article grid to screen size and text scaling.

## Built with

- Flutter and Dart
- `flutter_bloc` and `equatable` for state management
- `dio` for API requests and error handling
- `cached_network_image` for article images
- `intl` for date formatting
- `url_launcher` for opening original articles

## Architecture

The app separates the news UI from API access:

```text
lib/
├── core/
│   ├── constants/       # API and responsive layout constants
│   ├── errors/          # API error type
│   ├── network/         # Dio setup and API client
│   ├── theme/           # Light and dark themes
│   ├── utils/           # Responsive layout helpers
│   └── widgets/         # Shared UI components
├── features/
│   └── news/
│       ├── models/      # Article model and JSON parsing
│       ├── repositories/# API response-to-model mapping
│       ├── viewmodels/  # News state and Cubit
│       ├── views/       # News feed and article reader
│       └── widgets/     # News-specific UI components
└── main.dart            # App setup and dependency composition
```

`ApiClient` owns Dio requests and transport error handling. `NewsRepository` validates API response data and maps it to models. `NewsViewModel` manages feed, search, refresh, and pagination state.

## API

The app requests articles from `GET /articles/` on the Spaceflight News API. Initial requests include a page size of 10; search requests include the search query. Pagination follows the `next` URL returned by the API.

## Getting started

### Requirements

- Flutter SDK (Dart SDK is included with Flutter)
- An Android or iOS device/emulator, or a supported desktop/web target

### Run

```bash
git clone <repository-url>
cd simple_news_app
flutter pub get
flutter run
```

### Analyze and test

```bash
flutter analyze
flutter test
```

## Error behavior

Request timeouts, connection failures, server HTTP responses, and malformed data are handled separately and surfaced through the app's error or retry UI. A connection failure means the app could not reach the API; it does not necessarily mean the device has no internet access.
Repository

GitHub: https://github.com/Sangeetha22shan/simple_news_app

Author

Sangeetha S

Flutter Developer