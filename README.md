# ALP (Adaptive Learning Platform)

ALP is a Flutter-based educational application designed to support adaptive learning. It supports both **Windows** and **Android** platforms and comes with advanced features such as an AI assistant and peer-to-peer data synchronization.

## 🚀 Key Features

* **Smart AI Assistant**: Integrated with Google Gemini to assist in the teaching and learning process.
* **Multi-Role Management**: Supports **Student** and **Teacher** roles with tailored features.
* **Offline Synchronization (P2P)**: Enables data exchange between devices using local connections and QR Codes (without internet).
* **Local Storage**: Uses SQLite for efficient and secure data storage.
* **Multi-Platform**: Runs seamlessly on Android devices and Windows Desktops.
* **Security**: Secure user authentication.

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (Latest version recommended, minimum 3.10.x).
2. **Visual Studio Code (VS Code)**.
3. **VS Code Extensions**:
    * [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
    * [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)
4. **For Android**:
    * Android SDK & Tools (usually installed via Android Studio Setup or command line tools).
    * Android Emulator or Physical Device (with USB Debugging enabled).
5. **For Windows**:
    * Visual Studio 2022 (Community Edition is sufficient).
    * **"Desktop development with C++"** workload must be installed.

## 📦 Installation & Setup

1. **Clone the Repository**:
    Open your terminal or command prompt and run:

    ```bash
    git clone https://github.com/ade-karya/alp-flutter.git
    cd alp-flutter
    ```

2. **Open in VS Code**:
    Open the cloned folder in Visual Studio Code.

3. **Install Dependencies**:
    * Open the integrated terminal in VS Code (`Ctrl +` ` ` `).
    * Run the following command:

        ```bash
        flutter pub get
        ```

    * Alternatively, when you open `pubspec.yaml`, VS Code often prompts you to "Get Packages". You can click that button.

## ▶️ How to Run (VS Code Guide)

### 1. Select Your Device

* Look at the bottom right corner of the VS Code status bar. You should see the currently selected device (e.g., "Windows (windows-x64)" or "Pixel 4a").
* Click on it to change the target device (select an Android emulator/device or Windows).

### 2. Run the Application

* Open `lib/main.dart`.
* Press **F5** on your keyboard to start debugging.
* Or, go to the top menu: **Run** > **Start Debugging**.

### 📱 Running on Android

* Ensure your emulator is running or your physical device is connected.
* Select the Android device in the VS Code status bar.
* Press **F5**.

### 💻 Running on Windows

* **Important**: Ensure Developer Mode is enabled in Windows Settings (Settings > Update & Security > For developers).
* Select "Windows" in the VS Code status bar.
* Press **F5**.

## 🏗️ Project Structure

This project follows **Clean Architecture** and uses the **BLoC** pattern for state management.

* `lib/core`: Core components, utilities, and base configurations.
* `lib/features`: Main feature modules (Auth, Student, Teacher, Network, AI Assistant, etc.).
* `lib/main.dart`: Application entry point.

## 🔧 Troubleshooting

* **Windows Database Issues**: If you encounter errors related to `sqlite3.dll` on Windows, ensure the C++ build tools are correctly installed via Visual Studio.
* **P2P Connection**: For synchronization, ensure both devices are on the same Wi-Fi network or one device has Hotspot enabled.
* **VS Code Device Not Showing**: If no device is shown, try running `flutter doctor` in the terminal to diagnose environment issues.

---
Developed with ❤️ using Flutter.
