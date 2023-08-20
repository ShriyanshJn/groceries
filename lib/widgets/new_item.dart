import 'package:flutter/material.dart';
import 'dart:convert'; // json.

import 'package:http/http.dart' as http;
// all the content provided by this package should be bundled into object http

import 'package:groceries/data/categories.dart';
import 'package:groceries/models/category.dart';
import 'package:groceries/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  // We are using _isSending to avoid multiple requests EG: The user clicks in add item many items (So, we disable the button after it is clicked while we are sending data)
  var _isSending = false;

  // Save item button click
  void _saveItem() async {
    // Validating item
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Now we are sending data to backend
      setState(() {
        _isSending = true;
      });
      // Uri.https('URL FROM FIREBASE','/(SUB FOLDER OF THIS RANDOM NAME WILL BE CREATED IN THE DB)ANY-RANDOM-NAME.JSON')
      final url = Uri.https(
          'grocery-bdfe1-default-rtdb.firebaseio.com', 'grocery-shopping.json');
      // headers : {key : value} => {header identifier : settings for those headers}
      // body : data which should be attached to the outgoing request (in json format)
      // post sends request to server and takes few milliseconds to complete the request and then send the response so it returns Future<Response>
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // encode converts to json formatted text & it needs a data which can easily be converted to json text which is map (map to json)
        body: json.encode({
          // firebase generates unique id for us
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title,
        }),
      );

      //* after getting response

      // response.statusCode tells us if the request suceeded or not
      // response.body gives us the data attached to the response as sent by the server
      // it gives us {key(grocery-shopping) : unique id}

      // mounted means that the Widget has a state
      // not mounted means that the Widget has been disposed or closed
      // We need to use this check as in till we wait for this response,maybe the state of the widget change
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;
      final resData = json.decode(response.body);
      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ), // instead of TextField()
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: category.value.color,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add Item'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
