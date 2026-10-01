// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subcategory_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubcategoryResponse {

 int get id;@JsonKey(name: 'category_id') int get categoryId; String get name; String? get icon;@JsonKey(name: 'icon_url') String? get iconUrl;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of SubcategoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubcategoryResponseCopyWith<SubcategoryResponse> get copyWith => _$SubcategoryResponseCopyWithImpl<SubcategoryResponse>(this as SubcategoryResponse, _$identity);

  /// Serializes this SubcategoryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubcategoryResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,icon,iconUrl,isActive);

@override
String toString() {
  return 'SubcategoryResponse(id: $id, categoryId: $categoryId, name: $name, icon: $icon, iconUrl: $iconUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $SubcategoryResponseCopyWith<$Res>  {
  factory $SubcategoryResponseCopyWith(SubcategoryResponse value, $Res Function(SubcategoryResponse) _then) = _$SubcategoryResponseCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'category_id') int categoryId, String name, String? icon,@JsonKey(name: 'icon_url') String? iconUrl,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$SubcategoryResponseCopyWithImpl<$Res>
    implements $SubcategoryResponseCopyWith<$Res> {
  _$SubcategoryResponseCopyWithImpl(this._self, this._then);

  final SubcategoryResponse _self;
  final $Res Function(SubcategoryResponse) _then;

/// Create a copy of SubcategoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? icon = freezed,Object? iconUrl = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubcategoryResponse].
extension SubcategoryResponsePatterns on SubcategoryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubcategoryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubcategoryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubcategoryResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubcategoryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubcategoryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubcategoryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'category_id')  int categoryId,  String name,  String? icon, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubcategoryResponse() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.icon,_that.iconUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'category_id')  int categoryId,  String name,  String? icon, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _SubcategoryResponse():
return $default(_that.id,_that.categoryId,_that.name,_that.icon,_that.iconUrl,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'category_id')  int categoryId,  String name,  String? icon, @JsonKey(name: 'icon_url')  String? iconUrl, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _SubcategoryResponse() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.icon,_that.iconUrl,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubcategoryResponse implements SubcategoryResponse {
  const _SubcategoryResponse({required this.id, @JsonKey(name: 'category_id') required this.categoryId, required this.name, this.icon, @JsonKey(name: 'icon_url') this.iconUrl, @JsonKey(name: 'is_active') required this.isActive});
  factory _SubcategoryResponse.fromJson(Map<String, dynamic> json) => _$SubcategoryResponseFromJson(json);

@override final  int id;
@override@JsonKey(name: 'category_id') final  int categoryId;
@override final  String name;
@override final  String? icon;
@override@JsonKey(name: 'icon_url') final  String? iconUrl;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of SubcategoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubcategoryResponseCopyWith<_SubcategoryResponse> get copyWith => __$SubcategoryResponseCopyWithImpl<_SubcategoryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubcategoryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubcategoryResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,icon,iconUrl,isActive);

@override
String toString() {
  return 'SubcategoryResponse(id: $id, categoryId: $categoryId, name: $name, icon: $icon, iconUrl: $iconUrl, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$SubcategoryResponseCopyWith<$Res> implements $SubcategoryResponseCopyWith<$Res> {
  factory _$SubcategoryResponseCopyWith(_SubcategoryResponse value, $Res Function(_SubcategoryResponse) _then) = __$SubcategoryResponseCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'category_id') int categoryId, String name, String? icon,@JsonKey(name: 'icon_url') String? iconUrl,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$SubcategoryResponseCopyWithImpl<$Res>
    implements _$SubcategoryResponseCopyWith<$Res> {
  __$SubcategoryResponseCopyWithImpl(this._self, this._then);

  final _SubcategoryResponse _self;
  final $Res Function(_SubcategoryResponse) _then;

/// Create a copy of SubcategoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? icon = freezed,Object? iconUrl = freezed,Object? isActive = null,}) {
  return _then(_SubcategoryResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,iconUrl: freezed == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
