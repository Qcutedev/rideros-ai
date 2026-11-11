import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_pair.freezed.dart';
part 'token_pair.g.dart';

/// `POST /auth/login` and `POST /auth/refresh` response.
@freezed
abstract class TokenPair with _$TokenPair {
  const factory TokenPair({
    required String accessToken,
    required String refreshToken,
    @Default('bearer') String tokenType,

    /// Access-token lifetime in seconds.
    required int expiresIn,
    required DateTime refreshExpiresAt,
  }) = _TokenPair;

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);
}
