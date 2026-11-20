# Simple News App

A Flutter app for browsing spaceflight news from the [Spaceflight News API](https://api.spaceflightnewsapi.net/v4/docs/). Discover articles in a responsive grid, search the feed, read article details, and open the original story in your browser.

## Implemented features

- Browse paginated spaceflight news articles, including their images, sources, and publication dates.
- Search articles with a debounced search field.
- Pull to refresh the feed and load more articles as you scroll.
- Open an in-app article reader with swipe navigation, then follow the link to the original article.
- Show loading, empty, retry, and error states.
- Support light and dark themes based on the device setting.
- Adapt the article grid to screen size and text scaling.

### Search Implementation

The application uses the Spaceflight News API's `title_contains` query parameter to implement article search.

**Implementation details:**
- Users can enter keywords in the search field.
- Search requests are debounced to avoid unnecessary API calls.
- The entered keyword is passed to the API through the `title_contains` parameter.
- Previous search requests are handled safely to prevent outdated results from replacing newer results.
- Search results support pagination.

**API limitation / design decision:**

The current implementation uses the API's title-based search parameter. Summary-based matching is not independently implemented in the current version. This is a documented limitation of the search implementation.

### Swipe Navigation – Reference Video Implementation

The article detail screen supports horizontal swipe navigation, following the Gmail-style interaction demonstrated in the reference video provided with the assignment.

**Implemented Behavior:**
- **Swipe Left:** Navigate to the next (newer) news article.
- **Swipe Right:** Navigate to the previous (older) news article.

**Clarification Regarding Assignment Requirements:**

The assignment contains two different swipe-navigation descriptions:

1. **Written requirement (Page 2):**
    - Swipe Left → Previous news article.
    - Swipe Right → Next news article.

2. **Reference video:**
    - Swipe Left → Next news article.
    - Swipe Right → Previous news article.

Since the reference video demonstrates the Gmail-style interaction, I followed the video as the primary interaction reference when implementing this feature.

**Implementation Decision:**

The application intentionally follows the swipe behavior demonstrated in the supplied reference video rather than the opposite direction stated in the written description.

This is an intentional design decision based on the provided visual reference, not a navigation bug or an incomplete implementation.

Both swipe directions are fully functional, including navigation between loaded articles and fetching the next page when the user reaches the end of the available articles.
## Demo

Run the app on a device or emulator:

```bash
flutter run
```

On the **Discover** screen, browse the latest articles, enter a title keyword such as `cricket` in the search field, pull down to refresh, or scroll to load another page. 
Tap an article to open its details, swipe between articles, and select **Read Full Article** to open the publisher's page.

## Built with

- Flutter and Dart
- `flutter_bloc` and `equatable` for state management
- `dio` for API requests and error handling
- `cached_network_image` for article images
- `intl` for date formatting
- `url_launcher` for opening original articles

## Architecture

The app separates the news UI from API access:

### Why Cubit?

Cubit keeps this app's feed, search, pagination, and refresh state transitions straightforward: the UI calls focused methods such as `fetchNews()` or `loadMoreNews()` directly, without extra event classes and handlers. It also works well with the repository boundary, making asynchronous success and error states easy to test in isolation. `Equatable` gives the states value-based equality.

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

The app requests articles from `GET /articles/` on the Spaceflight News API. Initial requests include a page size of 10; search requests use the `title_contains` parameter to match article titles. Pagination follows the `next` URL returned by the API.

## Getting started

### Requirements

- Flutter SDK (Dart SDK is included with Flutter)
- An Android or iOS device/emulator, or a supported desktop/web target

### Run

```bash
git clone https://github.com/Sangeetha22shan/simple_news_app.git
cd simple_news_app
flutter pub get
flutter run
```

## Tests

Run the full automated test suite and static analysis:

```bash
flutter test
flutter analyze
```

The tests cover API query construction and transport errors, repository response parsing/search/pagination, ViewModel state transitions (including debounce, stale searches, pagination retries, refresh, duplicate filtering, and disposal), and news-list rendering and retry behavior.

## Error behavior

Request timeouts, connection failures, server HTTP responses, and malformed data are handled separately and surfaced through the app's error or retry UI. A connection failure means the app could not reach the API; it does not necessarily mean the device has no internet access.

## Repository

GitHub: https://github.com/Sangeetha22shan/simple_news_app

## Author

Sangeetha S

Flutter Developer