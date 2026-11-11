// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'road_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoadPoint {

 double get lat; double get lng;
/// Create a copy of RoadPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoadPointCopyWith<RoadPoint> get copyWith => _$RoadPointCopyWithImpl<RoadPoint>(this as RoadPoint, _$identity);

  /// Serializes this RoadPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoadPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoadPoint&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoadPoint;
  return Object.hash(runtimeType,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as RoadPoint;
  return 'RoadPoint(lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $RoadPointCopyWith<$Res>  {
  factory $RoadPointCopyWith(RoadPoint value, $Res Function(RoadPoint) _then) = _$RoadPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$RoadPointCopyWithImpl<$Res>
    implements $RoadPointCopyWith<$Res> {
  _$RoadPointCopyWithImpl(this._self, this._then);

  final RoadPoint _self;
  final $Res Function(RoadPoint) _then;

/// Create a copy of RoadPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(RoadPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RoadPoint].
extension RoadPointPatterns on RoadPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoadPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoadPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoadPoint value)  $default,){
final _that = this;
switch (_that) {
case _RoadPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoadPoint value)?  $default,){
final _that = this;
switch (_that) {
case _RoadPoint() when $default != null:
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
case _RoadPoint() when $default != null:
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
case _RoadPoint():
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
case _RoadPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoadPoint implements RoadPoint {
  const _RoadPoint({required this.lat, required this.lng});
  factory _RoadPoint.fromJson(Map<String, dynamic> json) => _$RoadPointFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of RoadPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoadPointCopyWith<_RoadPoint> get copyWith => __$RoadPointCopyWithImpl<_RoadPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoadPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoadPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng);
}

@override
String toString() {
    return 'RoadPoint(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$RoadPointCopyWith<$Res> implements $RoadPointCopyWith<$Res> {
  factory _$RoadPointCopyWith(_RoadPoint value, $Res Function(_RoadPoint) _then) = __$RoadPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$RoadPointCopyWithImpl<$Res>
    implements _$RoadPointCopyWith<$Res> {
  __$RoadPointCopyWithImpl(this._self, this._then);

  final _RoadPoint _self;
  final $Res Function(_RoadPoint) _then;

/// Create a copy of RoadPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_RoadPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Incident {

 String get id; RoadCategory get category;/// Effective status: an open incident past [expiresAt] reads `expired`.
 IncidentStatus get status; RoadPoint get location; DateTime get firstReportedAt; DateTime get lastReportedAt; int get reportCount;/// Riders who reported it or said it is still there.
 int get distinctReporters;/// Riders who said it is gone since the last report.
 int get clearedCount; DateTime get expiresAt;/// Only in `/nearby` results.
 double? get distanceM;
/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentCopyWith<Incident> get copyWith => _$IncidentCopyWithImpl<Incident>(this as Incident, _$identity);

  /// Serializes this Incident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Incident;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Incident&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.firstReportedAt, _this.firstReportedAt) || other.firstReportedAt == _this.firstReportedAt)&&(identical(other.lastReportedAt, _this.lastReportedAt) || other.lastReportedAt == _this.lastReportedAt)&&(identical(other.reportCount, _this.reportCount) || other.reportCount == _this.reportCount)&&(identical(other.distinctReporters, _this.distinctReporters) || other.distinctReporters == _this.distinctReporters)&&(identical(other.clearedCount, _this.clearedCount) || other.clearedCount == _this.clearedCount)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.distanceM, _this.distanceM) || other.distanceM == _this.distanceM));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Incident;
  return Object.hash(runtimeType,_this.id,_this.category,_this.status,_this.location,_this.firstReportedAt,_this.lastReportedAt,_this.reportCount,_this.distinctReporters,_this.clearedCount,_this.expiresAt,_this.distanceM);
}

@override
String toString() {
  final _this = this as Incident;
  return 'Incident(id: ${_this.id}, category: ${_this.category}, status: ${_this.status}, location: ${_this.location}, firstReportedAt: ${_this.firstReportedAt}, lastReportedAt: ${_this.lastReportedAt}, reportCount: ${_this.reportCount}, distinctReporters: ${_this.distinctReporters}, clearedCount: ${_this.clearedCount}, expiresAt: ${_this.expiresAt}, distanceM: ${_this.distanceM})';
}


}

/// @nodoc
abstract mixin class $IncidentCopyWith<$Res>  {
  factory $IncidentCopyWith(Incident value, $Res Function(Incident) _then) = _$IncidentCopyWithImpl;
@useResult
$Res call({
 String id, RoadCategory category, IncidentStatus status, RoadPoint location, DateTime firstReportedAt, DateTime lastReportedAt, int reportCount, int distinctReporters, int clearedCount, DateTime expiresAt, double? distanceM
});


$RoadPointCopyWith<$Res> get location;

}
/// @nodoc
class _$IncidentCopyWithImpl<$Res>
    implements $IncidentCopyWith<$Res> {
  _$IncidentCopyWithImpl(this._self, this._then);

  final Incident _self;
  final $Res Function(Incident) _then;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? status = null,Object? location = null,Object? firstReportedAt = null,Object? lastReportedAt = null,Object? reportCount = null,Object? distinctReporters = null,Object? clearedCount = null,Object? expiresAt = null,Object? distanceM = freezed,}) {
  return _then(Incident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RoadCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IncidentStatus,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as RoadPoint,firstReportedAt: null == firstReportedAt ? _self.firstReportedAt : firstReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastReportedAt: null == lastReportedAt ? _self.lastReportedAt : lastReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,distinctReporters: null == distinctReporters ? _self.distinctReporters : distinctReporters // ignore: cast_nullable_to_non_nullable
as int,clearedCount: null == clearedCount ? _self.clearedCount : clearedCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadPointCopyWith<$Res> get location {
  
  return $RoadPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [Incident].
extension IncidentPatterns on Incident {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Incident value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Incident() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Incident value)  $default,){
final _that = this;
switch (_that) {
case _Incident():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Incident value)?  $default,){
final _that = this;
switch (_that) {
case _Incident() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  RoadCategory category,  IncidentStatus status,  RoadPoint location,  DateTime firstReportedAt,  DateTime lastReportedAt,  int reportCount,  int distinctReporters,  int clearedCount,  DateTime expiresAt,  double? distanceM)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that.id,_that.category,_that.status,_that.location,_that.firstReportedAt,_that.lastReportedAt,_that.reportCount,_that.distinctReporters,_that.clearedCount,_that.expiresAt,_that.distanceM);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  RoadCategory category,  IncidentStatus status,  RoadPoint location,  DateTime firstReportedAt,  DateTime lastReportedAt,  int reportCount,  int distinctReporters,  int clearedCount,  DateTime expiresAt,  double? distanceM)  $default,) {final _that = this;
switch (_that) {
case _Incident():
return $default(_that.id,_that.category,_that.status,_that.location,_that.firstReportedAt,_that.lastReportedAt,_that.reportCount,_that.distinctReporters,_that.clearedCount,_that.expiresAt,_that.distanceM);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  RoadCategory category,  IncidentStatus status,  RoadPoint location,  DateTime firstReportedAt,  DateTime lastReportedAt,  int reportCount,  int distinctReporters,  int clearedCount,  DateTime expiresAt,  double? distanceM)?  $default,) {final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that.id,_that.category,_that.status,_that.location,_that.firstReportedAt,_that.lastReportedAt,_that.reportCount,_that.distinctReporters,_that.clearedCount,_that.expiresAt,_that.distanceM);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Incident implements Incident {
  const _Incident({required this.id, required this.category, required this.status, required this.location, required this.firstReportedAt, required this.lastReportedAt, required this.reportCount, required this.distinctReporters, required this.clearedCount, required this.expiresAt, this.distanceM});
  factory _Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);

