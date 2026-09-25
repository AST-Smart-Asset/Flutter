import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../../data/models/user_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/dashboard_kpi_model.dart';
import '../../data/models/work_order_model.dart';
import '../../data/models/stocktake_model.dart';

class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException(this.message, {this.code = 'UNKNOWN', this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const _tokenKey = 'ast_jwt_token';
  static const _userKey = 'ast_user_profile';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _accessToken;
  UserModel? currentUser;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoggedIn => isAuthenticated;

  /// AST-SEC-REQ-41: Initialize session from encrypted secure storage on app launch
  Future<void> initSecureSession() async {
    try {
      _accessToken = await _secureStorage.read(key: _tokenKey);
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        currentUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (_) {
      // Graceful fallback for non-hardware environments
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  dynamic _processResponse(http.Response res) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(res.body);
    } catch (_) {
      throw ApiException('Server returned an unparseable response', statusCode: res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (jsonBody is Map && jsonBody['success'] == true) {
        return jsonBody['data'];
      }
      return jsonBody;
    } else {
      final errorMap = jsonBody is Map ? jsonBody['error'] : null;
      final msg = errorMap?['message'] ?? 'An error occurred (${res.statusCode})';
      final code = errorMap?['code'] ?? 'HTTP_${res.statusCode}';
      throw ApiException(msg, code: code, statusCode: res.statusCode);
    }
  }

  // 1. Authentication (AST-FR-01 & AST-SEC-REQ-41)
  Future<UserModel> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _processResponse(response);
    _accessToken = data['accessToken'] as String;
    currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    // AST-SEC-REQ-41: Securely persist token using hardware-backed keystore/keychain
    try {
      await _secureStorage.write(key: _tokenKey, value: _accessToken);
      await _secureStorage.write(key: _userKey, value: jsonEncode(data['user']));
    } catch (_) {}

    return currentUser!;
  }

  Future<void> logout() async {
    _accessToken = null;
    currentUser = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    } catch (_) {}
  }

  // 2. Dashboard KPIs (AST-FR-02)
  Future<DashboardKPIModel> getDashboardKPIs() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/dashboard/kpis');
    final response = await http.get(url, headers: _headers());
    final data = _processResponse(response);
    return DashboardKPIModel.fromJson(data as Map<String, dynamic>);
  }

  // 3. Asset Registry & Search (AST-FR-03)
  Future<List<AssetModel>> getAssets({
    String? search,
    String? status,
    String? condition,
    String? riskBand,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;
    if (condition != null) queryParams['condition'] = condition;
    if (riskBand != null) queryParams['riskBand'] = riskBand;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/assets').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _headers());
    final data = _processResponse(response);

    if (data is List) {
      return data.map((json) => AssetModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<AssetModel> getAssetById(String id) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/assets/$id');
    final response = await http.get(url, headers: _headers());
    final data = _processResponse(response);
    return AssetModel.fromJson(data);
  }

  // 4. Custody & Transfer (AST-FR-04)
  Future<void> transferAsset({
    required String assetId,
    required String targetLocationId,
    String? targetCustodianId,
    required String reason,
    String? approvalNotes,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/custody/$assetId/transfer');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'targetLocationId': targetLocationId,
        'targetCustodianId': targetCustodianId,
        'reason': reason,
        'approvalNotes': approvalNotes,
      }),
    );
    _processResponse(response);
  }

  // 5. Work Orders (AST-FR-06)
  Future<List<WorkOrderModel>> getWorkOrders({String? status, String? priority}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;

    final url = Uri.parse('${AppConfig.apiBaseUrl}/work-orders').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _headers());
    final data = _processResponse(response);

    if (data is List) {
      return data.map((json) => WorkOrderModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> closeWorkOrder({
    required String workOrderId,
    required String outcome,
    required double cost,
    required double downtimeHours,
    required String completionNotes,
    String? newCondition,
  }) async {
    final body = <String, dynamic>{
      'outcome': outcome,
      'cost': cost,
      'downtimeHours': downtimeHours,
      'completionNotes': completionNotes,
    };
    if (newCondition != null) {
      body['assetNewCondition'] = newCondition;
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/work-orders/$workOrderId/close');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );
    _processResponse(response);
  }

  // 6. Stocktake & QR Audits (AST-FR-07)
  Future<List<StocktakeSessionModel>> getStocktakeSessions() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stocktake/sessions');
    final response = await http.get(url, headers: _headers());
    final data = _processResponse(response);
    if (data is List) {
      return data.map((json) => StocktakeSessionModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> scanAssetQR({
    required String sessionId,
    required String assetTag,
    required String observedLocationId,
    String? notes,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/stocktake/sessions/$sessionId/scan');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'assetTag': assetTag,
        'observedLocationId': observedLocationId,
        'notes': notes,
      }),
    );
    return _processResponse(response);
  }

  // 7. Predictive AI Risk Evaluation (AST-FR-09)
  Future<Map<String, dynamic>> evaluateAssetRisk(String assetId) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/predictions/evaluate/$assetId');
    final response = await http.post(url, headers: _headers());
    return _processResponse(response);
  }
}
