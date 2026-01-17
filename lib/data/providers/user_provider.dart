import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? email;
  String? name;
  
  void setUser(String email, String name) {
    this.email = email;
    this.name = name;
    notifyListeners();
  }
}
