import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/date_json.dart';
import '../../../core/utils/decimal_json.dart';

part 'profit_records.freezed.dart';
part 'profit_records.g.dart';

/// Column limits (`backend/app/modules/profit/schemas.py`): NUMERIC(precision, scale)
/// and text lengths. The app validates with the same bounds; the server stays the authority.
abstract final class ProfitLimits {
  static const money = (maxDigits: 12, places: 2);
  static const distanceKm = (maxDigits: 8, places: 2);
  static const hours = (maxDigits: 5, places: 2);
  static final maxHours = Decimal.fromInt(24);
  static const maxOrderCount = 10000;
  static const notesMaxLength = 500;
  static const sourceLabelMaxLength = 50;
  static final firstDate = DateTime.utc(2000);
  static final lastDate = DateTime.utc(2100, 12, 31);

  /// A work session may last at most this long (`work_session_too_long`).
  static const maxSession = Duration(hours: 24);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum ExpenseCategory { fuel, maintenance, depreciation, other }

/// `GET /income/{id}`.
@freezed
abstract class Income with _$Income {
  const factory Income({
    required String id,
    @DateOnlyConverter() required DateTime occurredOn,
    @DecimalConverter() required Decimal amount,
    String? workSessionId,
    int? orderCount,
    @NullableDecimalConverter() Decimal? distanceKm,
    @NullableDecimalConverter() Decimal? workingHours,
    String? sourceLabel,
    String? notes,
    @Default(false) bool isDemo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Income;

  factory Income.fromJson(Map<String, dynamic> json) => _$IncomeFromJson(json);
}

/// `POST /income` and `PATCH /income/{id}` body. Every field is sent, so an empty
/// optional field clears the stored value on update.
@Freezed(fromJson: false, toJson: true)
abstract class IncomeInput with _$IncomeInput {
  @JsonSerializable(includeIfNull: true)
  const factory IncomeInput({
    @DateOnlyConverter() required DateTime occurredOn,
    @DecimalConverter() required Decimal amount,
    String? workSessionId,
    int? orderCount,
    @NullableDecimalConverter() Decimal? distanceKm,
    @NullableDecimalConverter() Decimal? workingHours,
    String? sourceLabel,
    String? notes,
  }) = _IncomeInput;
}

/// `GET /expenses/{id}`.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    @DateOnlyConverter() required DateTime occurredOn,
    required ExpenseCategory category,
    @DecimalConverter() required Decimal amount,
    String? workSessionId,
    String? description,
    @Default(false) bool isDemo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

/// `POST /expenses` and `PATCH /expenses/{id}` body. `work_session_id` is not part of
/// the form, so it is never sent and an existing link stays as it is.
@Freezed(fromJson: false, toJson: true)
abstract class ExpenseInput with _$ExpenseInput {
  @JsonSerializable(includeIfNull: true)
  const factory ExpenseInput({
    @DateOnlyConverter() required DateTime occurredOn,
    required ExpenseCategory category,
    @DecimalConverter() required Decimal amount,
    String? description,
  }) = _ExpenseInput;
}

/// `GET /work-sessions/{id}`. Times are converted to the device's local time.
@freezed
abstract class WorkSession with _$WorkSession {
  const WorkSession._();

  const factory WorkSession({
    required String id,
    @AwareDateTimeConverter() required DateTime startedAt,
    @AwareDateTimeConverter() required DateTime endedAt,
    @NullableDecimalConverter() Decimal? distanceKm,
    int? orderCount,
    String? notes,
    @Default(false) bool isDemo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkSession;

  factory WorkSession.fromJson(Map<String, dynamic> json) =>
      _$WorkSessionFromJson(json);

  Duration get duration => endedAt.difference(startedAt);
}

/// `POST /work-sessions` and `PATCH /work-sessions/{id}` body. Times carry the
/// device's UTC offset.
@Freezed(fromJson: false, toJson: true)
abstract class WorkSessionInput with _$WorkSessionInput {
  @JsonSerializable(includeIfNull: true)
  const factory WorkSessionInput({
    @AwareDateTimeConverter() required DateTime startedAt,
    @AwareDateTimeConverter() required DateTime endedAt,
    @NullableDecimalConverter() Decimal? distanceKm,
    int? orderCount,
    String? notes,
  }) = _WorkSessionInput;
}
