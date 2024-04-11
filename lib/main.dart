import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TextEditingController _productNameController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  List<Product> _products = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ürün Ekle'),
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_products[index].name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Barkod: ${_products[index].barcode}'),
                Text('Adedi: ${_products[index].quantity}'),
              ],
            ),
            leading:
                Image.memory(Uint8List.fromList(_products[index].image ?? [])),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _showAddProductDialog(context);
            },
            child: Icon(Icons.add),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              _scanAndDecreaseQuantity(context);
            },
            backgroundColor: Colors.red,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ürün Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _productNameController,
                  decoration: InputDecoration(labelText: 'Ürün İsmi'),
                ),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: 'Adedi'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                String barcodeScanResult =
                    await FlutterBarcodeScanner.scanBarcode(
                        '#ff6666', 'İptal', true, ScanMode.BARCODE);

                if (mounted) {
                  Fluttertoast.showToast(
                      msg: 'Barcode: $barcodeScanResult',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      fontSize: 16.0);

                  var image = await _getImage();
                  _saveProduct(_productNameController.text, barcodeScanResult,
                      int.parse(_quantityController.text), image);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Barkod ve Fotoğraf'),
            ),
            TextButton(
              onPressed: () {
                _saveProduct(_productNameController.text, '',
                    int.parse(_quantityController.text), null);
                Navigator.of(context).pop();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return await pickedFile.readAsBytes();
    }
    return [];
  }

  void _saveProduct(
      String productName, String barcode, int quantity, List<int>? image) {
    _products.add(Product(
        name: productName, barcode: barcode, quantity: quantity, image: image));
    setState(() {}); // Widget'i güncellemek için setState kullanılıyor
  }

  void _scanAndDecreaseQuantity(BuildContext context) async {
    String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Cancel', true, ScanMode.BARCODE);

    if (mounted) {
      Fluttertoast.showToast(
          msg: 'Barcode: $barcodeScanResult',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0);

      var product = _products.firstWhere(
          (element) => element.barcode == barcodeScanResult,
          orElse: () =>
              Product(name: '', barcode: '', quantity: 0, image: null));
      if (product.name.isNotEmpty) {
        product.quantity -= 1;
        setState(() {}); // Widget'i güncellemek için setState kullanılıyor
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

class Product {
  String name;
  String barcode;
  int quantity;
  List<int>? image;

  Product(
      {required this.name,
      required this.barcode,
      required this.quantity,
      required this.image});
}
