// FutureBuilder => Widget that listens to the future and update the UI as the Future resolves or updates the data
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:groceries/data/categories.dart';

import 'package:http/http.dart' as http;
import 'package:groceries/models/grocery_item.dart';
import 'package:groceries/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // this _loadItems method can be used when we first enter the app with the help of initState
  void _loadItems() async {
    final url = Uri.https(
        'grocery-bdfe1-default-rtdb.firebaseio.com', 'grocery-shopping.json');
    // try => put the code (try the code) which could potenially throw exception ie fail
    try {
      // Here, if we the user have no internet connection try fails
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }
      // print statement can be used to check the format of the response.body without any confusions
      // print(response.body);
      if (response.body == 'null') {
        // some backend return '' (empty string) some return 'null' string
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // decode to convert json data to maybe map
      final Map<String, dynamic> listData = json.decode(response.body);
      // tmp list through which we will update the main grocery items list
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      // updating main list of items by the data in firebase
      setState(() {
        _groceryItems = loadedItems;
        // after items are loaded
        _isLoading = false;
      });
    } catch (error) {
      // if something fails in try
      setState(
        () {
          _error = 'Something went wrong! Please try again later.';
        },
      );
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) return;
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    // removing item from ui (user side)
    setState(() {
      _groceryItems.remove(item);
    });
    // removing item from backend
    final url = Uri.https('grocery-bdfe1-default-rtdb.firebaseio.com',
        'grocery-shopping/${item.id}.json');
    final response = await http.delete(url);
    // if error occured again adding item
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _groceryItems[index].category.color,
                shape: BoxShape.circle,
              ),
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Text(_error!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
