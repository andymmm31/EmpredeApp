import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/services/database_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  ProductFormScreen({this.product});

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  bool _isLoading = false;

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioVentaController;
  late TextEditingController _costoProduccionController;
  late TextEditingController _stockController;
  late TextEditingController _stockAlertaController;

  String? _imagePath;
  int? _selectedCategoryId;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;
    _loadInitialData();
  }

  void _loadInitialData() {
    _categoriesFuture = DatabaseHelper.instance.getAllCategories();

    _nombreController = TextEditingController(text: _isEditMode ? widget.product!.nombre : '');
    _descripcionController = TextEditingController(text: _isEditMode ? widget.product!.descripcion : '');
    _precioVentaController = TextEditingController(text: _isEditMode ? widget.product!.precioVenta.toStringAsFixed(2) : '0.00');
    _costoProduccionController = TextEditingController(text: _isEditMode ? widget.product!.costoProduccion.toStringAsFixed(2) : '0.00');
    _stockController = TextEditingController(text: _isEditMode ? widget.product!.stock.toString() : '0');
    _stockAlertaController = TextEditingController(text: _isEditMode ? widget.product!.stockAlerta.toString() : '0');

    if (_isEditMode) {
      _selectedCategoryId = widget.product!.categoriaId;
      _imagePath = widget.product!.imagen;
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final product = Product(
        id: _isEditMode ? widget.product!.id : null,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
        categoriaId: _selectedCategoryId,
        precioVenta: double.tryParse(_precioVentaController.text) ?? 0.0,
        costoProduccion: double.tryParse(_costoProduccionController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        stockAlerta: int.tryParse(_stockAlertaController.text) ?? 0,
        imagen: _imagePath,
      );

      try {
        if (_isEditMode) {
          await DatabaseHelper.instance.updateProduct(product);
        } else {
          await DatabaseHelper.instance.createProduct(product);
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el producto: $e')),
          );
        }
      }
    }
  }

  Widget _buildCompactNumericField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    bool isInt = false,
  }) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Spacer(),
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
          onPressed: onDecrement,
          splashRadius: 20,
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            keyboardType: isInt ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: UnderlineInputBorder(),
              prefixText: isInt ? '' : '\$ ',
            ),
            validator: (v) {
              if (v == null || v.isEmpty || double.tryParse(v) == null) return 'Inv.';
              return null;
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
          onPressed: onIncrement,
          splashRadius: 20,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _isLoading ? null : _saveForm)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(labelText: 'Descripción (Opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Category>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error al cargar categorías: ${snapshot.error}', style: TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('No hay categorías. Añade una primero.');
                        }
                        return DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          items: snapshot.data!.map((category) => DropdownMenuItem<int>(value: category.id, child: Text(category.nombre))).toList(),
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                          decoration: InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                          validator: (value) => value == null ? 'Seleccione una categoría' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text("Imagen del Producto (Opcional)", style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imagePath != null && _imagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.grey.shade600, size: 40),
                                  const SizedBox(height: 4),
                                  Text("Toca para seleccionar una imagen", style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCompactNumericField(
                      label: 'Precio de Venta',
                      controller: _precioVentaController,
                      onDecrement: () => setState(() => _precioVentaController.text = (double.tryParse(_precioVentaController.text) ?? 0.0 - 0.50).clamp(0.0, 999999).toStringAsFixed(2)),
                      onIncrement: () => setState(() => _precioVentaController.text = (double.tryParse(_precioVentaController.text) ?? 0.0 + 0.50).toStringAsFixed(2)),
                    ),
                    const SizedBox(height: 16),
                    _buildCompactNumericField(
                      label: 'Costo de Producción',
                      controller: _costoProduccionController,
                      onDecrement: () => setState(() => _costoProduccionController.text = (double.tryParse(_costoProduccionController.text) ?? 0.0 - 0.50).clamp(0.0, 999999).toStringAsFixed(2)),
                      onIncrement: () => setState(() => _costoProduccionController.text = (double.tryParse(_costoProduccionController.text) ?? 0.0 + 0.50).toStringAsFixed(2)),
                    ),
                    const SizedBox(height: 16),
                    _buildCompactNumericField(
                      label: 'Stock Actual',
                      controller: _stockController,
                      isInt: true,
                      onDecrement: () => setState(() => _stockController.text = ((int.tryParse(_stockController.text) ?? 0) - 1).clamp(0, 999999).toString()),
                      onIncrement: () => setState(() => _stockController.text = ((int.tryParse(_stockController.text) ?? 0) + 1).toString()),
                    ),
                    const SizedBox(height: 16),
                    _buildCompactNumericField(
                      label: 'Alerta de Stock Bajo',
                      controller: _stockAlertaController,
                      isInt: true,
                      onDecrement: () => setState(() => _stockAlertaController.text = ((int.tryParse(_stockAlertaController.text) ?? 0) - 1).clamp(0, 999999).toString()),
                      onIncrement: () => setState(() => _stockAlertaController.text = ((int.tryParse(_stockAlertaController.text) ?? 0) + 1).toString()),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveForm,
                      child: Text('Guardar Producto'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}