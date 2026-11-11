// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftAssumptions {

@NullableDecimalConverter() Decimal? get ordersPerHour;@NullableDecimalConverter() Decimal? get incomePerOrder;@NullableDecimalConverter() Decimal? get kmPerOrder;@NullableDecimalConverter() Decimal? get fuelKmPerLiter;@NullableDecimalConverter() Decimal? get fuelPricePerLiter;@NullableDecimalConverter() Decimal? get depreciationPerKm;/// Fixed costs of the shift (parking, food, ...). Both methods use it.
@NullableDecimalConverter() Decimal? get otherCosts;
/// Create a copy of ShiftAssumptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftAssumptionsCopyWith<ShiftAssumptions> get copyWith => _$ShiftAssumptionsCopyWithImpl<ShiftAssumptions>(this as ShiftAssumptions, _$identity);

  /// Serializes this ShiftAssumptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftAssumptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftAssumptions&&(identical(other.ordersPerHour, _this.ordersPerHour) || other.ordersPerHour == _this.ordersPerHour)&&(identical(other.incomePerOrder, _this.incomePerOrder) || other.incomePerOrder == _this.incomePerOrder)&&(identical(other.kmPerOrder, _this.kmPerOrder) || other.kmPerOrder == _this.kmPerOrder)&&(identical(other.fuelKmPerLiter, _this.fuelKmPerLiter) || other.fuelKmPerLiter == _this.fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, _this.fuelPricePerLiter) || other.fuelPricePerLiter == _this.fuelPricePerLiter)&&(identical(other.depreciationPerKm, _this.depreciationPerKm) || other.depreciationPerKm == _this.depreciationPerKm)&&(identical(other.otherCosts, _this.otherCosts) || other.otherCosts == _this.otherCosts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftAssumptions;
  return Object.hash(runtimeType,_this.ordersPerHour,_this.incomePerOrder,_this.kmPerOrder,_this.fuelKmPerLiter,_this.fuelPricePerLiter,_this.depreciationPerKm,_this.otherCosts);
}

@override
String toString() {
  final _this = this as ShiftAssumptions;
  return 'ShiftAssumptions(ordersPerHour: ${_this.ordersPerHour}, incomePerOrder: ${_this.incomePerOrder}, kmPerOrder: ${_this.kmPerOrder}, fuelKmPerLiter: ${_this.fuelKmPerLiter}, fuelPricePerLiter: ${_this.fuelPricePerLiter}, depreciationPerKm: ${_this.depreciationPerKm}, otherCosts: ${_this.otherCosts})';
}


}

