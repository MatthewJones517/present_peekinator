// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peek_vm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeekVM _$PeekVMFromJson(Map<String, dynamic> json) => _PeekVM(
  bucket: json['bucket'] as String,
  contentType: json['contentType'] as String,
  downloadURL: json['downloadURL'] as String,
  filePath: json['filePath'] as String,
  size: json['size'] as String,
  uploadedAt: DateTime.parse(json['uploadedAt'] as String),
);

Map<String, dynamic> _$PeekVMToJson(_PeekVM instance) => <String, dynamic>{
  'bucket': instance.bucket,
  'contentType': instance.contentType,
  'downloadURL': instance.downloadURL,
  'filePath': instance.filePath,
  'size': instance.size,
  'uploadedAt': instance.uploadedAt.toIso8601String(),
};
