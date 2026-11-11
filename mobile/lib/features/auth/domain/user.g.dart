// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_User',
  json,
  ($checkedConvert) {
    final val = _User(
      id: $checkedConvert('id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      displayName: $checkedConvert('display_name', (v) => v as String),
      role: $checkedConvert('role', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'displayName': 'display_name', 'createdAt': 'created_at'},
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'role': instance.role,
  'created_at': instance.createdAt.toIso8601String(),
};
