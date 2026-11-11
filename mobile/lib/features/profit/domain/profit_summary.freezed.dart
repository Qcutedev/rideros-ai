// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitMetrics {

@DecimalConverter() Decimal get totalRevenue;@DecimalConverter() Decimal get totalExpenses;@DecimalConverter() Decimal get netProfit;@DecimalConverter() Decimal get workingHours;/// `null` when [workingHours] is 0 ([reason] says why).
@NullableDecimalConverter() Decimal? get revenuePerHour;@NullableDecimalConverter() Decimal? get netProfitPerHour; String? get reason; int get incomeCount; int get expenseCount; int get workSessionCount;
/// Create a copy of ProfitMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitMetricsCopyWith<ProfitMetrics> get copyWith => _$ProfitMetricsCopyWithImpl<ProfitMetrics>(this as ProfitMetrics, _$identity);

  /// Serializes this ProfitMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProfitMetrics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitMetrics&&(identical(other.totalRevenue, _this.totalRevenue) || other.totalRevenue == _this.totalRevenue)&&(identical(other.totalExpenses, _this.totalExpenses) || other.totalExpenses == _this.totalExpenses)&&(identical(other.netProfit, _this.netProfit) || other.netProfit == _this.netProfit)&&(identical(other.workingHours, _this.workingHours) || other.workingHours == _this.workingHours)&&(identical(other.revenuePerHour, _this.revenuePerHour) || other.revenuePerHour == _this.revenuePerHour)&&(identical(other.netProfitPerHour, _this.netProfitPerHour) || other.netProfitPerHour == _this.netProfitPerHour)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.incomeCount, _this.incomeCount) || other.incomeCount == _this.incomeCount)&&(identical(other.expenseCount, _this.expenseCount) || other.expenseCount == _this.expenseCount)&&(identical(other.workSessionCount, _this.workSessionCount) || other.workSessionCount == _this.workSessionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProfitMetrics;
  return Object.hash(runtimeType,_this.totalRevenue,_this.totalExpenses,_this.netProfit,_this.workingHours,_this.revenuePerHour,_this.netProfitPerHour,_this.reason,_this.incomeCount,_this.expenseCount,_this.workSessionCount);
}

@override
String toString() {
  final _this = this as ProfitMetrics;
  return 'ProfitMetrics(totalRevenue: ${_this.totalRevenue}, totalExpenses: ${_this.totalExpenses}, netProfit: ${_this.netProfit}, workingHours: ${_this.workingHours}, revenuePerHour: ${_this.revenuePerHour}, netProfitPerHour: ${_this.netProfitPerHour}, reason: ${_this.reason}, incomeCount: ${_this.incomeCount}, expenseCount: ${_this.expenseCount}, workSessionCount: ${_this.workSessionCount})';
}


}

