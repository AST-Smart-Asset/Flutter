class AppConfig {
  // Default to Android Emulator address (10.0.2.2)
  // For physical device on Wi-Fi, change to your PC local IP (e.g. 192.168.1.X)
  // For Web or iOS Simulator, use http://localhost:5000/api/v1
  static String apiBaseUrl = 'http://10.0.2.2:5000/api/v1';

  static const String appName = 'Smart Asset Inventory';
  static const String appVersion = '1.0.0';
  static const String requirementPrefix = 'AST';

  static void setBaseUrl(String url) {
    apiBaseUrl = url.endsWith('/api/v1') ? url : '$url/api/v1';
  }
}
