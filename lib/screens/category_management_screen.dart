// lib/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key}); // Agregar const y super.key

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState(); // Cambiar nombre del método
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late Future<List<Category>> _categoriesFuture;
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
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
                leading: const Icon(Icons.category),
                title: Text(category.nombre),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCategoryDialog(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nota: Las categorías "Vinos" y "Chocolates" son categorías por defecto del sistema.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  try {
                    // Verificar si la categoría ya existe
                    final existingCategory = await DatabaseHelper.instance
                        .getCategoryByName(categoryName);
                    if (existingCategory != null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('La categoría "$categoryName" ya existe'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    await DatabaseHelper.instance.createCategory(
                      Category(nombre: categoryName),
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                      _refreshCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Categoría "$categoryName" agregada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar categoría: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                if (category.nombre == 'Vinos' ||
                    category.nombre == 'Chocolates' ||
                    category.nombre == 'Tecnología')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta es una categoría por defecto del sistema. Puedes editarla, pero se recomienda mantenerla.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty &&
                    categoryName != category.nombre) {
                  try {
                    // Verificar si la categoría ya existe
                    final existingCategory = await DatabaseHelper.instance
                        .getCategoryByName(categoryName);
                    if (existingCategory != null &&
                        existingCategory.id != category.id) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('La categoría "$categoryName" ya existe'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    final updatedCategory = Category(
                      id: category.id,
                      nombre: categoryName,
                      fechaCreacion: category.fechaCreacion,
                    );

                    await DatabaseHelper.instance
                        .updateCategory(updatedCategory);
                    if (mounted) {
                      Navigator.of(context).pop();
                      _refreshCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Categoría actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar categoría: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(Category category) async {
    // Verificar si hay productos asociados a esta categoría
    final products =
        await DatabaseHelper.instance.getProductsByCategory(category.id!);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '¿Estás seguro de que deseas eliminar la categoría "${category.nombre}"?'),
                const SizedBox(height: 12),
                if (products.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Advertencia',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esta categoría tiene ${products.length} producto(s) asociado(s). Si elimina esta categoría, los productos asociados también serán eliminados.',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCategory(category.id!);
                if (mounted) {
                  Navigator.of(context).pop();
                  _refreshCategories();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
