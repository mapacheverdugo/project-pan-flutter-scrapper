// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_credit_card_bill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedCreditCardBill _$ExtractedCreditCardBillFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBill(
  periodId: json['periodId'] as String,
  currencyType: const CurrencyTypeJsonConverter().fromJson(
    json['currencyType'] as String,
  ),
  summary: json['summary'] == null
      ? null
      : ExtractedCreditCardBillSummary.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
  transactions: (json['transactions'] as List<dynamic>?)
      ?.map(
        (e) => ExtractedTransactionWithoutProviderId.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
);

Map<String, dynamic> _$ExtractedCreditCardBillToJson(
  ExtractedCreditCardBill instance,
) => <String, dynamic>{
  'periodId': instance.periodId,
  'currencyType': const CurrencyTypeJsonConverter().toJson(
    instance.currencyType,
  ),
  'summary': instance.summary?.toJson(),
  'transactions': instance.transactions?.map((e) => e.toJson()).toList(),
};
