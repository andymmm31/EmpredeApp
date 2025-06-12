// lib/screens/product_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/screens/category_management_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Los controladores ahora se inicializan en initState
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioVentaController;
  late TextEditingController _precioCompraController; // CORREGIDO: Renombrado
  late TextEditingController _stockController;
  late TextEditingController _stockAlertaController;

  String? _imagePath;
  int? _selectedCategoryId;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final productToEdit = widget.product;
    final isEditMode = productToEdit != null;

    _categoriesFuture = DatabaseHelper.instance.getAllCategories();
    
    // Inicialización de controladores
    _nombreController = TextEditingController(text: isEditMode ? productToEdit.nombre : '');
    _descripcionController = TextEditingController(text: isEditMode ? productToEdit.descripcion : '');
    _precioVentaController = TextEditingController(text: isEditMode ? productToEdit.precioVenta.toStringAsFixed(2) : '0.00');
    // CORREGIDO: Se usa precioCompra en lugar de costoProduccion
    _precioCompraController = TextEditingController(text: isEditMode ? productToEdit.precioCompra.toStringAsFixed(2) : '0.00');
    _stockController = TextEditingController(text: isEditMode ? productToEdit.stock.toString() : '0');
    _stockAlertaController = TextEditingController(text: isEditMode ? productToEdit.stockAlerta.toString() : '5'); // Valor por defecto sensato

    if (isEditMode) {
      _selectedCategoryId = productToEdit.categoriaId;
      _imagePath = productToEdit.imagen;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioVentaController.dispose();
    _precioCompraController.dispose();
    _stockController.dispose();
    _stockAlertaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final product = Product(
        id: widget.product?.id, // Forma segura de obtener el ID
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isNotEmpty ? _descripcionController.text.trim() : null,
        categoriaId: _selectedCategoryId,
        precioVenta: double.tryParse(_precioVentaController.text) ?? 0.0,
        // CORREGIDO: Se usa precioCompra
        precioCompra: double.tryParse(_precioCompraController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        stockAlerta: int.tryParse(_stockAlertaController.text) ?? 5,
        imagen: _imagePath,
      );

      try {
        if (widget.product != null) { // Si estamos en modo edición
          await DatabaseHelper.instance.updateProduct(product);
        } else {
          await DatabaseHelper.instance.createProduct(product);
        }
        if (mounted) Navigator.of(context).pop(true); // Devuelve true para indicar éxito
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _isLoading ? null : _saveForm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción (Opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FutureBuilder<List<Category>>(
                            future: _categoriesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Text('Error al cargar categorías', style: TextStyle(color: Colors.red));
                              }
                              final categories = snapshot.data ?? [];
                              return DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                items: categories.map((category) => DropdownMenuItem<int>(value: category.id, child: Text(category.nombre))).toList(),
                                onChanged: (value) => setState(() => _selectedCategoryId = value),
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  border: const OutlineInputBorder(),
                                  hintText: categories.isEmpty ? 'Añade una categoría' : 'Seleccionar',
                                ),
                                validator: (value) => value == null ? 'Seleccione una categoría' : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: IconButton(
                            icon: Icon(Icons.settings, color: Theme.of(context).primaryColor),
                            tooltip: 'Gestionar Categorías',
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                              );
                              setState(() {
                                _categoriesFuture = DatabaseHelper.instance.getAllCategories();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text("Imagen del Producto (Opcional)", style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: _imagePath != null && _imagePath!.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_imagePath!), fit: BoxFit.cover))
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
                    // CORREGIDO: Se usa el controlador y la etiqueta correcta
                    _buildCompactNumericField(
                      label: 'Precio de Compra',
                      controller: _precioCompraController,
                      onDecrement: () => setState(() => _precioCompraController.text = (double.tryParse(_precioCompraController.text) ?? 0.0 - 0.50).clamp(0.0, 999999).toStringAsFixed(2)),
                      onIncrement: () => setState(() => _precioCompraController.text = (double.tryParse(_precioCompraController.text) ?? 0.0 + 0.50).toStringAsFixed(2)),
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar Producto'),
                    ),
                  ],
                ),
              ),
            ),
    );
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
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
          onPressed: onDecrement,
          splashRadius: 20,
        ),
        SizedBox(
          width: 100,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            keyboardType: isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: const UnderlineInputBorder(),
              prefixText: isInt ? '' : '\$ ',
            ),
            validator: (v) {
              if (v == null || v.isEmpty || double.tryParse(v) == null) return 'Inv.';
              return null;
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
          onPressed: onIncrement,
          splashRadius: 20,
        ),
      ],
    );
  }
}