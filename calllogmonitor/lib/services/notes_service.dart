import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const String _notesKey = 'call_notes';

  // Get notes for a specific phone number
  static Future<String> getNotes(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '{}';
      final Map<String, dynamic> allNotes = jsonDecode(notesJson);
      return allNotes[phoneNumber] ?? '';
    } catch (e) {
      return '';
    }
  }

  // Save notes for a specific phone number
  static Future<bool> saveNotes(String phoneNumber, String notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '{}';
      final Map<String, dynamic> allNotes = jsonDecode(notesJson);
      
      if (notes.trim().isEmpty) {
        allNotes.remove(phoneNumber);
      } else {
        allNotes[phoneNumber] = notes.trim();
      }
      
      await prefs.setString(_notesKey, jsonEncode(allNotes));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all notes
  static Future<Map<String, String>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '{}';
      final Map<String, dynamic> allNotes = jsonDecode(notesJson);
      return allNotes.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  // Delete notes for a specific phone number
  static Future<bool> deleteNotes(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey) ?? '{}';
      final Map<String, dynamic> allNotes = jsonDecode(notesJson);
      allNotes.remove(phoneNumber);
      await prefs.setString(_notesKey, jsonEncode(allNotes));
      return true;
    } catch (e) {
      return false;
    }
  }
}