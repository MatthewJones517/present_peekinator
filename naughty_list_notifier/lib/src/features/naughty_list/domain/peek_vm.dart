import 'package:freezed_annotation/freezed_annotation.dart';

part 'peek_vm.freezed.dart';
part 'peek_vm.g.dart';

@freezed
abstract class PeekVM with _$PeekVM {
  const factory PeekVM({
    required String bucket,
    required String contentType,
    required String downloadURL,
    required String filePath,
    required String size,
    required DateTime uploadedAt,
  }) = _PeekVM;

  factory PeekVM.fromJson(Map<String, dynamic> json) => _$PeekVMFromJson(json);
}
