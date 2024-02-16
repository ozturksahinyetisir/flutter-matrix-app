import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MaterialApp(
    home: MyHomePage(title: 'Matrix Uygulaması'),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController textEditingController = TextEditingController();
  Color _selectedColor = Colors.blue;
  Color currentColor = Colors.black;
  List<String> itemListGrid = [];
  List<Color> colorListGrid = [];
  List<bool> isFavoriteList = [];
  bool _showingFavorites = false;
  List<String> allItems = [];
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      allItems = prefs.getStringList('itemList') ?? [];
      itemListGrid = List.from(allItems);
      colorListGrid = (prefs.getStringList('colorList') ?? [])
          .map((color) => Color(int.parse(color)))
          .toList();
      isFavoriteList = (prefs.getStringList('isFavoriteList') ?? [])
          .map((isFavorite) => isFavorite == 'true')
          .toList();
    });
  }

  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setStringList('itemList', allItems);
    prefs.setStringList('colorList',
        colorListGrid.map((color) => color.value.toString()).toList());
    prefs.setStringList('isFavoriteList',
        isFavoriteList.map((isFavorite) => isFavorite.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              _showInputDialog();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.star,
              color: Colors.white,
            ),
            onPressed: () {
              _showFavorites();
            },
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: GridView.count(
        scrollDirection: Axis.vertical,
        crossAxisCount: 8,
        shrinkWrap: true,
        children: List.generate(itemListGrid.length, (index) {
          return _buildItem(index);
        }),
      ),
    );
  }

  Widget _buildItem(int index) {
  if (index >= isFavoriteList.length) {
    isFavoriteList.add(false);
  }

  IconData iconData;
  if (itemListGrid[index].length >= 10 &&
      itemListGrid[index].substring(0, 10) == "/data/user") {
    iconData = Icons.image;
  } else if (int.tryParse(itemListGrid[index]) != null) {
    iconData = Icons.onetwothree;
  } else {
    iconData = Icons.text_format;
  }
  return InkWell(
    onTap: () {
      if (itemListGrid[index].length >= 10 &&
          itemListGrid[index].substring(0, 10) == "/data/user") {
        _navigateToDetailPageWithImage(
            itemListGrid[index].toString(), context);
      } else {
        _navigateToDetailPage(index);
      }
    },
    onLongPress: () {
      setState(() {
        if (index < isFavoriteList.length) {
          isFavoriteList[index] = !isFavoriteList[index];
        }
      });
    },
    child: Padding(
      padding: EdgeInsets.all(5.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorListGrid[index],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Container(
            child: Center(
              child: Icon(
                iconData,
                color: Colors.white,
              ),
            ),
          ),
          if (index < isFavoriteList.length && isFavoriteList[index])
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.star,
                color: Colors.yellow,
              ),
            ),
        ],
      ),
    ),
  );
}

  void _showInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Yeni Nesne Ekle'),
          content: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showTextDialog();
                },
                child: Text('Metin Ekle'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showImageDialog();
                },
                child: Text('Resim Ekle'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showIntDialog();
                },
                child: Text('Sayı Ekle'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Metin Ekle'),
          content: Column(
            children: [
              TextField(
                controller: textEditingController,
                decoration: InputDecoration(labelText: 'Metni Girin'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _openColorPicker();
                },
                child: Text('Renk Seçin:'),
              ),
              ElevatedButton(
                onPressed: () {
                  _insertText();
                  Navigator.pop(context);
                },
                child: Text('Ekle'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openColorPicker() async {
    Color? color = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Renk Seçin'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                setState(() {
                  currentColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                _buildColorButton(currentColor);
                Navigator.of(context).pop(currentColor);
              },
            ),
          ],
        );
      },
    );

    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Future<void> _showImageDialog() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      setState(() {
        itemListGrid.add(imageFile.path);
        colorListGrid.add(Colors.grey);
        isFavoriteList.add(false);
        _saveData();
      });

      _navigateToDetailPageWithImage(imageFile.path, context);
    }
  }

  void _showIntDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? numberValue;

        return AlertDialog(
          title: Text('Sayı Ekle'),
          content: Column(
            children: [
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  int? parsedValue = int.tryParse(value);
                  if (parsedValue != null) {
                    setState(() {
                      numberValue = parsedValue;
                    });
                  } else {
                    print("hatalı giriş yaptınız");
                  }
                },
                decoration: InputDecoration(labelText: 'Sayıyı Girin'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _openColorPicker();
                },
                child: Text('Renk Seçin:'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (numberValue != null) {
                    _insertNumber(numberValue!);
                    Navigator.pop(context);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Hata'),
                          content: Text('Geçerli bir tam sayı değeri giriniz.'),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                textEditingController.text = '';
                              },
                              child: Text('Tamam'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('Ekle'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _insertNumber(int number) {
    setState(() {
      itemListGrid.add(number.toString());
      colorListGrid.add(_selectedColor);
      isFavoriteList.add(false);
      _saveData();
    });
  }

  Widget _buildColorButton(Color color) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedColor = color;
        });
      },
      style: ElevatedButton.styleFrom(primary: color),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 9),
            width: 10,
            height: 10,
          ),
        ],
      ),
    );
  }

  void _insertText() {
    setState(() {
      itemListGrid.add(textEditingController.text);
      colorListGrid.add(_selectedColor);
      isFavoriteList.add(false);
      _saveData();
    });
  }

  void _removeItem(int index) {
    setState(() {
      itemListGrid.removeAt(index);
      colorListGrid.removeAt(index);
      isFavoriteList.removeAt(index);
      _saveData();
      Navigator.pop(context);
    });
  }

  void _navigateToDetailPage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          currentColor: colorListGrid[index],
          itemListGrid: [itemListGrid[index]],
          text: itemListGrid[index],
          itemType: itemListGrid[index],
          onDelete: () {
            _removeItem(index);
          },
        ),
      ),
    );
  }

  void _navigateToDetailPageWithImage(String imageFile, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPageWithImage(
          imageFile: imageFile,
        ),
      ),
    );
  }
  void _toggleFavorite(int index) {
    setState(() {
      isFavoriteList[index] = !isFavoriteList[index];
      _saveData();
    });
  }

  void _showFavorites() {
    if (_showingFavorites) {
      setState(() {
        itemListGrid = List.from(allItems); 
        _showingFavorites = false;
      });
    } else {
      List<String> favoriteItems = [];

      for (int i = 0; i < itemListGrid.length; i++) {
        if (isFavoriteList[i]) {
          favoriteItems.add(itemListGrid[i]);
        }
      }

      setState(() {
        itemListGrid = favoriteItems;
        _showingFavorites = true;
      });
    }
  }}

class DetailsPageWithImage extends StatelessWidget {
  final String imageFile;

  const DetailsPageWithImage({Key? key, required this.imageFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details Page'),
      ),
      body: Center(
        child: Image.file(File(imageFile)),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final String text;
  final String itemType;
  final VoidCallback onDelete;
  final List<String> itemListGrid;
  final Color currentColor;

  DetailsPage({
    Key? key,
    required this.currentColor,
    required this.text,
    required this.itemType,
    required this.onDelete,
    required this.itemListGrid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: currentColor,
      appBar: AppBar(
        backgroundColor: currentColor.withOpacity(0.1),
        title: const Text(
          'Details Page',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.black,
            ),
            onPressed: onDelete,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.black,
            height: 4.0,
          ),
        ),
      ),
      body: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}