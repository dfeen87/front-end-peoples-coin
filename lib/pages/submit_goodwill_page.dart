// lib/pages/submit_goodwill_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';

// --- DATA MODELS ---

class GoodwillAction {
  final String? id;
  final String performerUserId;
  final String actionType;
  final String description;
  final int lovesValue;
  final Map<String, dynamic> contextualData;
  final DateTime? createdAt;
  final String? status;

  GoodwillAction({
    this.id,
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.lovesValue,
    required this.contextualData,
    this.createdAt,
    this.status,
  });

  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id'],
      performerUserId: json['performer_user_id'] ?? json['performerUserId'] ?? '',
      actionType: json['action_type'] ?? json['actionType'] ?? '',
      description: json['description'] ?? '',
      lovesValue: (json['loves_value'] ?? json['lovesValue'] ?? 0).toInt(),
      contextualData: Map<String, dynamic>.from(json['contextual_data'] ?? json['contextualData'] ?? {}),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'performer_user_id': performerUserId,
      'action_type': actionType,
      'description': description,
      'loves_value': lovesValue,
      'contextual_data': contextualData,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (status != null) 'status': status,
    };
  }
}

class GoodwillProcessingState {
  final bool isProcessingGoodwill;
  final String? error;
  final List<GoodwillAction> pendingSubmissions;
  final List<GoodwillAction> recentSubmissions;

  GoodwillProcessingState({
    this.isProcessingGoodwill = false,
    this.error,
    this.pendingSubmissions = const [],
    this.recentSubmissions = const [],
  });

  GoodwillProcessingState copyWith({
    bool? isProcessingGoodwill,
    String? error,
    List<GoodwillAction>? pendingSubmissions,
    List<GoodwillAction>? recentSubmissions,
  }) {
    return GoodwillProcessingState(
      isProcessingGoodwill: isProcessingGoodwill ?? this.isProcessingGoodwill,
      error: error,
      pendingSubmissions: pendingSubmissions ?? this.pendingSubmissions,
      recentSubmissions: recentSubmissions ?? this.recentSubmissions,
    );
  }
}

class BackendStatus {
  final String nodeVersion;
  final bool metabolicActive;
  final bool nervousActive;
  final bool endocrineActive;
  final bool immuneActive;
  final List<String> recentEvents;
  final int totalSubmissions;
  final int pendingCount;

  BackendStatus({
    required this.nodeVersion,
    required this.metabolicActive,
    required this.nervousActive,
    required this.endocrineActive,
    required this.immuneActive,
    required this.recentEvents,
    this.totalSubmissions = 0,
    this.pendingCount = 0,
  });

  factory BackendStatus.fromJson(Map<String, dynamic> json) {
    return BackendStatus(
      nodeVersion: json['node_version'] ?? json['nodeVersion'] ?? 'Unknown',
      metabolicActive: json['metabolic_active'] ?? json['metabolicActive'] == false,
      nervousActive: json['nervous_active'] ?? json['nervousActive'] == false,
      endocrineActive: json['endocrine_active'] ?? json['endocrineActive'] == false,
      immuneActive: json['immune_active'] ?? json['immuneActive'] == false,
      recentEvents: List<String>.from(json['recent_events'] ?? json['recentEvents'] ?? []),
      totalSubmissions: (json['total_submissions'] ?? json['totalSubmissions'] ?? 0).toInt(),
      pendingCount: (json['pending_count'] ?? json['pendingCount'] ?? 0).toInt(),
    );
  }
}

// --- FLASK API SERVICE ---