@override final  String id;
@override final  RoadCategory category;
/// Effective status: an open incident past [expiresAt] reads `expired`.
@override final  IncidentStatus status;
@override final  RoadPoint location;
@override final  DateTime firstReportedAt;
@override final  DateTime lastReportedAt;
@override final  int reportCount;
/// Riders who reported it or said it is still there.
@override final  int distinctReporters;
/// Riders who said it is gone since the last report.
@override final  int clearedCount;
@override final  DateTime expiresAt;
/// Only in `/nearby` results.
@override final  double? distanceM;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentCopyWith<_Incident> get copyWith => __$IncidentCopyWithImpl<_Incident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncidentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Incident&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.location, location) || other.location == location)&&(identical(other.firstReportedAt, firstReportedAt) || other.firstReportedAt == firstReportedAt)&&(identical(other.lastReportedAt, lastReportedAt) || other.lastReportedAt == lastReportedAt)&&(identical(other.reportCount, reportCount) || other.reportCount == reportCount)&&(identical(other.distinctReporters, distinctReporters) || other.distinctReporters == distinctReporters)&&(identical(other.clearedCount, clearedCount) || other.clearedCount == clearedCount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,category,status,location,firstReportedAt,lastReportedAt,reportCount,distinctReporters,clearedCount,expiresAt,distanceM);
}

