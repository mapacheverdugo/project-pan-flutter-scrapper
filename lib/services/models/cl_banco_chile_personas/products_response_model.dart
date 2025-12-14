class ClBancoChilePersonasProductsResponseModel {
  final String? nombre;
  final String? rut;
  final List<ClBancoChilePersonasProducto> productos;

  ClBancoChilePersonasProductsResponseModel({
    this.nombre,
    this.rut,
    required this.productos,
  });

  factory ClBancoChilePersonasProductsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasProductsResponseModel(
      nombre: json['nombre'] as String?,
      rut: json['rut'] as String?,
      productos: json['productos'] == null
          ? []
          : (json['productos'] as List<dynamic>)
              .map((e) =>
                  ClBancoChilePersonasProducto.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ClBancoChilePersonasProducto {
  final String? id;
  final String? codigo;
  final String? numero;
  final String? mascara;
  final String? descripcionLogo;
  final String? tarjetaHabiente;
  final String? tipoCliente;
  final String? claseCuenta;
  final String? codigoMoneda;

  ClBancoChilePersonasProducto({
    this.id,
    this.codigo,
    this.numero,
    this.mascara,
    this.descripcionLogo,
    this.tarjetaHabiente,
    this.tipoCliente,
    this.claseCuenta,
    this.codigoMoneda,
  });

  factory ClBancoChilePersonasProducto.fromJson(Map<String, dynamic> json) {
    return ClBancoChilePersonasProducto(
      id: json['id'] as String?,
      codigo: json['codigo'] as String?,
      numero: json['numero'] as String?,
      mascara: json['mascara'] as String?,
      descripcionLogo: json['descripcionLogo'] as String?,
      tarjetaHabiente: json['tarjetaHabiente'] as String?,
      tipoCliente: json['tipoCliente'] as String?,
      claseCuenta: json['claseCuenta'] as String?,
      codigoMoneda: json['codigoMoneda'] as String?,
    );
  }
}

