import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();

  File? _profileImage;
  File? _cnicFront;
  File? _cnicBack;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _cityController.text = user.location?.city ?? '';
      _areaController.text = user.location?.area ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      if (type == 'profile') _profileImage = File(picked.path);
      if (type == 'cnic_front') _cnicFront = File(picked.path);
      if (type == 'cnic_back') _cnicBack = File(picked.path);
    });
  }

  Future<String?> _uploadToStorage(String uid, File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child('users/$uid/$path');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{};

      // Profile image
      if (_profileImage != null) {
        updates['profilePhoto'] =
        await _uploadToStorage(user.id, _profileImage!, 'profile.jpg');
      }

      // CNIC images
      if (_cnicFront != null || _cnicBack != null) {
        updates['cnic'] = {
          'frontImage': _cnicFront != null
              ? await _uploadToStorage(user.id, _cnicFront!, 'cnic/front.jpg')
              : user.cnic?.frontImage,
          'backImage': _cnicBack != null
              ? await _uploadToStorage(user.id, _cnicBack!, 'cnic/back.jpg')
              : user.cnic?.backImage,
          'verificationStatus': 'pending',
          'number': user.cnic?.number,
        };
      }

      // Text fields
      if (_emailController.text.isNotEmpty) updates['email'] = _emailController.text.trim();
      if (_cityController.text.isNotEmpty) updates['location.city'] = _cityController.text.trim();
      if (_areaController.text.isNotEmpty) updates['location.area'] = _areaController.text.trim();

      await authProvider.updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & CNIC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (user.profilePhoto != null
                        ? NetworkImage(user.profilePhoto!)
                        : const AssetImage('assets/avatar_placeholder.png')) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _pickImage(ImageSource.gallery, 'profile'),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            CustomTextField(
              controller: TextEditingController(text: user.fullName),
              label: 'Full Name',
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Email
            CustomTextField(
              controller: _emailController,
              label: 'Email',
            ),
            const SizedBox(height: 16),

            // Phone
            CustomTextField(
              controller: TextEditingController(text: user.phoneNumber),
              label: 'Phone Number',
              enabled: false,
            ),
            const SizedBox(height: 16),

            // City
            CustomTextField(
              controller: _cityController,
              label: 'City',
            ),
            const SizedBox(height: 16),

            // Area
            CustomTextField(
              controller: _areaController,
              label: 'Area',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // CNIC Section
            const Text(
              'CNIC Verification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // CNIC Number
            CustomTextField(
              controller: TextEditingController(text: user.cnic?.number ?? ''),
              label: 'CNIC Number',
            ),
            const SizedBox(height: 16),

            _imageUploadSection('CNIC Front', 'cnic_front', _cnicFront,
                existingUrl: user.cnic?.frontImage),
            const SizedBox(height: 16),
            _imageUploadSection('CNIC Back', 'cnic_back', _cnicBack,
                existingUrl: user.cnic?.backImage),
            const SizedBox(height: 16),

            Text(
              'Status: ${user.cnic?.verificationStatus ?? 'not submitted'}',
              style: TextStyle(
                color: user.cnic?.verificationStatus == 'verified'
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: 'Save Changes',
              onPressed: _saveProfile,
              isLoading: _isSaving,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageUploadSection(String label, String type, File? file,
      {String? existingUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  image: file != null
                      ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                      : (existingUrl != null
                      ? DecorationImage(image: NetworkImage(existingUrl), fit: BoxFit.cover)
                      : null),
                ),
                child: file == null && existingUrl == null
                    ? const Center(child: Text('No image selected'))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: () => _pickImage(ImageSource.gallery, type),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _pickImage(ImageSource.camera, type),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
