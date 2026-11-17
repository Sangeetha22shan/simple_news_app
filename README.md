# Simple News App – Flutter

## Project Overview

Simple News App is a cross-platform Flutter application that fetches and displays the latest space-related news articles using the Spaceflight News API.

The application is designed with a clean and maintainable architecture, reusable UI components, and efficient state management using Flutter Bloc/Cubit.

## Features

- Fetch and display news articles from the Spaceflight News API.
- Display article images, titles, news sources, and published dates.
- Pull-to-refresh functionality.
- Infinite scrolling with pagination.
- Loading and error states with retry functionality.
- Handle missing images and nullable API fields.
- Responsive UI for different screen sizes.
- Light and dark theme support.

### Planned Features

- Search articles by title and summary.
- Article detail screen.
- Previous and next article swipe navigation.
- Open original articles in an external browser.
- Unit tests and widget tests.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| Flutter Bloc / Cubit | State management |
| Dio | REST API integration |
| Equatable | State and model comparison |
| Cached Network Image | Image caching |
| Intl | Date formatting |
| Flutter Test | Application testing |

## Architecture

The project follows the MVVM architectural pattern.

```text
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── theme/
│
├── data/
│   ├── models/
│   │   └── article_model.dart
│   │
│   └── repositories/
│       └── news_repository.dart
│
├── features/
│   └── news/
│       ├── cubit/
│       │   ├── news_cubit.dart
│       │   └── news_state.dart
│       │
│       ├── views/
│       │   └── news_list_screen.dart
│       │
│       └── widgets/
│           └── article_card.dart
│
└── main.dart
```

### Architecture Responsibilities

**View**
- Displays the news articles.
- Handles user interactions.
- Updates the UI based on Cubit states.

**ViewModel (Cubit)**
- Manages application state.
- Handles loading and refresh operations.
- Controls pagination and error states.

**Repository**
- Fetches article data.
- Converts API responses into application models.
- Provides data to the Cubit.

**Model**
- Represents news article data.
- Parses JSON responses into Dart objects.

**API Client**
- Centralizes HTTP requests using Dio.
- Handles request timeouts and API errors.

## API Integration

API Provider: Spaceflight News API

Base URL:

https://api.spaceflightnewsapi.net/v4/

### Endpoints

**Get Articles**

GET /articles/

**Search Articles**

GET /articles/?title_contains=cricket

**Get Article Details**

GET /articles/{id}

API Documentation:

https://api.spaceflightnewsapi.net/v4/docs/

## State Management

This application uses Flutter Bloc/Cubit for state management.

Cubit provides a simple way to manage application states without requiring events.

The application uses the following states:

- Initial
- Loading
- Success
- Failure

Additional flags manage pagination and refresh operations.

## Installation and Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or physical Android device

### Clone the Repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
```

### Navigate to the Project

```bash
cd simple_news_app
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

### Check Code Quality

```bash
flutter analyze
```

### Run Tests

```bash
flutter test
```

## Error Handling

The application handles:

- API connection failures.
- Request timeouts.
- Server errors.
- Missing article images.
- Missing or nullable API fields.
- Pagination errors.
- Empty article responses.

## Assumptions

- News articles are retrieved from the Spaceflight News API.
- The news site field is used as the source name.
- Missing images are replaced with a placeholder.
- Article data is parsed using null-safe Dart models.
- Pagination uses the API-provided next-page URL.

## Author

Flutter Developer

## License

This project was developed as a Flutter developer technical assessment.

