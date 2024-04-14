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
  TextEditingController _priceController = TextEditingController();
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
                Text('Fiyatı: ${_products[index].price.toStringAsFixed(2)} TL',
                    style: TextStyle(color: Colors.green)),
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
              _scanBarcodes(context);
            },
            backgroundColor: Colors.red,
            child: Icon(Icons.camera_alt),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              _addProduct(context);
            },
            backgroundColor: Colors.green,
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _addProduct(BuildContext context) {
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
                TextField(
                  controller: _priceController,
                  decoration:
                      InputDecoration(labelText: 'Fiyat (TL)', prefixText: '₺'),
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
                  _saveProduct(
                      _productNameController.text,
                      barcodeScanResult,
                      int.parse(_quantityController.text),
                      double.parse(_priceController.text),
                      image);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Barkod ve Fotoğraf'),
            ),
            TextButton(
              onPressed: () {
                _saveProduct(
                    _productNameController.text,
                    '',
                    int.parse(_quantityController.text),
                    double.parse(_priceController.text),
                    null);
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

  void _saveProduct(String productName, String barcode, int quantity,
      double price, List<int>? image) {
    _products.add(Product(
        name: productName,
        barcode: barcode,
        quantity: quantity,
        price: price,
        image: image));
    setState(() {}); // Widget'i güncellemek için setState kullanılıyor
  }

  void _scanBarcodes(BuildContext context) async {
    List<Product> scannedProducts = [];

    while (true) {
      String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);

      if (barcodeScanResult == '-1') {
        break;
      }

      if (mounted) {
        Fluttertoast.showToast(
            msg: 'Barcode: $barcodeScanResult',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            fontSize: 16.0);

        var product = _findProduct(barcodeScanResult);
        if (product != null) {
          scannedProducts.add(product);
        }
      }
    }

    _showScannedResults(context, scannedProducts);
  }

  Product? _findProduct(String barcode) {
    return _products.firstWhere(
      (product) => product.barcode == barcode,
      orElse: () => Product(
        name: '',
        barcode: '',
        quantity: 0,
        price: 0.0,
        image: null,
      ),
    );
  }

  void _showScannedResults(
      BuildContext context, List<Product> scannedProducts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sonuçlar'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: scannedProducts.map((product) {
                return ListTile(
                  title: Text('Ürün: ${product.name}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barkod: ${product.barcode}'),
                      Text('Fiyat: ${product.price.toString()} TL'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                scannedProducts.forEach((product) {
                  product.quantity--;
                });
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

class Product {
  String name;
  String barcode;
  int quantity;
  double price;
  List<int>? image;

  Product(
      {required this.name,
      required this.barcode,
      required this.quantity,
      required this.price,
      required this.image});
}
