import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/extracted_credit_card_bill_period.dart';

class PeriodCard extends StatelessWidget {
  final ExtractedCreditCardBillPeriod period;

  const PeriodCard({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity),
            Text('ID: ${period.providerId}'),
            Text(
              'Period: ${period.startDate}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Currency: ${period.currency}'),
            Text('Currency Type: ${period.currencyType.name}'),
            if (period.endDate != null) Text('End Date: ${period.endDate}'),
          ],
        ),
      ),
    );
  }
}
