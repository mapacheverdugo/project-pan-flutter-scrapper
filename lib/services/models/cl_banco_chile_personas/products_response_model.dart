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
                .map(
                  (e) => ClBancoChilePersonasProducto.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
    );
  }
}

class ClBancoChilePersonasProducto {
  ClBancoChilePersonasProducto({
    required this.id,
    required this.numero,
    required this.mascara,
    required this.codigo,
    required this.codigoMoneda,
    required this.alias,
    required this.label,
    required this.tipo,
    required this.claseCuenta,
    required this.subProducto,
    required this.estado,
    required this.detalleEstado,
    required this.tarjetaHabiente,
    required this.descripcionLogo,
    required this.tipoCliente,
  });

  final String id;
  final String numero;
  final String mascara;
  final String codigo;
  final String codigoMoneda;
  final String? alias;
  final String label;
  final String tipo;
  final String? claseCuenta;
  final String? subProducto;
  final String? estado;
  final String? detalleEstado;
  final String? tarjetaHabiente;
  final String? descripcionLogo;
  final String? tipoCliente;

  factory ClBancoChilePersonasProducto.fromJson(Map<String, dynamic> json) {
    return ClBancoChilePersonasProducto(
      id: json["id"],
      numero: json["numero"],
      mascara: json["mascara"],
      codigo: json["codigo"],
      codigoMoneda: json["codigoMoneda"],
      alias: json["alias"],
      label: json["label"],
      tipo: json["tipo"],
      claseCuenta: json["claseCuenta"],
      subProducto: json["subProducto"],
      estado: json["estado"],
      detalleEstado: json["detalleEstado"],
      tarjetaHabiente: json["tarjetaHabiente"],
      descripcionLogo: json["descripcionLogo"],
      tipoCliente: json["tipoCliente"],
    );
  }
}
