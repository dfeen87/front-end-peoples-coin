// lib/state/goodwill_processing_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_action_to_send.dart';

class GoodwillProcessingProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  bool _isProcessingGoodwill = false;
  String? _error;
  GoodwillAction? _lastSubmittedAction;
  
  /// List to track goodwill actions currently pending backend confirmation
  final List<GoodwillAction> _pendingSubmissions = [];
  
  bool get isProcessingGoodwill => _isProcessingGoodwill;
  String? get error => _error;
  GoodwillAction? get lastSubmittedAction => _lastSubmittedAction;
  
  /// Public unmodifiable view of pending goodwill submissions
  List<GoodwillAction> get pendingSubmissions => List.unmodifiable(_pendingSubmissions);
  
  GoodwillProcessingProvider(this._apiClient);
  
  /// Helper to always get a fresh Firebase ID token
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not signed in.');
    final token = await user.getIdToken();
    if (token == null || token?.isEmpty == true) throw Exception('Failed to get Firebase ID token.');
    return token!;
  }
  
  /// Submits a goodwill action securely with ID token
  ///
  /// Adds the action to the pending queue immediately, then attempts submission.
  /// On success, removes it from pending and stores last submitted action.
  Future<bool> submitGoodwill({
    required String performerUserId,
    required String actionType,
    required String description,
    required int lovesValue,
    Map<String, dynamic>? contextualData,
  }) async {
    _isProcessingGoodwill = true;
    _error = null;
    _lastSubmittedAction = null;
    notifyListeners();
    
    final finalContextualData = contextualData ?? {};
    final now = DateTime.now().toUtc();
    
    // Create the action to send and a corresponding GoodwillAction for local tracking
    final actionToSend = GoodwillActionToSend(
      performerUserId: performerUserId,
      actionType: actionType,
      description: description,
      lovesValue: lovesValue,
      contextualData: finalContextualData,
      timestamp: now,
    );
    
    // Fix: Create a pending GoodwillAction object using proper constructor parameters
    final pendingAction = GoodwillAction(
      id: 'pending_${now.millisecondsSinceEpoch}', // temporary ID
      performerUserId: performerUserId,
      actionType: actionType,
      description: description,
      lovesValue: lovesValue,
      contextualData: finalContextualData,
      // Fix: Use createdAt and updatedAt instead of timestamp
      createdAt: now,
      updatedAt: now,
      status: GoodwillStatus.pendingVerification,
    );
    
    // Add to pending submissions immediately
    _pendingSubmissions.insert(0, pendingAction);
    notifyListeners();
    
    try {
      final idToken = await _getIdToken();
      final result = await _apiClient.submitGoodwill(
        goodwillAction: actionToSend.toJson(),
        idToken: idToken,
      );
      
      if (result['success'] == true) {
        // Remove from pending by matching on unique fields like timestamp & description
        _pendingSubmissions.removeWhere((action) =>
            action.createdAt == pendingAction.createdAt &&
            action.description == pendingAction.description);
        
        _lastSubmittedAction = GoodwillAction.fromJson(result['data']);
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'An unknown error occurred during submission.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "An unexpected error occurred: $e";
      notifyListeners();
      return false;
    } finally {
      _isProcessingGoodwill = false;
      notifyListeners();
    }
  }
}