class FlaskGoodwillService {
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FlaskGoodwillService({required this.baseUrl});

  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getIdToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> submitGoodwill(GoodwillAction action) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/goodwill/submit'),
        headers: headers,
        body: json.encode(action.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit goodwill action');
      }
    } catch (e) {
      print('Error submitting goodwill: $e');
      if (e is Exception) rethrow;
      return false;
    }
  }

  Future<List<GoodwillAction>> getUserSubmissions({
    int limit = 10,
    String? status, // 'pending', 'approved', 'rejected'
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/goodwill/user-submissions')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> submissions = data['submissions'] ?? data['data'] ?? [];
        
        return submissions
            .map((submission) => GoodwillAction.fromJson(submission))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch submissions');
      }
    } catch (e) {
      print('Error fetching user submissions: $e');
      if (e is Exception) rethrow;
      return [];
    }
  }

  Future<BackendStatus> getBackendStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BackendStatus.fromJson(data);
      } else {
        throw Exception('Failed to fetch backend status');
      }
    } catch (e) {
      print('Error fetching backend status: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> calculateLovesValue({
    required String actionType,
    required String description,
    required String impactLevel,
    required int durationMinutes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/goodwill/calculate-loves'),
        headers: headers,
        body: json.encode({
          'action_type': actionType,
          'description': description,
          'impact_level': impactLevel,
          'duration_minutes': durationMinutes,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Fallback to local calculation if endpoint doesn't exist
        return _calculateLovesLocally(
          description: description,
          impactLevel: impactLevel,
          durationMinutes: durationMinutes,
        );
      }
    } catch (e) {
      print('Error calculating loves value: $e');
      // Fallback to local calculation
      return _calculateLovesLocally(
        description: description,
        impactLevel: impactLevel,
        durationMinutes: durationMinutes,
      );
    }
  }

  Map<String, dynamic> _calculateLovesLocally({
    required String description,
    required String impactLevel,
    required int durationMinutes,
  }) {
    int baseFromDescription = (description.trim()?.length ?? 0 / 2).clamp(10, 50).toInt();
    int durationScore = ((durationMinutes.clamp(0, 120) / 120) * 50).toInt();

    final impactMultipliers = {
      'Low': 0.8,
      'Medium': 1.0,
      'High': 1.2,
    };
    double impactMultiplier = impactMultipliers[impactLevel] ?? 1.0;

    final calculatedLoves = ((baseFromDescription + durationScore) * impactMultiplier).clamp(1, 100).toInt();

    return {
      'loves_value': calculatedLoves,
      'breakdown': {
        'description_score': baseFromDescription,
        'duration_score': durationScore,
        'impact_multiplier': impactMultiplier,
      },
    };
  }
}

// --- STATE MANAGEMENT ---

class GoodwillProcessingNotifier extends StateNotifier<GoodwillProcessingState> {
  final FlaskGoodwillService _service;
  Timer? _statusRefreshTimer;

