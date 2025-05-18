import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';


class UserProfile {
  final String id;
  String? fullName;
  String? email;
  String? profileImageUrl;
  int? age;
  String? gender;
  double? height;
  double? weight;

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.profileImageUrl,
    this.age,
    this.gender,
    this.height,
    this.weight,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      age: json['age'],
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_image_url': profileImageUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }
}

class UserProfileProvider with ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      _profile = UserProfile.fromJson(response);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Updating profile in database');
      debugPrint('Profile data: ${updatedProfile.toJson()}');

      await Supabase.instance.client
          .from('users')
          .update(updatedProfile.toJson())
          .eq('id', user.id);

      _profile = updatedProfile;
      _error = null;
      debugPrint('Profile updated in database successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadProfileImage(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      debugPrint('Starting image upload for user: ${user.id}');
      debugPrint('Image path: $imagePath');

      final file = File(imagePath);
      final fileExt = imagePath.split('.').last;
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName; // Simplified path

      debugPrint('Uploading to path: $filePath');

      try {
        // Upload the file
        final uploadResponse = await Supabase.instance.client.storage
            .from('users')
            .upload(filePath, file);

        debugPrint('Upload response: $uploadResponse');

        if (uploadResponse == null) {
          throw Exception('Failed to upload image');
        }

        // Get the public URL
        final imageUrl = Supabase.instance.client.storage
            .from('users')
            .getPublicUrl(filePath);

        debugPrint('Generated image URL: $imageUrl');

        // Update the profile with the new image URL
        if (_profile != null) {
          debugPrint('Updating profile with new image URL');
          _profile!.profileImageUrl = imageUrl;
          await updateProfile(_profile!);
          debugPrint('Profile updated successfully');
        } else {
          debugPrint('Profile is null, cannot update');
        }
      } catch (e) {
        debugPrint('Error in upload process: $e');
        if (e is StorageException) {
          debugPrint('Storage error details: ${e.message}');
          debugPrint('Storage error status code: ${e.statusCode}');
        }
        rethrow;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error uploading profile image: $e');
      if (e is StorageException) {
        debugPrint('Storage error details: ${e.message}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