/// @nodoc
abstract mixin class $ProfitMetricsCopyWith<$Res>  {
  factory $ProfitMetricsCopyWith(ProfitMetrics value, $Res Function(ProfitMetrics) _then) = _$ProfitMetricsCopyWithImpl;
@useResult
$Res call({
@DecimalConverter() Decimal totalRevenue,@DecimalConverter() Decimal totalExpenses,@DecimalConverter() Decimal netProfit,@DecimalConverter() Decimal workingHours,@NullableDecimalConverter() Decimal? revenuePerHour,@NullableDecimalConverter() Decimal? netProfitPerHour, String? reason, int incomeCount, int expenseCount, int workSessionCount
});




}
/// @nodoc
class _$ProfitMetricsCopyWithImpl<$Res>
    implements $ProfitMetricsCopyWith<$Res> {
  _$ProfitMetricsCopyWithImpl(this._self, this._then);

  final ProfitMetrics _self;
  final $Res Function(ProfitMetrics) _then;

/// Create a copy of ProfitMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalRevenue = null,Object? totalExpenses = null,Object? netProfit = null,Object? workingHours = null,Object? revenuePerHour = freezed,Object? netProfitPerHour = freezed,Object? reason = freezed,Object? incomeCount = null,Object? expenseCount = null,Object? workSessionCount = null,}) {
  return _then(ProfitMetrics(
totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as Decimal,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as Decimal,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as Decimal,workingHours: null == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal,revenuePerHour: freezed == revenuePerHour ? _self.revenuePerHour : revenuePerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,netProfitPerHour: freezed == netProfitPerHour ? _self.netProfitPerHour : netProfitPerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,incomeCount: null == incomeCount ? _self.incomeCount : incomeCount // ignore: cast_nullable_to_non_nullable
as int,expenseCount: null == expenseCount ? _self.expenseCount : expenseCount // ignore: cast_nullable_to_non_nullable
as int,workSessionCount: null == workSessionCount ? _self.workSessionCount : workSessionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitMetrics].
extension ProfitMetricsPatterns on ProfitMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitMetrics value)  $default,){
final _that = this;
switch (_that) {
case _ProfitMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal totalRevenue, @DecimalConverter()  Decimal totalExpenses, @DecimalConverter()  Decimal netProfit, @DecimalConverter()  Decimal workingHours, @NullableDecimalConverter()  Decimal? revenuePerHour, @NullableDecimalConverter()  Decimal? netProfitPerHour,  String? reason,  int incomeCount,  int expenseCount,  int workSessionCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitMetrics() when $default != null:
return $default(_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.workingHours,_that.revenuePerHour,_that.netProfitPerHour,_that.reason,_that.incomeCount,_that.expenseCount,_that.workSessionCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal totalRevenue, @DecimalConverter()  Decimal totalExpenses, @DecimalConverter()  Decimal netProfit, @DecimalConverter()  Decimal workingHours, @NullableDecimalConverter()  Decimal? revenuePerHour, @NullableDecimalConverter()  Decimal? netProfitPerHour,  String? reason,  int incomeCount,  int expenseCount,  int workSessionCount)  $default,) {final _that = this;
switch (_that) {
case _ProfitMetrics():
return $default(_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.workingHours,_that.revenuePerHour,_that.netProfitPerHour,_that.reason,_that.incomeCount,_that.expenseCount,_that.workSessionCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalConverter()  Decimal totalRevenue, @DecimalConverter()  Decimal totalExpenses, @DecimalConverter()  Decimal netProfit, @DecimalConverter()  Decimal workingHours, @NullableDecimalConverter()  Decimal? revenuePerHour, @NullableDecimalConverter()  Decimal? netProfitPerHour,  String? reason,  int incomeCount,  int expenseCount,  int workSessionCount)?  $default,) {final _that = this;
switch (_that) {
case _ProfitMetrics() when $default != null:
return $default(_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.workingHours,_that.revenuePerHour,_that.netProfitPerHour,_that.reason,_that.incomeCount,_that.expenseCount,_that.workSessionCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitMetrics extends ProfitMetrics {
  const _ProfitMetrics({@DecimalConverter() required this.totalRevenue, @DecimalConverter() required this.totalExpenses, @DecimalConverter() required this.netProfit, @DecimalConverter() required this.workingHours, @NullableDecimalConverter() this.revenuePerHour, @NullableDecimalConverter() this.netProfitPerHour, this.reason, required this.incomeCount, required this.expenseCount, required this.workSessionCount}): super._();
  factory _ProfitMetrics.fromJson(Map<String, dynamic> json) => _$ProfitMetricsFromJson(json);

@override@DecimalConverter() final  Decimal totalRevenue;
@override@DecimalConverter() final  Decimal totalExpenses;
@override@DecimalConverter() final  Decimal netProfit;
@override@DecimalConverter() final  Decimal workingHours;
/// `null` when [workingHours] is 0 ([reason] says why).
@override@NullableDecimalConverter() final  Decimal? revenuePerHour;
@override@NullableDecimalConverter() final  Decimal? netProfitPerHour;
@override final  String? reason;
@override final  int incomeCount;
@override final  int expenseCount;
@override final  int workSessionCount;

/// Create a copy of ProfitMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitMetricsCopyWith<_ProfitMetrics> get copyWith => __$ProfitMetricsCopyWithImpl<_ProfitMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitMetrics&&(identical(other.totalRevenue, totalRevenue) || other.totalRevenue == totalRevenue)&&(identical(other.totalExpenses, totalExpenses) || other.totalExpenses == totalExpenses)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.workingHours, workingHours) || other.workingHours == workingHours)&&(identical(other.revenuePerHour, revenuePerHour) || other.revenuePerHour == revenuePerHour)&&(identical(other.netProfitPerHour, netProfitPerHour) || other.netProfitPerHour == netProfitPerHour)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.incomeCount, incomeCount) || other.incomeCount == incomeCount)&&(identical(other.expenseCount, expenseCount) || other.expenseCount == expenseCount)&&(identical(other.workSessionCount, workSessionCount) || other.workSessionCount == workSessionCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalRevenue,totalExpenses,netProfit,workingHours,revenuePerHour,netProfitPerHour,reason,incomeCount,expenseCount,workSessionCount);
}

@override
String toString() {
    return 'ProfitMetrics(totalRevenue: $totalRevenue, totalExpenses: $totalExpenses, netProfit: $netProfit, workingHours: $workingHours, revenuePerHour: $revenuePerHour, netProfitPerHour: $netProfitPerHour, reason: $reason, incomeCount: $incomeCount, expenseCount: $expenseCount, workSessionCount: $workSessionCount)';
}


}

/// @nodoc
abstract mixin class _$ProfitMetricsCopyWith<$Res> implements $ProfitMetricsCopyWith<$Res> {
  factory _$ProfitMetricsCopyWith(_ProfitMetrics value, $Res Function(_ProfitMetrics) _then) = __$ProfitMetricsCopyWithImpl;
@override @useResult
$Res call({
@DecimalConverter() Decimal totalRevenue,@DecimalConverter() Decimal totalExpenses,@DecimalConverter() Decimal netProfit,@DecimalConverter() Decimal workingHours,@NullableDecimalConverter() Decimal? revenuePerHour,@NullableDecimalConverter() Decimal? netProfitPerHour, String? reason, int incomeCount, int expenseCount, int workSessionCount
});




}
/// @nodoc
class __$ProfitMetricsCopyWithImpl<$Res>
    implements _$ProfitMetricsCopyWith<$Res> {
  __$ProfitMetricsCopyWithImpl(this._self, this._then);

  final _ProfitMetrics _self;
  final $Res Function(_ProfitMetrics) _then;

/// Create a copy of ProfitMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRevenue = null,Object? totalExpenses = null,Object? netProfit = null,Object? workingHours = null,Object? revenuePerHour = freezed,Object? netProfitPerHour = freezed,Object? reason = freezed,Object? incomeCount = null,Object? expenseCount = null,Object? workSessionCount = null,}) {
  return _then(_ProfitMetrics(
totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as Decimal,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as Decimal,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as Decimal,workingHours: null == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal,revenuePerHour: freezed == revenuePerHour ? _self.revenuePerHour : revenuePerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,netProfitPerHour: freezed == netProfitPerHour ? _self.netProfitPerHour : netProfitPerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,incomeCount: null == incomeCount ? _self.incomeCount : incomeCount // ignore: cast_nullable_to_non_nullable
as int,expenseCount: null == expenseCount ? _self.expenseCount : expenseCount // ignore: cast_nullable_to_non_nullable
as int,workSessionCount: null == workSessionCount ? _self.workSessionCount : workSessionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
