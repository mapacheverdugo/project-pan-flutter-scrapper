import 'package:validate_rut/validate_rut.dart';

class Rut {
  late final String rut;
  late final String dv;

  String get _rutCompleto => '$rut$dv';
  String get formatted => formatRut(_rutCompleto);
  String get clean => removeRutFormatting(_rutCompleto);
  String get dotless => "$rut-$dv";

  bool get isValid => validateRut(_rutCompleto);

  Rut(String rutCompleto) {
    final rutClean = removeRutFormatting(rutCompleto);

    rut = rutClean.substring(0, rutClean.length - 1);
    dv = rutClean.substring(rutClean.length - 1).toUpperCase();
  }

  @override
  String toString() {
    return formatted;
  }
}
