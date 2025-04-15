[![iOS Release](https://github.com/La-Roue-Qui-Marche/LRQM-app/actions/workflows/ios-release.yml/badge.svg?branch=main)](https://github.com/La-Roue-Qui-Marche/LRQM-app/actions/workflows/ios-release.yml)
[![Android Release](https://github.com/La-Roue-Qui-Marche/LRQM-app/actions/workflows/android-release.yml/badge.svg?branch=main)](https://github.com/La-Roue-Qui-Marche/LRQM-app/actions/workflows/android-release.yml)

# LRQM Mobile Application

Welcome to the **LRQM Mobile Application**, designed to support the "Objectif 2'000'000 m" project. This app is built with Flutter and works seamlessly with the [LRQM Server](https://github.com/chloefont/LRQM-server).

Visit the project website: [larouequimarche.ch](https://larouequimarche.ch/)

This is a **cross-platform application**, compatible with both Android and iOS devices.

---

## Features

- **User Authentication**: Enter your Dossard number to access your personal contributions.
- **Track Contributions**: View your progress and contributions toward the project goal.
- **Session Management**: Start a session for yourself or a group to track and log your activities.
- **Real-Time Updates**: Receive live updates on your progress and contributions synced with the server.
- **Interactive UI**: Enjoy a user-friendly interface for an engaging and seamless experience.

---

## Prerequisites

To compile and run this project, ensure you have the following installed:

1. [Flutter](https://docs.flutter.dev/get-started/install)
2. A compatible IDE (e.g., [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio))

---

## Setup Instructions

1. Clone this repository:

   ```bash
   git clone https://github.com/chloefont/LRQM-app.git
   cd LRQM-app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the application:

   ```bash
   flutter run
   ```

---

## Server Configuration

This application communicates with the [LRQM Server](https://github.com/chloefont/LRQM-server). Ensure the server is set up and running before using the app.

---

## Permissions Required

This application requires the following permissions to function properly:

- **Camera**: Used to scan QR codes for session management and tracking.
- **Precise Location**: Used to accurately track your activities and contributions during a session.

Please ensure these permissions are granted when prompted to enjoy the full functionality of the app.

---

## Configuration File

The configuration file containing the app's parameters can be found [here](lib/Utils/config.dart).

---

## License

This project is licensed under the terms of the [LICENSE](LICENSE) file.

---

## Assets

This project uses the following fonts:

- **Roboto** (Bold, Regular)

Font licenses are available in the [assets/fonts/](assets/fonts/) directory.

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve the app.

---

## Contact

For any inquiries, please contact the project maintainers via the [Issues](https://github.com/La-Roue-Qui-Marche/LRQM-app/issues) section.

---

Thank you for contributing to the "Objectif 2'000'000 m" project! 🌟