@override
String toString() {
    return 'Incident(id: $id, category: $category, status: $status, location: $location, firstReportedAt: $firstReportedAt, lastReportedAt: $lastReportedAt, reportCount: $reportCount, distinctReporters: $distinctReporters, clearedCount: $clearedCount, expiresAt: $expiresAt, distanceM: $distanceM)';
}


}

/// @nodoc
abstract mixin class _$IncidentCopyWith<$Res> implements $IncidentCopyWith<$Res> {
  factory _$IncidentCopyWith(_Incident value, $Res Function(_Incident) _then) = __$IncidentCopyWithImpl;
@override @useResult
$Res call({
 String id, RoadCategory category, IncidentStatus status, RoadPoint location, DateTime firstReportedAt, DateTime lastReportedAt, int reportCount, int distinctReporters, int clearedCount, DateTime expiresAt, double? distanceM
});


@override $RoadPointCopyWith<$Res> get location;

}
/// @nodoc
class __$IncidentCopyWithImpl<$Res>
    implements _$IncidentCopyWith<$Res> {
  __$IncidentCopyWithImpl(this._self, this._then);

  final _Incident _self;
  final $Res Function(_Incident) _then;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? status = null,Object? location = null,Object? firstReportedAt = null,Object? lastReportedAt = null,Object? reportCount = null,Object? distinctReporters = null,Object? clearedCount = null,Object? expiresAt = null,Object? distanceM = freezed,}) {
  return _then(_Incident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RoadCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IncidentStatus,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as RoadPoint,firstReportedAt: null == firstReportedAt ? _self.firstReportedAt : firstReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastReportedAt: null == lastReportedAt ? _self.lastReportedAt : lastReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reportCount: null == reportCount ? _self.reportCount : reportCount // ignore: cast_nullable_to_non_nullable
as int,distinctReporters: null == distinctReporters ? _self.distinctReporters : distinctReporters // ignore: cast_nullable_to_non_nullable
as int,clearedCount: null == clearedCount ? _self.clearedCount : clearedCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadPointCopyWith<$Res> get location {
  
  return $RoadPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$IncidentList {

 List<Incident> get items;/// More incidents matched than the server returns: zoom in or move closer.
 bool get truncated;
/// Create a copy of IncidentList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentListCopyWith<IncidentList> get copyWith => _$IncidentListCopyWithImpl<IncidentList>(this as IncidentList, _$identity);

  /// Serializes this IncidentList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IncidentList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncidentList&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IncidentList;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.truncated);
}

@override
String toString() {
  final _this = this as IncidentList;
  return 'IncidentList(items: ${_this.items}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class $IncidentListCopyWith<$Res>  {
  factory $IncidentListCopyWith(IncidentList value, $Res Function(IncidentList) _then) = _$IncidentListCopyWithImpl;
@useResult
$Res call({
 List<Incident> items, bool truncated
});




}
/// @nodoc
class _$IncidentListCopyWithImpl<$Res>
    implements $IncidentListCopyWith<$Res> {
  _$IncidentListCopyWithImpl(this._self, this._then);

  final IncidentList _self;
  final $Res Function(IncidentList) _then;

/// Create a copy of IncidentList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? truncated = null,}) {
  return _then(IncidentList(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Incident>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IncidentList].
extension IncidentListPatterns on IncidentList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncidentList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncidentList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncidentList value)  $default,){
final _that = this;
switch (_that) {
case _IncidentList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncidentList value)?  $default,){
final _that = this;
switch (_that) {
case _IncidentList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Incident> items,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncidentList() when $default != null:
return $default(_that.items,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Incident> items,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case _IncidentList():
return $default(_that.items,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Incident> items,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case _IncidentList() when $default != null:
return $default(_that.items,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncidentList implements IncidentList {
  const _IncidentList({required  List<Incident> items, this.truncated = false}): _items = items;
  factory _IncidentList.fromJson(Map<String, dynamic> json) => _$IncidentListFromJson(json);

 final  List<Incident> _items;
@override List<Incident> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// More incidents matched than the server returns: zoom in or move closer.
@override@JsonKey() final  bool truncated;

/// Create a copy of IncidentList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentListCopyWith<_IncidentList> get copyWith => __$IncidentListCopyWithImpl<_IncidentList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncidentListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncidentList&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),truncated);
}

@override
String toString() {
    return 'IncidentList(items: $items, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$IncidentListCopyWith<$Res> implements $IncidentListCopyWith<$Res> {
  factory _$IncidentListCopyWith(_IncidentList value, $Res Function(_IncidentList) _then) = __$IncidentListCopyWithImpl;
@override @useResult
$Res call({
 List<Incident> items, bool truncated
});




}
/// @nodoc
class __$IncidentListCopyWithImpl<$Res>
    implements _$IncidentListCopyWith<$Res> {
  __$IncidentListCopyWithImpl(this._self, this._then);

  final _IncidentList _self;
  final $Res Function(_IncidentList) _then;

/// Create a copy of IncidentList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? truncated = null,}) {
  return _then(_IncidentList(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Incident>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OwnReport {

 String get id; String get incidentId; RoadCategory get category; String? get description; RoadPoint get location; bool get hasImage; AiStatus get aiStatus;/// Category suggested from the photo; a suggestion only.
 String? get aiLabel;@NullableDecimalConverter() Decimal? get aiConfidence; DateTime get createdAt; IncidentStatus get incidentStatus;
/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnReportCopyWith<OwnReport> get copyWith => _$OwnReportCopyWithImpl<OwnReport>(this as OwnReport, _$identity);

  /// Serializes this OwnReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OwnReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnReport&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.incidentId, _this.incidentId) || other.incidentId == _this.incidentId)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.hasImage, _this.hasImage) || other.hasImage == _this.hasImage)&&(identical(other.aiStatus, _this.aiStatus) || other.aiStatus == _this.aiStatus)&&(identical(other.aiLabel, _this.aiLabel) || other.aiLabel == _this.aiLabel)&&(identical(other.aiConfidence, _this.aiConfidence) || other.aiConfidence == _this.aiConfidence)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.incidentStatus, _this.incidentStatus) || other.incidentStatus == _this.incidentStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OwnReport;
  return Object.hash(runtimeType,_this.id,_this.incidentId,_this.category,_this.description,_this.location,_this.hasImage,_this.aiStatus,_this.aiLabel,_this.aiConfidence,_this.createdAt,_this.incidentStatus);
}

@override
String toString() {
  final _this = this as OwnReport;
  return 'OwnReport(id: ${_this.id}, incidentId: ${_this.incidentId}, category: ${_this.category}, description: ${_this.description}, location: ${_this.location}, hasImage: ${_this.hasImage}, aiStatus: ${_this.aiStatus}, aiLabel: ${_this.aiLabel}, aiConfidence: ${_this.aiConfidence}, createdAt: ${_this.createdAt}, incidentStatus: ${_this.incidentStatus})';
}


}

/// @nodoc
abstract mixin class $OwnReportCopyWith<$Res>  {
  factory $OwnReportCopyWith(OwnReport value, $Res Function(OwnReport) _then) = _$OwnReportCopyWithImpl;
@useResult
$Res call({
 String id, String incidentId, RoadCategory category, String? description, RoadPoint location, bool hasImage, AiStatus aiStatus, String? aiLabel,@NullableDecimalConverter() Decimal? aiConfidence, DateTime createdAt, IncidentStatus incidentStatus
});


$RoadPointCopyWith<$Res> get location;

}
/// @nodoc
class _$OwnReportCopyWithImpl<$Res>
    implements $OwnReportCopyWith<$Res> {
  _$OwnReportCopyWithImpl(this._self, this._then);

  final OwnReport _self;
  final $Res Function(OwnReport) _then;

/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? incidentId = null,Object? category = null,Object? description = freezed,Object? location = null,Object? hasImage = null,Object? aiStatus = null,Object? aiLabel = freezed,Object? aiConfidence = freezed,Object? createdAt = null,Object? incidentStatus = null,}) {
  return _then(OwnReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,incidentId: null == incidentId ? _self.incidentId : incidentId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RoadCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as RoadPoint,hasImage: null == hasImage ? _self.hasImage : hasImage // ignore: cast_nullable_to_non_nullable
as bool,aiStatus: null == aiStatus ? _self.aiStatus : aiStatus // ignore: cast_nullable_to_non_nullable
as AiStatus,aiLabel: freezed == aiLabel ? _self.aiLabel : aiLabel // ignore: cast_nullable_to_non_nullable
as String?,aiConfidence: freezed == aiConfidence ? _self.aiConfidence : aiConfidence // ignore: cast_nullable_to_non_nullable
as Decimal?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,incidentStatus: null == incidentStatus ? _self.incidentStatus : incidentStatus // ignore: cast_nullable_to_non_nullable
as IncidentStatus,
  ));
}
/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadPointCopyWith<$Res> get location {
  
  return $RoadPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [OwnReport].
extension OwnReportPatterns on OwnReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnReport value)  $default,){
final _that = this;
switch (_that) {
case _OwnReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnReport value)?  $default,){
final _that = this;
switch (_that) {
case _OwnReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String incidentId,  RoadCategory category,  String? description,  RoadPoint location,  bool hasImage,  AiStatus aiStatus,  String? aiLabel, @NullableDecimalConverter()  Decimal? aiConfidence,  DateTime createdAt,  IncidentStatus incidentStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnReport() when $default != null:
return $default(_that.id,_that.incidentId,_that.category,_that.description,_that.location,_that.hasImage,_that.aiStatus,_that.aiLabel,_that.aiConfidence,_that.createdAt,_that.incidentStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String incidentId,  RoadCategory category,  String? description,  RoadPoint location,  bool hasImage,  AiStatus aiStatus,  String? aiLabel, @NullableDecimalConverter()  Decimal? aiConfidence,  DateTime createdAt,  IncidentStatus incidentStatus)  $default,) {final _that = this;
switch (_that) {
case _OwnReport():
return $default(_that.id,_that.incidentId,_that.category,_that.description,_that.location,_that.hasImage,_that.aiStatus,_that.aiLabel,_that.aiConfidence,_that.createdAt,_that.incidentStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String incidentId,  RoadCategory category,  String? description,  RoadPoint location,  bool hasImage,  AiStatus aiStatus,  String? aiLabel, @NullableDecimalConverter()  Decimal? aiConfidence,  DateTime createdAt,  IncidentStatus incidentStatus)?  $default,) {final _that = this;
switch (_that) {
case _OwnReport() when $default != null:
return $default(_that.id,_that.incidentId,_that.category,_that.description,_that.location,_that.hasImage,_that.aiStatus,_that.aiLabel,_that.aiConfidence,_that.createdAt,_that.incidentStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OwnReport implements OwnReport {
  const _OwnReport({required this.id, required this.incidentId, required this.category, this.description, required this.location, required this.hasImage, required this.aiStatus, this.aiLabel, @NullableDecimalConverter() this.aiConfidence, required this.createdAt, required this.incidentStatus});
  factory _OwnReport.fromJson(Map<String, dynamic> json) => _$OwnReportFromJson(json);

@override final  String id;
@override final  String incidentId;
@override final  RoadCategory category;
@override final  String? description;
@override final  RoadPoint location;
@override final  bool hasImage;
@override final  AiStatus aiStatus;
/// Category suggested from the photo; a suggestion only.
@override final  String? aiLabel;
@override@NullableDecimalConverter() final  Decimal? aiConfidence;
@override final  DateTime createdAt;
@override final  IncidentStatus incidentStatus;

/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnReportCopyWith<_OwnReport> get copyWith => __$OwnReportCopyWithImpl<_OwnReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnReport&&(identical(other.id, id) || other.id == id)&&(identical(other.incidentId, incidentId) || other.incidentId == incidentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.hasImage, hasImage) || other.hasImage == hasImage)&&(identical(other.aiStatus, aiStatus) || other.aiStatus == aiStatus)&&(identical(other.aiLabel, aiLabel) || other.aiLabel == aiLabel)&&(identical(other.aiConfidence, aiConfidence) || other.aiConfidence == aiConfidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.incidentStatus, incidentStatus) || other.incidentStatus == incidentStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,incidentId,category,description,location,hasImage,aiStatus,aiLabel,aiConfidence,createdAt,incidentStatus);
}

@override
String toString() {
    return 'OwnReport(id: $id, incidentId: $incidentId, category: $category, description: $description, location: $location, hasImage: $hasImage, aiStatus: $aiStatus, aiLabel: $aiLabel, aiConfidence: $aiConfidence, createdAt: $createdAt, incidentStatus: $incidentStatus)';
}


}

/// @nodoc
abstract mixin class _$OwnReportCopyWith<$Res> implements $OwnReportCopyWith<$Res> {
  factory _$OwnReportCopyWith(_OwnReport value, $Res Function(_OwnReport) _then) = __$OwnReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String incidentId, RoadCategory category, String? description, RoadPoint location, bool hasImage, AiStatus aiStatus, String? aiLabel,@NullableDecimalConverter() Decimal? aiConfidence, DateTime createdAt, IncidentStatus incidentStatus
});


@override $RoadPointCopyWith<$Res> get location;

}
/// @nodoc
class __$OwnReportCopyWithImpl<$Res>
    implements _$OwnReportCopyWith<$Res> {
  __$OwnReportCopyWithImpl(this._self, this._then);

  final _OwnReport _self;
  final $Res Function(_OwnReport) _then;

/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? incidentId = null,Object? category = null,Object? description = freezed,Object? location = null,Object? hasImage = null,Object? aiStatus = null,Object? aiLabel = freezed,Object? aiConfidence = freezed,Object? createdAt = null,Object? incidentStatus = null,}) {
  return _then(_OwnReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,incidentId: null == incidentId ? _self.incidentId : incidentId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RoadCategory,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as RoadPoint,hasImage: null == hasImage ? _self.hasImage : hasImage // ignore: cast_nullable_to_non_nullable
as bool,aiStatus: null == aiStatus ? _self.aiStatus : aiStatus // ignore: cast_nullable_to_non_nullable
as AiStatus,aiLabel: freezed == aiLabel ? _self.aiLabel : aiLabel // ignore: cast_nullable_to_non_nullable
as String?,aiConfidence: freezed == aiConfidence ? _self.aiConfidence : aiConfidence // ignore: cast_nullable_to_non_nullable
as Decimal?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,incidentStatus: null == incidentStatus ? _self.incidentStatus : incidentStatus // ignore: cast_nullable_to_non_nullable
as IncidentStatus,
  ));
}

/// Create a copy of OwnReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoadPointCopyWith<$Res> get location {
  
  return $RoadPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$MyConfirmation {

 bool get stillPresent; DateTime get createdAt;
/// Create a copy of MyConfirmation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyConfirmationCopyWith<MyConfirmation> get copyWith => _$MyConfirmationCopyWithImpl<MyConfirmation>(this as MyConfirmation, _$identity);

  /// Serializes this MyConfirmation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MyConfirmation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyConfirmation&&(identical(other.stillPresent, _this.stillPresent) || other.stillPresent == _this.stillPresent)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MyConfirmation;
  return Object.hash(runtimeType,_this.stillPresent,_this.createdAt);
}

@override
String toString() {
  final _this = this as MyConfirmation;
  return 'MyConfirmation(stillPresent: ${_this.stillPresent}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MyConfirmationCopyWith<$Res>  {
  factory $MyConfirmationCopyWith(MyConfirmation value, $Res Function(MyConfirmation) _then) = _$MyConfirmationCopyWithImpl;
@useResult
$Res call({
 bool stillPresent, DateTime createdAt
});




}
/// @nodoc
class _$MyConfirmationCopyWithImpl<$Res>
    implements $MyConfirmationCopyWith<$Res> {
  _$MyConfirmationCopyWithImpl(this._self, this._then);

  final MyConfirmation _self;
  final $Res Function(MyConfirmation) _then;

/// Create a copy of MyConfirmation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stillPresent = null,Object? createdAt = null,}) {
  return _then(MyConfirmation(
stillPresent: null == stillPresent ? _self.stillPresent : stillPresent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MyConfirmation].
extension MyConfirmationPatterns on MyConfirmation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyConfirmation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyConfirmation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyConfirmation value)  $default,){
final _that = this;
switch (_that) {
case _MyConfirmation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyConfirmation value)?  $default,){
final _that = this;
switch (_that) {
case _MyConfirmation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool stillPresent,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyConfirmation() when $default != null:
return $default(_that.stillPresent,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool stillPresent,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MyConfirmation():
return $default(_that.stillPresent,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool stillPresent,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MyConfirmation() when $default != null:
return $default(_that.stillPresent,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyConfirmation implements MyConfirmation {
  const _MyConfirmation({required this.stillPresent, required this.createdAt});
  factory _MyConfirmation.fromJson(Map<String, dynamic> json) => _$MyConfirmationFromJson(json);

@override final  bool stillPresent;
@override final  DateTime createdAt;

/// Create a copy of MyConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyConfirmationCopyWith<_MyConfirmation> get copyWith => __$MyConfirmationCopyWithImpl<_MyConfirmation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyConfirmationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyConfirmation&&(identical(other.stillPresent, stillPresent) || other.stillPresent == stillPresent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,stillPresent,createdAt);
}

@override
String toString() {
    return 'MyConfirmation(stillPresent: $stillPresent, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MyConfirmationCopyWith<$Res> implements $MyConfirmationCopyWith<$Res> {
  factory _$MyConfirmationCopyWith(_MyConfirmation value, $Res Function(_MyConfirmation) _then) = __$MyConfirmationCopyWithImpl;
@override @useResult
$Res call({
 bool stillPresent, DateTime createdAt
});




}
/// @nodoc
class __$MyConfirmationCopyWithImpl<$Res>
    implements _$MyConfirmationCopyWith<$Res> {
  __$MyConfirmationCopyWithImpl(this._self, this._then);

  final _MyConfirmation _self;
  final $Res Function(_MyConfirmation) _then;

/// Create a copy of MyConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stillPresent = null,Object? createdAt = null,}) {
  return _then(_MyConfirmation(
stillPresent: null == stillPresent ? _self.stillPresent : stillPresent // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ReportCreated {

 String get reportId; String get incidentId;/// The report joined an existing nearby incident.
 bool get merged; IncidentStatus get status; Incident get incident;
/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCreatedCopyWith<ReportCreated> get copyWith => _$ReportCreatedCopyWithImpl<ReportCreated>(this as ReportCreated, _$identity);

  /// Serializes this ReportCreated to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReportCreated;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportCreated&&(identical(other.reportId, _this.reportId) || other.reportId == _this.reportId)&&(identical(other.incidentId, _this.incidentId) || other.incidentId == _this.incidentId)&&(identical(other.merged, _this.merged) || other.merged == _this.merged)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.incident, _this.incident) || other.incident == _this.incident));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReportCreated;
  return Object.hash(runtimeType,_this.reportId,_this.incidentId,_this.merged,_this.status,_this.incident);
}

@override
String toString() {
  final _this = this as ReportCreated;
  return 'ReportCreated(reportId: ${_this.reportId}, incidentId: ${_this.incidentId}, merged: ${_this.merged}, status: ${_this.status}, incident: ${_this.incident})';
}


}

/// @nodoc
abstract mixin class $ReportCreatedCopyWith<$Res>  {
  factory $ReportCreatedCopyWith(ReportCreated value, $Res Function(ReportCreated) _then) = _$ReportCreatedCopyWithImpl;
@useResult
$Res call({
 String reportId, String incidentId, bool merged, IncidentStatus status, Incident incident
});


$IncidentCopyWith<$Res> get incident;

}
/// @nodoc
class _$ReportCreatedCopyWithImpl<$Res>
    implements $ReportCreatedCopyWith<$Res> {
  _$ReportCreatedCopyWithImpl(this._self, this._then);

  final ReportCreated _self;
  final $Res Function(ReportCreated) _then;

/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reportId = null,Object? incidentId = null,Object? merged = null,Object? status = null,Object? incident = null,}) {
  return _then(ReportCreated(
reportId: null == reportId ? _self.reportId : reportId // ignore: cast_nullable_to_non_nullable
as String,incidentId: null == incidentId ? _self.incidentId : incidentId // ignore: cast_nullable_to_non_nullable
as String,merged: null == merged ? _self.merged : merged // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IncidentStatus,incident: null == incident ? _self.incident : incident // ignore: cast_nullable_to_non_nullable
as Incident,
  ));
}
/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncidentCopyWith<$Res> get incident {
  
  return $IncidentCopyWith<$Res>(_self.incident, (value) {
    return _then(_self.copyWith(incident: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReportCreated].
extension ReportCreatedPatterns on ReportCreated {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportCreated value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportCreated() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportCreated value)  $default,){
final _that = this;
switch (_that) {
case _ReportCreated():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportCreated value)?  $default,){
final _that = this;
switch (_that) {
case _ReportCreated() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reportId,  String incidentId,  bool merged,  IncidentStatus status,  Incident incident)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportCreated() when $default != null:
return $default(_that.reportId,_that.incidentId,_that.merged,_that.status,_that.incident);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reportId,  String incidentId,  bool merged,  IncidentStatus status,  Incident incident)  $default,) {final _that = this;
switch (_that) {
case _ReportCreated():
return $default(_that.reportId,_that.incidentId,_that.merged,_that.status,_that.incident);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reportId,  String incidentId,  bool merged,  IncidentStatus status,  Incident incident)?  $default,) {final _that = this;
switch (_that) {
case _ReportCreated() when $default != null:
return $default(_that.reportId,_that.incidentId,_that.merged,_that.status,_that.incident);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportCreated implements ReportCreated {
  const _ReportCreated({required this.reportId, required this.incidentId, required this.merged, required this.status, required this.incident});
  factory _ReportCreated.fromJson(Map<String, dynamic> json) => _$ReportCreatedFromJson(json);

@override final  String reportId;
@override final  String incidentId;
/// The report joined an existing nearby incident.
@override final  bool merged;
@override final  IncidentStatus status;
@override final  Incident incident;

/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportCreatedCopyWith<_ReportCreated> get copyWith => __$ReportCreatedCopyWithImpl<_ReportCreated>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportCreatedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportCreated&&(identical(other.reportId, reportId) || other.reportId == reportId)&&(identical(other.incidentId, incidentId) || other.incidentId == incidentId)&&(identical(other.merged, merged) || other.merged == merged)&&(identical(other.status, status) || other.status == status)&&(identical(other.incident, incident) || other.incident == incident));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reportId,incidentId,merged,status,incident);
}

@override
String toString() {
    return 'ReportCreated(reportId: $reportId, incidentId: $incidentId, merged: $merged, status: $status, incident: $incident)';
}


}

/// @nodoc
abstract mixin class _$ReportCreatedCopyWith<$Res> implements $ReportCreatedCopyWith<$Res> {
  factory _$ReportCreatedCopyWith(_ReportCreated value, $Res Function(_ReportCreated) _then) = __$ReportCreatedCopyWithImpl;
@override @useResult
$Res call({
 String reportId, String incidentId, bool merged, IncidentStatus status, Incident incident
});


@override $IncidentCopyWith<$Res> get incident;

}
/// @nodoc
class __$ReportCreatedCopyWithImpl<$Res>
    implements _$ReportCreatedCopyWith<$Res> {
  __$ReportCreatedCopyWithImpl(this._self, this._then);

  final _ReportCreated _self;
  final $Res Function(_ReportCreated) _then;

/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reportId = null,Object? incidentId = null,Object? merged = null,Object? status = null,Object? incident = null,}) {
  return _then(_ReportCreated(
reportId: null == reportId ? _self.reportId : reportId // ignore: cast_nullable_to_non_nullable
as String,incidentId: null == incidentId ? _self.incidentId : incidentId // ignore: cast_nullable_to_non_nullable
as String,merged: null == merged ? _self.merged : merged // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IncidentStatus,incident: null == incident ? _self.incident : incident // ignore: cast_nullable_to_non_nullable
as Incident,
  ));
}

/// Create a copy of ReportCreated
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncidentCopyWith<$Res> get incident {
  
  return $IncidentCopyWith<$Res>(_self.incident, (value) {
    return _then(_self.copyWith(incident: value));
  });
}
}

// dart format on
