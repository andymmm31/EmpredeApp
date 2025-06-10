import 'package:flutter/material.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/services/database_helper.dart';

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

  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) return;

    final newCategory = Category(nombre: _categoryController.text.trim());
    await DatabaseHelper.instance.createCategory(newCategory);
    _categoryController.clear();
    Navigator.of(context).pop(); // Cierra el diálogo
    _refreshCategories();
  }

  Future<void> _deleteCategory(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de que desea eliminar esta categoría? Los productos existentes en esta categoría quedarán como "Sin Categoría".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCategory(id);
      _refreshCategories();
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Añadir Nueva Categoría'),
          content: TextField(
            controller: _categoryController,
            autofocus: true,
            decoration: InputDecoration(hintText: "Nombre de la categoría"),
            onSubmitted: (_) => _addCategory(), // Permite añadir con Enter
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
            ElevatedButton(onPressed: _addCategory, child: Text('Añadir')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Categorías'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No hay categorías.', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Crear la primera categoría'),
                    onPressed: _showAddCategoryDialog,
                  ),
                ],
              ),
            );
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(category.nombre, style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteCategory(category.id!),
                    tooltip: 'Eliminar Categoría',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Añadir Categoría',
        child: Icon(Icons.add),
      ),
    );
  }
}