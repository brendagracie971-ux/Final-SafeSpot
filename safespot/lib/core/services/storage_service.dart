import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Registration Status
  static const String keyRegistered = "registered";

  // Profile Data
  static const String keyName = "name";
  static const String keyContact = "contact";
  static const String keyGender = "gender";
  static const String keyBlood = "blood";
  static const String keyAllergies = "allergies";

  // Save User
  static Future<void> saveUser({
    required String name,
    required String contact,
    required String gender,
    required String blood,
    required String allergies,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(keyName, name);
    await prefs.setString(keyContact, contact);
    await prefs.setString(keyGender, gender);
    await prefs.setString(keyBlood, blood);
    await prefs.setString(keyAllergies, allergies);

    // Mark registration complete
    await prefs.setBool(keyRegistered, true);
  }

  // Check Registration Status
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyRegistered) ?? false;
  }

  // Get Profile Data
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyName);
  }

  static Future<String?> getContact() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyContact);
  }

  static Future<String?> getBlood() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyBlood);
  }

  static Future<String?> getAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAllergies);
  }

  // Development / Testing Reset
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}