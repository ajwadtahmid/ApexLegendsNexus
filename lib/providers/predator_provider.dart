import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/predator.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

final predatorProvider = FutureProvider<ApiResult<PredatorResponse>>((
  ref,
) async {
  return ref.watch(predatorServiceProvider).getPredator();
});
