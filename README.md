# Apex Legends Nexus

**Master every legend. Track every rank.**

## Description

Apex Legends Nexus is your complete companion app for Apex Legends. Whether you're grinding ranked, tracking progress across multiple legends, or just want to know which map is loading next, Nexus gives you instant access to everything that matters.

Search for any player in seconds and dive deep into their statistics — rank progression, legend winrates, lifetime kills, seasonal performance, and more. Get real-time updates on map rotations so you're never caught off guard. Monitor server health across all regions to understand connection quality before you queue.

Built for competitive and casual players alike, Nexus runs on everything — your phone during queue, your desktop while you play, even Linux if that's your thing. No ads. No login required. Just pure, fast, local-first Apex data at your fingertips.

## ✨ Features

- **Player Search** - Look up detailed statistics for any Apex Legends player
- **Player Stats** - View comprehensive player data including:
  - Rank and RP progression
  - Legend-specific statistics
  - Lifetime stats and seasonal performance
  - Win rates and kill/death ratios
- **Map Rotations** - Check current and upcoming map rotations
- **Server Status** - Real-time server status for all regions
- **Push Notifications** - Get alerts for important updates without opening the app
- **Multi-Platform** - Available on Android, iOS, Windows, and Linux

## 📱 Platform Support

| Platform | Status | Installation |
|----------|--------|--------------|
| **Android** | ✅ Stable | [Google Play Store](https://play.google.com/store) |
| **iOS** | ✅ WIP | [Apple App Store](https://apps.apple.com) |
| **Windows** | ✅ Stable | Windows installer (.exe) |
| **Linux** | ✅ Stable | AppImage (portable) |

## 🚀 Installation

### Android
1. Install the latest release from [Google Play Store](https://play.google.com/store)

### iOS (WIP)
1. Install the latest release from [Apple App Store](https://apps.apple.com)

### Windows
1. Download `apex-legends-nexus-installer.exe` from [Releases](../../releases)
2. Run the installer (admin privileges required)
3. Follow the installation wizard
4. Launch from Start Menu or Desktop shortcut

### Linux
1. Download `apex-legends-nexus-*.AppImage` from [Releases](../../releases)
2. Make it executable:
   ```bash
   chmod +x apex-legends-nexus-*.AppImage
   ```
3. Run it:
   ```bash
   ./apex-legends-nexus-*.AppImage
   ```

## 🔧 Development

### Prerequisites
- Flutter SDK 3.11.5 or later
- Dart SDK (included with Flutter)
- For Android: Java 17, Android SDK
- For Windows: Visual Studio or Visual Studio Build Tools
- For Linux: GTK 3 development libraries
- For iOS: Xcode 14+

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ApexLegendsNexus.git
   cd ApexLegendsNexus
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate environment code**
   ```bash
   dart run build_runner build
   ```

4. **Run the app**
   ```bash
   # Development mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Configuration

This app uses **envied** for secure credential management. Environment variables are obfuscated at compile-time rather than stored as plain text.

To configure:
1. Create a `.env` file in the project root:
   ```env
   PROXY_URL=<your-proxy-url>
   CLIENT_TOKEN=<your-client-token>
   ```

2. Regenerate environment code:
   ```bash
   dart run build_runner build
   ```

The credentials are now compiled into the binary and obfuscated - they won't be visible in the distributed app or source code.

## 🏗️ Building Releases

### Android
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Windows
```bash
flutter build windows --release
# Then build the installer with NSIS
```
Output: `apex-legends-nexus-installer.exe`

### Linux
```bash
flutter build linux --release
# AppImage is built automatically by GitHub Actions
```

### iOS
```bash
flutter build ios --release
```

## 🔐 Security & Privacy

- **No user authentication required** - All data is public (player stats, maps, server status)
- **Obfuscated credentials** - API credentials are XOR-obfuscated at compile-time using `envied`
- **No data collection** - The app does not collect or store user data
- **Open source** - Full transparency of how data is handled

## ⚠️ Disclaimer

This is an **unofficial** companion app for Apex Legends. It is not made by, affiliated with, endorsed by, or in any way associated with Electronic Arts or Respawn Entertainment.

Apex Legends is a registered trademark of Electronic Arts Inc.

## 🌐 Data Sources

This app fetches data from:
- **Player Statistics** - Public Apex Legends API data
- **Map Rotations** - Official rotation information
- **Server Status** - Real-time server health data

All data is sourced from publicly available APIs and is not stored locally beyond caching for performance.

## 📋 Architecture

Built with:
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management and dependency injection
- **Dio** - HTTP client with interceptors
- **Shared Preferences** - Local data persistence
- **Flutter Local Notifications** - Push notifications for important updates

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Code Style

This project follows:
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Best Practices](https://docs.flutter.dev/testing/best-practices)

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - The amazing framework
- [Riverpod](https://riverpod.dev) - State management
- Apex Legends community for the inspiration

## 📞 Support

For issues, feature requests, or questions:
- Open an [issue](../../issues)
- Check existing [discussions](../../discussions)

---

**Note:** This is a fan-made project and is not affiliated with or endorsed by Electronic Arts or Respawn Entertainment.
