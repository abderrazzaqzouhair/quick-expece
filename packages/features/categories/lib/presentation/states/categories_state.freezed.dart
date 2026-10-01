// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categories_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoriesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoriesState()';
}


}

/// @nodoc
class $CategoriesStateCopyWith<$Res>  {
$CategoriesStateCopyWith(CategoriesState _, $Res Function(CategoriesState) __);
}


/// Adds pattern-matching-related methods to [CategoriesState].
extension CategoriesStatePatterns on CategoriesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CategoriesInitial value)?  initial,TResult Function( CategoriesLoading value)?  loading,TResult Function( CategoriesSuccess value)?  success,TResult Function( CategoriesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CategoriesInitial() when initial != null:
return initial(_that);case CategoriesLoading() when loading != null:
return loading(_that);case CategoriesSuccess() when success != null:
return success(_that);case CategoriesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CategoriesInitial value)  initial,required TResult Function( CategoriesLoading value)  loading,required TResult Function( CategoriesSuccess value)  success,required TResult Function( CategoriesFailure value)  failure,}){
final _that = this;
switch (_that) {
case CategoriesInitial():
return initial(_that);case CategoriesLoading():
return loading(_that);case CategoriesSuccess():
return success(_that);case CategoriesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CategoriesInitial value)?  initial,TResult? Function( CategoriesLoading value)?  loading,TResult? Function( CategoriesSuccess value)?  success,TResult? Function( CategoriesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CategoriesInitial() when initial != null:
return initial(_that);case CategoriesLoading() when loading != null:
return loading(_that);case CategoriesSuccess() when success != null:
return success(_that);case CategoriesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<CategoryEntity> items)?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CategoriesInitial() when initial != null:
return initial();case CategoriesLoading() when loading != null:
return loading();case CategoriesSuccess() when success != null:
return success(_that.items);case CategoriesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<CategoryEntity> items)  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case CategoriesInitial():
return initial();case CategoriesLoading():
return loading();case CategoriesSuccess():
return success(_that.items);case CategoriesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<CategoryEntity> items)?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case CategoriesInitial() when initial != null:
return initial();case CategoriesLoading() when loading != null:
return loading();case CategoriesSuccess() when success != null:
return success(_that.items);case CategoriesFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class CategoriesInitial implements CategoriesState {
  const CategoriesInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoriesState.initial()';
}


}




/// @nodoc


class CategoriesLoading implements CategoriesState {
  const CategoriesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoriesState.loading()';
}


}




/// @nodoc


class CategoriesSuccess implements CategoriesState {
  const CategoriesSuccess(final  List<CategoryEntity> items): _items = items;
  

 final  List<CategoryEntity> _items;
 List<CategoryEntity> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoriesSuccessCopyWith<CategoriesSuccess> get copyWith => _$CategoriesSuccessCopyWithImpl<CategoriesSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesSuccess&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CategoriesState.success(items: $items)';
}


}

/// @nodoc
abstract mixin class $CategoriesSuccessCopyWith<$Res> implements $CategoriesStateCopyWith<$Res> {
  factory $CategoriesSuccessCopyWith(CategoriesSuccess value, $Res Function(CategoriesSuccess) _then) = _$CategoriesSuccessCopyWithImpl;
@useResult
$Res call({
 List<CategoryEntity> items
});




}
/// @nodoc
class _$CategoriesSuccessCopyWithImpl<$Res>
    implements $CategoriesSuccessCopyWith<$Res> {
  _$CategoriesSuccessCopyWithImpl(this._self, this._then);

  final CategoriesSuccess _self;
  final $Res Function(CategoriesSuccess) _then;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(CategoriesSuccess(
null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CategoryEntity>,
  ));
}


}

/// @nodoc


class CategoriesFailure implements CategoriesState {
  const CategoriesFailure(this.message);
  

 final  String message;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoriesFailureCopyWith<CategoriesFailure> get copyWith => _$CategoriesFailureCopyWithImpl<CategoriesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoriesFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CategoriesState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $CategoriesFailureCopyWith<$Res> implements $CategoriesStateCopyWith<$Res> {
  factory $CategoriesFailureCopyWith(CategoriesFailure value, $Res Function(CategoriesFailure) _then) = _$CategoriesFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CategoriesFailureCopyWithImpl<$Res>
    implements $CategoriesFailureCopyWith<$Res> {
  _$CategoriesFailureCopyWithImpl(this._self, this._then);

  final CategoriesFailure _self;
  final $Res Function(CategoriesFailure) _then;

/// Create a copy of CategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CategoriesFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
