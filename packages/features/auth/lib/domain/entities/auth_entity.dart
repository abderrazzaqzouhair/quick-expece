import 'package:equatable/equatable.dart';

/// Plain domain entity — no JSON/Freezed coupling. Add fields as the
/// `auth` domain takes shape.
class AuthEntity extends Equatable {
  const AuthEntity({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
