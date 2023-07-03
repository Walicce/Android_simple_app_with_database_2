import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Database> _database;
  late List<Phone> _phoneList = [];
  bool _isEditing = false;
  Phone? _selectedPhone;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'phone_list.db');

    _database = openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE phones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            manufacturer TEXT,
            model TEXT,
            softwareVersion TEXT,
            image TEXT
          )
          ''',
        );
      },
    );

    _refreshPhoneList();
  }

  Future<void> _refreshPhoneList() async {
    final database = await _database;
    final phones = await database.query('phones');
    setState(() {
      _phoneList = phones.map((phoneData) => Phone.fromMap(phoneData)).toList();
    });
  }

  Future<void> _addPhone(Phone phone) async {
    final database = await _database;
    await database.insert('phones', phone.toMap());
    _refreshPhoneList();
  }

  Future<void> _updatePhone(Phone phone) async {
    final database = await _database;
    await database.update(
      'phones',
      phone.toMap(),
      where: 'id = ?',
      whereArgs: [phone.id],
    );
    _refreshPhoneList();
  }

  Future<void> _deletePhone(Phone phone) async {
    final database = await _database;
    await database.delete(
      'phones',
      where: 'id = ?',
      whereArgs: [phone.id],
    );
    _refreshPhoneList();
  }

  Future<void> _deleteAllPhones() async {
    final database = await _database;
    await database.delete('phones');
    _refreshPhoneList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone List'),
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _phoneList.length,
              itemBuilder: (context, index) {
                final phone = _phoneList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(phone.image),
                  ),
                  title: Text('${phone.manufacturer} ${phone.model}'),
                  subtitle: Text('Software Version: ${phone.softwareVersion}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                            _selectedPhone = phone;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePhone(phone),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isEditing && _selectedPhone != null)
            Expanded(
              child: AddEditPhoneDialog(
                phone: _selectedPhone,
                onSave: (updatedPhone) async {
                  await _updatePhone(updatedPhone);
                  setState(() {
                    _isEditing = false;
                    _selectedPhone = null;
                  });
                },
                onCancel: () {
                  setState(() {
                    _isEditing = false;
                    _selectedPhone = null;
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddPhoneDialog(context),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: const Text('Delete All'),
              onPressed: () => _deleteAllPhones(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPhoneDialog(BuildContext context) async {
    final newPhone = await showDialog<Phone>(
      context: context,
      builder: (BuildContext dialogContext) => AddEditPhoneDialog(onSave: (Phone ) {  }, onCancel: () {  },),
    );

    if (newPhone != null) {
      await _addPhone(newPhone);
    }
  }
}

class Phone {
  final int id;
  final String manufacturer;
  final String model;
  final String softwareVersion;
  final String image;

  Phone({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.softwareVersion,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'softwareVersion': softwareVersion,
      'image': image,
    };
  }

  factory Phone.fromMap(Map<String, dynamic> map) {
    return Phone(
      id: map['id'],
      manufacturer: map['manufacturer'],
      model: map['model'],
      softwareVersion: map['softwareVersion'],
      image: map['image'],
    );
  }
}

class AddEditPhoneDialog extends StatefulWidget {
  final Phone? phone;
  final Function(Phone) onSave;
  final VoidCallback onCancel;

  AddEditPhoneDialog({
    this.phone,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _AddEditPhoneDialogState createState() => _AddEditPhoneDialogState();
}

class _AddEditPhoneDialogState extends State<AddEditPhoneDialog> {
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  late TextEditingController _softwareVersionController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _manufacturerController = TextEditingController();
    _modelController = TextEditingController();
    _softwareVersionController = TextEditingController();
    _imageController = TextEditingController();

    if (widget.phone != null) {
      _manufacturerController.text = widget.phone!.manufacturer;
      _modelController.text = widget.phone!.model;
      _softwareVersionController.text = widget.phone!.softwareVersion;
      _imageController.text = widget.phone!.image;
    }
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _softwareVersionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.phone == null ? 'Add Phone' : 'Edit Phone'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _manufacturerController,
              decoration: const InputDecoration(labelText: 'Manufacturer'),
            ),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            TextField(
              controller: _softwareVersionController,
              decoration: const InputDecoration(labelText: 'Software Version'),
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Image'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: widget.onCancel,
        ),
        TextButton(
          child: Text(widget.phone == null ? 'Add' : 'Save'),
          onPressed: () {
            final manufacturer = _manufacturerController.text;
            final model = _modelController.text;
            final softwareVersion = _softwareVersionController.text;
            final image = _imageController.text;

            final updatedPhone = Phone(
              id: widget.phone?.id ?? DateTime.now().microsecondsSinceEpoch,
              manufacturer: manufacturer,
              model: model,
              softwareVersion: softwareVersion,
              image: image,
            );

            widget.onSave(updatedPhone);
          },
        ),
      ],
    );
  }
}
