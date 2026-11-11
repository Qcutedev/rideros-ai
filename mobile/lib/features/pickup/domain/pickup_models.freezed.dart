// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pickup_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Coordinates {

 double get lat; double get lng;
/// Create a copy of Coordinates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoordinatesCopyWith<Coordinates> get copyWith => _$CoordinatesCopyWithImpl<Coordinates>(this as Coordinates, _$identity);

  /// Serializes this Coordinates to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Coordinates;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Coordinates&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Coordinates;
  return Object.hash(runtimeType,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as Coordinates;
  return 'Coordinates(lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $CoordinatesCopyWith<$Res>  {
  factory $CoordinatesCopyWith(Coordinates value, $Res Function(Coordinates) _then) = _$CoordinatesCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$CoordinatesCopyWithImpl<$Res>
    implements $CoordinatesCopyWith<$Res> {
  _$CoordinatesCopyWithImpl(this._self, this._then);

  final Coordinates _self;
  final $Res Function(Coordinates) _then;

/// Create a copy of Coordinates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(Coordinates(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Coordinates].
extension CoordinatesPatterns on Coordinates {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Coordinates value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Coordinates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Coordinates value)  $default,){
final _that = this;
switch (_that) {
case _Coordinates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Coordinates value)?  $default,){
final _that = this;
switch (_that) {
case _Coordinates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Coordinates() when $default != null:
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _Coordinates():
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _Coordinates() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Coordinates implements Coordinates {
  const _Coordinates({required this.lat, required this.lng});
  factory _Coordinates.fromJson(Map<String, dynamic> json) => _$CoordinatesFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of Coordinates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoordinatesCopyWith<_Coordinates> get copyWith => __$CoordinatesCopyWithImpl<_Coordinates>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoordinatesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Coordinates&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng);
}

@override
String toString() {
    return 'Coordinates(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$CoordinatesCopyWith<$Res> implements $CoordinatesCopyWith<$Res> {
  factory _$CoordinatesCopyWith(_Coordinates value, $Res Function(_Coordinates) _then) = __$CoordinatesCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$CoordinatesCopyWithImpl<$Res>
    implements _$CoordinatesCopyWith<$Res> {
  __$CoordinatesCopyWithImpl(this._self, this._then);

  final _Coordinates _self;
  final $Res Function(_Coordinates) _then;

/// Create a copy of Coordinates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_Coordinates(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Restaurant {

 String get id; String get source; String get name; bool get isOwn;/// Only dataset restaurants are known to the model.
 bool get supportsPrediction; DataAvailability? get dataAvailability; int? get nOrders;/// Only for the rider's own restaurants.
 Coordinates? get location; DateTime get createdAt;
/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantCopyWith<Restaurant> get copyWith => _$RestaurantCopyWithImpl<Restaurant>(this as Restaurant, _$identity);

  /// Serializes this Restaurant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Restaurant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Restaurant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isOwn, _this.isOwn) || other.isOwn == _this.isOwn)&&(identical(other.supportsPrediction, _this.supportsPrediction) || other.supportsPrediction == _this.supportsPrediction)&&(identical(other.dataAvailability, _this.dataAvailability) || other.dataAvailability == _this.dataAvailability)&&(identical(other.nOrders, _this.nOrders) || other.nOrders == _this.nOrders)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Restaurant;
  return Object.hash(runtimeType,_this.id,_this.source,_this.name,_this.isOwn,_this.supportsPrediction,_this.dataAvailability,_this.nOrders,_this.location,_this.createdAt);
}

@override
String toString() {
  final _this = this as Restaurant;
  return 'Restaurant(id: ${_this.id}, source: ${_this.source}, name: ${_this.name}, isOwn: ${_this.isOwn}, supportsPrediction: ${_this.supportsPrediction}, dataAvailability: ${_this.dataAvailability}, nOrders: ${_this.nOrders}, location: ${_this.location}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $RestaurantCopyWith<$Res>  {
  factory $RestaurantCopyWith(Restaurant value, $Res Function(Restaurant) _then) = _$RestaurantCopyWithImpl;
@useResult
$Res call({
 String id, String source, String name, bool isOwn, bool supportsPrediction, DataAvailability? dataAvailability, int? nOrders, Coordinates? location, DateTime createdAt
});


$CoordinatesCopyWith<$Res>? get location;

}
/// @nodoc
class _$RestaurantCopyWithImpl<$Res>
    implements $RestaurantCopyWith<$Res> {
  _$RestaurantCopyWithImpl(this._self, this._then);

  final Restaurant _self;
  final $Res Function(Restaurant) _then;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? name = null,Object? isOwn = null,Object? supportsPrediction = null,Object? dataAvailability = freezed,Object? nOrders = freezed,Object? location = freezed,Object? createdAt = null,}) {
  return _then(Restaurant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,supportsPrediction: null == supportsPrediction ? _self.supportsPrediction : supportsPrediction // ignore: cast_nullable_to_non_nullable
as bool,dataAvailability: freezed == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability?,nOrders: freezed == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Coordinates?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordinatesCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $CoordinatesCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Restaurant].
extension RestaurantPatterns on Restaurant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Restaurant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Restaurant value)  $default,){
final _that = this;
switch (_that) {
case _Restaurant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Restaurant value)?  $default,){
final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String source,  String name,  bool isOwn,  bool supportsPrediction,  DataAvailability? dataAvailability,  int? nOrders,  Coordinates? location,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that.id,_that.source,_that.name,_that.isOwn,_that.supportsPrediction,_that.dataAvailability,_that.nOrders,_that.location,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String source,  String name,  bool isOwn,  bool supportsPrediction,  DataAvailability? dataAvailability,  int? nOrders,  Coordinates? location,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Restaurant():
return $default(_that.id,_that.source,_that.name,_that.isOwn,_that.supportsPrediction,_that.dataAvailability,_that.nOrders,_that.location,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String source,  String name,  bool isOwn,  bool supportsPrediction,  DataAvailability? dataAvailability,  int? nOrders,  Coordinates? location,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Restaurant() when $default != null:
return $default(_that.id,_that.source,_that.name,_that.isOwn,_that.supportsPrediction,_that.dataAvailability,_that.nOrders,_that.location,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Restaurant implements Restaurant {
  const _Restaurant({required this.id, required this.source, required this.name, required this.isOwn, required this.supportsPrediction, this.dataAvailability, this.nOrders, this.location, required this.createdAt});
  factory _Restaurant.fromJson(Map<String, dynamic> json) => _$RestaurantFromJson(json);

@override final  String id;
@override final  String source;
@override final  String name;
@override final  bool isOwn;
/// Only dataset restaurants are known to the model.
@override final  bool supportsPrediction;
@override final  DataAvailability? dataAvailability;
@override final  int? nOrders;
/// Only for the rider's own restaurants.
@override final  Coordinates? location;
@override final  DateTime createdAt;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantCopyWith<_Restaurant> get copyWith => __$RestaurantCopyWithImpl<_Restaurant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Restaurant&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.name, name) || other.name == name)&&(identical(other.isOwn, isOwn) || other.isOwn == isOwn)&&(identical(other.supportsPrediction, supportsPrediction) || other.supportsPrediction == supportsPrediction)&&(identical(other.dataAvailability, dataAvailability) || other.dataAvailability == dataAvailability)&&(identical(other.nOrders, nOrders) || other.nOrders == nOrders)&&(identical(other.location, location) || other.location == location)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,source,name,isOwn,supportsPrediction,dataAvailability,nOrders,location,createdAt);
}

@override
String toString() {
    return 'Restaurant(id: $id, source: $source, name: $name, isOwn: $isOwn, supportsPrediction: $supportsPrediction, dataAvailability: $dataAvailability, nOrders: $nOrders, location: $location, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RestaurantCopyWith<$Res> implements $RestaurantCopyWith<$Res> {
  factory _$RestaurantCopyWith(_Restaurant value, $Res Function(_Restaurant) _then) = __$RestaurantCopyWithImpl;
@override @useResult
$Res call({
 String id, String source, String name, bool isOwn, bool supportsPrediction, DataAvailability? dataAvailability, int? nOrders, Coordinates? location, DateTime createdAt
});


@override $CoordinatesCopyWith<$Res>? get location;

}
/// @nodoc
class __$RestaurantCopyWithImpl<$Res>
    implements _$RestaurantCopyWith<$Res> {
  __$RestaurantCopyWithImpl(this._self, this._then);

  final _Restaurant _self;
  final $Res Function(_Restaurant) _then;

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? name = null,Object? isOwn = null,Object? supportsPrediction = null,Object? dataAvailability = freezed,Object? nOrders = freezed,Object? location = freezed,Object? createdAt = null,}) {
  return _then(_Restaurant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,supportsPrediction: null == supportsPrediction ? _self.supportsPrediction : supportsPrediction // ignore: cast_nullable_to_non_nullable
as bool,dataAvailability: freezed == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability?,nOrders: freezed == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Coordinates?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Restaurant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordinatesCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $CoordinatesCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

/// @nodoc
mixin _$RestaurantInput {

 String get name; Coordinates? get location;
/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantInputCopyWith<RestaurantInput> get copyWith => _$RestaurantInputCopyWithImpl<RestaurantInput>(this as RestaurantInput, _$identity);

  /// Serializes this RestaurantInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantInput&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.location, _this.location) || other.location == _this.location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantInput;
  return Object.hash(runtimeType,_this.name,_this.location);
}

@override
String toString() {
  final _this = this as RestaurantInput;
  return 'RestaurantInput(name: ${_this.name}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $RestaurantInputCopyWith<$Res>  {
  factory $RestaurantInputCopyWith(RestaurantInput value, $Res Function(RestaurantInput) _then) = _$RestaurantInputCopyWithImpl;
@useResult
$Res call({
 String name, Coordinates? location
});


$CoordinatesCopyWith<$Res>? get location;

}
/// @nodoc
class _$RestaurantInputCopyWithImpl<$Res>
    implements $RestaurantInputCopyWith<$Res> {
  _$RestaurantInputCopyWithImpl(this._self, this._then);

  final RestaurantInput _self;
  final $Res Function(RestaurantInput) _then;

/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? location = freezed,}) {
  return _then(RestaurantInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Coordinates?,
  ));
}
/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordinatesCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $CoordinatesCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [RestaurantInput].
extension RestaurantInputPatterns on RestaurantInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantInput value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantInput value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  Coordinates? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantInput() when $default != null:
return $default(_that.name,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  Coordinates? location)  $default,) {final _that = this;
switch (_that) {
case _RestaurantInput():
return $default(_that.name,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  Coordinates? location)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantInput() when $default != null:
return $default(_that.name,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _RestaurantInput implements RestaurantInput {
  const _RestaurantInput({required this.name, this.location});
  

@override final  String name;
@override final  Coordinates? location;

/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantInputCopyWith<_RestaurantInput> get copyWith => __$RestaurantInputCopyWithImpl<_RestaurantInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantInput&&(identical(other.name, name) || other.name == name)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,location);
}

@override
String toString() {
    return 'RestaurantInput(name: $name, location: $location)';
}


}

/// @nodoc
abstract mixin class _$RestaurantInputCopyWith<$Res> implements $RestaurantInputCopyWith<$Res> {
  factory _$RestaurantInputCopyWith(_RestaurantInput value, $Res Function(_RestaurantInput) _then) = __$RestaurantInputCopyWithImpl;
@override @useResult
$Res call({
 String name, Coordinates? location
});


@override $CoordinatesCopyWith<$Res>? get location;

}
/// @nodoc
class __$RestaurantInputCopyWithImpl<$Res>
    implements _$RestaurantInputCopyWith<$Res> {
  __$RestaurantInputCopyWithImpl(this._self, this._then);

  final _RestaurantInput _self;
  final $Res Function(_RestaurantInput) _then;

/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? location = freezed,}) {
  return _then(_RestaurantInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Coordinates?,
  ));
}

