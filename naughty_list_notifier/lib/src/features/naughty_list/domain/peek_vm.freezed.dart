// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'peek_vm.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeekVM {

 String get bucket; String get contentType; String get downloadURL; String get filePath; String get size; DateTime get uploadedAt;
/// Create a copy of PeekVM
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeekVMCopyWith<PeekVM> get copyWith => _$PeekVMCopyWithImpl<PeekVM>(this as PeekVM, _$identity);

  /// Serializes this PeekVM to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeekVM&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.downloadURL, downloadURL) || other.downloadURL == downloadURL)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bucket,contentType,downloadURL,filePath,size,uploadedAt);

@override
String toString() {
  return 'PeekVM(bucket: $bucket, contentType: $contentType, downloadURL: $downloadURL, filePath: $filePath, size: $size, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $PeekVMCopyWith<$Res>  {
  factory $PeekVMCopyWith(PeekVM value, $Res Function(PeekVM) _then) = _$PeekVMCopyWithImpl;
@useResult
$Res call({
 String bucket, String contentType, String downloadURL, String filePath, String size, DateTime uploadedAt
});




}
/// @nodoc
class _$PeekVMCopyWithImpl<$Res>
    implements $PeekVMCopyWith<$Res> {
  _$PeekVMCopyWithImpl(this._self, this._then);

  final PeekVM _self;
  final $Res Function(PeekVM) _then;

/// Create a copy of PeekVM
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucket = null,Object? contentType = null,Object? downloadURL = null,Object? filePath = null,Object? size = null,Object? uploadedAt = null,}) {
  return _then(_self.copyWith(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,downloadURL: null == downloadURL ? _self.downloadURL : downloadURL // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PeekVM].
extension PeekVMPatterns on PeekVM {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeekVM value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeekVM() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeekVM value)  $default,){
final _that = this;
switch (_that) {
case _PeekVM():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeekVM value)?  $default,){
final _that = this;
switch (_that) {
case _PeekVM() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bucket,  String contentType,  String downloadURL,  String filePath,  String size,  DateTime uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeekVM() when $default != null:
return $default(_that.bucket,_that.contentType,_that.downloadURL,_that.filePath,_that.size,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bucket,  String contentType,  String downloadURL,  String filePath,  String size,  DateTime uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _PeekVM():
return $default(_that.bucket,_that.contentType,_that.downloadURL,_that.filePath,_that.size,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bucket,  String contentType,  String downloadURL,  String filePath,  String size,  DateTime uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _PeekVM() when $default != null:
return $default(_that.bucket,_that.contentType,_that.downloadURL,_that.filePath,_that.size,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeekVM implements PeekVM {
  const _PeekVM({required this.bucket, required this.contentType, required this.downloadURL, required this.filePath, required this.size, required this.uploadedAt});
  factory _PeekVM.fromJson(Map<String, dynamic> json) => _$PeekVMFromJson(json);

@override final  String bucket;
@override final  String contentType;
@override final  String downloadURL;
@override final  String filePath;
@override final  String size;
@override final  DateTime uploadedAt;

/// Create a copy of PeekVM
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeekVMCopyWith<_PeekVM> get copyWith => __$PeekVMCopyWithImpl<_PeekVM>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeekVMToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeekVM&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.downloadURL, downloadURL) || other.downloadURL == downloadURL)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bucket,contentType,downloadURL,filePath,size,uploadedAt);

@override
String toString() {
  return 'PeekVM(bucket: $bucket, contentType: $contentType, downloadURL: $downloadURL, filePath: $filePath, size: $size, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$PeekVMCopyWith<$Res> implements $PeekVMCopyWith<$Res> {
  factory _$PeekVMCopyWith(_PeekVM value, $Res Function(_PeekVM) _then) = __$PeekVMCopyWithImpl;
@override @useResult
$Res call({
 String bucket, String contentType, String downloadURL, String filePath, String size, DateTime uploadedAt
});




}
/// @nodoc
class __$PeekVMCopyWithImpl<$Res>
    implements _$PeekVMCopyWith<$Res> {
  __$PeekVMCopyWithImpl(this._self, this._then);

  final _PeekVM _self;
  final $Res Function(_PeekVM) _then;

/// Create a copy of PeekVM
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucket = null,Object? contentType = null,Object? downloadURL = null,Object? filePath = null,Object? size = null,Object? uploadedAt = null,}) {
  return _then(_PeekVM(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,downloadURL: null == downloadURL ? _self.downloadURL : downloadURL // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