  GoodwillProcessingNotifier(this._service) : super(GoodwillProcessingState()) {
    _refreshUserSubmissions();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshUserSubmissions();
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUserSubmissions() async {
    try {
      final pending = await _service.getUserSubmissions(status: 'pending');
      final recent = await _service.getUserSubmissions(limit: 5);
      
      state = state.copyWith(
        pendingSubmissions: pending,
        recentSubmissions: recent,
      );
    } catch (e) {
      print('Error refreshing user submissions: $e');
    }
  }

  Future<bool> submitGoodwill({
    required String performerUserId,
    required String actionType,
    required String description,
    required int lovesValue,
    required Map<String, dynamic> contextualData,
  }) async {
    state = state.copyWith(isProcessingGoodwill: true, error: null);
    
    final newSubmission = GoodwillAction(
      performerUserId: performerUserId,
      actionType: actionType,
      description: description,
      lovesValue: lovesValue,
      contextualData: contextualData,
      status: 'pending',
    );

    // Optimistically add to pending list
    state = state.copyWith(
      pendingSubmissions: [...state.pendingSubmissions, newSubmission],
    );

    try {
      final success = await _service.submitGoodwill(newSubmission);
      
      if (success) {
        // Refresh the actual data from server
        await _refreshUserSubmissions();
        state = state.copyWith(isProcessingGoodwill: false);
        return true;
      } else {
        // Remove from pending list if failed
        final updatedPending = List<GoodwillAction>.from(state.pendingSubmissions);
        updatedPending.remove(newSubmission);
        state = state.copyWith(
          isProcessingGoodwill: false,
          pendingSubmissions: updatedPending,
          error: 'Failed to submit goodwill action',
        );
        return false;
      }
    } catch (e) {
      // Remove from pending list if failed
      final updatedPending = List<GoodwillAction>.from(state.pendingSubmissions);
      updatedPending.remove(newSubmission);
      state = state.copyWith(
        isProcessingGoodwill: false,
        pendingSubmissions: updatedPending,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> calculateLovesValue({
    required String actionType,
    required String description,
    required String impactLevel,
    required int durationMinutes,
  }) async {
    try {
      return await _service.calculateLovesValue(
        actionType: actionType,
        description: description,
        impactLevel: impactLevel,
        durationMinutes: durationMinutes,
      );
    } catch (e) {
      print('Error calculating loves value: $e');
      return _service._calculateLovesLocally(
        description: description,
        impactLevel: impactLevel,
        durationMinutes: durationMinutes,
      );
    }
  }
}

class BackendStatusNotifier extends StateNotifier<BackendStatus?> {
  final FlaskGoodwillService _service;
  Timer? _refreshTimer;

  BackendStatusNotifier(this._service) : super(null) {
    _fetchStatus();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _service.getBackendStatus();
      state = status;
    } catch (e) {
      print('Error fetching backend status: $e');
      // Keep the previous state if fetch fails
    }
  }
}

// User provider using Firebase Auth
class UserNotifier extends StateNotifier<User?> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  UserNotifier() : super(null) {
    _authSubscription = _auth.authStateChanges().listen((user) {
      state = user;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// --- RIVERPOD PROVIDERS ---

// Use the same Flask base URL as the ledger page
final flaskBaseUrlProvider = Provider<String>((ref) {
  return 'http://your-flask-backend-url.com'; // Replace with your actual URL
});

final flaskGoodwillServiceProvider = Provider<FlaskGoodwillService>((ref) {
  final baseUrl = ref.watch(flaskBaseUrlProvider);
  return FlaskGoodwillService(baseUrl: baseUrl);
});

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

final goodwillProcessingProvider = StateNotifierProvider<GoodwillProcessingNotifier, GoodwillProcessingState>((ref) {
  final service = ref.watch(flaskGoodwillServiceProvider);
  return GoodwillProcessingNotifier(service);
});

final backendStatusProvider = StateNotifierProvider<BackendStatusNotifier, BackendStatus?>((ref) {
  final service = ref.watch(flaskGoodwillServiceProvider);
  return BackendStatusNotifier(service);
});

// --- WIDGETS ---

const Map<String, IconData> _actTypes = {
  'Mentorship': Icons.school_outlined,
  'Volunteering': Icons.volunteer_activism_outlined,
  'Donation': Icons.monetization_on_outlined,
  'Support': Icons.support_agent_outlined,
  'Kindness': Icons.favorite_border,
  'Community': Icons.groups_outlined,
  'Environment': Icons.eco_outlined,
  'Other': Icons.more_horiz,
};

class SubmitGoodwillPage extends ConsumerStatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  ConsumerState<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends ConsumerState<SubmitGoodwillPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _actionType = '';
  String _description = '';
  String _impactLevel = 'Medium';

  int _lovesValue = 25;
  int _durationMinutes = 0;
  bool _isCalculatingLoves = false;

  late final TabController _tabController;
  OverlayEntry? _celebrationOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _celebrationOverlay?.remove();
    super.dispose();
  }

  Future<void> _updateLovesScore() async {
    if (_actionType?.isEmpty == true || _description.trim()?.isEmpty == true) return;
    
    setState(() => _isCalculatingLoves = true);
    
    try {
      final result = await ref.read(goodwillProcessingProvider.notifier).calculateLovesValue(
        actionType: _actionType,
        description: _description,
        impactLevel: _impactLevel,
        durationMinutes: _durationMinutes,
      );
      
      if (mounted) {
        setState(() {
          _lovesValue = result['loves_value'] ?? 25;
          _isCalculatingLoves = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculatingLoves = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating loves: $e')),
        );
      }
    }
  }

  void _showSuccessOverlay() {
    _celebrationOverlay = OverlayEntry(
      builder: (_) => const CyclingCelebrationOverlay(
        message: "Submission Successful!",
      ),
    );

    Overlay.of(context).insert(_celebrationOverlay!);

    Future.delayed(const Duration(seconds: 12), () { // 4 seconds per effect, 3 effects
      _celebrationOverlay?.remove();
      _celebrationOverlay = null;
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  bool _validateAndSaveStep(int step) {
    switch (step) {
      case 0:
        if (_actionType?.isEmpty == true) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please choose a type of act.'), backgroundColor: Colors.redAccent),
          );
          return false;
        }
        return true;
      case 1:
        if (!(_formKey.currentState?.validate() == false)) return false;
        _formKey.currentState!.save();
        _updateLovesScore();
        return true;
      case 3:
        if (_durationMinutes <= 0) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid duration (minutes).'), backgroundColor: Colors.redAccent),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitForm() async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Please sign in to submit."), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final success = await ref.read(goodwillProcessingProvider.notifier).submitGoodwill(
      performerUserId: currentUser.uid,
      actionType: _actionType,
      description: _description.trim(),
      lovesValue: _lovesValue,
      contextualData: {
        'duration_minutes': _durationMinutes,
        'impact_level': _impactLevel,
        'submitted_at': DateTime.now().toIso8601String(),
      },
    );

    if (success && mounted) {
      _showSuccessOverlay();
      setState(() {
        _currentStep = 0;
        _actionType = '';
        _description = '';
        _impactLevel = 'Medium';
        _durationMinutes = 0;
        _lovesValue = 25;
      });
    } else if (mounted) {
      final error = ref.read(goodwillProcessingProvider).error;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit act: ${error ?? "Unknown error"}')),
      );
    }
  }

  VoidCallback _handleStepContinue() {
    return () async {
      final isStepValid = _validateAndSaveStep(_currentStep);
      if (!isStepValid) return;

      if (_currentStep < 4) {
        setState(() => _currentStep += 1);
      } else {
        await _submitForm();
      }
    };
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final goodwillState = ref.watch(goodwillProcessingProvider);
    
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: goodwillState.isProcessingGoodwill ? null : details.onStepCancel,
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: goodwillState.isProcessingGoodwill || _isCalculatingLoves 
                ? null 
                : details.onStepContinue,
            icon: goodwillState.isProcessingGoodwill || _isCalculatingLoves
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Icon(_currentStep == 4 ? Icons.check_circle_outline : Icons.arrow_forward),
            label: Text(
              goodwillState.isProcessingGoodwill 
                  ? 'Submitting...'
                  : _isCalculatingLoves
                      ? 'Calculating...'
                      : _currentStep == 4 
                          ? 'Submit' 
                          : 'Next'
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Choose', style: TextStyle(color: Colors.white)),
        content: _buildStep1ChooseAct(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Describe', style: TextStyle(color: Colors.white)),
        content: _buildStep2Describe(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Value', style: TextStyle(color: Colors.white)),
        content: _buildStep3LovesSlider(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Details', style: TextStyle(color: Colors.white)),
        content: _buildStep4DurationImpact(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: _buildStep5Summary(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  // --- Step Content Widgets ---

  Widget _buildStep1ChooseAct() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _actTypes.entries.map((entry) {
        final selected = _actionType == entry.key;
        return ChoiceChip(
          label: Text(entry.key),
          avatar: Icon(entry.value, color: selected ? Colors.white : Colors.black54),
          selected: selected,
          onSelected: (v) {
            setState(() => _actionType = v ? entry.key : '');
          },
          selectedColor: Colors.amber[700],
          backgroundColor: Colors.grey[800],
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
        );
      }).toList(),
    );
  }

  Widget _buildStep2Describe() {
    return Form(
      key: _formKey,
      child: TextFormField(
        initialValue: _description,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Describe your act of goodwill in detail...',
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(),
          helperText: 'Be specific about what you did, who it helped, and the impact it had.',
        ),
        validator: (val) {
          if (val == null || val.trim()?.isEmpty == true) {
            return 'Description cannot be empty';
          }
          if ((val?.trim()?.length ?? 0) < 10) {
            return 'Please provide a more detailed description (at least 10 characters)';
          }
          return null;
        },
        onSaved: (val) => _description = val ?? '',
        onChanged: (val) {
          _description = val;
          // Auto-calculate loves when description changes
          if (val.length > 10 && _actionType.isNotEmpty) {
            _updateLovesScore();
          }
        },
      ),
    );
  }

  Widget _buildStep3LovesSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Loves Value: $_lovesValue', style: const TextStyle(color: Colors.white, fontSize: 16)),
            if (_isCalculatingLoves)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          min: 1,
          max: 100,
          divisions: 99,
          value: _lovesValue.toDouble(),
          onChanged: (val) => setState(() => _lovesValue = val.toInt()),
          activeColor: Colors.amber,
          inactiveColor: Colors.amber[200],
        ),
        const SizedBox(height: 8),
        const Text(
          'This value will be automatically calculated based on your description, but you can adjust it if needed.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep4DurationImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _impactLevel,
          decoration: const InputDecoration(
            labelText: 'Impact Level',
            filled: true,
            fillColor: Colors.white12,
            helperText: 'How significant was the impact of your action?',
          ),
          items: ['Low', 'Medium', 'High']
              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
              .toList(),
          onChanged: (val) {
            setState(() => _impactLevel = val ?? 'Medium');
            _updateLovesScore();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Duration (minutes)',
            filled: true,
            fillColor: Colors.white12,
            helperText: 'How long did this action take?',
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val!);
            if (parsed != null) {
              setState(() => _durationMinutes = parsed);
              _updateLovesScore();
            }
          },
          validator: (val) {
            if (val == null || val?.isEmpty == true) return 'Duration required';
            final parsed = int.tryParse(val!);
            if (parsed == null || parsed <= 0) return 'Enter valid positive minutes';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep5Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.grey[800],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_actTypes[_actionType], color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('Type: $_actionType', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Description:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_description, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loves Value: $_lovesValue', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        Text('Impact Level: $_impactLevel', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Duration: $_durationMinutes min', style: const TextStyle(color: Colors.white70)),
                        Text('Status: Pending Review', style: TextStyle(color: Colors.orange[300])),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'By submitting this goodwill action, you confirm that the information provided is accurate and that this action was genuinely performed.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final goodwillState = ref.watch(goodwillProcessingProvider);
    final user = ref.watch(userProvider);

    // Show sign-in message if user is not authenticated
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Submit Bright Act'),
          backgroundColor: Colors.amber[800],
        ),
        backgroundColor: Colors.grey[900],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Please sign in to submit goodwill actions',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Bright Act'),
        backgroundColor: Colors.amber[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(goodwillProcessingProvider.notifier)._refreshUserSubmissions();
              ref.read(backendStatusProvider.notifier)._fetchStatus();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Submit Act'),
            Tab(icon: Icon(Icons.cloud_queue), text: 'Status & History'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: TabBarView(
        controller: _tabController,
        children: [
          // Submit Act Form
          Stepper(
            currentStep: _currentStep,
            onStepContinue: _handleStepContinue(),
            onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
            controlsBuilder: _buildControls,
            steps: _buildSteps(),
            type: StepperType.vertical,
            physics: const ClampingScrollPhysics(),
          ),

          // Status & History Tab
          const _BackendStatusTab(),
        ],
      ),
      floatingActionButton: goodwillState.isProcessingGoodwill
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.amber,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : null,
    );
  }
}

/// Widget to display backend status & user submissions
class _BackendStatusTab extends ConsumerWidget {
  const _BackendStatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendStatus = ref.watch(backendStatusProvider);
    final goodwillState = ref.watch(goodwillProcessingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(backendStatusProvider.notifier)._fetchStatus(),
          ref.read(goodwillProcessingProvider.notifier)._refreshUserSubmissions(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Status Card
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Backend Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (backendStatus == null)
                      const Center(child: CircularProgressIndicator(color: Colors.amber))
                    else ...[
                      Text('Node Version: ${backendStatus.nodeVersion}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Total Submissions: ${backendStatus.totalSubmissions}', 
                           style: const TextStyle(color: Colors.white70)),
                      Text('Pending Review: ${backendStatus.pendingCount}', 
                           style: const TextStyle(color: Colors.orange)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip('Metabolic System', backendStatus.metabolicActive),
                          _statusChip('Nervous System', backendStatus.nervousActive),
                          _statusChip('Endocrine System', backendStatus.endocrineActive),
                          _statusChip('Immune System', backendStatus.immuneActive),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Recent Events Card
            if (backendStatus != null && backendStatus.recentEvents.isNotEmpty) ...[
              Card(
                color: Colors.grey[800],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Recent Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...backendStatus.recentEvents.take(5).map((event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(event, style: const TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pending Submissions Card
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_empty, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Pending Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                        const Spacer(),
                        Text('${goodwillState.pendingSubmissions.length}', 
                             style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (goodwillState.pendingSubmissions?.isEmpty == true)
                      const Text('No pending submissions.', style: TextStyle(color: Colors.white70))
                    else
                      _PendingSubmissionsList(pending: goodwillState.pendingSubmissions),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Submissions Card
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Recent Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (goodwillState.recentSubmissions?.isEmpty == true)
                      const Text('No recent submissions.', style: TextStyle(color: Colors.white70))
                    else
                      _RecentSubmissionsList(recent: goodwillState.recentSubmissions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: active ? Colors.greenAccent : Colors.redAccent,
        size: 16,
      ),
      backgroundColor: Colors.grey[700],
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Widget showing pending goodwill submissions
class _PendingSubmissionsList extends StatelessWidget {
  final List<GoodwillAction> pending;

  const _PendingSubmissionsList({required this.pending});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: pending.map((submission) => Card(
        color: Colors.grey[700],
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.2),
            child: const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
          ),
          title: Text(submission.actionType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                submission.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${submission.lovesValue} ❤️', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('${submission.contextualData['duration_minutes'] ?? 0} min', 
                       style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          trailing: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12)),
        ),
      )).toList(),
    );
  }
}

/// Widget showing recent goodwill submissions
class _RecentSubmissionsList extends StatelessWidget {
  final List<GoodwillAction> recent;

  const _RecentSubmissionsList({required this.recent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: recent.map((submission) {
        final status = submission.status ?? 'unknown';
        final statusColor = status == 'approved' 
            ? Colors.green 
            : status == 'rejected' 
                ? Colors.red 
                : Colors.orange;
        
        return Card(
          color: Colors.grey[700],
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(
                status == 'approved' 
                    ? Icons.check_circle 
                    : status == 'rejected' 
                        ? Icons.cancel 
                        : Icons.hourglass_empty,
                color: statusColor,
                size: 16,
              ),
            ),
            title: Text(submission.actionType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${submission.lovesValue} ❤️', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(width: 8),
                    if (submission.createdAt != null)
                      Text(
                        _formatDate(submission.createdAt!),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              status.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

// --- MAIN APP ENTRY POINT ---

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Goodwill App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const SubmitGoodwillPage(),
    );
  }
}

// ==========================================================
// COMBINED AND ENHANCED CELEBRATION OVERLAY
// ==========================================================

/// The main widget that cycles through multiple celebration effects.
/// It also displays a success message.
class CyclingCelebrationOverlay extends StatefulWidget {
  final Duration cycleDuration;
  final String message;

  const CyclingCelebrationOverlay({
    Key? key,
    this.cycleDuration = const Duration(seconds: 4),
    this.message = 'Submission Successful!',
  }) : super(key: key);

  @override
  State<CyclingCelebrationOverlay> createState() => _CyclingCelebrationOverlayState();
}

class _CyclingCelebrationOverlayState extends State<CyclingCelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Widget Function(Animation<double>)> _effectsBuilders = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _effectsBuilders.addAll([
      (anim) => ConfettiOverlay(controller: anim),
      (anim) => HeartsOverlay(controller: anim),
      (anim) => SparklesOverlay(controller: anim),
    ]);

    _controller = AnimationController(vsync: this, duration: widget.cycleDuration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _effectsBuilders.length;
        });
        _controller.forward(from: 0.0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = _effectsBuilders[_currentIndex];
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // The cycling particle effects
            builder(_controller),
            
            // The success message text
            Align(
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 8.0,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONFETTI EFFECT ---

class ConfettiOverlay extends StatelessWidget {
  final Animation<double> controller;

  const ConfettiOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: ConfettiPainter(progress: controller.value),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int particleCount = (progress * 100).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * (1 - progress);
      paint.color = Color.fromARGB(
        (255 * (1 - progress)).toInt(),
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
      );

      final radius = _random.nextDouble() * 4 + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

// --- HEARTS EFFECT ---

class HeartsOverlay extends StatelessWidget {
  final Animation<double> controller;

  const HeartsOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: HeartsPainter(progress: controller.value),
      ),
    );
  }
}

class HeartsPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  HeartsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    int particleCount = (progress * 40).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = size.height - (_random.nextDouble() * size.height * progress);
      final scale = 0.5 + _random.nextDouble();

      paint.color = Colors.red.withOpacity(1 - progress);

      _drawHeart(canvas, paint, Offset(x, y), 10 * scale);
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();

    final double x = center.dx;
    final double y = center.dy;
    final double s = size / 2;

    path.moveTo(x, y + s / 4);
    path.cubicTo(x, y, x - s, y, x - s, y + s / 2);
    path.cubicTo(x - s, y + s, x, y + s * 1.5, x, y + s * 2);
    path.cubicTo(x, y + s * 1.5, x + s, y + s, x + s, y + s / 2);
    path.cubicTo(x + s, y, x, y, x, y + s / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) => oldDelegate.progress != progress;
}

// --- SPARKLES EFFECT ---

class SparklesOverlay extends StatelessWidget {
  final Animation<double> controller;

  const SparklesOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: SparklesPainter(progress: controller.value),
      ),
    );
  }
}

class SparklesPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int sparkleCount = (progress * 80).toInt();

    for (int i = 0; i < sparkleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      paint.color = Colors.white.withOpacity(1 - progress);

      _drawSparkle(canvas, paint, Offset(x, y), 3 + 2 * (1 - progress));
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final s = size / 2;

    path.moveTo(center.dx, center.dy - s);
    path.lineTo(center.dx + s / 3, center.dy - s / 3);
    path.lineTo(center.dx + s, center.dy);
    path.lineTo(center.dx + s / 3, center.dy + s / 3);
    path.lineTo(center.dx, center.dy + s);
    path.lineTo(center.dx - s / 3, center.dy + s / 3);
    path.lineTo(center.dx - s, center.dy);
    path.lineTo(center.dx - s / 3, center.dy - s / 3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) => oldDelegate.progress != progress;
}
