import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for ChangeNotifier
import '../models/goodwill_action.dart';
import '../services/api_client.dart';

class GoodwillActionsProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<GoodwillAction> _actions = [];
  bool _isLoading = false;
  String? _error;

  List<GoodwillAction> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GoodwillActionsProvider(this._apiClient);

  Future<void> fetchUserActions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _actions = await _apiClient.getUserGoodwillActions(userId);
    } catch (e) {
      _error = 'Failed to fetch goodwill actions: $e';
      _actions = []; // FIX: Clear the list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
