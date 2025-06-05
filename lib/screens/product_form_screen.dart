// lib/screens/product_form_screen.dart
import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Necesitarás este plugin
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/services/database_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // Producto existente para editar, o null para agregar nuevo

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioVentaController;
  late TextEditingController _costoProduccionController;
  late TextEditingController _stockController;
  late TextEditingController _stockAlertaController;

  Category? _selectedCategory;
  List<Category> _categories = [];
  File? _selectedImageFile; // Para la imagen seleccionada

  bool _isEditing = false;
  bool _isLoadingCategories = true; // Para mostrar un indicador de carga

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    _nombreController = TextEditingController(text: widget.product?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.product?.descripcion ?? '');
    _precioVentaController = TextEditingController(text: widget.product?.precioVenta.toString() ?? '');
    _costoProduccionController = TextEditingController(text: widget.product?.costoProduccion.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _stockAlertaController = TextEditingController(text: widget.product?.stockAlerta.toString() ?? '');

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final categoriesFromDb = await DatabaseHelper.instance.getAllCategories();
      if (!mounted) return; // Verificar si el widget sigue montado
      setState(() {
        _categories = categoriesFromDb;
        if (_isEditing && widget.product?.categoriaId != null) {
          // Intentar encontrar la categoría, si no se encuentra, _selectedCategory será null
          try {
            _selectedCategory = _categories.firstWhere(
              (cat) => cat.id == widget.product!.categoriaId,
            );
          } catch (e) {
            _selectedCategory = null; // La categoría del producto no existe en la lista actual
            print("Advertencia: Categoría ID ${widget.product!.categoriaId} no encontrada.");
          }
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
      print("Error cargando categorías: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar categorías: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioVentaController.dispose();
    _costoProduccionController.dispose();
    _stockController.dispose();
    _stockAlertaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text;
      final descripcion = _descripcionController.text;
      final precioVenta = double.tryParse(_precioVentaController.text) ?? 0.0;
      final costoProduccion = double.tryParse(_costoProduccionController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final stockAlerta = int.tryParse(_stockAlertaController.text) ?? 0;

      String? imagePath = _isEditing ? widget.product?.imagen : null;
      if (_selectedImageFile != null) {
        // TODO: Implementar copiado de imagen a directorio de la app
        // Por ahora, solo usaremos el path temporal (NO RECOMENDADO PARA PRODUCCIÓN)
        // Necesitarías usar path_provider para obtener un directorio seguro
        // y luego copiar el archivo usando dart:io File.copy()
        // Ejemplo conceptual:
        // final appDir = await getApplicationDocumentsDirectory();
        // final fileName = path.basename(_selectedImageFile!.path);
        // final localImage = await _selectedImageFile!.copy('${appDir.path}/$fileName');
        // imagePath = localImage.path;
        imagePath = _selectedImageFile!.path; // Manteniendo la lógica temporal por ahora
      }

      final productToSave = Product(
        id: widget.product?.id,
        nombre: nombre,
        descripcion: descripcion.isNotEmpty ? descripcion : null,
        categoriaId: _selectedCategory?.id,
        precioVenta: precioVenta,
        costoProduccion: costoProduccion,
        stock: stock,
        stockAlerta: stockAlerta,
        imagen: imagePath,
        fechaCreacion: widget.product?.fechaCreacion ?? DateTime.now(),
      );

      try {
        if (_isEditing) {
          await DatabaseHelper.instance.updateProduct(productToSave);
        } else {
          await DatabaseHelper.instance.createProduct(productToSave);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto ${_isEditing ? 'actualizado' : 'guardado'} correctamente!')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar producto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProduct,
            tooltip: 'Guardar Producto',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              _isLoadingCategories
                  ? Center(child: CircularProgressIndicator())
                  : (_categories.isEmpty
                      ? Text('No hay categorías disponibles. Agregue algunas primero.')
                      : DropdownButtonFormField<Category?>( // CORRECCIÓN AQUÍ
                          value: _selectedCategory,
                          decoration: InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                          items: _categories.map((Category category) {
                            return DropdownMenuItem<Category?>( // CORRECCIÓN AQUÍ
                              value: category,
                              child: Text(category.nombre),
                            );
                          }).toList(),
                          onChanged: (Category? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          validator: (value) {
                            // Hacer la categoría opcional si se está editando,
                            // o si realmente puede no tener una categoría.
                            // Si siempre debe tener una, incluso al editar, ajustar esta lógica.
                            if (value == null && !_isEditing) { // Requerido solo al crear
                              return 'Seleccione una categoría';
                            }
                            return null;
                          },
                        )),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioVentaController,
                      decoration: InputDecoration(labelText: 'Precio Venta (\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese precio';
                        final n = double.tryParse(value);
                        if (n == null) return 'Número inválido';
                        if (n <= 0) return 'Debe ser > 0';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _costoProduccionController,
                      decoration: InputDecoration(labelText: 'Costo Producción (\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese costo';
                        final n = double.tryParse(value);
                        if (n == null) return 'Número inválido';
                        if (n < 0) return 'Debe ser >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(labelText: 'Stock Inicial/Actual', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese stock';
                        final n = int.tryParse(value);
                        if (n == null) return 'Número inválido';
                        if (n < 0) return 'Debe ser >= 0';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockAlertaController,
                      decoration: InputDecoration(labelText: 'Stock de Alerta', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese alerta';
                        final n = int.tryParse(value);
                        if (n == null) return 'Número inválido';
                        if (n < 0) return 'Debe ser >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('Imagen del Producto:', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.image_search),
                    label: Text('Seleccionar'),
                    onPressed: _pickImage,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _selectedImageFile != null
                          ? Image.file(_selectedImageFile!, fit: BoxFit.contain)
                          : (widget.product?.imagen != null && widget.product!.imagen!.isNotEmpty && File(widget.product!.imagen!).existsSync()
                              ? Image.file(File(widget.product!.imagen!), fit: BoxFit.contain)
                              : Center(child: Text('Ninguna imagen', textAlign: TextAlign.center))),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Guardar Producto', style: TextStyle(fontSize: 16)),
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // Usar color primario del tema
                  foregroundColor: Colors.white, // Color del texto
                  padding: EdgeInsets.symmetric(vertical: 12)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}