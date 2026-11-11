// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_pair.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_TokenPair',
  json,
  ($checkedConvert) {
    final val = _TokenPair(
      accessToken: $checkedConvert('access_token', (v) => v as String),
      refreshToken: $checkedConvert('refresh_token', (v) => v as String),
      tokenType: $checkedConvert('token_type', (v) => v as String? ?? 'bearer'),
      expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
      refreshExpiresAt: $checkedConvert(
        'refresh_expires_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'accessToken': 'access_token',
    'refreshToken': 'refresh_token',
    'tokenType': 'token_type',
    'expiresIn': 'expires_in',
    'refreshExpiresAt': 'refresh_expires_at',
  },
);

Map<String, dynamic> _$TokenPairToJson(_TokenPair instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'refresh_expires_at': instance.refreshExpiresAt.toIso8601String(),
    };
