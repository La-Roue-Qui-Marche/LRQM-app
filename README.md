# LRQM Mobile App

A cross-platform Flutter app for the "Objectif 2'000'000 m" project by La Roue Qui Marche.

[Project website](https://larouequimarche.ch/)

---

## Features

- keep track your walking/running contributions
- Join sessions individually or as a group
- View your progress toward the collective goal
- Real-time sync with the LRQM server
- Tracks your activity even when the phone is in your pocket

---

## Getting Started

- **Flutter version required:** 3.24.3

```sh
# Install Flutter (version 3.24.3)
# See https://docs.flutter.dev/get-started/install

# Clone the repository
$ git clone https://github.com/La-Roue-Qui-Marche/LRQM-app.git
$ cd LRQM-app

# Install dependencies
$ flutter pub get

# Run the app
$ flutter run
```

---

## Permissions

### Android

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `WAKE_LOCK`
- `INTERNET`
- `CAMERA`

### iOS

- `NSCameraUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

> These permissions are required for QR code scanning and accurate activity tracking, even when the phone is in your pocket.

---

## Configuration

App parameters are in [`lib/Utils/config.dart`](lib/Utils/config.dart).

---

## License & Assets

- Licensed under [LICENSE](LICENSE)
- Fonts used: **SFPRO** (see [assets/fonts/](assets/fonts/))

---

## Contributing & Support

- Issues and PRs welcome
- Contact via [GitHub Issues](https://github.com/La-Roue-Qui-Marche/LRQM-app/issues)

---

Thank you for supporting "Objectif 2'000'000 m"!
