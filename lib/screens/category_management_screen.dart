// lib/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() => _CategoryManagementScreenState();
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
          title: Text('Agregar Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                SizedBox(height: 16),
                Text(
                  'Nota: Las categorías "Vinos" y "Chocolates" son categorías por defecto del sistema.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Agregar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty) {
                  try {
                    // Verificar si la categoría ya existe
                    final existingCategory = await DatabaseHelper.instance.getCategoryByName(categoryName);
                    if (existingCategory != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('La categoría "$categoryName" ya existe'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.createCategory(
                      Category(nombre: categoryName),
                    );
                    Navigator.of(context).pop();
                    _refreshCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Categoría "$categoryName" agregada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                SizedBox(height: 16),
                if (category.nombre == 'Vinos' || category.nombre == 'Chocolates')
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta es una categoría por defecto del sistema. Puedes editarla, pero se recomienda mantenerla.',
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
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
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () async {
                final categoryName = _categoryController.text.trim();
                if (categoryName.isNotEmpty && categoryName != category.nombre) {
                  try {
                    // Verificar si la categoría ya existe
                    final existingCategory = await DatabaseHelper.instance.getCategoryByName(categoryName);
                    if (existingCategory != null && existingCategory.id != category.id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('La categoría "$categoryName" ya existe'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final updatedCategory = Category(
                      id: category.id,
                      nombre: categoryName,
                      fechaCreacion: category.fechaCreacion,
                    );
                    
                    await DatabaseHelper.instance.updateCategory(updatedCategory);
                    Navigator.of(context).pop();
                    _refreshCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Categoría actualizada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar categoría: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
    final products = await DatabaseHelper.instance.getProductsByCategory(category.id!);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Estás seguro de que deseas eliminar la categoría "${category.nombre}"?'),
                SizedBox(height: 12),
                if (products.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12),
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
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Advertencia',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Esta categoría tiene ${products.length} producto(s) asociado(s). Si eliminas la categoría, estos productos quedarán sin categoría.',
                          style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta categoría no tiene productos asociados.',
                            style: TextStyle(fontSize: 12, color: Colors.green[800]),
                          ),
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
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar'),
              onPressed: () async {
                try {
                  await DatabaseHelper.instance.deleteCategory(category.id!);
                  Navigator.of(context).pop();
                  _refreshCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Categoría "${category.nombre}" eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
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

  Widget _buildCategoryCard(Category category, int productCount) {
    bool isDefaultCategory = category.nombre == 'Vinos' || category.nombre == 'Chocolates';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDefaultCategory ? Colors.blue : Colors.grey,
          child: Icon(
            isDefaultCategory ? Icons.star : Icons.category,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              category.nombre,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isDefaultCategory) ...[
              SizedBox(width: 8),
              Chip(
                label: Text('Por defecto'),
                backgroundColor: Colors.blue[100],
                labelStyle: TextStyle(fontSize: 10, color: Colors.blue[800]),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$productCount producto(s)'),
            Text(
              'Creada: ${category.fechaCreacion.day}/${category.fechaCreacion.month}/${category.fechaCreacion.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _showEditCategoryDialog(category);
                break;
              case 'delete':
                await _showDeleteConfirmDialog(category);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Categorías'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshCategories,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red),
                  SizedBox(height: 20),
                  Text('Error al cargar categorías', style: TextStyle(fontSize: 18, color: Colors.red)),
                  SizedBox(height: 10),
                  Text('${snapshot.error}', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshCategories,
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No hay categorías creadas', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  SizedBox(height: 10),
                  Text('Las categorías por defecto se crearán automáticamente', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Agregar Categoría'),
                    onPressed: _showAddCategoryDialog,
                  ),
                ],
              ),
            );
          }

          final categories = snapshot.data!;
          
          return Column(
            children: [
              // Información de categorías por defecto
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categorías del Sistema',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Las categorías "Vinos" y "Chocolates" son parte del sistema por defecto. Puedes editarlas o agregar nuevas categorías.',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de categorías
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return FutureBuilder<List<dynamic>>(
                      future: DatabaseHelper.instance.getProductsByCategory(category.id!),
                      builder: (context, productSnapshot) {
                        final productCount = productSnapshot.hasData ? productSnapshot.data!.length : 0;
                        return _buildCategoryCard(category, productCount);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Agregar Categoría',
        child: Icon(Icons.add),
      ),
    );
  }
}