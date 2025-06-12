// lib/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late Future<List<Category>> _categoriesFuture;
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }
  
  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay categorías disponibles'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _parseColor(category.color), // Usamos el color de la categoría
                  size: 24,
                ),
                title: Text(category.nombre),
                subtitle: Text(category.descripcion ?? 'Sin descripción'), // Mostramos la descripción
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditCategoryDialog(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper para convertir el string del color a un objeto Color
  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey; // Color por defecto
    }
    try {
      final hexCode = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.grey; // Color de respaldo si hay un error
    }
  }
  
  void _refreshCategories() {
    setState(() {
      _categoriesFuture = DatabaseHelper.instance.getAllCategories();
    });
  }

  Future<void> _showAddCategoryDialog() async {
    _categoryController.clear();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Agregar Nueva Categoría'),
          content: SingleChildScrollView(
            child: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  try {
                    await DatabaseHelper.instance.createCategory(
                      Category(nombre: categoryName, descripcion: 'Nueva categoría'),
                    );
                    
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    _refreshCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Categoría "$categoryName" agregada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al agregar categoría: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                   }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    _categoryController.text = category.nombre;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: SingleChildScrollView(
            child: TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty && categoryName != category.nombre) {
                  try {
                    final updatedCategory = category.copy(nombre: categoryName);
                    await DatabaseHelper.instance.updateCategory(updatedCategory);
                    
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    _refreshCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoría actualizada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar categoría: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(Category category) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Categoría'),
          content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.nombre}"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                try {
                  await DatabaseHelper.instance.deleteCategory(category.id!);
                  
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  _refreshCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Categoría "${category.nombre}" eliminada.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar categoría: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}