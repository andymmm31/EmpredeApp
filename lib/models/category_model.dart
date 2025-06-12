// lib/models/category_model.dart

// Define los nombres de las columnas para evitar errores de tipeo.
class CategoryFields {
  static const String id = '_id';
  static const String nombre = 'nombre';
  static const String descripcion = 'descripcion';
  static const String color = 'color';
}

class Category {
  final int? id;
  final String nombre;
  final String? descripcion; // Puede ser nulo
  final String? color;       // Puede ser nulo

  const Category({
    this.id,
    required this.nombre,
    this.descripcion,
    this.color,
  });

  // Método para convertir un objeto Category a un mapa para la base de datos.
  Map<String, dynamic> toMap() {
    return {
      CategoryFields.id: id,
      CategoryFields.nombre: nombre,
      CategoryFields.descripcion: descripcion,
      CategoryFields.color: color,
    };
  }

  // Método para crear un objeto Category a partir de un mapa de la base de datos.
  static Category fromMap(Map<String, dynamic> map) {
    return Category(
      // Se lee el ID de la columna '_id'.
      id: map[CategoryFields.id] as int?,
      
      // El nombre es obligatorio.
      nombre: map[CategoryFields.nombre] as String,
      
      // La descripción puede ser nula, por lo que el cast es a 'String?'.
      descripcion: map[CategoryFields.descripcion] as String?,
      
      // El color también puede ser nulo.
      color: map[CategoryFields.color] as String?,
    );
  }

  // Método para crear una copia de la categoría con algunos campos modificados.
  // Es útil para las actualizaciones.
  Category copy({
    int? id,
    String? nombre,
    String? descripcion,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
    );
  }
}