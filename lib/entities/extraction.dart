import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/extraction_operation_json_converter.dart';
import 'package:pan_scrapper/entities/extraction_operation.dart';

part 'extraction.g.dart';

@JsonSerializable(
  explicitToJson: true,
  converters: [ExtractionOperationJsonConverter()],
)
class Extraction {
  final dynamic payload;
  final Map<String, dynamic>? params;
  final ExtractionOperation operation;

  Extraction({
    required this.payload,
    required this.params,
    required this.operation,
  });

  factory Extraction.fromJson(Map<String, dynamic> json) =>
      _$ExtractionFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractionToJson(this);
}
