import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_profile_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await context
          .read<UserProfileProvider>()
          .uploadProfileImage(pickedFile.path);
    }
  }

  void _updateControllers(UserProfile profile) {
    _fullNameController.text = profile.fullName ?? '';
    _emailController.text = profile.email ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _selectedGender = profile.gender;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = context.read<UserProfileProvider>().profile;
      if (profile != null) {
        final updatedProfile = UserProfile(
          id: profile.id,
          fullName: _fullNameController.text,
          email: _emailController.text,
          profileImageUrl: profile.profileImageUrl,
          age: int.tryParse(_ageController.text),
          gender: _selectedGender,
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
        );

        await context.read<UserProfileProvider>().updateProfile(updatedProfile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.error != null) {
          return Center(
            child: Text('Error: ${profileProvider.error}'),
          );
        }

        final profile = profileProvider.profile;
        if (profile != null) {
          _updateControllers(profile);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProfile,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          child: profile?.profileImageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profile!.profileImageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    memCacheHeight: 200,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint('Error loading image: $error');
                                      debugPrint('Failed URL: $url');

                                      // Try to load the image directly
                                      http.get(Uri.parse(url)).then((response) {
                                        debugPrint(
                                            'Direct image load status: ${response.statusCode}');
                                        if (response.statusCode == 200) {
                                          debugPrint(
                                              'Image loaded successfully');
                                          debugPrint(
                                              'Content-Type: ${response.headers['content-type']}');
                                        } else {
                                          debugPrint(
                                              'Failed to load image: ${response.body}');
                                        }
                                      }).catchError((e) {
                                        debugPrint(
                                            'Direct image load error: $e');
                                      });

                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, size: 50),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
