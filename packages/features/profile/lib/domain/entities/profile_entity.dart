import 'package:equatable/equatable.dart';

/// Plain domain entity — no JSON/Freezed coupling. Add fields as the
/// `profile` domain takes shape.
class ProfileEntity extends Equatable {
  const ProfileEntity({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