/// Create a copy of RestaurantInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoordinatesCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $CoordinatesCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$StatCell {

 int get hour; int get nOrders;@NullableDecimalConverter() Decimal? get medianMin;@NullableDecimalConverter() Decimal? get p25Min;@NullableDecimalConverter() Decimal? get p75Min;@NullableDecimalConverter() Decimal? get p90Min;
/// Create a copy of StatCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatCellCopyWith<StatCell> get copyWith => _$StatCellCopyWithImpl<StatCell>(this as StatCell, _$identity);

  /// Serializes this StatCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StatCell;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatCell&&(identical(other.hour, _this.hour) || other.hour == _this.hour)&&(identical(other.nOrders, _this.nOrders) || other.nOrders == _this.nOrders)&&(identical(other.medianMin, _this.medianMin) || other.medianMin == _this.medianMin)&&(identical(other.p25Min, _this.p25Min) || other.p25Min == _this.p25Min)&&(identical(other.p75Min, _this.p75Min) || other.p75Min == _this.p75Min)&&(identical(other.p90Min, _this.p90Min) || other.p90Min == _this.p90Min));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StatCell;
  return Object.hash(runtimeType,_this.hour,_this.nOrders,_this.medianMin,_this.p25Min,_this.p75Min,_this.p90Min);
}

@override
String toString() {
  final _this = this as StatCell;
  return 'StatCell(hour: ${_this.hour}, nOrders: ${_this.nOrders}, medianMin: ${_this.medianMin}, p25Min: ${_this.p25Min}, p75Min: ${_this.p75Min}, p90Min: ${_this.p90Min})';
}


}

