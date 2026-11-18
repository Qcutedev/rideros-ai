// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rider_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RiderProfile {

 VehicleType? get vehicleType;@NullableDecimalConverter() Decimal? get fuelKmPerLiter;@NullableDecimalConverter() Decimal? get fuelPricePerLiter;@NullableDecimalConverter() Decimal? get depreciationPerKm;/// Net-profit target for one day (Home progress ring); `null` = no goal.
@NullableDecimalConverter() Decimal? get dailyGoal; String get timezone; String get currency; bool get isConfigured; DateTime? get updatedAt;
/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiderProfileCopyWith<RiderProfile> get copyWith => _$RiderProfileCopyWithImpl<RiderProfile>(this as RiderProfile, _$identity);

  /// Serializes this RiderProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiderProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiderProfile&&(identical(other.vehicleType, _this.vehicleType) || other.vehicleType == _this.vehicleType)&&(identical(other.fuelKmPerLiter, _this.fuelKmPerLiter) || other.fuelKmPerLiter == _this.fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, _this.fuelPricePerLiter) || other.fuelPricePerLiter == _this.fuelPricePerLiter)&&(identical(other.depreciationPerKm, _this.depreciationPerKm) || other.depreciationPerKm == _this.depreciationPerKm)&&(identical(other.dailyGoal, _this.dailyGoal) || other.dailyGoal == _this.dailyGoal)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.isConfigured, _this.isConfigured) || other.isConfigured == _this.isConfigured)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiderProfile;
  return Object.hash(runtimeType,_this.vehicleType,_this.fuelKmPerLiter,_this.fuelPricePerLiter,_this.depreciationPerKm,_this.dailyGoal,_this.timezone,_this.currency,_this.isConfigured,_this.updatedAt);
}

@override
String toString() {
  final _this = this as RiderProfile;
  return 'RiderProfile(vehicleType: ${_this.vehicleType}, fuelKmPerLiter: ${_this.fuelKmPerLiter}, fuelPricePerLiter: ${_this.fuelPricePerLiter}, depreciationPerKm: ${_this.depreciationPerKm}, dailyGoal: ${_this.dailyGoal}, timezone: ${_this.timezone}, currency: ${_this.currency}, isConfigured: ${_this.isConfigured}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $RiderProfileCopyWith<$Res>  {
  factory $RiderProfileCopyWith(RiderProfile value, $Res Function(RiderProfile) _then) = _$RiderProfileCopyWithImpl;
@useResult
$Res call({
 VehicleType? vehicleType,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? dailyGoal, String timezone, String currency, bool isConfigured, DateTime? updatedAt
});




}
/// @nodoc
class _$RiderProfileCopyWithImpl<$Res>
    implements $RiderProfileCopyWith<$Res> {
  _$RiderProfileCopyWithImpl(this._self, this._then);

  final RiderProfile _self;
  final $Res Function(RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vehicleType = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? dailyGoal = freezed,Object? timezone = null,Object? currency = null,Object? isConfigured = null,Object? updatedAt = freezed,}) {
  return _then(RiderProfile(
vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as VehicleType?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,dailyGoal: freezed == dailyGoal ? _self.dailyGoal : dailyGoal // ignore: cast_nullable_to_non_nullable
as Decimal?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isConfigured: null == isConfigured ? _self.isConfigured : isConfigured // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiderProfile].
extension RiderProfilePatterns on RiderProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiderProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiderProfile value)  $default,){
final _that = this;
switch (_that) {
case _RiderProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiderProfile value)?  $default,){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency,  bool isConfigured,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency,_that.isConfigured,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency,  bool isConfigured,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RiderProfile():
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency,_that.isConfigured,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency,  bool isConfigured,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency,_that.isConfigured,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiderProfile implements RiderProfile {
  const _RiderProfile({this.vehicleType, @NullableDecimalConverter() this.fuelKmPerLiter, @NullableDecimalConverter() this.fuelPricePerLiter, @NullableDecimalConverter() this.depreciationPerKm, @NullableDecimalConverter() this.dailyGoal, this.timezone = RiderProfileDefaults.timezone, this.currency = RiderProfileDefaults.currency, this.isConfigured = false, this.updatedAt});
  factory _RiderProfile.fromJson(Map<String, dynamic> json) => _$RiderProfileFromJson(json);

@override final  VehicleType? vehicleType;
@override@NullableDecimalConverter() final  Decimal? fuelKmPerLiter;
@override@NullableDecimalConverter() final  Decimal? fuelPricePerLiter;
@override@NullableDecimalConverter() final  Decimal? depreciationPerKm;
/// Net-profit target for one day (Home progress ring); `null` = no goal.
@override@NullableDecimalConverter() final  Decimal? dailyGoal;
@override@JsonKey() final  String timezone;
@override@JsonKey() final  String currency;
@override@JsonKey() final  bool isConfigured;
@override final  DateTime? updatedAt;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiderProfileCopyWith<_RiderProfile> get copyWith => __$RiderProfileCopyWithImpl<_RiderProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiderProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiderProfile&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.fuelKmPerLiter, fuelKmPerLiter) || other.fuelKmPerLiter == fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, fuelPricePerLiter) || other.fuelPricePerLiter == fuelPricePerLiter)&&(identical(other.depreciationPerKm, depreciationPerKm) || other.depreciationPerKm == depreciationPerKm)&&(identical(other.dailyGoal, dailyGoal) || other.dailyGoal == dailyGoal)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isConfigured, isConfigured) || other.isConfigured == isConfigured)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,vehicleType,fuelKmPerLiter,fuelPricePerLiter,depreciationPerKm,dailyGoal,timezone,currency,isConfigured,updatedAt);
}

