class ApiConfig {
  static const String baseUrl = 'https://customprint.deodap.com';
  static const String apiPath = '/api_amzDD_return';

  static String getLoginUrl() {
    return '$baseUrl$apiPath/dropshipper_user_login.php';
  }
}