/// @nodoc
abstract mixin class $StatCellCopyWith<$Res>  {
  factory $StatCellCopyWith(StatCell value, $Res Function(StatCell) _then) = _$StatCellCopyWithImpl;
@useResult
$Res call({
 int hour, int nOrders,@NullableDecimalConverter() Decimal? medianMin,@NullableDecimalConverter() Decimal? p25Min,@NullableDecimalConverter() Decimal? p75Min,@NullableDecimalConverter() Decimal? p90Min
});




}
/// @nodoc
class _$StatCellCopyWithImpl<$Res>
    implements $StatCellCopyWith<$Res> {
  _$StatCellCopyWithImpl(this._self, this._then);

  final StatCell _self;
  final $Res Function(StatCell) _then;

/// Create a copy of StatCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hour = null,Object? nOrders = null,Object? medianMin = freezed,Object? p25Min = freezed,Object? p75Min = freezed,Object? p90Min = freezed,}) {
  return _then(StatCell(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,nOrders: null == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int,medianMin: freezed == medianMin ? _self.medianMin : medianMin // ignore: cast_nullable_to_non_nullable
as Decimal?,p25Min: freezed == p25Min ? _self.p25Min : p25Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p75Min: freezed == p75Min ? _self.p75Min : p75Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p90Min: freezed == p90Min ? _self.p90Min : p90Min // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatCell].
extension StatCellPatterns on StatCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatCell value)  $default,){
final _that = this;
switch (_that) {
case _StatCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatCell value)?  $default,){
final _that = this;
switch (_that) {
case _StatCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int hour,  int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatCell() when $default != null:
return $default(_that.hour,_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int hour,  int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min)  $default,) {final _that = this;
switch (_that) {
case _StatCell():
return $default(_that.hour,_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int hour,  int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min)?  $default,) {final _that = this;
switch (_that) {
case _StatCell() when $default != null:
return $default(_that.hour,_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatCell implements StatCell {
  const _StatCell({required this.hour, required this.nOrders, @NullableDecimalConverter() this.medianMin, @NullableDecimalConverter() this.p25Min, @NullableDecimalConverter() this.p75Min, @NullableDecimalConverter() this.p90Min});
  factory _StatCell.fromJson(Map<String, dynamic> json) => _$StatCellFromJson(json);

@override final  int hour;
@override final  int nOrders;
@override@NullableDecimalConverter() final  Decimal? medianMin;
@override@NullableDecimalConverter() final  Decimal? p25Min;
@override@NullableDecimalConverter() final  Decimal? p75Min;
@override@NullableDecimalConverter() final  Decimal? p90Min;

/// Create a copy of StatCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatCellCopyWith<_StatCell> get copyWith => __$StatCellCopyWithImpl<_StatCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatCellToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatCell&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.nOrders, nOrders) || other.nOrders == nOrders)&&(identical(other.medianMin, medianMin) || other.medianMin == medianMin)&&(identical(other.p25Min, p25Min) || other.p25Min == p25Min)&&(identical(other.p75Min, p75Min) || other.p75Min == p75Min)&&(identical(other.p90Min, p90Min) || other.p90Min == p90Min));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,hour,nOrders,medianMin,p25Min,p75Min,p90Min);
}

@override
String toString() {
    return 'StatCell(hour: $hour, nOrders: $nOrders, medianMin: $medianMin, p25Min: $p25Min, p75Min: $p75Min, p90Min: $p90Min)';
}


}

/// @nodoc
abstract mixin class _$StatCellCopyWith<$Res> implements $StatCellCopyWith<$Res> {
  factory _$StatCellCopyWith(_StatCell value, $Res Function(_StatCell) _then) = __$StatCellCopyWithImpl;
@override @useResult
$Res call({
 int hour, int nOrders,@NullableDecimalConverter() Decimal? medianMin,@NullableDecimalConverter() Decimal? p25Min,@NullableDecimalConverter() Decimal? p75Min,@NullableDecimalConverter() Decimal? p90Min
});




}
/// @nodoc
class __$StatCellCopyWithImpl<$Res>
    implements _$StatCellCopyWith<$Res> {
  __$StatCellCopyWithImpl(this._self, this._then);

  final _StatCell _self;
  final $Res Function(_StatCell) _then;

/// Create a copy of StatCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hour = null,Object? nOrders = null,Object? medianMin = freezed,Object? p25Min = freezed,Object? p75Min = freezed,Object? p90Min = freezed,}) {
  return _then(_StatCell(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,nOrders: null == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int,medianMin: freezed == medianMin ? _self.medianMin : medianMin // ignore: cast_nullable_to_non_nullable
as Decimal?,p25Min: freezed == p25Min ? _self.p25Min : p25Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p75Min: freezed == p75Min ? _self.p75Min : p75Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p90Min: freezed == p90Min ? _self.p90Min : p90Min // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}


}


/// @nodoc
mixin _$OverallStats {

 int get nOrders;@NullableDecimalConverter() Decimal? get medianMin;@NullableDecimalConverter() Decimal? get p25Min;@NullableDecimalConverter() Decimal? get p75Min;@NullableDecimalConverter() Decimal? get p90Min; int? get peakHour;
/// Create a copy of OverallStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverallStatsCopyWith<OverallStats> get copyWith => _$OverallStatsCopyWithImpl<OverallStats>(this as OverallStats, _$identity);

  /// Serializes this OverallStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OverallStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverallStats&&(identical(other.nOrders, _this.nOrders) || other.nOrders == _this.nOrders)&&(identical(other.medianMin, _this.medianMin) || other.medianMin == _this.medianMin)&&(identical(other.p25Min, _this.p25Min) || other.p25Min == _this.p25Min)&&(identical(other.p75Min, _this.p75Min) || other.p75Min == _this.p75Min)&&(identical(other.p90Min, _this.p90Min) || other.p90Min == _this.p90Min)&&(identical(other.peakHour, _this.peakHour) || other.peakHour == _this.peakHour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OverallStats;
  return Object.hash(runtimeType,_this.nOrders,_this.medianMin,_this.p25Min,_this.p75Min,_this.p90Min,_this.peakHour);
}

@override
String toString() {
  final _this = this as OverallStats;
  return 'OverallStats(nOrders: ${_this.nOrders}, medianMin: ${_this.medianMin}, p25Min: ${_this.p25Min}, p75Min: ${_this.p75Min}, p90Min: ${_this.p90Min}, peakHour: ${_this.peakHour})';
}


}

/// @nodoc
abstract mixin class $OverallStatsCopyWith<$Res>  {
  factory $OverallStatsCopyWith(OverallStats value, $Res Function(OverallStats) _then) = _$OverallStatsCopyWithImpl;
@useResult
$Res call({
 int nOrders,@NullableDecimalConverter() Decimal? medianMin,@NullableDecimalConverter() Decimal? p25Min,@NullableDecimalConverter() Decimal? p75Min,@NullableDecimalConverter() Decimal? p90Min, int? peakHour
});




}
/// @nodoc
class _$OverallStatsCopyWithImpl<$Res>
    implements $OverallStatsCopyWith<$Res> {
  _$OverallStatsCopyWithImpl(this._self, this._then);

  final OverallStats _self;
  final $Res Function(OverallStats) _then;

/// Create a copy of OverallStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nOrders = null,Object? medianMin = freezed,Object? p25Min = freezed,Object? p75Min = freezed,Object? p90Min = freezed,Object? peakHour = freezed,}) {
  return _then(OverallStats(
nOrders: null == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int,medianMin: freezed == medianMin ? _self.medianMin : medianMin // ignore: cast_nullable_to_non_nullable
as Decimal?,p25Min: freezed == p25Min ? _self.p25Min : p25Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p75Min: freezed == p75Min ? _self.p75Min : p75Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p90Min: freezed == p90Min ? _self.p90Min : p90Min // ignore: cast_nullable_to_non_nullable
as Decimal?,peakHour: freezed == peakHour ? _self.peakHour : peakHour // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OverallStats].
extension OverallStatsPatterns on OverallStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverallStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverallStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverallStats value)  $default,){
final _that = this;
switch (_that) {
case _OverallStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverallStats value)?  $default,){
final _that = this;
switch (_that) {
case _OverallStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min,  int? peakHour)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverallStats() when $default != null:
return $default(_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min,_that.peakHour);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min,  int? peakHour)  $default,) {final _that = this;
switch (_that) {
case _OverallStats():
return $default(_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min,_that.peakHour);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int nOrders, @NullableDecimalConverter()  Decimal? medianMin, @NullableDecimalConverter()  Decimal? p25Min, @NullableDecimalConverter()  Decimal? p75Min, @NullableDecimalConverter()  Decimal? p90Min,  int? peakHour)?  $default,) {final _that = this;
switch (_that) {
case _OverallStats() when $default != null:
return $default(_that.nOrders,_that.medianMin,_that.p25Min,_that.p75Min,_that.p90Min,_that.peakHour);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverallStats implements OverallStats {
  const _OverallStats({required this.nOrders, @NullableDecimalConverter() this.medianMin, @NullableDecimalConverter() this.p25Min, @NullableDecimalConverter() this.p75Min, @NullableDecimalConverter() this.p90Min, this.peakHour});
  factory _OverallStats.fromJson(Map<String, dynamic> json) => _$OverallStatsFromJson(json);

@override final  int nOrders;
@override@NullableDecimalConverter() final  Decimal? medianMin;
@override@NullableDecimalConverter() final  Decimal? p25Min;
@override@NullableDecimalConverter() final  Decimal? p75Min;
@override@NullableDecimalConverter() final  Decimal? p90Min;
@override final  int? peakHour;

/// Create a copy of OverallStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverallStatsCopyWith<_OverallStats> get copyWith => __$OverallStatsCopyWithImpl<_OverallStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverallStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverallStats&&(identical(other.nOrders, nOrders) || other.nOrders == nOrders)&&(identical(other.medianMin, medianMin) || other.medianMin == medianMin)&&(identical(other.p25Min, p25Min) || other.p25Min == p25Min)&&(identical(other.p75Min, p75Min) || other.p75Min == p75Min)&&(identical(other.p90Min, p90Min) || other.p90Min == p90Min)&&(identical(other.peakHour, peakHour) || other.peakHour == peakHour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nOrders,medianMin,p25Min,p75Min,p90Min,peakHour);
}

@override
String toString() {
    return 'OverallStats(nOrders: $nOrders, medianMin: $medianMin, p25Min: $p25Min, p75Min: $p75Min, p90Min: $p90Min, peakHour: $peakHour)';
}


}

/// @nodoc
abstract mixin class _$OverallStatsCopyWith<$Res> implements $OverallStatsCopyWith<$Res> {
  factory _$OverallStatsCopyWith(_OverallStats value, $Res Function(_OverallStats) _then) = __$OverallStatsCopyWithImpl;
@override @useResult
$Res call({
 int nOrders,@NullableDecimalConverter() Decimal? medianMin,@NullableDecimalConverter() Decimal? p25Min,@NullableDecimalConverter() Decimal? p75Min,@NullableDecimalConverter() Decimal? p90Min, int? peakHour
});




}
/// @nodoc
class __$OverallStatsCopyWithImpl<$Res>
    implements _$OverallStatsCopyWith<$Res> {
  __$OverallStatsCopyWithImpl(this._self, this._then);

  final _OverallStats _self;
  final $Res Function(_OverallStats) _then;

/// Create a copy of OverallStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nOrders = null,Object? medianMin = freezed,Object? p25Min = freezed,Object? p75Min = freezed,Object? p90Min = freezed,Object? peakHour = freezed,}) {
  return _then(_OverallStats(
nOrders: null == nOrders ? _self.nOrders : nOrders // ignore: cast_nullable_to_non_nullable
as int,medianMin: freezed == medianMin ? _self.medianMin : medianMin // ignore: cast_nullable_to_non_nullable
as Decimal?,p25Min: freezed == p25Min ? _self.p25Min : p25Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p75Min: freezed == p75Min ? _self.p75Min : p75Min // ignore: cast_nullable_to_non_nullable
as Decimal?,p90Min: freezed == p90Min ? _self.p90Min : p90Min // ignore: cast_nullable_to_non_nullable
as Decimal?,peakHour: freezed == peakHour ? _self.peakHour : peakHour // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$RestaurantAnalytics {

 Restaurant get restaurant; DataAvailability get dataAvailability;/// `null` for the rider's own restaurants.
 OverallStats? get overall; Map<String, List<StatCell>> get byHour; int get minOrdersForStats; String? get datasetVersion; String? get acknowledgement;
/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantAnalyticsCopyWith<RestaurantAnalytics> get copyWith => _$RestaurantAnalyticsCopyWithImpl<RestaurantAnalytics>(this as RestaurantAnalytics, _$identity);

  /// Serializes this RestaurantAnalytics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantAnalytics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantAnalytics&&(identical(other.restaurant, _this.restaurant) || other.restaurant == _this.restaurant)&&(identical(other.dataAvailability, _this.dataAvailability) || other.dataAvailability == _this.dataAvailability)&&(identical(other.overall, _this.overall) || other.overall == _this.overall)&&const DeepCollectionEquality().equals(other.byHour, _this.byHour)&&(identical(other.minOrdersForStats, _this.minOrdersForStats) || other.minOrdersForStats == _this.minOrdersForStats)&&(identical(other.datasetVersion, _this.datasetVersion) || other.datasetVersion == _this.datasetVersion)&&(identical(other.acknowledgement, _this.acknowledgement) || other.acknowledgement == _this.acknowledgement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantAnalytics;
  return Object.hash(runtimeType,_this.restaurant,_this.dataAvailability,_this.overall,const DeepCollectionEquality().hash(_this.byHour),_this.minOrdersForStats,_this.datasetVersion,_this.acknowledgement);
}

@override
String toString() {
  final _this = this as RestaurantAnalytics;
  return 'RestaurantAnalytics(restaurant: ${_this.restaurant}, dataAvailability: ${_this.dataAvailability}, overall: ${_this.overall}, byHour: ${_this.byHour}, minOrdersForStats: ${_this.minOrdersForStats}, datasetVersion: ${_this.datasetVersion}, acknowledgement: ${_this.acknowledgement})';
}


}

/// @nodoc
abstract mixin class $RestaurantAnalyticsCopyWith<$Res>  {
  factory $RestaurantAnalyticsCopyWith(RestaurantAnalytics value, $Res Function(RestaurantAnalytics) _then) = _$RestaurantAnalyticsCopyWithImpl;
@useResult
$Res call({
 Restaurant restaurant, DataAvailability dataAvailability, OverallStats? overall, Map<String, List<StatCell>> byHour, int minOrdersForStats, String? datasetVersion, String? acknowledgement
});


$RestaurantCopyWith<$Res> get restaurant;$OverallStatsCopyWith<$Res>? get overall;

}
/// @nodoc
class _$RestaurantAnalyticsCopyWithImpl<$Res>
    implements $RestaurantAnalyticsCopyWith<$Res> {
  _$RestaurantAnalyticsCopyWithImpl(this._self, this._then);

  final RestaurantAnalytics _self;
  final $Res Function(RestaurantAnalytics) _then;

/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurant = null,Object? dataAvailability = null,Object? overall = freezed,Object? byHour = null,Object? minOrdersForStats = null,Object? datasetVersion = freezed,Object? acknowledgement = freezed,}) {
  return _then(RestaurantAnalytics(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Restaurant,dataAvailability: null == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability,overall: freezed == overall ? _self.overall : overall // ignore: cast_nullable_to_non_nullable
as OverallStats?,byHour: null == byHour ? _self.byHour : byHour // ignore: cast_nullable_to_non_nullable
as Map<String, List<StatCell>>,minOrdersForStats: null == minOrdersForStats ? _self.minOrdersForStats : minOrdersForStats // ignore: cast_nullable_to_non_nullable
as int,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,acknowledgement: freezed == acknowledgement ? _self.acknowledgement : acknowledgement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCopyWith<$Res> get restaurant {
  
  return $RestaurantCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverallStatsCopyWith<$Res>? get overall {
    if (_self.overall == null) {
    return null;
  }

  return $OverallStatsCopyWith<$Res>(_self.overall!, (value) {
    return _then(_self.copyWith(overall: value));
  });
}
}


/// Adds pattern-matching-related methods to [RestaurantAnalytics].
extension RestaurantAnalyticsPatterns on RestaurantAnalytics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantAnalytics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantAnalytics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantAnalytics value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantAnalytics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantAnalytics value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantAnalytics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Restaurant restaurant,  DataAvailability dataAvailability,  OverallStats? overall,  Map<String, List<StatCell>> byHour,  int minOrdersForStats,  String? datasetVersion,  String? acknowledgement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantAnalytics() when $default != null:
return $default(_that.restaurant,_that.dataAvailability,_that.overall,_that.byHour,_that.minOrdersForStats,_that.datasetVersion,_that.acknowledgement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Restaurant restaurant,  DataAvailability dataAvailability,  OverallStats? overall,  Map<String, List<StatCell>> byHour,  int minOrdersForStats,  String? datasetVersion,  String? acknowledgement)  $default,) {final _that = this;
switch (_that) {
case _RestaurantAnalytics():
return $default(_that.restaurant,_that.dataAvailability,_that.overall,_that.byHour,_that.minOrdersForStats,_that.datasetVersion,_that.acknowledgement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Restaurant restaurant,  DataAvailability dataAvailability,  OverallStats? overall,  Map<String, List<StatCell>> byHour,  int minOrdersForStats,  String? datasetVersion,  String? acknowledgement)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantAnalytics() when $default != null:
return $default(_that.restaurant,_that.dataAvailability,_that.overall,_that.byHour,_that.minOrdersForStats,_that.datasetVersion,_that.acknowledgement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantAnalytics implements RestaurantAnalytics {
  const _RestaurantAnalytics({required this.restaurant, required this.dataAvailability, this.overall,  Map<String, List<StatCell>> byHour = const {}, this.minOrdersForStats = 30, this.datasetVersion, this.acknowledgement}): _byHour = byHour;
  factory _RestaurantAnalytics.fromJson(Map<String, dynamic> json) => _$RestaurantAnalyticsFromJson(json);

@override final  Restaurant restaurant;
@override final  DataAvailability dataAvailability;
/// `null` for the rider's own restaurants.
@override final  OverallStats? overall;
 final  Map<String, List<StatCell>> _byHour;
@override@JsonKey() Map<String, List<StatCell>> get byHour {
  if (_byHour is EqualUnmodifiableMapView) return _byHour;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byHour);
}

@override@JsonKey() final  int minOrdersForStats;
@override final  String? datasetVersion;
@override final  String? acknowledgement;

/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantAnalyticsCopyWith<_RestaurantAnalytics> get copyWith => __$RestaurantAnalyticsCopyWithImpl<_RestaurantAnalytics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantAnalyticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantAnalytics&&(identical(other.restaurant, restaurant) || other.restaurant == restaurant)&&(identical(other.dataAvailability, dataAvailability) || other.dataAvailability == dataAvailability)&&(identical(other.overall, overall) || other.overall == overall)&&const DeepCollectionEquality().equals(other.byHour, _byHour)&&(identical(other.minOrdersForStats, minOrdersForStats) || other.minOrdersForStats == minOrdersForStats)&&(identical(other.datasetVersion, datasetVersion) || other.datasetVersion == datasetVersion)&&(identical(other.acknowledgement, acknowledgement) || other.acknowledgement == acknowledgement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,restaurant,dataAvailability,overall,const DeepCollectionEquality().hash(_byHour),minOrdersForStats,datasetVersion,acknowledgement);
}

@override
String toString() {
    return 'RestaurantAnalytics(restaurant: $restaurant, dataAvailability: $dataAvailability, overall: $overall, byHour: $byHour, minOrdersForStats: $minOrdersForStats, datasetVersion: $datasetVersion, acknowledgement: $acknowledgement)';
}


}

/// @nodoc
abstract mixin class _$RestaurantAnalyticsCopyWith<$Res> implements $RestaurantAnalyticsCopyWith<$Res> {
  factory _$RestaurantAnalyticsCopyWith(_RestaurantAnalytics value, $Res Function(_RestaurantAnalytics) _then) = __$RestaurantAnalyticsCopyWithImpl;
@override @useResult
$Res call({
 Restaurant restaurant, DataAvailability dataAvailability, OverallStats? overall, Map<String, List<StatCell>> byHour, int minOrdersForStats, String? datasetVersion, String? acknowledgement
});


@override $RestaurantCopyWith<$Res> get restaurant;@override $OverallStatsCopyWith<$Res>? get overall;

}
/// @nodoc
class __$RestaurantAnalyticsCopyWithImpl<$Res>
    implements _$RestaurantAnalyticsCopyWith<$Res> {
  __$RestaurantAnalyticsCopyWithImpl(this._self, this._then);

  final _RestaurantAnalytics _self;
  final $Res Function(_RestaurantAnalytics) _then;

/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurant = null,Object? dataAvailability = null,Object? overall = freezed,Object? byHour = null,Object? minOrdersForStats = null,Object? datasetVersion = freezed,Object? acknowledgement = freezed,}) {
  return _then(_RestaurantAnalytics(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Restaurant,dataAvailability: null == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability,overall: freezed == overall ? _self.overall : overall // ignore: cast_nullable_to_non_nullable
as OverallStats?,byHour: null == byHour ? _self._byHour : byHour // ignore: cast_nullable_to_non_nullable
as Map<String, List<StatCell>>,minOrdersForStats: null == minOrdersForStats ? _self.minOrdersForStats : minOrdersForStats // ignore: cast_nullable_to_non_nullable
as int,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,acknowledgement: freezed == acknowledgement ? _self.acknowledgement : acknowledgement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCopyWith<$Res> get restaurant {
  
  return $RestaurantCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}/// Create a copy of RestaurantAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverallStatsCopyWith<$Res>? get overall {
    if (_self.overall == null) {
    return null;
  }

  return $OverallStatsCopyWith<$Res>(_self.overall!, (value) {
    return _then(_self.copyWith(overall: value));
  });
}
}


/// @nodoc
mixin _$WaitStats {

 String get restaurantId; int get n;@NullableDecimalConverter() Decimal? get medianMinutes;@NullableDecimalConverter() Decimal? get p80Minutes; WaitConfidence get confidence;
/// Create a copy of WaitStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitStatsCopyWith<WaitStats> get copyWith => _$WaitStatsCopyWithImpl<WaitStats>(this as WaitStats, _$identity);

  /// Serializes this WaitStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaitStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitStats&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.n, _this.n) || other.n == _this.n)&&(identical(other.medianMinutes, _this.medianMinutes) || other.medianMinutes == _this.medianMinutes)&&(identical(other.p80Minutes, _this.p80Minutes) || other.p80Minutes == _this.p80Minutes)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaitStats;
  return Object.hash(runtimeType,_this.restaurantId,_this.n,_this.medianMinutes,_this.p80Minutes,_this.confidence);
}

@override
String toString() {
  final _this = this as WaitStats;
  return 'WaitStats(restaurantId: ${_this.restaurantId}, n: ${_this.n}, medianMinutes: ${_this.medianMinutes}, p80Minutes: ${_this.p80Minutes}, confidence: ${_this.confidence})';
}


}

/// @nodoc
abstract mixin class $WaitStatsCopyWith<$Res>  {
  factory $WaitStatsCopyWith(WaitStats value, $Res Function(WaitStats) _then) = _$WaitStatsCopyWithImpl;
@useResult
$Res call({
 String restaurantId, int n,@NullableDecimalConverter() Decimal? medianMinutes,@NullableDecimalConverter() Decimal? p80Minutes, WaitConfidence confidence
});




}
/// @nodoc
class _$WaitStatsCopyWithImpl<$Res>
    implements $WaitStatsCopyWith<$Res> {
  _$WaitStatsCopyWithImpl(this._self, this._then);

  final WaitStats _self;
  final $Res Function(WaitStats) _then;

/// Create a copy of WaitStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurantId = null,Object? n = null,Object? medianMinutes = freezed,Object? p80Minutes = freezed,Object? confidence = null,}) {
  return _then(WaitStats(
restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,medianMinutes: freezed == medianMinutes ? _self.medianMinutes : medianMinutes // ignore: cast_nullable_to_non_nullable
as Decimal?,p80Minutes: freezed == p80Minutes ? _self.p80Minutes : p80Minutes // ignore: cast_nullable_to_non_nullable
as Decimal?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as WaitConfidence,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitStats].
extension WaitStatsPatterns on WaitStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitStats value)  $default,){
final _that = this;
switch (_that) {
case _WaitStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitStats value)?  $default,){
final _that = this;
switch (_that) {
case _WaitStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String restaurantId,  int n, @NullableDecimalConverter()  Decimal? medianMinutes, @NullableDecimalConverter()  Decimal? p80Minutes,  WaitConfidence confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitStats() when $default != null:
return $default(_that.restaurantId,_that.n,_that.medianMinutes,_that.p80Minutes,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String restaurantId,  int n, @NullableDecimalConverter()  Decimal? medianMinutes, @NullableDecimalConverter()  Decimal? p80Minutes,  WaitConfidence confidence)  $default,) {final _that = this;
switch (_that) {
case _WaitStats():
return $default(_that.restaurantId,_that.n,_that.medianMinutes,_that.p80Minutes,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String restaurantId,  int n, @NullableDecimalConverter()  Decimal? medianMinutes, @NullableDecimalConverter()  Decimal? p80Minutes,  WaitConfidence confidence)?  $default,) {final _that = this;
switch (_that) {
case _WaitStats() when $default != null:
return $default(_that.restaurantId,_that.n,_that.medianMinutes,_that.p80Minutes,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitStats implements WaitStats {
  const _WaitStats({required this.restaurantId, required this.n, @NullableDecimalConverter() this.medianMinutes, @NullableDecimalConverter() this.p80Minutes, required this.confidence});
  factory _WaitStats.fromJson(Map<String, dynamic> json) => _$WaitStatsFromJson(json);

@override final  String restaurantId;
@override final  int n;
@override@NullableDecimalConverter() final  Decimal? medianMinutes;
@override@NullableDecimalConverter() final  Decimal? p80Minutes;
@override final  WaitConfidence confidence;

/// Create a copy of WaitStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitStatsCopyWith<_WaitStats> get copyWith => __$WaitStatsCopyWithImpl<_WaitStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitStats&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.n, n) || other.n == n)&&(identical(other.medianMinutes, medianMinutes) || other.medianMinutes == medianMinutes)&&(identical(other.p80Minutes, p80Minutes) || other.p80Minutes == p80Minutes)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,restaurantId,n,medianMinutes,p80Minutes,confidence);
}

@override
String toString() {
    return 'WaitStats(restaurantId: $restaurantId, n: $n, medianMinutes: $medianMinutes, p80Minutes: $p80Minutes, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$WaitStatsCopyWith<$Res> implements $WaitStatsCopyWith<$Res> {
  factory _$WaitStatsCopyWith(_WaitStats value, $Res Function(_WaitStats) _then) = __$WaitStatsCopyWithImpl;
@override @useResult
$Res call({
 String restaurantId, int n,@NullableDecimalConverter() Decimal? medianMinutes,@NullableDecimalConverter() Decimal? p80Minutes, WaitConfidence confidence
});




}
/// @nodoc
class __$WaitStatsCopyWithImpl<$Res>
    implements _$WaitStatsCopyWith<$Res> {
  __$WaitStatsCopyWithImpl(this._self, this._then);

  final _WaitStats _self;
  final $Res Function(_WaitStats) _then;

/// Create a copy of WaitStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurantId = null,Object? n = null,Object? medianMinutes = freezed,Object? p80Minutes = freezed,Object? confidence = null,}) {
  return _then(_WaitStats(
restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,medianMinutes: freezed == medianMinutes ? _self.medianMinutes : medianMinutes // ignore: cast_nullable_to_non_nullable
as Decimal?,p80Minutes: freezed == p80Minutes ? _self.p80Minutes : p80Minutes // ignore: cast_nullable_to_non_nullable
as Decimal?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as WaitConfidence,
  ));
}


}


/// @nodoc
mixin _$PredictionInterval {

@DecimalConverter() Decimal get low;@DecimalConverter() Decimal get high;/// `null` in history rows of a version that is no longer loaded.
 double? get nominalCoverage;
/// Create a copy of PredictionInterval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionIntervalCopyWith<PredictionInterval> get copyWith => _$PredictionIntervalCopyWithImpl<PredictionInterval>(this as PredictionInterval, _$identity);

  /// Serializes this PredictionInterval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PredictionInterval;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictionInterval&&(identical(other.low, _this.low) || other.low == _this.low)&&(identical(other.high, _this.high) || other.high == _this.high)&&(identical(other.nominalCoverage, _this.nominalCoverage) || other.nominalCoverage == _this.nominalCoverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PredictionInterval;
  return Object.hash(runtimeType,_this.low,_this.high,_this.nominalCoverage);
}

@override
String toString() {
  final _this = this as PredictionInterval;
  return 'PredictionInterval(low: ${_this.low}, high: ${_this.high}, nominalCoverage: ${_this.nominalCoverage})';
}


}

/// @nodoc
abstract mixin class $PredictionIntervalCopyWith<$Res>  {
  factory $PredictionIntervalCopyWith(PredictionInterval value, $Res Function(PredictionInterval) _then) = _$PredictionIntervalCopyWithImpl;
@useResult
$Res call({
@DecimalConverter() Decimal low,@DecimalConverter() Decimal high, double? nominalCoverage
});




}
/// @nodoc
class _$PredictionIntervalCopyWithImpl<$Res>
    implements $PredictionIntervalCopyWith<$Res> {
  _$PredictionIntervalCopyWithImpl(this._self, this._then);

  final PredictionInterval _self;
  final $Res Function(PredictionInterval) _then;

/// Create a copy of PredictionInterval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? low = null,Object? high = null,Object? nominalCoverage = freezed,}) {
  return _then(PredictionInterval(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,nominalCoverage: freezed == nominalCoverage ? _self.nominalCoverage : nominalCoverage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictionInterval].
extension PredictionIntervalPatterns on PredictionInterval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictionInterval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictionInterval() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictionInterval value)  $default,){
final _that = this;
switch (_that) {
case _PredictionInterval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictionInterval value)?  $default,){
final _that = this;
switch (_that) {
case _PredictionInterval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal low, @DecimalConverter()  Decimal high,  double? nominalCoverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictionInterval() when $default != null:
return $default(_that.low,_that.high,_that.nominalCoverage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal low, @DecimalConverter()  Decimal high,  double? nominalCoverage)  $default,) {final _that = this;
switch (_that) {
case _PredictionInterval():
return $default(_that.low,_that.high,_that.nominalCoverage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalConverter()  Decimal low, @DecimalConverter()  Decimal high,  double? nominalCoverage)?  $default,) {final _that = this;
switch (_that) {
case _PredictionInterval() when $default != null:
return $default(_that.low,_that.high,_that.nominalCoverage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictionInterval implements PredictionInterval {
  const _PredictionInterval({@DecimalConverter() required this.low, @DecimalConverter() required this.high, this.nominalCoverage});
  factory _PredictionInterval.fromJson(Map<String, dynamic> json) => _$PredictionIntervalFromJson(json);

@override@DecimalConverter() final  Decimal low;
@override@DecimalConverter() final  Decimal high;
/// `null` in history rows of a version that is no longer loaded.
@override final  double? nominalCoverage;

/// Create a copy of PredictionInterval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionIntervalCopyWith<_PredictionInterval> get copyWith => __$PredictionIntervalCopyWithImpl<_PredictionInterval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionIntervalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictionInterval&&(identical(other.low, low) || other.low == low)&&(identical(other.high, high) || other.high == high)&&(identical(other.nominalCoverage, nominalCoverage) || other.nominalCoverage == nominalCoverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,low,high,nominalCoverage);
}

@override
String toString() {
    return 'PredictionInterval(low: $low, high: $high, nominalCoverage: $nominalCoverage)';
}


}

/// @nodoc
abstract mixin class _$PredictionIntervalCopyWith<$Res> implements $PredictionIntervalCopyWith<$Res> {
  factory _$PredictionIntervalCopyWith(_PredictionInterval value, $Res Function(_PredictionInterval) _then) = __$PredictionIntervalCopyWithImpl;
@override @useResult
$Res call({
@DecimalConverter() Decimal low,@DecimalConverter() Decimal high, double? nominalCoverage
});




}
/// @nodoc
class __$PredictionIntervalCopyWithImpl<$Res>
    implements _$PredictionIntervalCopyWith<$Res> {
  __$PredictionIntervalCopyWithImpl(this._self, this._then);

  final _PredictionInterval _self;
  final $Res Function(_PredictionInterval) _then;

/// Create a copy of PredictionInterval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? low = null,Object? high = null,Object? nominalCoverage = freezed,}) {
  return _then(_PredictionInterval(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,nominalCoverage: freezed == nominalCoverage ? _self.nominalCoverage : nominalCoverage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Prediction {

 String get id; String? get restaurantId; String? get restaurantName;@DecimalConverter() Decimal get predictedMinutes; PredictionInterval get interval; DataAvailability get dataAvailability; List<String> get warnings; String get modelVersion;@AwareDateTimeConverter() DateTime get requestedAt; String get disclaimer; DateTime get createdAt;
/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictionCopyWith<Prediction> get copyWith => _$PredictionCopyWithImpl<Prediction>(this as Prediction, _$identity);

  /// Serializes this Prediction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Prediction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Prediction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.predictedMinutes, _this.predictedMinutes) || other.predictedMinutes == _this.predictedMinutes)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.dataAvailability, _this.dataAvailability) || other.dataAvailability == _this.dataAvailability)&&const DeepCollectionEquality().equals(other.warnings, _this.warnings)&&(identical(other.modelVersion, _this.modelVersion) || other.modelVersion == _this.modelVersion)&&(identical(other.requestedAt, _this.requestedAt) || other.requestedAt == _this.requestedAt)&&(identical(other.disclaimer, _this.disclaimer) || other.disclaimer == _this.disclaimer)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Prediction;
  return Object.hash(runtimeType,_this.id,_this.restaurantId,_this.restaurantName,_this.predictedMinutes,_this.interval,_this.dataAvailability,const DeepCollectionEquality().hash(_this.warnings),_this.modelVersion,_this.requestedAt,_this.disclaimer,_this.createdAt);
}

@override
String toString() {
  final _this = this as Prediction;
  return 'Prediction(id: ${_this.id}, restaurantId: ${_this.restaurantId}, restaurantName: ${_this.restaurantName}, predictedMinutes: ${_this.predictedMinutes}, interval: ${_this.interval}, dataAvailability: ${_this.dataAvailability}, warnings: ${_this.warnings}, modelVersion: ${_this.modelVersion}, requestedAt: ${_this.requestedAt}, disclaimer: ${_this.disclaimer}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $PredictionCopyWith<$Res>  {
  factory $PredictionCopyWith(Prediction value, $Res Function(Prediction) _then) = _$PredictionCopyWithImpl;
@useResult
$Res call({
 String id, String? restaurantId, String? restaurantName,@DecimalConverter() Decimal predictedMinutes, PredictionInterval interval, DataAvailability dataAvailability, List<String> warnings, String modelVersion,@AwareDateTimeConverter() DateTime requestedAt, String disclaimer, DateTime createdAt
});


$PredictionIntervalCopyWith<$Res> get interval;

}
/// @nodoc
class _$PredictionCopyWithImpl<$Res>
    implements $PredictionCopyWith<$Res> {
  _$PredictionCopyWithImpl(this._self, this._then);

  final Prediction _self;
  final $Res Function(Prediction) _then;

/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantId = freezed,Object? restaurantName = freezed,Object? predictedMinutes = null,Object? interval = null,Object? dataAvailability = null,Object? warnings = null,Object? modelVersion = null,Object? requestedAt = null,Object? disclaimer = null,Object? createdAt = null,}) {
  return _then(Prediction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: freezed == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String?,restaurantName: freezed == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String?,predictedMinutes: null == predictedMinutes ? _self.predictedMinutes : predictedMinutes // ignore: cast_nullable_to_non_nullable
as Decimal,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as PredictionInterval,dataAvailability: null == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredictionIntervalCopyWith<$Res> get interval {
  
  return $PredictionIntervalCopyWith<$Res>(_self.interval, (value) {
    return _then(_self.copyWith(interval: value));
  });
}
}


/// Adds pattern-matching-related methods to [Prediction].
extension PredictionPatterns on Prediction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Prediction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Prediction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Prediction value)  $default,){
final _that = this;
switch (_that) {
case _Prediction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Prediction value)?  $default,){
final _that = this;
switch (_that) {
case _Prediction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? restaurantId,  String? restaurantName, @DecimalConverter()  Decimal predictedMinutes,  PredictionInterval interval,  DataAvailability dataAvailability,  List<String> warnings,  String modelVersion, @AwareDateTimeConverter()  DateTime requestedAt,  String disclaimer,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Prediction() when $default != null:
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.predictedMinutes,_that.interval,_that.dataAvailability,_that.warnings,_that.modelVersion,_that.requestedAt,_that.disclaimer,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? restaurantId,  String? restaurantName, @DecimalConverter()  Decimal predictedMinutes,  PredictionInterval interval,  DataAvailability dataAvailability,  List<String> warnings,  String modelVersion, @AwareDateTimeConverter()  DateTime requestedAt,  String disclaimer,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Prediction():
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.predictedMinutes,_that.interval,_that.dataAvailability,_that.warnings,_that.modelVersion,_that.requestedAt,_that.disclaimer,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? restaurantId,  String? restaurantName, @DecimalConverter()  Decimal predictedMinutes,  PredictionInterval interval,  DataAvailability dataAvailability,  List<String> warnings,  String modelVersion, @AwareDateTimeConverter()  DateTime requestedAt,  String disclaimer,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Prediction() when $default != null:
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.predictedMinutes,_that.interval,_that.dataAvailability,_that.warnings,_that.modelVersion,_that.requestedAt,_that.disclaimer,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Prediction implements Prediction {
  const _Prediction({required this.id, this.restaurantId, this.restaurantName, @DecimalConverter() required this.predictedMinutes, required this.interval, required this.dataAvailability,  List<String> warnings = const [], required this.modelVersion, @AwareDateTimeConverter() required this.requestedAt, required this.disclaimer, required this.createdAt}): _warnings = warnings;
  factory _Prediction.fromJson(Map<String, dynamic> json) => _$PredictionFromJson(json);

@override final  String id;
@override final  String? restaurantId;
@override final  String? restaurantName;
@override@DecimalConverter() final  Decimal predictedMinutes;
@override final  PredictionInterval interval;
@override final  DataAvailability dataAvailability;
 final  List<String> _warnings;
@override@JsonKey() List<String> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}

@override final  String modelVersion;
@override@AwareDateTimeConverter() final  DateTime requestedAt;
@override final  String disclaimer;
@override final  DateTime createdAt;

/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictionCopyWith<_Prediction> get copyWith => __$PredictionCopyWithImpl<_Prediction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Prediction&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.predictedMinutes, predictedMinutes) || other.predictedMinutes == predictedMinutes)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.dataAvailability, dataAvailability) || other.dataAvailability == dataAvailability)&&const DeepCollectionEquality().equals(other.warnings, _warnings)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.disclaimer, disclaimer) || other.disclaimer == disclaimer)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantId,restaurantName,predictedMinutes,interval,dataAvailability,const DeepCollectionEquality().hash(_warnings),modelVersion,requestedAt,disclaimer,createdAt);
}

@override
String toString() {
    return 'Prediction(id: $id, restaurantId: $restaurantId, restaurantName: $restaurantName, predictedMinutes: $predictedMinutes, interval: $interval, dataAvailability: $dataAvailability, warnings: $warnings, modelVersion: $modelVersion, requestedAt: $requestedAt, disclaimer: $disclaimer, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PredictionCopyWith<$Res> implements $PredictionCopyWith<$Res> {
  factory _$PredictionCopyWith(_Prediction value, $Res Function(_Prediction) _then) = __$PredictionCopyWithImpl;
@override @useResult
$Res call({
 String id, String? restaurantId, String? restaurantName,@DecimalConverter() Decimal predictedMinutes, PredictionInterval interval, DataAvailability dataAvailability, List<String> warnings, String modelVersion,@AwareDateTimeConverter() DateTime requestedAt, String disclaimer, DateTime createdAt
});


@override $PredictionIntervalCopyWith<$Res> get interval;

}
/// @nodoc
class __$PredictionCopyWithImpl<$Res>
    implements _$PredictionCopyWith<$Res> {
  __$PredictionCopyWithImpl(this._self, this._then);

  final _Prediction _self;
  final $Res Function(_Prediction) _then;

/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantId = freezed,Object? restaurantName = freezed,Object? predictedMinutes = null,Object? interval = null,Object? dataAvailability = null,Object? warnings = null,Object? modelVersion = null,Object? requestedAt = null,Object? disclaimer = null,Object? createdAt = null,}) {
  return _then(_Prediction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: freezed == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String?,restaurantName: freezed == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String?,predictedMinutes: null == predictedMinutes ? _self.predictedMinutes : predictedMinutes // ignore: cast_nullable_to_non_nullable
as Decimal,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as PredictionInterval,dataAvailability: null == dataAvailability ? _self.dataAvailability : dataAvailability // ignore: cast_nullable_to_non_nullable
as DataAvailability,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,modelVersion: null == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Prediction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredictionIntervalCopyWith<$Res> get interval {
  
  return $PredictionIntervalCopyWith<$Res>(_self.interval, (value) {
    return _then(_self.copyWith(interval: value));
  });
}
}


/// @nodoc
mixin _$ModelInfo {

 String get name; String get version; String get dataset; String get domain; DateTime? get trainedAt; Map<String, dynamic> get testMetrics; Map<String, dynamic>? get baselineTestMetrics; Map<String, dynamic> get interval; List<String> get limitations; String get acknowledgement;
/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelInfoCopyWith<ModelInfo> get copyWith => _$ModelInfoCopyWithImpl<ModelInfo>(this as ModelInfo, _$identity);

  /// Serializes this ModelInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModelInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelInfo&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.dataset, _this.dataset) || other.dataset == _this.dataset)&&(identical(other.domain, _this.domain) || other.domain == _this.domain)&&(identical(other.trainedAt, _this.trainedAt) || other.trainedAt == _this.trainedAt)&&const DeepCollectionEquality().equals(other.testMetrics, _this.testMetrics)&&const DeepCollectionEquality().equals(other.baselineTestMetrics, _this.baselineTestMetrics)&&const DeepCollectionEquality().equals(other.interval, _this.interval)&&const DeepCollectionEquality().equals(other.limitations, _this.limitations)&&(identical(other.acknowledgement, _this.acknowledgement) || other.acknowledgement == _this.acknowledgement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModelInfo;
  return Object.hash(runtimeType,_this.name,_this.version,_this.dataset,_this.domain,_this.trainedAt,const DeepCollectionEquality().hash(_this.testMetrics),const DeepCollectionEquality().hash(_this.baselineTestMetrics),const DeepCollectionEquality().hash(_this.interval),const DeepCollectionEquality().hash(_this.limitations),_this.acknowledgement);
}

@override
String toString() {
  final _this = this as ModelInfo;
  return 'ModelInfo(name: ${_this.name}, version: ${_this.version}, dataset: ${_this.dataset}, domain: ${_this.domain}, trainedAt: ${_this.trainedAt}, testMetrics: ${_this.testMetrics}, baselineTestMetrics: ${_this.baselineTestMetrics}, interval: ${_this.interval}, limitations: ${_this.limitations}, acknowledgement: ${_this.acknowledgement})';
}


}

/// @nodoc
abstract mixin class $ModelInfoCopyWith<$Res>  {
  factory $ModelInfoCopyWith(ModelInfo value, $Res Function(ModelInfo) _then) = _$ModelInfoCopyWithImpl;
@useResult
$Res call({
 String name, String version, String dataset, String domain, DateTime? trainedAt, Map<String, dynamic> testMetrics, Map<String, dynamic>? baselineTestMetrics, Map<String, dynamic> interval, List<String> limitations, String acknowledgement
});




}
/// @nodoc
class _$ModelInfoCopyWithImpl<$Res>
    implements $ModelInfoCopyWith<$Res> {
  _$ModelInfoCopyWithImpl(this._self, this._then);

  final ModelInfo _self;
  final $Res Function(ModelInfo) _then;

/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? version = null,Object? dataset = null,Object? domain = null,Object? trainedAt = freezed,Object? testMetrics = null,Object? baselineTestMetrics = freezed,Object? interval = null,Object? limitations = null,Object? acknowledgement = null,}) {
  return _then(ModelInfo(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,dataset: null == dataset ? _self.dataset : dataset // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,trainedAt: freezed == trainedAt ? _self.trainedAt : trainedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,testMetrics: null == testMetrics ? _self.testMetrics : testMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,baselineTestMetrics: freezed == baselineTestMetrics ? _self.baselineTestMetrics : baselineTestMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,limitations: null == limitations ? _self.limitations : limitations // ignore: cast_nullable_to_non_nullable
as List<String>,acknowledgement: null == acknowledgement ? _self.acknowledgement : acknowledgement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelInfo].
extension ModelInfoPatterns on ModelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelInfo value)  $default,){
final _that = this;
switch (_that) {
case _ModelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ModelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String version,  String dataset,  String domain,  DateTime? trainedAt,  Map<String, dynamic> testMetrics,  Map<String, dynamic>? baselineTestMetrics,  Map<String, dynamic> interval,  List<String> limitations,  String acknowledgement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelInfo() when $default != null:
return $default(_that.name,_that.version,_that.dataset,_that.domain,_that.trainedAt,_that.testMetrics,_that.baselineTestMetrics,_that.interval,_that.limitations,_that.acknowledgement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String version,  String dataset,  String domain,  DateTime? trainedAt,  Map<String, dynamic> testMetrics,  Map<String, dynamic>? baselineTestMetrics,  Map<String, dynamic> interval,  List<String> limitations,  String acknowledgement)  $default,) {final _that = this;
switch (_that) {
case _ModelInfo():
return $default(_that.name,_that.version,_that.dataset,_that.domain,_that.trainedAt,_that.testMetrics,_that.baselineTestMetrics,_that.interval,_that.limitations,_that.acknowledgement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String version,  String dataset,  String domain,  DateTime? trainedAt,  Map<String, dynamic> testMetrics,  Map<String, dynamic>? baselineTestMetrics,  Map<String, dynamic> interval,  List<String> limitations,  String acknowledgement)?  $default,) {final _that = this;
switch (_that) {
case _ModelInfo() when $default != null:
return $default(_that.name,_that.version,_that.dataset,_that.domain,_that.trainedAt,_that.testMetrics,_that.baselineTestMetrics,_that.interval,_that.limitations,_that.acknowledgement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelInfo extends ModelInfo {
  const _ModelInfo({required this.name, required this.version, required this.dataset, required this.domain, this.trainedAt,  Map<String, dynamic> testMetrics = const {},  Map<String, dynamic>? baselineTestMetrics,  Map<String, dynamic> interval = const {},  List<String> limitations = const [], required this.acknowledgement}): _testMetrics = testMetrics,_baselineTestMetrics = baselineTestMetrics,_interval = interval,_limitations = limitations,super._();
  factory _ModelInfo.fromJson(Map<String, dynamic> json) => _$ModelInfoFromJson(json);

@override final  String name;
@override final  String version;
@override final  String dataset;
@override final  String domain;
@override final  DateTime? trainedAt;
 final  Map<String, dynamic> _testMetrics;
@override@JsonKey() Map<String, dynamic> get testMetrics {
  if (_testMetrics is EqualUnmodifiableMapView) return _testMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_testMetrics);
}

 final  Map<String, dynamic>? _baselineTestMetrics;
@override Map<String, dynamic>? get baselineTestMetrics {
  final value = _baselineTestMetrics;
  if (value == null) return null;
  if (_baselineTestMetrics is EqualUnmodifiableMapView) return _baselineTestMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic> _interval;
@override@JsonKey() Map<String, dynamic> get interval {
  if (_interval is EqualUnmodifiableMapView) return _interval;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_interval);
}

 final  List<String> _limitations;
@override@JsonKey() List<String> get limitations {
  if (_limitations is EqualUnmodifiableListView) return _limitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_limitations);
}

@override final  String acknowledgement;

/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelInfoCopyWith<_ModelInfo> get copyWith => __$ModelInfoCopyWithImpl<_ModelInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelInfo&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.dataset, dataset) || other.dataset == dataset)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.trainedAt, trainedAt) || other.trainedAt == trainedAt)&&const DeepCollectionEquality().equals(other.testMetrics, _testMetrics)&&const DeepCollectionEquality().equals(other.baselineTestMetrics, _baselineTestMetrics)&&const DeepCollectionEquality().equals(other.interval, _interval)&&const DeepCollectionEquality().equals(other.limitations, _limitations)&&(identical(other.acknowledgement, acknowledgement) || other.acknowledgement == acknowledgement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,version,dataset,domain,trainedAt,const DeepCollectionEquality().hash(_testMetrics),const DeepCollectionEquality().hash(_baselineTestMetrics),const DeepCollectionEquality().hash(_interval),const DeepCollectionEquality().hash(_limitations),acknowledgement);
}

@override
String toString() {
    return 'ModelInfo(name: $name, version: $version, dataset: $dataset, domain: $domain, trainedAt: $trainedAt, testMetrics: $testMetrics, baselineTestMetrics: $baselineTestMetrics, interval: $interval, limitations: $limitations, acknowledgement: $acknowledgement)';
}


}

/// @nodoc
abstract mixin class _$ModelInfoCopyWith<$Res> implements $ModelInfoCopyWith<$Res> {
  factory _$ModelInfoCopyWith(_ModelInfo value, $Res Function(_ModelInfo) _then) = __$ModelInfoCopyWithImpl;
@override @useResult
$Res call({
 String name, String version, String dataset, String domain, DateTime? trainedAt, Map<String, dynamic> testMetrics, Map<String, dynamic>? baselineTestMetrics, Map<String, dynamic> interval, List<String> limitations, String acknowledgement
});




}
/// @nodoc
class __$ModelInfoCopyWithImpl<$Res>
    implements _$ModelInfoCopyWith<$Res> {
  __$ModelInfoCopyWithImpl(this._self, this._then);

  final _ModelInfo _self;
  final $Res Function(_ModelInfo) _then;

/// Create a copy of ModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? version = null,Object? dataset = null,Object? domain = null,Object? trainedAt = freezed,Object? testMetrics = null,Object? baselineTestMetrics = freezed,Object? interval = null,Object? limitations = null,Object? acknowledgement = null,}) {
  return _then(_ModelInfo(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,dataset: null == dataset ? _self.dataset : dataset // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,trainedAt: freezed == trainedAt ? _self.trainedAt : trainedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,testMetrics: null == testMetrics ? _self._testMetrics : testMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,baselineTestMetrics: freezed == baselineTestMetrics ? _self._baselineTestMetrics : baselineTestMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,interval: null == interval ? _self._interval : interval // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,limitations: null == limitations ? _self._limitations : limitations // ignore: cast_nullable_to_non_nullable
as List<String>,acknowledgement: null == acknowledgement ? _self.acknowledgement : acknowledgement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PickupLog {

 String get id; String get restaurantId; String get restaurantName;@AwareDateTimeConverter() DateTime get arrivedAt;@AwareDateTimeConverter() DateTime get pickedUpAt;@DecimalConverter() Decimal get waitMinutes; String? get notes; DateTime get createdAt;
/// Create a copy of PickupLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickupLogCopyWith<PickupLog> get copyWith => _$PickupLogCopyWithImpl<PickupLog>(this as PickupLog, _$identity);

  /// Serializes this PickupLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PickupLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickupLog&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.arrivedAt, _this.arrivedAt) || other.arrivedAt == _this.arrivedAt)&&(identical(other.pickedUpAt, _this.pickedUpAt) || other.pickedUpAt == _this.pickedUpAt)&&(identical(other.waitMinutes, _this.waitMinutes) || other.waitMinutes == _this.waitMinutes)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PickupLog;
  return Object.hash(runtimeType,_this.id,_this.restaurantId,_this.restaurantName,_this.arrivedAt,_this.pickedUpAt,_this.waitMinutes,_this.notes,_this.createdAt);
}

@override
String toString() {
  final _this = this as PickupLog;
  return 'PickupLog(id: ${_this.id}, restaurantId: ${_this.restaurantId}, restaurantName: ${_this.restaurantName}, arrivedAt: ${_this.arrivedAt}, pickedUpAt: ${_this.pickedUpAt}, waitMinutes: ${_this.waitMinutes}, notes: ${_this.notes}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $PickupLogCopyWith<$Res>  {
  factory $PickupLogCopyWith(PickupLog value, $Res Function(PickupLog) _then) = _$PickupLogCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantId, String restaurantName,@AwareDateTimeConverter() DateTime arrivedAt,@AwareDateTimeConverter() DateTime pickedUpAt,@DecimalConverter() Decimal waitMinutes, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$PickupLogCopyWithImpl<$Res>
    implements $PickupLogCopyWith<$Res> {
  _$PickupLogCopyWithImpl(this._self, this._then);

  final PickupLog _self;
  final $Res Function(PickupLog) _then;

/// Create a copy of PickupLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantId = null,Object? restaurantName = null,Object? arrivedAt = null,Object? pickedUpAt = null,Object? waitMinutes = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(PickupLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,arrivedAt: null == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: null == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime,waitMinutes: null == waitMinutes ? _self.waitMinutes : waitMinutes // ignore: cast_nullable_to_non_nullable
as Decimal,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PickupLog].
extension PickupLogPatterns on PickupLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PickupLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PickupLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PickupLog value)  $default,){
final _that = this;
switch (_that) {
case _PickupLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PickupLog value)?  $default,){
final _that = this;
switch (_that) {
case _PickupLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String restaurantName, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt, @DecimalConverter()  Decimal waitMinutes,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PickupLog() when $default != null:
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.arrivedAt,_that.pickedUpAt,_that.waitMinutes,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String restaurantName, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt, @DecimalConverter()  Decimal waitMinutes,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PickupLog():
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.arrivedAt,_that.pickedUpAt,_that.waitMinutes,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantId,  String restaurantName, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt, @DecimalConverter()  Decimal waitMinutes,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PickupLog() when $default != null:
return $default(_that.id,_that.restaurantId,_that.restaurantName,_that.arrivedAt,_that.pickedUpAt,_that.waitMinutes,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PickupLog implements PickupLog {
  const _PickupLog({required this.id, required this.restaurantId, required this.restaurantName, @AwareDateTimeConverter() required this.arrivedAt, @AwareDateTimeConverter() required this.pickedUpAt, @DecimalConverter() required this.waitMinutes, this.notes, required this.createdAt});
  factory _PickupLog.fromJson(Map<String, dynamic> json) => _$PickupLogFromJson(json);

@override final  String id;
@override final  String restaurantId;
@override final  String restaurantName;
@override@AwareDateTimeConverter() final  DateTime arrivedAt;
@override@AwareDateTimeConverter() final  DateTime pickedUpAt;
@override@DecimalConverter() final  Decimal waitMinutes;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of PickupLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PickupLogCopyWith<_PickupLog> get copyWith => __$PickupLogCopyWithImpl<_PickupLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PickupLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PickupLog&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.waitMinutes, waitMinutes) || other.waitMinutes == waitMinutes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantId,restaurantName,arrivedAt,pickedUpAt,waitMinutes,notes,createdAt);
}

@override
String toString() {
    return 'PickupLog(id: $id, restaurantId: $restaurantId, restaurantName: $restaurantName, arrivedAt: $arrivedAt, pickedUpAt: $pickedUpAt, waitMinutes: $waitMinutes, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PickupLogCopyWith<$Res> implements $PickupLogCopyWith<$Res> {
  factory _$PickupLogCopyWith(_PickupLog value, $Res Function(_PickupLog) _then) = __$PickupLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantId, String restaurantName,@AwareDateTimeConverter() DateTime arrivedAt,@AwareDateTimeConverter() DateTime pickedUpAt,@DecimalConverter() Decimal waitMinutes, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$PickupLogCopyWithImpl<$Res>
    implements _$PickupLogCopyWith<$Res> {
  __$PickupLogCopyWithImpl(this._self, this._then);

  final _PickupLog _self;
  final $Res Function(_PickupLog) _then;

/// Create a copy of PickupLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantId = null,Object? restaurantName = null,Object? arrivedAt = null,Object? pickedUpAt = null,Object? waitMinutes = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_PickupLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,arrivedAt: null == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: null == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime,waitMinutes: null == waitMinutes ? _self.waitMinutes : waitMinutes // ignore: cast_nullable_to_non_nullable
as Decimal,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$PickupLogInput {

 String get restaurantId;@AwareDateTimeConverter() DateTime get arrivedAt;@AwareDateTimeConverter() DateTime get pickedUpAt; String? get notes;
/// Create a copy of PickupLogInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickupLogInputCopyWith<PickupLogInput> get copyWith => _$PickupLogInputCopyWithImpl<PickupLogInput>(this as PickupLogInput, _$identity);

  /// Serializes this PickupLogInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PickupLogInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickupLogInput&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.arrivedAt, _this.arrivedAt) || other.arrivedAt == _this.arrivedAt)&&(identical(other.pickedUpAt, _this.pickedUpAt) || other.pickedUpAt == _this.pickedUpAt)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PickupLogInput;
  return Object.hash(runtimeType,_this.restaurantId,_this.arrivedAt,_this.pickedUpAt,_this.notes);
}

@override
String toString() {
  final _this = this as PickupLogInput;
  return 'PickupLogInput(restaurantId: ${_this.restaurantId}, arrivedAt: ${_this.arrivedAt}, pickedUpAt: ${_this.pickedUpAt}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $PickupLogInputCopyWith<$Res>  {
  factory $PickupLogInputCopyWith(PickupLogInput value, $Res Function(PickupLogInput) _then) = _$PickupLogInputCopyWithImpl;
@useResult
$Res call({
 String restaurantId,@AwareDateTimeConverter() DateTime arrivedAt,@AwareDateTimeConverter() DateTime pickedUpAt, String? notes
});




}
/// @nodoc
class _$PickupLogInputCopyWithImpl<$Res>
    implements $PickupLogInputCopyWith<$Res> {
  _$PickupLogInputCopyWithImpl(this._self, this._then);

  final PickupLogInput _self;
  final $Res Function(PickupLogInput) _then;

/// Create a copy of PickupLogInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurantId = null,Object? arrivedAt = null,Object? pickedUpAt = null,Object? notes = freezed,}) {
  return _then(PickupLogInput(
restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,arrivedAt: null == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: null == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PickupLogInput].
extension PickupLogInputPatterns on PickupLogInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PickupLogInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PickupLogInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PickupLogInput value)  $default,){
final _that = this;
switch (_that) {
case _PickupLogInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PickupLogInput value)?  $default,){
final _that = this;
switch (_that) {
case _PickupLogInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String restaurantId, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PickupLogInput() when $default != null:
return $default(_that.restaurantId,_that.arrivedAt,_that.pickedUpAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String restaurantId, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _PickupLogInput():
return $default(_that.restaurantId,_that.arrivedAt,_that.pickedUpAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String restaurantId, @AwareDateTimeConverter()  DateTime arrivedAt, @AwareDateTimeConverter()  DateTime pickedUpAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _PickupLogInput() when $default != null:
return $default(_that.restaurantId,_that.arrivedAt,_that.pickedUpAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createFactory: false)

class _PickupLogInput implements PickupLogInput {
  const _PickupLogInput({required this.restaurantId, @AwareDateTimeConverter() required this.arrivedAt, @AwareDateTimeConverter() required this.pickedUpAt, this.notes});
  

@override final  String restaurantId;
@override@AwareDateTimeConverter() final  DateTime arrivedAt;
@override@AwareDateTimeConverter() final  DateTime pickedUpAt;
@override final  String? notes;

/// Create a copy of PickupLogInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PickupLogInputCopyWith<_PickupLogInput> get copyWith => __$PickupLogInputCopyWithImpl<_PickupLogInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PickupLogInputToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PickupLogInput&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,restaurantId,arrivedAt,pickedUpAt,notes);
}

@override
String toString() {
    return 'PickupLogInput(restaurantId: $restaurantId, arrivedAt: $arrivedAt, pickedUpAt: $pickedUpAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$PickupLogInputCopyWith<$Res> implements $PickupLogInputCopyWith<$Res> {
  factory _$PickupLogInputCopyWith(_PickupLogInput value, $Res Function(_PickupLogInput) _then) = __$PickupLogInputCopyWithImpl;
@override @useResult
$Res call({
 String restaurantId,@AwareDateTimeConverter() DateTime arrivedAt,@AwareDateTimeConverter() DateTime pickedUpAt, String? notes
});




}
/// @nodoc
class __$PickupLogInputCopyWithImpl<$Res>
    implements _$PickupLogInputCopyWith<$Res> {
  __$PickupLogInputCopyWithImpl(this._self, this._then);

  final _PickupLogInput _self;
  final $Res Function(_PickupLogInput) _then;

/// Create a copy of PickupLogInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurantId = null,Object? arrivedAt = null,Object? pickedUpAt = null,Object? notes = freezed,}) {
  return _then(_PickupLogInput(
restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,arrivedAt: null == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: null == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
