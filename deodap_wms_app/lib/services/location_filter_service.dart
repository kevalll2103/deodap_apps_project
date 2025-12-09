import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationFilterService {
  static const String _selectedLocationKey = 'selected_physical_location';
  static const String _locationsKey = 'stock_physical_locations';

  // Save the selected physical location
  static Future<void> saveSelectedLocation(String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLocationKey, location);
      print('LocationFilterService: Saved selected location: "$location"');
    } catch (e) {
      print('LocationFilterService: Error saving selected location: $e');
    }
  }

  // Get the selected physical location
  static Future<String> getSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final location = prefs.getString(_selectedLocationKey) ?? '';
      print('LocationFilterService: Retrieved selected location: "$location"');
      return location;
    } catch (e) {
      print('LocationFilterService: Error getting selected location: $e');
      return '';
    }
  }

  // Clear the selected physical location
  static Future<void> clearSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedLocationKey);
      print('LocationFilterService: Cleared selected location');
    } catch (e) {
      print('LocationFilterService: Error clearing selected location: $e');
    }
  }

  // Save available locations (from profile API)
  static Future<void> saveAvailableLocations(List<String> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_locationsKey, locations);
      print('LocationFilterService: Saved ${locations.length} available locations');
    } catch (e) {
      print('LocationFilterService: Error saving available locations: $e');
    }
  }

  // Get available locations
  static Future<List<String>> getAvailableLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locations = prefs.getStringList(_locationsKey) ?? [];
      print('LocationFilterService: Retrieved ${locations.length} available locations');
      return locations;
    } catch (e) {
      print('LocationFilterService: Error getting available locations: $e');
      return [];
    }
  }

  // Check if a location filter is active
  static Future<bool> isLocationFilterActive() async {
    final location = await getSelectedLocation();
    return location.isNotEmpty;
  }

  // Get location display name (empty -> "All Locations")
  static Future<String> getLocationDisplayName() async {
    final location = await getSelectedLocation();
    return location.isEmpty ? 'All Locations' : location;
  }
}