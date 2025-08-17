class ApiConfig {
  // Environment configuration
  static const String _devBaseUrl = 'https://dev-api.brightacts.com';
  static const String _stagingBaseUrl = 'https://staging-api.brightacts.com';
  static const String _prodBaseUrl = 'https://api.brightacts.com';
  
  // Current environment - change this for different builds
  static const Environment currentEnvironment = Environment.development;
  
  // Get base URL based on current environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _devBaseUrl;
      case Environment.staging:
        return _stagingBaseUrl;
      case Environment.production:
        return _prodBaseUrl;
    }
  }
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String proposalsEndpoint = '/proposals';
  static const String votesEndpoint = '/votes';
  static const String goodwillActionsEndpoint = '/goodwill-actions';
  static const String ledgerEndpoint = '/ledger';
  static const String walletEndpoint = '/wallet';
  
  // API configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache configuration
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  
  // Feature flags
  static const bool enableCaching = true;
  static const bool enableRetry = true;
  static const bool enableLogging = true;
  
  // API version
  static const String apiVersion = 'v1';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'API-Version': apiVersion,
  };
  
  // Authentication
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const Duration tokenExpiration = Duration(hours: 24);
  
  // WebSocket configuration (if needed)
  static String get wsBaseUrl {
    final httpUrl = baseUrl;
    return httpUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
  }
  
  // File upload configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/pdf',
    'text/plain',
  ];
  
  // Error messages
  static const Map<int, String> errorMessages = {
    400: 'Bad request. Please check your input.',
    401: 'Authentication required. Please sign in.',
    403: 'Access denied. You don\'t have permission for this action.',
    404: 'Resource not found.',
    408: 'Request timeout. Please try again.',
    409: 'Conflict. The resource already exists.',
    422: 'Validation error. Please check your input.',
    429: 'Too many requests. Please wait before trying again.',
    500: 'Server error. Please try again later.',
    502: 'Bad gateway. Service temporarily unavailable.',
    503: 'Service unavailable. Please try again later.',
    504: 'Gateway timeout. Please try again.',
  };
  
  // Development configuration
  static const bool isDevelopment = currentEnvironment == Environment.development;
  static const bool isProduction = currentEnvironment == Environment.production;
  
  // Logging configuration
  static const bool enableDebugLogging = isDevelopment;
  static const bool enableErrorReporting = isProduction;
  
  // Performance monitoring
  static const bool enablePerformanceMonitoring = true;
  static const Duration performanceThreshold = Duration(seconds: 3);
  
  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  
  // Encryption
  static const String encryptionAlgorithm = 'AES-256-GCM';
  static const int encryptionKeyLength = 32;
  
  // Validation rules
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxBioLength = 500;
  static const int maxProposalTitleLength = 200;
  static const int maxProposalDescriptionLength = 5000;
  
  // UI configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Blockchain configuration (if applicable)
  static const String defaultNetworkType = 'mainnet';
  static const Map<String, String> networkRpcUrls = {
    'mainnet': 'https://mainnet-rpc.brightacts.com',
    'testnet': 'https://testnet-rpc.brightacts.com',
    'local': 'http://localhost:8545',
  };
  
  // Social features
  static const int maxFollowing = 5000;
  static const int maxFollowers = 100000;
  static const Duration activityFeedCacheTime = Duration(minutes: 2);
  
  // Notification configuration
  static const bool enablePushNotifications = true;
  static const Duration notificationDebounce = Duration(seconds: 30);
  
  // Search configuration
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  
  // Analytics
  static const bool enableAnalytics = isProduction;
  static const String analyticsEndpoint = '/analytics';
  
  // A/B testing
  static const bool enableABTesting = true;
  static const Duration abTestCacheTime = Duration(hours: 1);
  
  // Security
  static const bool enforceHttps = isProduction;
  static const Duration sessionTimeout = Duration(hours: 8);
  static const bool enableCertificatePinning = isProduction;
  
  // Content moderation
  static const bool enableContentModeration = true;
  static const int maxReportReason = 500;
  
  // Backup and sync
  static const Duration backupInterval = Duration(hours: 6);
  static const bool enableCloudSync = true;
  
  // Helper methods
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
  
  static String getErrorMessage(int statusCode) {
    return errorMessages[statusCode] ?? 'An unexpected error occurred.';
  }
  
  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
  
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }
  
  static bool isServerError(int statusCode) {
    return statusCode >= 500;
  }
}

enum Environment {
  development,
  staging,
  production,
}

extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }
  
  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
}