@override
String toString() {
    return 'RiderProfile(vehicleType: $vehicleType, fuelKmPerLiter: $fuelKmPerLiter, fuelPricePerLiter: $fuelPricePerLiter, depreciationPerKm: $depreciationPerKm, dailyGoal: $dailyGoal, timezone: $timezone, currency: $currency, isConfigured: $isConfigured, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RiderProfileCopyWith<$Res> implements $RiderProfileCopyWith<$Res> {
  factory _$RiderProfileCopyWith(_RiderProfile value, $Res Function(_RiderProfile) _then) = __$RiderProfileCopyWithImpl;
@override @useResult
$Res call({
 VehicleType? vehicleType,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? dailyGoal, String timezone, String currency, bool isConfigured, DateTime? updatedAt
});




}
/// @nodoc
class __$RiderProfileCopyWithImpl<$Res>
    implements _$RiderProfileCopyWith<$Res> {
  __$RiderProfileCopyWithImpl(this._self, this._then);

  final _RiderProfile _self;
  final $Res Function(_RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vehicleType = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? dailyGoal = freezed,Object? timezone = null,Object? currency = null,Object? isConfigured = null,Object? updatedAt = freezed,}) {
  return _then(_RiderProfile(
vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as VehicleType?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,dailyGoal: freezed == dailyGoal ? _self.dailyGoal : dailyGoal // ignore: cast_nullable_to_non_nullable
as Decimal?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isConfigured: null == isConfigured ? _self.isConfigured : isConfigured // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$RiderProfileInput {

 VehicleType? get vehicleType;@NullableDecimalConverter() Decimal? get fuelKmPerLiter;@NullableDecimalConverter() Decimal? get fuelPricePerLiter;@NullableDecimalConverter() Decimal? get depreciationPerKm;@NullableDecimalConverter() Decimal? get dailyGoal; String get timezone; String get currency;
/// Create a copy of RiderProfileInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiderProfileInputCopyWith<RiderProfileInput> get copyWith => _$RiderProfileInputCopyWithImpl<RiderProfileInput>(this as RiderProfileInput, _$identity);

  /// Serializes this RiderProfileInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiderProfileInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiderProfileInput&&(identical(other.vehicleType, _this.vehicleType) || other.vehicleType == _this.vehicleType)&&(identical(other.fuelKmPerLiter, _this.fuelKmPerLiter) || other.fuelKmPerLiter == _this.fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, _this.fuelPricePerLiter) || other.fuelPricePerLiter == _this.fuelPricePerLiter)&&(identical(other.depreciationPerKm, _this.depreciationPerKm) || other.depreciationPerKm == _this.depreciationPerKm)&&(identical(other.dailyGoal, _this.dailyGoal) || other.dailyGoal == _this.dailyGoal)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.currency, _this.currency) || other.currency == _this.currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiderProfileInput;
  return Object.hash(runtimeType,_this.vehicleType,_this.fuelKmPerLiter,_this.fuelPricePerLiter,_this.depreciationPerKm,_this.dailyGoal,_this.timezone,_this.currency);
}

@override
String toString() {
  final _this = this as RiderProfileInput;
  return 'RiderProfileInput(vehicleType: ${_this.vehicleType}, fuelKmPerLiter: ${_this.fuelKmPerLiter}, fuelPricePerLiter: ${_this.fuelPricePerLiter}, depreciationPerKm: ${_this.depreciationPerKm}, dailyGoal: ${_this.dailyGoal}, timezone: ${_this.timezone}, currency: ${_this.currency})';
}


}

/// @nodoc
abstract mixin class $RiderProfileInputCopyWith<$Res>  {
  factory $RiderProfileInputCopyWith(RiderProfileInput value, $Res Function(RiderProfileInput) _then) = _$RiderProfileInputCopyWithImpl;
@useResult
$Res call({
 VehicleType? vehicleType,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? dailyGoal, String timezone, String currency
});




}
/// @nodoc
class _$RiderProfileInputCopyWithImpl<$Res>
    implements $RiderProfileInputCopyWith<$Res> {
  _$RiderProfileInputCopyWithImpl(this._self, this._then);

  final RiderProfileInput _self;
  final $Res Function(RiderProfileInput) _then;

/// Create a copy of RiderProfileInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vehicleType = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? dailyGoal = freezed,Object? timezone = null,Object? currency = null,}) {
  return _then(RiderProfileInput(
vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as VehicleType?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,dailyGoal: freezed == dailyGoal ? _self.dailyGoal : dailyGoal // ignore: cast_nullable_to_non_nullable
as Decimal?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RiderProfileInput].
extension RiderProfileInputPatterns on RiderProfileInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiderProfileInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiderProfileInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiderProfileInput value)  $default,){
final _that = this;
switch (_that) {
case _RiderProfileInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiderProfileInput value)?  $default,){
final _that = this;
switch (_that) {
case _RiderProfileInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiderProfileInput() when $default != null:
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency)  $default,) {final _that = this;
switch (_that) {
case _RiderProfileInput():
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VehicleType? vehicleType, @NullableDecimalConverter()  Decimal? fuelKmPerLiter, @NullableDecimalConverter()  Decimal? fuelPricePerLiter, @NullableDecimalConverter()  Decimal? depreciationPerKm, @NullableDecimalConverter()  Decimal? dailyGoal,  String timezone,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _RiderProfileInput() when $default != null:
return $default(_that.vehicleType,_that.fuelKmPerLiter,_that.fuelPricePerLiter,_that.depreciationPerKm,_that.dailyGoal,_that.timezone,_that.currency);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: true)
class _RiderProfileInput implements RiderProfileInput {
  const _RiderProfileInput({this.vehicleType, @NullableDecimalConverter() this.fuelKmPerLiter, @NullableDecimalConverter() this.fuelPricePerLiter, @NullableDecimalConverter() this.depreciationPerKm, @NullableDecimalConverter() this.dailyGoal, this.timezone = RiderProfileDefaults.timezone, this.currency = RiderProfileDefaults.currency});
  

@override final  VehicleType? vehicleType;
@override@NullableDecimalConverter() final  Decimal? fuelKmPerLiter;
@override@NullableDecimalConverter() final  Decimal? fuelPricePerLiter;
@override@NullableDecimalConverter() final  Decimal? depreciationPerKm;
@override@NullableDecimalConverter() final  Decimal? dailyGoal;
@override@JsonKey() final  String timezone;
@override@JsonKey() final  String currency;

/// Create a copy of RiderProfileInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiderProfileInputCopyWith<_RiderProfileInput> get copyWith => __$RiderProfileInputCopyWithImpl<_RiderProfileInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiderProfileInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiderProfileInput&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.fuelKmPerLiter, fuelKmPerLiter) || other.fuelKmPerLiter == fuelKmPerLiter)&&(identical(other.fuelPricePerLiter, fuelPricePerLiter) || other.fuelPricePerLiter == fuelPricePerLiter)&&(identical(other.depreciationPerKm, depreciationPerKm) || other.depreciationPerKm == depreciationPerKm)&&(identical(other.dailyGoal, dailyGoal) || other.dailyGoal == dailyGoal)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,vehicleType,fuelKmPerLiter,fuelPricePerLiter,depreciationPerKm,dailyGoal,timezone,currency);
}

@override
String toString() {
    return 'RiderProfileInput(vehicleType: $vehicleType, fuelKmPerLiter: $fuelKmPerLiter, fuelPricePerLiter: $fuelPricePerLiter, depreciationPerKm: $depreciationPerKm, dailyGoal: $dailyGoal, timezone: $timezone, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$RiderProfileInputCopyWith<$Res> implements $RiderProfileInputCopyWith<$Res> {
  factory _$RiderProfileInputCopyWith(_RiderProfileInput value, $Res Function(_RiderProfileInput) _then) = __$RiderProfileInputCopyWithImpl;
@override @useResult
$Res call({
 VehicleType? vehicleType,@NullableDecimalConverter() Decimal? fuelKmPerLiter,@NullableDecimalConverter() Decimal? fuelPricePerLiter,@NullableDecimalConverter() Decimal? depreciationPerKm,@NullableDecimalConverter() Decimal? dailyGoal, String timezone, String currency
});




}
/// @nodoc
class __$RiderProfileInputCopyWithImpl<$Res>
    implements _$RiderProfileInputCopyWith<$Res> {
  __$RiderProfileInputCopyWithImpl(this._self, this._then);

  final _RiderProfileInput _self;
  final $Res Function(_RiderProfileInput) _then;

/// Create a copy of RiderProfileInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vehicleType = freezed,Object? fuelKmPerLiter = freezed,Object? fuelPricePerLiter = freezed,Object? depreciationPerKm = freezed,Object? dailyGoal = freezed,Object? timezone = null,Object? currency = null,}) {
  return _then(_RiderProfileInput(
vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as VehicleType?,fuelKmPerLiter: freezed == fuelKmPerLiter ? _self.fuelKmPerLiter : fuelKmPerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,fuelPricePerLiter: freezed == fuelPricePerLiter ? _self.fuelPricePerLiter : fuelPricePerLiter // ignore: cast_nullable_to_non_nullable
as Decimal?,depreciationPerKm: freezed == depreciationPerKm ? _self.depreciationPerKm : depreciationPerKm // ignore: cast_nullable_to_non_nullable
as Decimal?,dailyGoal: freezed == dailyGoal ? _self.dailyGoal : dailyGoal // ignore: cast_nullable_to_non_nullable
as Decimal?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
