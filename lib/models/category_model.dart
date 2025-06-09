class CategoryFields {
  static final List<String> values = [id, nombre, fechaCreacion];

  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String fechaCreacion = 'fecha_creacion';
}

class Category {
  final int? id;
  final String nombre;
  final DateTime fechaCreacion;

  Category({
    this.id,
    required this.nombre,
    DateTime? fechaCreacion,
  }) : this.fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        CategoryFields.id: id,
        CategoryFields.nombre: nombre,
        CategoryFields.fechaCreacion: fechaCreacion.toIso8601String(),
      };

  static Category fromMap(Map<String, dynamic> map) => Category(
        id: map[CategoryFields.id] as int?,
        nombre: map[CategoryFields.nombre] as String,
        fechaCreacion: DateTime.parse(map[CategoryFields.fechaCreacion] as String),
      );
}