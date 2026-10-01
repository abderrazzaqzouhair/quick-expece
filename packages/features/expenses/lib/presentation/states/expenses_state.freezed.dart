// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expenses_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExpensesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpensesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExpensesState()';
}


}

/// @nodoc
class $ExpensesStateCopyWith<$Res>  {
$ExpensesStateCopyWith(ExpensesState _, $Res Function(ExpensesState) __);
}


/// Adds pattern-matching-related methods to [ExpensesState].
extension ExpensesStatePatterns on ExpensesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExpensesInitial value)?  initial,TResult Function( ExpensesLoading value)?  loading,TResult Function( ExpensesSuccess value)?  success,TResult Function( ExpensesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExpensesInitial() when initial != null:
return initial(_that);case ExpensesLoading() when loading != null:
return loading(_that);case ExpensesSuccess() when success != null:
return success(_that);case ExpensesFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExpensesInitial value)  initial,required TResult Function( ExpensesLoading value)  loading,required TResult Function( ExpensesSuccess value)  success,required TResult Function( ExpensesFailure value)  failure,}){
final _that = this;
switch (_that) {
case ExpensesInitial():
return initial(_that);case ExpensesLoading():
return loading(_that);case ExpensesSuccess():
return success(_that);case ExpensesFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExpensesInitial value)?  initial,TResult? Function( ExpensesLoading value)?  loading,TResult? Function( ExpensesSuccess value)?  success,TResult? Function( ExpensesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ExpensesInitial() when initial != null:
return initial(_that);case ExpensesLoading() when loading != null:
return loading(_that);case ExpensesSuccess() when success != null:
return success(_that);case ExpensesFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ExpensesEntity> items)?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExpensesInitial() when initial != null:
return initial();case ExpensesLoading() when loading != null:
return loading();case ExpensesSuccess() when success != null:
return success(_that.items);case ExpensesFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ExpensesEntity> items)  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case ExpensesInitial():
return initial();case ExpensesLoading():
return loading();case ExpensesSuccess():
return success(_that.items);case ExpensesFailure():
return failure(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ExpensesEntity> items)?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case ExpensesInitial() when initial != null:
return initial();case ExpensesLoading() when loading != null:
return loading();case ExpensesSuccess() when success != null:
return success(_that.items);case ExpensesFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ExpensesInitial implements ExpensesState {
  const ExpensesInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpensesInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExpensesState.initial()';
}


}




/// @nodoc


class ExpensesLoading implements ExpensesState {
  const ExpensesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpensesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExpensesState.loading()';
}


}




/// @nodoc


class ExpensesSuccess implements ExpensesState {
  const ExpensesSuccess(final  List<ExpensesEntity> items): _items = items;
  

 final  List<ExpensesEntity> _items;
 List<ExpensesEntity> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ExpensesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpensesSuccessCopyWith<ExpensesSuccess> get copyWith => _$ExpensesSuccessCopyWithImpl<ExpensesSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpensesSuccess&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ExpensesState.success(items: $items)';
}


}

/// @nodoc
abstract mixin class $ExpensesSuccessCopyWith<$Res> implements $ExpensesStateCopyWith<$Res> {
  factory $ExpensesSuccessCopyWith(ExpensesSuccess value, $Res Function(ExpensesSuccess) _then) = _$ExpensesSuccessCopyWithImpl;
@useResult
$Res call({
 List<ExpensesEntity> items
});




}
/// @nodoc
class _$ExpensesSuccessCopyWithImpl<$Res>
    implements $ExpensesSuccessCopyWith<$Res> {
  _$ExpensesSuccessCopyWithImpl(this._self, this._then);

  final ExpensesSuccess _self;
  final $Res Function(ExpensesSuccess) _then;

/// Create a copy of ExpensesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(ExpensesSuccess(
null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ExpensesEntity>,
  ));
}


}

/// @nodoc


class ExpensesFailure implements ExpensesState {
  const ExpensesFailure(this.message);
  

 final  String message;

/// Create a copy of ExpensesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpensesFailureCopyWith<ExpensesFailure> get copyWith => _$ExpensesFailureCopyWithImpl<ExpensesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpensesFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ExpensesState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $ExpensesFailureCopyWith<$Res> implements $ExpensesStateCopyWith<$Res> {
  factory $ExpensesFailureCopyWith(ExpensesFailure value, $Res Function(ExpensesFailure) _then) = _$ExpensesFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ExpensesFailureCopyWithImpl<$Res>
    implements $ExpensesFailureCopyWith<$Res> {
  _$ExpensesFailureCopyWithImpl(this._self, this._then);

  final ExpensesFailure _self;
  final $Res Function(ExpensesFailure) _then;

/// Create a copy of ExpensesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ExpensesFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
