import 'package:pan_scrapper/services/models/cl_scotiabank_personas/card_details_response_model.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/card_response_model.dart';

class ClScotiabankPersonasCardWithDetailsModel {
  ClScotiabankPersonasCardWithDetailsModel({
    required this.card,
    required this.details,
  });

  final ClScotiabankPersonasCardResponseModel card;
  final ClScotiabankPersonasCardDetailsResponseModel details;
}
