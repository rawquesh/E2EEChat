class ElasticSearchCredentials {
  static const String _elasticUrl = "http://192.168.29.11:9201/";
  static const String _elasticBasicAuth = "ApiKey aHA0aXA1UUIzS2h0UU9HUGw4aWg6cXpQc2FwX25TM09aQ01CTm5NVHBxUQ==";

  static String geBaseUrl() => _elasticUrl;
  static String getBasicAuth() => _elasticBasicAuth;
}

class CloudinaryCredentials {
  static const String _apiKey = "759459561928956";
  static const String _apiSecret = "LuL1tF83yPCTSg9TiH9aAS2DoCM";
  static const String _cloudName = "dgumhxsah";
  static const String _cloudinaryUrl = "cloudinary://759459561928956:LuL1tF83yPCTSg9TiH9aAS2DoCM@dgumhxsah";

  static String getCloudinaryApiKey() => _apiKey;
  static String getCloudinaryApiSecret() => _apiSecret;
  static String getCloudinaryCloudName() => _cloudName;
  static String getCloudinaryUrl() => _cloudinaryUrl;
}
