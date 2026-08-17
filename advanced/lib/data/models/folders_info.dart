import 'package:json_annotation/json_annotation.dart';

part 'folders_info.g.dart';

/// A single monitored folder from the Glances `folders` plugin.
///
/// The folders plugin reports the disk usage of a configured list of folders
/// (unlike `fs`, which reports every mount point). All values are nullable
/// because the fields reported can vary between Glances versions; the size
/// fields are byte counts and [percent] is on a 0-100 scale.
@JsonSerializable()
class FolderInfo {
  /// Folder name/label as configured on the server.
  final String? name;

  /// Bytes used by the folder's contents.
  final num? used;

  /// Bytes free inside the folder's filesystem.
  final num? free;

  /// Total bytes allocated to the folder's filesystem.
  final num? size;

  /// Fraction of the folder's filesystem used, on a 0-100 scale.
  final num? percent;

  /// Creates a [FolderInfo] with all fields optional.
  const FolderInfo({
    this.name,
    this.used,
    this.free,
    this.size,
    this.percent,
  });

  factory FolderInfo.fromJson(Map<String, dynamic> json) =>
      _$FolderInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FolderInfoToJson(this);
}