import 'package:equatable/equatable.dart';

/// Plain domain entity — no JSON/Freezed coupling. Add fields as the
/// `expenses` domain takes shape.
class ExpensesEntity extends Equatable {
  const ExpensesEntity({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
