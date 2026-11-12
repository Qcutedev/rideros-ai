import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/utils/date_json.dart';
import '../domain/profit_records.dart';
import '../domain/profit_repositories.dart';
import '../domain/profit_summary.dart';
import '../domain/work_patterns.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => ApiRecordRepository(
    ref.watch(apiClientProvider),
    path: '/income',
    fromJson: Income.fromJson,
    toJson: (input) => input.toJson(),
  ),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ApiRecordRepository(
    ref.watch(apiClientProvider),
    path: '/expenses',
    fromJson: Expense.fromJson,
    toJson: (input) => input.toJson(),
  ),
);

final workSessionRepositoryProvider = Provider<WorkSessionRepository>(
  (ref) => ApiRecordRepository(
    ref.watch(apiClientProvider),
    path: '/work-sessions',
    fromJson: WorkSession.fromJson,
    toJson: (input) => input.toJson(),
  ),
);

final profitRepositoryProvider = Provider<ProfitRepository>(
  (ref) => ProfitRepositoryImpl(ref.watch(apiClientProvider)),
);

class ApiRecordRepository<T, I> implements RecordRepository<T, I> {
  ApiRecordRepository(
    this._dio, {
    required this.path,
    required this.fromJson,
    required this.toJson,
  });

  final Dio _dio;
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(I input) toJson;

  @override
  Future<PagedResult<T>> list({String? cursor, DateTime? from, DateTime? to}) =>
      guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          path,
          queryParameters: {
            'cursor': ?cursor,
            if (from != null) 'from': formatIsoDate(from),
            if (to != null) 'to': formatIsoDate(to),
          },
        );
        return PagedResult.fromJson(response.data!, fromJson);
      });

  @override
  Future<T> get(String id) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('$path/$id');
    return fromJson(response.data!);
  });

  @override
  Future<T> create(I input) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: toJson(input),
    );
    return fromJson(response.data!);
  });

  @override
  Future<T> update(String id, I input) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$path/$id',
      data: toJson(input),
    );
    return fromJson(response.data!);
  });

  @override
  Future<void> delete(String id) => guardApi(() async {
    await _dio.delete<void>('$path/$id');
  });
}

class ProfitRepositoryImpl implements ProfitRepository {
  ProfitRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<ProfitSummary> summary(ProfitPeriod period, {DateTime? date}) =>
      guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/profit/summary',
          queryParameters: {
            'period': period.name,
            if (date != null) 'date': formatIsoDate(date),
          },
        );
        return ProfitSummary.fromJson(response.data!);
      });

  @override
  Future<ProfitTrends> trends(
    ProfitPeriod granularity, {
    DateTime? from,
    DateTime? to,
  }) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/profit/trends',
      queryParameters: {
        'granularity': granularity.name,
        if (from != null) 'from': formatIsoDate(from),
        if (to != null) 'to': formatIsoDate(to),
      },
    );
    return ProfitTrends.fromJson(response.data!);
  });

  @override
  Future<WorkPatterns> patterns() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/profit/patterns');
    return WorkPatterns.fromJson(response.data!);
  });
}