/// @nodoc
abstract mixin class $ShiftAssumptionsCopyWith<$Res>  {
  factory $ShiftAssumptionsCopyWith(ShiftAssumptions value, $Res Function(ShiftAssumptions) _then) = _$ShiftAssumptionsCopyWithImpl;
@useResult
$Res call({
@NullableDecimalConverter() Decimal? ordersPerHour,@NullableDecimalConverter() Decimal? incomePerOrder,@NullableDecimalConverter() Decimal? kmPerOrder,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? otherCosts
});




}
/// @nodoc
class _$ShiftAssumptionsCopyWithImpl<$Res>
    implements $ShiftAssumptionsCopyWith<$Res> {
  _$ShiftAssumptionsCopyWithImpl(this._self, this._then);

  final ShiftAssumptions _self;
  final $Res Function(ShiftAssumptions) _then;

/// Create a copy of ShiftAssumptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ordersPerHour = freezed,Object? incomePerOrder = freezed,Object? kmPerOrder = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? otherCosts = freezed,}) {
  return _then(ShiftAssumptions(
ordersPerHour: freezed == ordersPerHour ? _self.ordersPerHour : ordersPerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,incomePerOrder: freezed == incomePerOrder ? _self.incomePerOrder : incomePerOrder // ignore: cast_nullable_to_non_nullable
as Decimal?,kmPerOrder: freezed == kmPerOrder ? _self.kmPerOrder : kmPerOrder // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,otherCosts: freezed == otherCosts ? _self.otherCosts : otherCosts // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftAssumptions].
extension ShiftAssumptionsPatterns on ShiftAssumptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftAssumptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftAssumptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftAssumptions value)  $default,){
final _that = this;
switch (_that) {
case _ShiftAssumptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftAssumptions value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftAssumptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@NullableDecimalConverter()  Decimal? ordersPerHour, @NullableDecimalConverter()  Decimal? incomePerOrder, @NullableDecimalConverter()  Decimal? kmPerOrder, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? otherCosts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftAssumptions() when $default != null:
return $default(_that.ordersPerHour,_that.incomePerOrder,_that.kmPerOrder,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.otherCosts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@NullableDecimalConverter()  Decimal? ordersPerHour, @NullableDecimalConverter()  Decimal? incomePerOrder, @NullableDecimalConverter()  Decimal? kmPerOrder, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? otherCosts)  $default,) {final _that = this;
switch (_that) {
case _ShiftAssumptions():
return $default(_that.ordersPerHour,_that.incomePerOrder,_that.kmPerOrder,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.otherCosts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@NullableDecimalConverter()  Decimal? ordersPerHour, @NullableDecimalConverter()  Decimal? incomePerOrder, @NullableDecimalConverter()  Decimal? kmPerOrder, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? otherCosts)?  $default,) {final _that = this;
switch (_that) {
case _ShiftAssumptions() when $default != null:
return $default(_that.ordersPerHour,_that.incomePerOrder,_that.kmPerOrder,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.otherCosts);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _ShiftAssumptions implements ShiftAssumptions {
  const _ShiftAssumptions({@NullableDecimalConverter() this.ordersPerHour, @NullableDecimalConverter() this.incomePerOrder, @NullableDecimalConverter() this.kmPerOrder, @NullableDecimalConverter() this.fuelKmPerLiter, @NullableDecimalConverter() this.fuelPricePerLiter, @NullableDecimalConverter() this.depreciationPerKm, @NullableDecimalConverter() this.otherCosts});
  factory _ShiftAssumptions.fromJson(Map<String, dynamic> json) => _$ShiftAssumptionsFromJson(json);

@override@NullableDecimalConverter() final  Decimal? ordersPerHour;
@override@NullableDecimalConverter() final  Decimal? incomePerOrder;
@override@NullableDecimalConverter() final  Decimal? kmPerOrder;
@override@NullableDecimalConverter() final  Decimal? fuelKmPerLiter;
@override@NullableDecimalConverter() final  Decimal? fuelPricePerLiter;
@override@NullableDecimalConverter() final  Decimal? depreciationPerKm;
/// Fixed costs of the shift (parking, food, ...). Both methods use it.
@override@NullableDecimalConverter() final  Decimal? otherCosts;

/// Create a copy of ShiftAssumptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftAssumptionsCopyWith<_ShiftAssumptions> get copyWith => __$ShiftAssumptionsCopyWithImpl<_ShiftAssumptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftAssumptionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftAssumptions&&(identical(other.ordersPerHour, ordersPerHour) || other.ordersPerHour == ordersPerHour)&&(identical(other.incomePerOrder, incomePerOrder) || other.incomePerOrder == incomePerOrder)&&(identical(other.kmPerOrder, kmPerOrder) || other.kmPerOrder == kmPerOrder)&&(identical(other.fuelKmPerLiter, fuelKmPerLiter) || other.fuelKmPerLiter == fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, fuelPricePerLiter) || other.fuelPricePerLiter == fuelPricePerLiter)&&(identical(other.depreciationPerKm, depreciationPerKm) || other.depreciationPerKm == depreciationPerKm)&&(identical(other.otherCosts, otherCosts) || other.otherCosts == otherCosts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ordersPerHour,incomePerOrder,kmPerOrder,fuelKmPerLiter,fuelPricePerLiter,depreciationPerKm,otherCosts);
}

@override
String toString() {
    return 'ShiftAssumptions(ordersPerHour: $ordersPerHour, incomePerOrder: $incomePerOrder, kmPerOrder: $kmPerOrder, fuelKmPerLiter: $fuelKmPerLiter, fuelPricePerLiter: $fuelPricePerLiter, depreciationPerKm: $depreciationPerKm, otherCosts: $otherCosts)';
}


}

/// @nodoc
abstract mixin class _$ShiftAssumptionsCopyWith<$Res> implements $ShiftAssumptionsCopyWith<$Res> {
  factory _$ShiftAssumptionsCopyWith(_ShiftAssumptions value, $Res Function(_ShiftAssumptions) _then) = __$ShiftAssumptionsCopyWithImpl;
@override @useResult
$Res call({
@NullableDecimalConverter() Decimal? ordersPerHour,@NullableDecimalConverter() Decimal? incomePerOrder,@NullableDecimalConverter() Decimal? kmPerOrder,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? otherCosts
});




}
/// @nodoc
class __$ShiftAssumptionsCopyWithImpl<$Res>
    implements _$ShiftAssumptionsCopyWith<$Res> {
  __$ShiftAssumptionsCopyWithImpl(this._self, this._then);

  final _ShiftAssumptions _self;
  final $Res Function(_ShiftAssumptions) _then;

/// Create a copy of ShiftAssumptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ordersPerHour = freezed,Object? incomePerOrder = freezed,Object? kmPerOrder = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? otherCosts = freezed,}) {
  return _then(_ShiftAssumptions(
ordersPerHour: freezed == ordersPerHour ? _self.ordersPerHour : ordersPerHour // ignore: cast_nullable_to_non_nullable
as Decimal?,incomePerOrder: freezed == incomePerOrder ? _self.incomePerOrder : incomePerOrder // ignore: cast_nullable_to_non_nullable
as Decimal?,kmPerOrder: freezed == kmPerOrder ? _self.kmPerOrder : kmPerOrder // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,otherCosts: freezed == otherCosts ? _self.otherCosts : otherCosts // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}


}


/// @nodoc
mixin _$ShiftScenario {

 String get id; String get name;@ClockTimeConverter() ClockTime get startTime;@ClockTimeConverter() ClockTime get endTime; int get durationMinutes;/// 0 = Monday ... 6 = Sunday; `null` = any day.
 int? get plannedWeekday; EstimationMethod get estimationMethod; ShiftAssumptions get assumptions; bool get isEstimate;@DecimalConverter() Decimal get estimatedRevenue;@DecimalConverter() Decimal get estimatedExpenses;@DecimalConverter() Decimal get estimatedNetProfit;@DecimalConverter() Decimal get estimatedNetProfitPerHour;/// P20-P80 range of the net profit (`historical` only).
@NullableDecimalConverter() Decimal? get estimateLow;@NullableDecimalConverter() Decimal? get estimateHigh;@_DetailsConverter() ShiftEstimateDetails get estimateDetails; String? get actualWorkSessionId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftScenarioCopyWith<ShiftScenario> get copyWith => _$ShiftScenarioCopyWithImpl<ShiftScenario>(this as ShiftScenario, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShiftScenario;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftScenario&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.durationMinutes, _this.durationMinutes) || other.durationMinutes == _this.durationMinutes)&&(identical(other.plannedWeekday, _this.plannedWeekday) || other.plannedWeekday == _this.plannedWeekday)&&(identical(other.estimationMethod, _this.estimationMethod) || other.estimationMethod == _this.estimationMethod)&&(identical(other.assumptions, _this.assumptions) || other.assumptions == _this.assumptions)&&(identical(other.isEstimate, _this.isEstimate) || other.isEstimate == _this.isEstimate)&&(identical(other.estimatedRevenue, _this.estimatedRevenue) || other.estimatedRevenue == _this.estimatedRevenue)&&(identical(other.estimatedExpenses, _this.estimatedExpenses) || other.estimatedExpenses == _this.estimatedExpenses)&&(identical(other.estimatedNetProfit, _this.estimatedNetProfit) || other.estimatedNetProfit == _this.estimatedNetProfit)&&(identical(other.estimatedNetProfitPerHour, _this.estimatedNetProfitPerHour) || other.estimatedNetProfitPerHour == _this.estimatedNetProfitPerHour)&&(identical(other.estimateLow, _this.estimateLow) || other.estimateLow == _this.estimateLow)&&(identical(other.estimateHigh, _this.estimateHigh) || other.estimateHigh == _this.estimateHigh)&&(identical(other.estimateDetails, _this.estimateDetails) || other.estimateDetails == _this.estimateDetails)&&(identical(other.actualWorkSessionId, _this.actualWorkSessionId) || other.actualWorkSessionId == _this.actualWorkSessionId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftScenario;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.startTime,_this.endTime,_this.durationMinutes,_this.plannedWeekday,_this.estimationMethod,_this.assumptions,_this.isEstimate,_this.estimatedRevenue,_this.estimatedExpenses,_this.estimatedNetProfit,_this.estimatedNetProfitPerHour,_this.estimateLow,_this.estimateHigh,_this.estimateDetails,_this.actualWorkSessionId,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as ShiftScenario;
  return 'ShiftScenario(id: ${_this.id}, name: ${_this.name}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, durationMinutes: ${_this.durationMinutes}, plannedWeekday: ${_this.plannedWeekday}, estimationMethod: ${_this.estimationMethod}, assumptions: ${_this.assumptions}, isEstimate: ${_this.isEstimate}, estimatedRevenue: ${_this.estimatedRevenue}, estimatedExpenses: ${_this.estimatedExpenses}, estimatedNetProfit: ${_this.estimatedNetProfit}, estimatedNetProfitPerHour: ${_this.estimatedNetProfitPerHour}, estimateLow: ${_this.estimateLow}, estimateHigh: ${_this.estimateHigh}, estimateDetails: ${_this.estimateDetails}, actualWorkSessionId: ${_this.actualWorkSessionId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ShiftScenarioCopyWith<$Res>  {
  factory $ShiftScenarioCopyWith(ShiftScenario value, $Res Function(ShiftScenario) _then) = _$ShiftScenarioCopyWithImpl;
@useResult
$Res call({
 String id, String name,@ClockTimeConverter() ClockTime startTime,@ClockTimeConverter() ClockTime endTime, int durationMinutes, int? plannedWeekday, EstimationMethod estimationMethod, ShiftAssumptions assumptions, bool isEstimate,@DecimalConverter() Decimal estimatedRevenue,@DecimalConverter() Decimal estimatedExpenses,@DecimalConverter() Decimal estimatedNetProfit,@DecimalConverter() Decimal estimatedNetProfitPerHour,@NullableDecimalConverter() Decimal? estimateLow,@NullableDecimalConverter() Decimal? estimateHigh,@_DetailsConverter() ShiftEstimateDetails estimateDetails, String? actualWorkSessionId, DateTime createdAt, DateTime updatedAt
});


$ShiftAssumptionsCopyWith<$Res> get assumptions;

}
/// @nodoc
class _$ShiftScenarioCopyWithImpl<$Res>
    implements $ShiftScenarioCopyWith<$Res> {
  _$ShiftScenarioCopyWithImpl(this._self, this._then);

  final ShiftScenario _self;
  final $Res Function(ShiftScenario) _then;

/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? startTime = null,Object? endTime = null,Object? durationMinutes = null,Object? plannedWeekday = freezed,Object? estimationMethod = null,Object? assumptions = null,Object? isEstimate = null,Object? estimatedRevenue = null,Object? estimatedExpenses = null,Object? estimatedNetProfit = null,Object? estimatedNetProfitPerHour = null,Object? estimateLow = freezed,Object? estimateHigh = freezed,Object? estimateDetails = null,Object? actualWorkSessionId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(ShiftScenario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,plannedWeekday: freezed == plannedWeekday ? _self.plannedWeekday : plannedWeekday // ignore: cast_nullable_to_non_nullable
as int?,estimationMethod: null == estimationMethod ? _self.estimationMethod : estimationMethod // ignore: cast_nullable_to_non_nullable
as EstimationMethod,assumptions: null == assumptions ? _self.assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as ShiftAssumptions,isEstimate: null == isEstimate ? _self.isEstimate : isEstimate // ignore: cast_nullable_to_non_nullable
as bool,estimatedRevenue: null == estimatedRevenue ? _self.estimatedRevenue : estimatedRevenue // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedExpenses: null == estimatedExpenses ? _self.estimatedExpenses : estimatedExpenses // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedNetProfit: null == estimatedNetProfit ? _self.estimatedNetProfit : estimatedNetProfit // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedNetProfitPerHour: null == estimatedNetProfitPerHour ? _self.estimatedNetProfitPerHour : estimatedNetProfitPerHour // ignore: cast_nullable_to_non_nullable
as Decimal,estimateLow: freezed == estimateLow ? _self.estimateLow : estimateLow // ignore: cast_nullable_to_non_nullable
as Decimal?,estimateHigh: freezed == estimateHigh ? _self.estimateHigh : estimateHigh // ignore: cast_nullable_to_non_nullable
as Decimal?,estimateDetails: null == estimateDetails ? _self.estimateDetails : estimateDetails // ignore: cast_nullable_to_non_nullable
as ShiftEstimateDetails,actualWorkSessionId: freezed == actualWorkSessionId ? _self.actualWorkSessionId : actualWorkSessionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShiftAssumptionsCopyWith<$Res> get assumptions {
  
  return $ShiftAssumptionsCopyWith<$Res>(_self.assumptions, (value) {
    return _then(_self.copyWith(assumptions: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShiftScenario].
extension ShiftScenarioPatterns on ShiftScenario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftScenario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftScenario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftScenario value)  $default,){
final _that = this;
switch (_that) {
case _ShiftScenario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftScenario value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftScenario() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int durationMinutes,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions,  bool isEstimate, @DecimalConverter()  Decimal estimatedRevenue, @DecimalConverter()  Decimal estimatedExpenses, @DecimalConverter()  Decimal estimatedNetProfit, @DecimalConverter()  Decimal estimatedNetProfitPerHour, @NullableDecimalConverter()  Decimal? estimateLow, @NullableDecimalConverter()  Decimal? estimateHigh, @_DetailsConverter()  ShiftEstimateDetails estimateDetails,  String? actualWorkSessionId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftScenario() when $default != null:
return $default(_that.id,_that.name,_that.startTime,_that.endTime,_that.durationMinutes,_that.plannedWeekday,_that.estimationMethod,_that.assumptions,_that.isEstimate,_that.estimatedRevenue,_that.estimatedExpenses,_that.estimatedNetProfit,_that.estimatedNetProfitPerHour,_that.estimateLow,_that.estimateHigh,_that.estimateDetails,_that.actualWorkSessionId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int durationMinutes,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions,  bool isEstimate, @DecimalConverter()  Decimal estimatedRevenue, @DecimalConverter()  Decimal estimatedExpenses, @DecimalConverter()  Decimal estimatedNetProfit, @DecimalConverter()  Decimal estimatedNetProfitPerHour, @NullableDecimalConverter()  Decimal? estimateLow, @NullableDecimalConverter()  Decimal? estimateHigh, @_DetailsConverter()  ShiftEstimateDetails estimateDetails,  String? actualWorkSessionId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShiftScenario():
return $default(_that.id,_that.name,_that.startTime,_that.endTime,_that.durationMinutes,_that.plannedWeekday,_that.estimationMethod,_that.assumptions,_that.isEstimate,_that.estimatedRevenue,_that.estimatedExpenses,_that.estimatedNetProfit,_that.estimatedNetProfitPerHour,_that.estimateLow,_that.estimateHigh,_that.estimateDetails,_that.actualWorkSessionId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int durationMinutes,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions,  bool isEstimate, @DecimalConverter()  Decimal estimatedRevenue, @DecimalConverter()  Decimal estimatedExpenses, @DecimalConverter()  Decimal estimatedNetProfit, @DecimalConverter()  Decimal estimatedNetProfitPerHour, @NullableDecimalConverter()  Decimal? estimateLow, @NullableDecimalConverter()  Decimal? estimateHigh, @_DetailsConverter()  ShiftEstimateDetails estimateDetails,  String? actualWorkSessionId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShiftScenario() when $default != null:
return $default(_that.id,_that.name,_that.startTime,_that.endTime,_that.durationMinutes,_that.plannedWeekday,_that.estimationMethod,_that.assumptions,_that.isEstimate,_that.estimatedRevenue,_that.estimatedExpenses,_that.estimatedNetProfit,_that.estimatedNetProfitPerHour,_that.estimateLow,_that.estimateHigh,_that.estimateDetails,_that.actualWorkSessionId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _ShiftScenario extends ShiftScenario {
  const _ShiftScenario({required this.id, required this.name, @ClockTimeConverter() required this.startTime, @ClockTimeConverter() required this.endTime, required this.durationMinutes, this.plannedWeekday, required this.estimationMethod, this.assumptions = const ShiftAssumptions(), this.isEstimate = true, @DecimalConverter() required this.estimatedRevenue, @DecimalConverter() required this.estimatedExpenses, @DecimalConverter() required this.estimatedNetProfit, @DecimalConverter() required this.estimatedNetProfitPerHour, @NullableDecimalConverter() this.estimateLow, @NullableDecimalConverter() this.estimateHigh, @_DetailsConverter() required this.estimateDetails, this.actualWorkSessionId, required this.createdAt, required this.updatedAt}): super._();
  factory _ShiftScenario.fromJson(Map<String, dynamic> json) => _$ShiftScenarioFromJson(json);

@override final  String id;
@override final  String name;
@override@ClockTimeConverter() final  ClockTime startTime;
@override@ClockTimeConverter() final  ClockTime endTime;
@override final  int durationMinutes;
/// 0 = Monday ... 6 = Sunday; `null` = any day.
@override final  int? plannedWeekday;
@override final  EstimationMethod estimationMethod;
@override@JsonKey() final  ShiftAssumptions assumptions;
@override@JsonKey() final  bool isEstimate;
@override@DecimalConverter() final  Decimal estimatedRevenue;
@override@DecimalConverter() final  Decimal estimatedExpenses;
@override@DecimalConverter() final  Decimal estimatedNetProfit;
@override@DecimalConverter() final  Decimal estimatedNetProfitPerHour;
/// P20-P80 range of the net profit (`historical` only).
@override@NullableDecimalConverter() final  Decimal? estimateLow;
@override@NullableDecimalConverter() final  Decimal? estimateHigh;
@override@_DetailsConverter() final  ShiftEstimateDetails estimateDetails;
@override final  String? actualWorkSessionId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftScenarioCopyWith<_ShiftScenario> get copyWith => __$ShiftScenarioCopyWithImpl<_ShiftScenario>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftScenario&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.plannedWeekday, plannedWeekday) || other.plannedWeekday == plannedWeekday)&&(identical(other.estimationMethod, estimationMethod) || other.estimationMethod == estimationMethod)&&(identical(other.assumptions, assumptions) || other.assumptions == assumptions)&&(identical(other.isEstimate, isEstimate) || other.isEstimate == isEstimate)&&(identical(other.estimatedRevenue, estimatedRevenue) || other.estimatedRevenue == estimatedRevenue)&&(identical(other.estimatedExpenses, estimatedExpenses) || other.estimatedExpenses == estimatedExpenses)&&(identical(other.estimatedNetProfit, estimatedNetProfit) || other.estimatedNetProfit == estimatedNetProfit)&&(identical(other.estimatedNetProfitPerHour, estimatedNetProfitPerHour) || other.estimatedNetProfitPerHour == estimatedNetProfitPerHour)&&(identical(other.estimateLow, estimateLow) || other.estimateLow == estimateLow)&&(identical(other.estimateHigh, estimateHigh) || other.estimateHigh == estimateHigh)&&(identical(other.estimateDetails, estimateDetails) || other.estimateDetails == estimateDetails)&&(identical(other.actualWorkSessionId, actualWorkSessionId) || other.actualWorkSessionId == actualWorkSessionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,startTime,endTime,durationMinutes,plannedWeekday,estimationMethod,assumptions,isEstimate,estimatedRevenue,estimatedExpenses,estimatedNetProfit,estimatedNetProfitPerHour,estimateLow,estimateHigh,estimateDetails,actualWorkSessionId,createdAt,updatedAt]);
}

@override
String toString() {
    return 'ShiftScenario(id: $id, name: $name, startTime: $startTime, endTime: $endTime, durationMinutes: $durationMinutes, plannedWeekday: $plannedWeekday, estimationMethod: $estimationMethod, assumptions: $assumptions, isEstimate: $isEstimate, estimatedRevenue: $estimatedRevenue, estimatedExpenses: $estimatedExpenses, estimatedNetProfit: $estimatedNetProfit, estimatedNetProfitPerHour: $estimatedNetProfitPerHour, estimateLow: $estimateLow, estimateHigh: $estimateHigh, estimateDetails: $estimateDetails, actualWorkSessionId: $actualWorkSessionId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftScenarioCopyWith<$Res> implements $ShiftScenarioCopyWith<$Res> {
  factory _$ShiftScenarioCopyWith(_ShiftScenario value, $Res Function(_ShiftScenario) _then) = __$ShiftScenarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@ClockTimeConverter() ClockTime startTime,@ClockTimeConverter() ClockTime endTime, int durationMinutes, int? plannedWeekday, EstimationMethod estimationMethod, ShiftAssumptions assumptions, bool isEstimate,@DecimalConverter() Decimal estimatedRevenue,@DecimalConverter() Decimal estimatedExpenses,@DecimalConverter() Decimal estimatedNetProfit,@DecimalConverter() Decimal estimatedNetProfitPerHour,@NullableDecimalConverter() Decimal? estimateLow,@NullableDecimalConverter() Decimal? estimateHigh,@_DetailsConverter() ShiftEstimateDetails estimateDetails, String? actualWorkSessionId, DateTime createdAt, DateTime updatedAt
});


@override $ShiftAssumptionsCopyWith<$Res> get assumptions;

}
/// @nodoc
class __$ShiftScenarioCopyWithImpl<$Res>
    implements _$ShiftScenarioCopyWith<$Res> {
  __$ShiftScenarioCopyWithImpl(this._self, this._then);

  final _ShiftScenario _self;
  final $Res Function(_ShiftScenario) _then;

/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? startTime = null,Object? endTime = null,Object? durationMinutes = null,Object? plannedWeekday = freezed,Object? estimationMethod = null,Object? assumptions = null,Object? isEstimate = null,Object? estimatedRevenue = null,Object? estimatedExpenses = null,Object? estimatedNetProfit = null,Object? estimatedNetProfitPerHour = null,Object? estimateLow = freezed,Object? estimateHigh = freezed,Object? estimateDetails = null,Object? actualWorkSessionId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ShiftScenario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,plannedWeekday: freezed == plannedWeekday ? _self.plannedWeekday : plannedWeekday // ignore: cast_nullable_to_non_nullable
as int?,estimationMethod: null == estimationMethod ? _self.estimationMethod : estimationMethod // ignore: cast_nullable_to_non_nullable
as EstimationMethod,assumptions: null == assumptions ? _self.assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as ShiftAssumptions,isEstimate: null == isEstimate ? _self.isEstimate : isEstimate // ignore: cast_nullable_to_non_nullable
as bool,estimatedRevenue: null == estimatedRevenue ? _self.estimatedRevenue : estimatedRevenue // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedExpenses: null == estimatedExpenses ? _self.estimatedExpenses : estimatedExpenses // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedNetProfit: null == estimatedNetProfit ? _self.estimatedNetProfit : estimatedNetProfit // ignore: cast_nullable_to_non_nullable
as Decimal,estimatedNetProfitPerHour: null == estimatedNetProfitPerHour ? _self.estimatedNetProfitPerHour : estimatedNetProfitPerHour // ignore: cast_nullable_to_non_nullable
as Decimal,estimateLow: freezed == estimateLow ? _self.estimateLow : estimateLow // ignore: cast_nullable_to_non_nullable
as Decimal?,estimateHigh: freezed == estimateHigh ? _self.estimateHigh : estimateHigh // ignore: cast_nullable_to_non_nullable
as Decimal?,estimateDetails: null == estimateDetails ? _self.estimateDetails : estimateDetails // ignore: cast_nullable_to_non_nullable
as ShiftEstimateDetails,actualWorkSessionId: freezed == actualWorkSessionId ? _self.actualWorkSessionId : actualWorkSessionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ShiftScenario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShiftAssumptionsCopyWith<$Res> get assumptions {
  
  return $ShiftAssumptionsCopyWith<$Res>(_self.assumptions, (value) {
    return _then(_self.copyWith(assumptions: value));
  });
}
}

/// @nodoc
mixin _$ShiftScenarioInput {

 String get name;@ClockTimeConverter() ClockTime get startTime;@ClockTimeConverter() ClockTime get endTime; int? get plannedWeekday; EstimationMethod get estimationMethod; ShiftAssumptions get assumptions;
/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftScenarioInputCopyWith<ShiftScenarioInput> get copyWith => _$ShiftScenarioInputCopyWithImpl<ShiftScenarioInput>(this as ShiftScenarioInput, _$identity);

  /// Serializes this ShiftScenarioInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftScenarioInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftScenarioInput&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.plannedWeekday, _this.plannedWeekday) || other.plannedWeekday == _this.plannedWeekday)&&(identical(other.estimationMethod, _this.estimationMethod) || other.estimationMethod == _this.estimationMethod)&&(identical(other.assumptions, _this.assumptions) || other.assumptions == _this.assumptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftScenarioInput;
  return Object.hash(runtimeType,_this.name,_this.startTime,_this.endTime,_this.plannedWeekday,_this.estimationMethod,_this.assumptions);
}

@override
String toString() {
  final _this = this as ShiftScenarioInput;
  return 'ShiftScenarioInput(name: ${_this.name}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, plannedWeekday: ${_this.plannedWeekday}, estimationMethod: ${_this.estimationMethod}, assumptions: ${_this.assumptions})';
}


}

/// @nodoc
abstract mixin class $ShiftScenarioInputCopyWith<$Res>  {
  factory $ShiftScenarioInputCopyWith(ShiftScenarioInput value, $Res Function(ShiftScenarioInput) _then) = _$ShiftScenarioInputCopyWithImpl;
@useResult
$Res call({
 String name,@ClockTimeConverter() ClockTime startTime,@ClockTimeConverter() ClockTime endTime, int? plannedWeekday, EstimationMethod estimationMethod, ShiftAssumptions assumptions
});


$ShiftAssumptionsCopyWith<$Res> get assumptions;

}
/// @nodoc
class _$ShiftScenarioInputCopyWithImpl<$Res>
    implements $ShiftScenarioInputCopyWith<$Res> {
  _$ShiftScenarioInputCopyWithImpl(this._self, this._then);

  final ShiftScenarioInput _self;
  final $Res Function(ShiftScenarioInput) _then;

/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? startTime = null,Object? endTime = null,Object? plannedWeekday = freezed,Object? estimationMethod = null,Object? assumptions = null,}) {
  return _then(ShiftScenarioInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime,plannedWeekday: freezed == plannedWeekday ? _self.plannedWeekday : plannedWeekday // ignore: cast_nullable_to_non_nullable
as int?,estimationMethod: null == estimationMethod ? _self.estimationMethod : estimationMethod // ignore: cast_nullable_to_non_nullable
as EstimationMethod,assumptions: null == assumptions ? _self.assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as ShiftAssumptions,
  ));
}
/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShiftAssumptionsCopyWith<$Res> get assumptions {
  
  return $ShiftAssumptionsCopyWith<$Res>(_self.assumptions, (value) {
    return _then(_self.copyWith(assumptions: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShiftScenarioInput].
extension ShiftScenarioInputPatterns on ShiftScenarioInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftScenarioInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftScenarioInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftScenarioInput value)  $default,){
final _that = this;
switch (_that) {
case _ShiftScenarioInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftScenarioInput value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftScenarioInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftScenarioInput() when $default != null:
return $default(_that.name,_that.startTime,_that.endTime,_that.plannedWeekday,_that.estimationMethod,_that.assumptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions)  $default,) {final _that = this;
switch (_that) {
case _ShiftScenarioInput():
return $default(_that.name,_that.startTime,_that.endTime,_that.plannedWeekday,_that.estimationMethod,_that.assumptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @ClockTimeConverter()  ClockTime startTime, @ClockTimeConverter()  ClockTime endTime,  int? plannedWeekday,  EstimationMethod estimationMethod,  ShiftAssumptions assumptions)?  $default,) {final _that = this;
switch (_that) {
case _ShiftScenarioInput() when $default != null:
return $default(_that.name,_that.startTime,_that.endTime,_that.plannedWeekday,_that.estimationMethod,_that.assumptions);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: true)
class _ShiftScenarioInput implements ShiftScenarioInput {
  const _ShiftScenarioInput({required this.name, @ClockTimeConverter() required this.startTime, @ClockTimeConverter() required this.endTime, this.plannedWeekday, required this.estimationMethod, required this.assumptions});
  

@override final  String name;
@override@ClockTimeConverter() final  ClockTime startTime;
@override@ClockTimeConverter() final  ClockTime endTime;
@override final  int? plannedWeekday;
@override final  EstimationMethod estimationMethod;
@override final  ShiftAssumptions assumptions;

/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftScenarioInputCopyWith<_ShiftScenarioInput> get copyWith => __$ShiftScenarioInputCopyWithImpl<_ShiftScenarioInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftScenarioInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftScenarioInput&&(identical(other.name, name) || other.name == name)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.plannedWeekday, plannedWeekday) || other.plannedWeekday == plannedWeekday)&&(identical(other.estimationMethod, estimationMethod) || other.estimationMethod == estimationMethod)&&(identical(other.assumptions, assumptions) || other.assumptions == assumptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,startTime,endTime,plannedWeekday,estimationMethod,assumptions);
}

@override
String toString() {
    return 'ShiftScenarioInput(name: $name, startTime: $startTime, endTime: $endTime, plannedWeekday: $plannedWeekday, estimationMethod: $estimationMethod, assumptions: $assumptions)';
}


}

/// @nodoc
abstract mixin class _$ShiftScenarioInputCopyWith<$Res> implements $ShiftScenarioInputCopyWith<$Res> {
  factory _$ShiftScenarioInputCopyWith(_ShiftScenarioInput value, $Res Function(_ShiftScenarioInput) _then) = __$ShiftScenarioInputCopyWithImpl;
@override @useResult
$Res call({
 String name,@ClockTimeConverter() ClockTime startTime,@ClockTimeConverter() ClockTime endTime, int? plannedWeekday, EstimationMethod estimationMethod, ShiftAssumptions assumptions
});


@override $ShiftAssumptionsCopyWith<$Res> get assumptions;

}
/// @nodoc
class __$ShiftScenarioInputCopyWithImpl<$Res>
    implements _$ShiftScenarioInputCopyWith<$Res> {
  __$ShiftScenarioInputCopyWithImpl(this._self, this._then);

  final _ShiftScenarioInput _self;
  final $Res Function(_ShiftScenarioInput) _then;

/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? startTime = null,Object? endTime = null,Object? plannedWeekday = freezed,Object? estimationMethod = null,Object? assumptions = null,}) {
  return _then(_ShiftScenarioInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime,plannedWeekday: freezed == plannedWeekday ? _self.plannedWeekday : plannedWeekday // ignore: cast_nullable_to_non_nullable
as int?,estimationMethod: null == estimationMethod ? _self.estimationMethod : estimationMethod // ignore: cast_nullable_to_non_nullable
as EstimationMethod,assumptions: null == assumptions ? _self.assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as ShiftAssumptions,
  ));
}

/// Create a copy of ShiftScenarioInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShiftAssumptionsCopyWith<$Res> get assumptions {
  
  return $ShiftAssumptionsCopyWith<$Res>(_self.assumptions, (value) {
    return _then(_self.copyWith(assumptions: value));
  });
}
}

// dart format on
