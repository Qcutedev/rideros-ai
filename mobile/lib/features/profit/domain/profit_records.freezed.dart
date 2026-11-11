// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_records.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Income {

 String get id;@DateOnlyConverter() DateTime get occurredOn;@DecimalConverter() Decimal get amount; String? get workSessionId; int? get orderCount;@NullableDecimalConverter() Decimal? get distanceKm;@NullableDecimalConverter() Decimal? get workingHours; String? get sourceLabel; String? get notes; bool get isDemo; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Income
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomeCopyWith<Income> get copyWith => _$IncomeCopyWithImpl<Income>(this as Income, _$identity);

  /// Serializes this Income to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Income;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Income&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.occurredOn, _this.occurredOn) || other.occurredOn == _this.occurredOn)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.workSessionId, _this.workSessionId) || other.workSessionId == _this.workSessionId)&&(identical(other.orderCount, _this.orderCount) || other.orderCount == _this.orderCount)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.workingHours, _this.workingHours) || other.workingHours == _this.workingHours)&&(identical(other.sourceLabel, _this.sourceLabel) || other.sourceLabel == _this.sourceLabel)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.isDemo, _this.isDemo) || other.isDemo == _this.isDemo)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Income;
  return Object.hash(runtimeType,_this.id,_this.occurredOn,_this.amount,_this.workSessionId,_this.orderCount,_this.distanceKm,_this.workingHours,_this.sourceLabel,_this.notes,_this.isDemo,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Income;
  return 'Income(id: ${_this.id}, occurredOn: ${_this.occurredOn}, amount: ${_this.amount}, workSessionId: ${_this.workSessionId}, orderCount: ${_this.orderCount}, distanceKm: ${_this.distanceKm}, workingHours: ${_this.workingHours}, sourceLabel: ${_this.sourceLabel}, notes: ${_this.notes}, isDemo: ${_this.isDemo}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $IncomeCopyWith<$Res>  {
  factory $IncomeCopyWith(Income value, $Res Function(Income) _then) = _$IncomeCopyWithImpl;
@useResult
$Res call({
 String id,@DateOnlyConverter() DateTime occurredOn,@DecimalConverter() Decimal amount, String? workSessionId, int? orderCount,@NullableDecimalConverter() Decimal? distanceKm,@NullableDecimalConverter() Decimal? workingHours, String? sourceLabel, String? notes, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$IncomeCopyWithImpl<$Res>
    implements $IncomeCopyWith<$Res> {
  _$IncomeCopyWithImpl(this._self, this._then);

  final Income _self;
  final $Res Function(Income) _then;

/// Create a copy of Income
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? occurredOn = null,Object? amount = null,Object? workSessionId = freezed,Object? orderCount = freezed,Object? distanceKm = freezed,Object? workingHours = freezed,Object? sourceLabel = freezed,Object? notes = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Income(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,workingHours: freezed == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Income].
extension IncomePatterns on Income {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Income value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Income() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Income value)  $default,){
final _that = this;
switch (_that) {
case _Income():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Income value)?  $default,){
final _that = this;
switch (_that) {
case _Income() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Income() when $default != null:
return $default(_that.id,_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Income():
return $default(_that.id,_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Income() when $default != null:
return $default(_that.id,_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Income implements Income {
  const _Income({required this.id, @DateOnlyConverter() required this.occurredOn, @DecimalConverter() required this.amount, this.workSessionId, this.orderCount, @NullableDecimalConverter() this.distanceKm, @NullableDecimalConverter() this.workingHours, this.sourceLabel, this.notes, this.isDemo = false, required this.createdAt, required this.updatedAt});
  factory _Income.fromJson(Map<String, dynamic> json) => _$IncomeFromJson(json);

@override final  String id;
@override@DateOnlyConverter() final  DateTime occurredOn;
@override@DecimalConverter() final  Decimal amount;
@override final  String? workSessionId;
@override final  int? orderCount;
@override@NullableDecimalConverter() final  Decimal? distanceKm;
@override@NullableDecimalConverter() final  Decimal? workingHours;
@override final  String? sourceLabel;
@override final  String? notes;
@override@JsonKey() final  bool isDemo;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Income
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomeCopyWith<_Income> get copyWith => __$IncomeCopyWithImpl<_Income>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncomeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Income&&(identical(other.id, id) || other.id == id)&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.workSessionId, workSessionId) || other.workSessionId == workSessionId)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.workingHours, workingHours) || other.workingHours == workingHours)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,occurredOn,amount,workSessionId,orderCount,distanceKm,workingHours,sourceLabel,notes,isDemo,createdAt,updatedAt);
}

@override
String toString() {
    return 'Income(id: $id, occurredOn: $occurredOn, amount: $amount, workSessionId: $workSessionId, orderCount: $orderCount, distanceKm: $distanceKm, workingHours: $workingHours, sourceLabel: $sourceLabel, notes: $notes, isDemo: $isDemo, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$IncomeCopyWith<$Res> implements $IncomeCopyWith<$Res> {
  factory _$IncomeCopyWith(_Income value, $Res Function(_Income) _then) = __$IncomeCopyWithImpl;
@override @useResult
$Res call({
 String id,@DateOnlyConverter() DateTime occurredOn,@DecimalConverter() Decimal amount, String? workSessionId, int? orderCount,@NullableDecimalConverter() Decimal? distanceKm,@NullableDecimalConverter() Decimal? workingHours, String? sourceLabel, String? notes, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$IncomeCopyWithImpl<$Res>
    implements _$IncomeCopyWith<$Res> {
  __$IncomeCopyWithImpl(this._self, this._then);

  final _Income _self;
  final $Res Function(_Income) _then;

/// Create a copy of Income
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? occurredOn = null,Object? amount = null,Object? workSessionId = freezed,Object? orderCount = freezed,Object? distanceKm = freezed,Object? workingHours = freezed,Object? sourceLabel = freezed,Object? notes = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Income(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,workingHours: freezed == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$IncomeInput {

@DateOnlyConverter() DateTime get occurredOn;@DecimalConverter() Decimal get amount; String? get workSessionId; int? get orderCount;@NullableDecimalConverter() Decimal? get distanceKm;@NullableDecimalConverter() Decimal? get workingHours; String? get sourceLabel; String? get notes;
/// Create a copy of IncomeInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomeInputCopyWith<IncomeInput> get copyWith => _$IncomeInputCopyWithImpl<IncomeInput>(this as IncomeInput, _$identity);

  /// Serializes this IncomeInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IncomeInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeInput&&(identical(other.occurredOn, _this.occurredOn) || other.occurredOn == _this.occurredOn)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.workSessionId, _this.workSessionId) || other.workSessionId == _this.workSessionId)&&(identical(other.orderCount, _this.orderCount) || other.orderCount == _this.orderCount)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.workingHours, _this.workingHours) || other.workingHours == _this.workingHours)&&(identical(other.sourceLabel, _this.sourceLabel) || other.sourceLabel == _this.sourceLabel)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IncomeInput;
  return Object.hash(runtimeType,_this.occurredOn,_this.amount,_this.workSessionId,_this.orderCount,_this.distanceKm,_this.workingHours,_this.sourceLabel,_this.notes);
}

@override
String toString() {
  final _this = this as IncomeInput;
  return 'IncomeInput(occurredOn: ${_this.occurredOn}, amount: ${_this.amount}, workSessionId: ${_this.workSessionId}, orderCount: ${_this.orderCount}, distanceKm: ${_this.distanceKm}, workingHours: ${_this.workingHours}, sourceLabel: ${_this.sourceLabel}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $IncomeInputCopyWith<$Res>  {
  factory $IncomeInputCopyWith(IncomeInput value, $Res Function(IncomeInput) _then) = _$IncomeInputCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime occurredOn,@DecimalConverter() Decimal amount, String? workSessionId, int? orderCount,@NullableDecimalConverter() Decimal? distanceKm,@NullableDecimalConverter() Decimal? workingHours, String? sourceLabel, String? notes
});




}
/// @nodoc
class _$IncomeInputCopyWithImpl<$Res>
    implements $IncomeInputCopyWith<$Res> {
  _$IncomeInputCopyWithImpl(this._self, this._then);

  final IncomeInput _self;
  final $Res Function(IncomeInput) _then;

/// Create a copy of IncomeInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? occurredOn = null,Object? amount = null,Object? workSessionId = freezed,Object? orderCount = freezed,Object? distanceKm = freezed,Object? workingHours = freezed,Object? sourceLabel = freezed,Object? notes = freezed,}) {
  return _then(IncomeInput(
occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,workingHours: freezed == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IncomeInput].
extension IncomeInputPatterns on IncomeInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomeInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomeInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomeInput value)  $default,){
final _that = this;
switch (_that) {
case _IncomeInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomeInput value)?  $default,){
final _that = this;
switch (_that) {
case _IncomeInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomeInput() when $default != null:
return $default(_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _IncomeInput():
return $default(_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime occurredOn, @DecimalConverter()  Decimal amount,  String? workSessionId,  int? orderCount, @NullableDecimalConverter()  Decimal? distanceKm, @NullableDecimalConverter()  Decimal? workingHours,  String? sourceLabel,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _IncomeInput() when $default != null:
return $default(_that.occurredOn,_that.amount,_that.workSessionId,_that.orderCount,_that.distanceKm,_that.workingHours,_that.sourceLabel,_that.notes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: true)
class _IncomeInput implements IncomeInput {
  const _IncomeInput({@DateOnlyConverter() required this.occurredOn, @DecimalConverter() required this.amount, this.workSessionId, this.orderCount, @NullableDecimalConverter() this.distanceKm, @NullableDecimalConverter() this.workingHours, this.sourceLabel, this.notes});
  

@override@DateOnlyConverter() final  DateTime occurredOn;
@override@DecimalConverter() final  Decimal amount;
@override final  String? workSessionId;
@override final  int? orderCount;
@override@NullableDecimalConverter() final  Decimal? distanceKm;
@override@NullableDecimalConverter() final  Decimal? workingHours;
@override final  String? sourceLabel;
@override final  String? notes;

/// Create a copy of IncomeInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomeInputCopyWith<_IncomeInput> get copyWith => __$IncomeInputCopyWithImpl<_IncomeInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncomeInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomeInput&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.workSessionId, workSessionId) || other.workSessionId == workSessionId)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.workingHours, workingHours) || other.workingHours == workingHours)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,occurredOn,amount,workSessionId,orderCount,distanceKm,workingHours,sourceLabel,notes);
}

@override
String toString() {
    return 'IncomeInput(occurredOn: $occurredOn, amount: $amount, workSessionId: $workSessionId, orderCount: $orderCount, distanceKm: $distanceKm, workingHours: $workingHours, sourceLabel: $sourceLabel, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$IncomeInputCopyWith<$Res> implements $IncomeInputCopyWith<$Res> {
  factory _$IncomeInputCopyWith(_IncomeInput value, $Res Function(_IncomeInput) _then) = __$IncomeInputCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime occurredOn,@DecimalConverter() Decimal amount, String? workSessionId, int? orderCount,@NullableDecimalConverter() Decimal? distanceKm,@NullableDecimalConverter() Decimal? workingHours, String? sourceLabel, String? notes
});




}
/// @nodoc
class __$IncomeInputCopyWithImpl<$Res>
    implements _$IncomeInputCopyWith<$Res> {
  __$IncomeInputCopyWithImpl(this._self, this._then);

  final _IncomeInput _self;
  final $Res Function(_IncomeInput) _then;

/// Create a copy of IncomeInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? occurredOn = null,Object? amount = null,Object? workSessionId = freezed,Object? orderCount = freezed,Object? distanceKm = freezed,Object? workingHours = freezed,Object? sourceLabel = freezed,Object? notes = freezed,}) {
  return _then(_IncomeInput(
occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,workingHours: freezed == workingHours ? _self.workingHours : workingHours // ignore: cast_nullable_to_non_nullable
as Decimal?,sourceLabel: freezed == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Expense {

 String get id;@DateOnlyConverter() DateTime get occurredOn; ExpenseCategory get category;@DecimalConverter() Decimal get amount; String? get workSessionId; String? get description; bool get isDemo; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Expense;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.occurredOn, _this.occurredOn) || other.occurredOn == _this.occurredOn)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.workSessionId, _this.workSessionId) || other.workSessionId == _this.workSessionId)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.isDemo, _this.isDemo) || other.isDemo == _this.isDemo)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Expense;
  return Object.hash(runtimeType,_this.id,_this.occurredOn,_this.category,_this.amount,_this.workSessionId,_this.description,_this.isDemo,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Expense;
  return 'Expense(id: ${_this.id}, occurredOn: ${_this.occurredOn}, category: ${_this.category}, amount: ${_this.amount}, workSessionId: ${_this.workSessionId}, description: ${_this.description}, isDemo: ${_this.isDemo}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id,@DateOnlyConverter() DateTime occurredOn, ExpenseCategory category,@DecimalConverter() Decimal amount, String? workSessionId, String? description, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? occurredOn = null,Object? category = null,Object? amount = null,Object? workSessionId = freezed,Object? description = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? workSessionId,  String? description,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.occurredOn,_that.category,_that.amount,_that.workSessionId,_that.description,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? workSessionId,  String? description,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.occurredOn,_that.category,_that.amount,_that.workSessionId,_that.description,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? workSessionId,  String? description,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.occurredOn,_that.category,_that.amount,_that.workSessionId,_that.description,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expense implements Expense {
  const _Expense({required this.id, @DateOnlyConverter() required this.occurredOn, required this.category, @DecimalConverter() required this.amount, this.workSessionId, this.description, this.isDemo = false, required this.createdAt, required this.updatedAt});
  factory _Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

@override final  String id;
@override@DateOnlyConverter() final  DateTime occurredOn;
@override final  ExpenseCategory category;
@override@DecimalConverter() final  Decimal amount;
@override final  String? workSessionId;
@override final  String? description;
@override@JsonKey() final  bool isDemo;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.workSessionId, workSessionId) || other.workSessionId == workSessionId)&&(identical(other.description, description) || other.description == description)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,occurredOn,category,amount,workSessionId,description,isDemo,createdAt,updatedAt);
}

@override
String toString() {
    return 'Expense(id: $id, occurredOn: $occurredOn, category: $category, amount: $amount, workSessionId: $workSessionId, description: $description, isDemo: $isDemo, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id,@DateOnlyConverter() DateTime occurredOn, ExpenseCategory category,@DecimalConverter() Decimal amount, String? workSessionId, String? description, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? occurredOn = null,Object? category = null,Object? amount = null,Object? workSessionId = freezed,Object? description = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,workSessionId: freezed == workSessionId ? _self.workSessionId : workSessionId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ExpenseInput {

@DateOnlyConverter() DateTime get occurredOn; ExpenseCategory get category;@DecimalConverter() Decimal get amount; String? get description;
/// Create a copy of ExpenseInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseInputCopyWith<ExpenseInput> get copyWith => _$ExpenseInputCopyWithImpl<ExpenseInput>(this as ExpenseInput, _$identity);

  /// Serializes this ExpenseInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExpenseInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseInput&&(identical(other.occurredOn, _this.occurredOn) || other.occurredOn == _this.occurredOn)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExpenseInput;
  return Object.hash(runtimeType,_this.occurredOn,_this.category,_this.amount,_this.description);
}

@override
String toString() {
  final _this = this as ExpenseInput;
  return 'ExpenseInput(occurredOn: ${_this.occurredOn}, category: ${_this.category}, amount: ${_this.amount}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $ExpenseInputCopyWith<$Res>  {
  factory $ExpenseInputCopyWith(ExpenseInput value, $Res Function(ExpenseInput) _then) = _$ExpenseInputCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime occurredOn, ExpenseCategory category,@DecimalConverter() Decimal amount, String? description
});




}
/// @nodoc
class _$ExpenseInputCopyWithImpl<$Res>
    implements $ExpenseInputCopyWith<$Res> {
  _$ExpenseInputCopyWithImpl(this._self, this._then);

  final ExpenseInput _self;
  final $Res Function(ExpenseInput) _then;

/// Create a copy of ExpenseInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? occurredOn = null,Object? category = null,Object? amount = null,Object? description = freezed,}) {
  return _then(ExpenseInput(
occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseInput].
extension ExpenseInputPatterns on ExpenseInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseInput value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseInput value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseInput() when $default != null:
return $default(_that.occurredOn,_that.category,_that.amount,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ExpenseInput():
return $default(_that.occurredOn,_that.category,_that.amount,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime occurredOn,  ExpenseCategory category, @DecimalConverter()  Decimal amount,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseInput() when $default != null:
return $default(_that.occurredOn,_that.category,_that.amount,_that.description);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: true)
class _ExpenseInput implements ExpenseInput {
  const _ExpenseInput({@DateOnlyConverter() required this.occurredOn, required this.category, @DecimalConverter() required this.amount, this.description});
  

@override@DateOnlyConverter() final  DateTime occurredOn;
@override final  ExpenseCategory category;
@override@DecimalConverter() final  Decimal amount;
@override final  String? description;

/// Create a copy of ExpenseInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseInputCopyWith<_ExpenseInput> get copyWith => __$ExpenseInputCopyWithImpl<_ExpenseInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseInput&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,occurredOn,category,amount,description);
}

@override
String toString() {
    return 'ExpenseInput(occurredOn: $occurredOn, category: $category, amount: $amount, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ExpenseInputCopyWith<$Res> implements $ExpenseInputCopyWith<$Res> {
  factory _$ExpenseInputCopyWith(_ExpenseInput value, $Res Function(_ExpenseInput) _then) = __$ExpenseInputCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime occurredOn, ExpenseCategory category,@DecimalConverter() Decimal amount, String? description
});




}
/// @nodoc
class __$ExpenseInputCopyWithImpl<$Res>
    implements _$ExpenseInputCopyWith<$Res> {
  __$ExpenseInputCopyWithImpl(this._self, this._then);

  final _ExpenseInput _self;
  final $Res Function(_ExpenseInput) _then;

/// Create a copy of ExpenseInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? occurredOn = null,Object? category = null,Object? amount = null,Object? description = freezed,}) {
  return _then(_ExpenseInput(
occurredOn: null == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkSession {

 String get id;@AwareDateTimeConverter() DateTime get startedAt;@AwareDateTimeConverter() DateTime get endedAt;@NullableDecimalConverter() Decimal? get distanceKm; int? get orderCount; String? get notes; bool get isDemo; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of WorkSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkSessionCopyWith<WorkSession> get copyWith => _$WorkSessionCopyWithImpl<WorkSession>(this as WorkSession, _$identity);

  /// Serializes this WorkSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WorkSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.orderCount, _this.orderCount) || other.orderCount == _this.orderCount)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.isDemo, _this.isDemo) || other.isDemo == _this.isDemo)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WorkSession;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.endedAt,_this.distanceKm,_this.orderCount,_this.notes,_this.isDemo,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as WorkSession;
  return 'WorkSession(id: ${_this.id}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, distanceKm: ${_this.distanceKm}, orderCount: ${_this.orderCount}, notes: ${_this.notes}, isDemo: ${_this.isDemo}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $WorkSessionCopyWith<$Res>  {
  factory $WorkSessionCopyWith(WorkSession value, $Res Function(WorkSession) _then) = _$WorkSessionCopyWithImpl;
@useResult
$Res call({
 String id,@AwareDateTimeConverter() DateTime startedAt,@AwareDateTimeConverter() DateTime endedAt,@NullableDecimalConverter() Decimal? distanceKm, int? orderCount, String? notes, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$WorkSessionCopyWithImpl<$Res>
    implements $WorkSessionCopyWith<$Res> {
  _$WorkSessionCopyWithImpl(this._self, this._then);

  final WorkSession _self;
  final $Res Function(WorkSession) _then;

/// Create a copy of WorkSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? endedAt = null,Object? distanceKm = freezed,Object? orderCount = freezed,Object? notes = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(WorkSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkSession].
extension WorkSessionPatterns on WorkSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkSession value)  $default,){
final _that = this;
switch (_that) {
case _WorkSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkSession value)?  $default,){
final _that = this;
switch (_that) {
case _WorkSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkSession():
return $default(_that.id,_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes,  bool isDemo,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes,_that.isDemo,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkSession extends WorkSession {
  const _WorkSession({required this.id, @AwareDateTimeConverter() required this.startedAt, @AwareDateTimeConverter() required this.endedAt, @NullableDecimalConverter() this.distanceKm, this.orderCount, this.notes, this.isDemo = false, required this.createdAt, required this.updatedAt}): super._();
  factory _WorkSession.fromJson(Map<String, dynamic> json) => _$WorkSessionFromJson(json);

@override final  String id;
@override@AwareDateTimeConverter() final  DateTime startedAt;
@override@AwareDateTimeConverter() final  DateTime endedAt;
@override@NullableDecimalConverter() final  Decimal? distanceKm;
@override final  int? orderCount;
@override final  String? notes;
@override@JsonKey() final  bool isDemo;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of WorkSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkSessionCopyWith<_WorkSession> get copyWith => __$WorkSessionCopyWithImpl<_WorkSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkSessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,startedAt,endedAt,distanceKm,orderCount,notes,isDemo,createdAt,updatedAt);
}

@override
String toString() {
    return 'WorkSession(id: $id, startedAt: $startedAt, endedAt: $endedAt, distanceKm: $distanceKm, orderCount: $orderCount, notes: $notes, isDemo: $isDemo, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkSessionCopyWith<$Res> implements $WorkSessionCopyWith<$Res> {
  factory _$WorkSessionCopyWith(_WorkSession value, $Res Function(_WorkSession) _then) = __$WorkSessionCopyWithImpl;
@override @useResult
$Res call({
 String id,@AwareDateTimeConverter() DateTime startedAt,@AwareDateTimeConverter() DateTime endedAt,@NullableDecimalConverter() Decimal? distanceKm, int? orderCount, String? notes, bool isDemo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$WorkSessionCopyWithImpl<$Res>
    implements _$WorkSessionCopyWith<$Res> {
  __$WorkSessionCopyWithImpl(this._self, this._then);

  final _WorkSession _self;
  final $Res Function(_WorkSession) _then;

/// Create a copy of WorkSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? endedAt = null,Object? distanceKm = freezed,Object? orderCount = freezed,Object? notes = freezed,Object? isDemo = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_WorkSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$WorkSessionInput {

@AwareDateTimeConverter() DateTime get startedAt;@AwareDateTimeConverter() DateTime get endedAt;@NullableDecimalConverter() Decimal? get distanceKm; int? get orderCount; String? get notes;
/// Create a copy of WorkSessionInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkSessionInputCopyWith<WorkSessionInput> get copyWith => _$WorkSessionInputCopyWithImpl<WorkSessionInput>(this as WorkSessionInput, _$identity);

  /// Serializes this WorkSessionInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WorkSessionInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkSessionInput&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.orderCount, _this.orderCount) || other.orderCount == _this.orderCount)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WorkSessionInput;
  return Object.hash(runtimeType,_this.startedAt,_this.endedAt,_this.distanceKm,_this.orderCount,_this.notes);
}

@override
String toString() {
  final _this = this as WorkSessionInput;
  return 'WorkSessionInput(startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, distanceKm: ${_this.distanceKm}, orderCount: ${_this.orderCount}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $WorkSessionInputCopyWith<$Res>  {
  factory $WorkSessionInputCopyWith(WorkSessionInput value, $Res Function(WorkSessionInput) _then) = _$WorkSessionInputCopyWithImpl;
@useResult
$Res call({
@AwareDateTimeConverter() DateTime startedAt,@AwareDateTimeConverter() DateTime endedAt,@NullableDecimalConverter() Decimal? distanceKm, int? orderCount, String? notes
});




}
/// @nodoc
class _$WorkSessionInputCopyWithImpl<$Res>
    implements $WorkSessionInputCopyWith<$Res> {
  _$WorkSessionInputCopyWithImpl(this._self, this._then);

  final WorkSessionInput _self;
  final $Res Function(WorkSessionInput) _then;

/// Create a copy of WorkSessionInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = null,Object? endedAt = null,Object? distanceKm = freezed,Object? orderCount = freezed,Object? notes = freezed,}) {
  return _then(WorkSessionInput(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkSessionInput].
extension WorkSessionInputPatterns on WorkSessionInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkSessionInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkSessionInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkSessionInput value)  $default,){
final _that = this;
switch (_that) {
case _WorkSessionInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkSessionInput value)?  $default,){
final _that = this;
switch (_that) {
case _WorkSessionInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkSessionInput() when $default != null:
return $default(_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _WorkSessionInput():
return $default(_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@AwareDateTimeConverter()  DateTime startedAt, @AwareDateTimeConverter()  DateTime endedAt, @NullableDecimalConverter()  Decimal? distanceKm,  int? orderCount,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _WorkSessionInput() when $default != null:
return $default(_that.startedAt,_that.endedAt,_that.distanceKm,_that.orderCount,_that.notes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: true)
class _WorkSessionInput implements WorkSessionInput {
  const _WorkSessionInput({@AwareDateTimeConverter() required this.startedAt, @AwareDateTimeConverter() required this.endedAt, @NullableDecimalConverter() this.distanceKm, this.orderCount, this.notes});
  

@override@AwareDateTimeConverter() final  DateTime startedAt;
@override@AwareDateTimeConverter() final  DateTime endedAt;
@override@NullableDecimalConverter() final  Decimal? distanceKm;
@override final  int? orderCount;
@override final  String? notes;

/// Create a copy of WorkSessionInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkSessionInputCopyWith<_WorkSessionInput> get copyWith => __$WorkSessionInputCopyWithImpl<_WorkSessionInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkSessionInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkSessionInput&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startedAt,endedAt,distanceKm,orderCount,notes);
}

@override
String toString() {
    return 'WorkSessionInput(startedAt: $startedAt, endedAt: $endedAt, distanceKm: $distanceKm, orderCount: $orderCount, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$WorkSessionInputCopyWith<$Res> implements $WorkSessionInputCopyWith<$Res> {
  factory _$WorkSessionInputCopyWith(_WorkSessionInput value, $Res Function(_WorkSessionInput) _then) = __$WorkSessionInputCopyWithImpl;
@override @useResult
$Res call({
@AwareDateTimeConverter() DateTime startedAt,@AwareDateTimeConverter() DateTime endedAt,@NullableDecimalConverter() Decimal? distanceKm, int? orderCount, String? notes
});




}
/// @nodoc
class __$WorkSessionInputCopyWithImpl<$Res>
    implements _$WorkSessionInputCopyWith<$Res> {
  __$WorkSessionInputCopyWithImpl(this._self, this._then);

  final _WorkSessionInput _self;
  final $Res Function(_WorkSessionInput) _then;

/// Create a copy of WorkSessionInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startedAt = null,Object? endedAt = null,Object? distanceKm = freezed,Object? orderCount = freezed,Object? notes = freezed,}) {
  return _then(_WorkSessionInput(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as Decimal?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
