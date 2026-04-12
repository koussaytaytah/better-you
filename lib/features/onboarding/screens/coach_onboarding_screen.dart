import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class CoachOnboardingScreen extends ConsumerStatefulWidget {
  const CoachOnboardingScreen({super.key});

  @override
  ConsumerState<CoachOnboardingScreen> createState() =>
      _CoachOnboardingScreenState();
}

class _CoachOnboardingScreenState extends ConsumerState<CoachOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? specialty;
  String? location;
  XFile? profileImage;
  XFile? verificationImage;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          profileImage = image;
        } else {
          verificationImage = image;
        }
      });
    }
  }

  Future<String?> _uploadImage(XFile? file, String folder) async {
    if (file == null) return null;
    final ref = FirebaseStorage.instance.ref().child(
      '$folder/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      await ref.putFile(File(file.path));
      return await ref.getDownloadURL();
    }
  }

  Future<void> _submitCoach() async {
    if (!_formKey.currentState!.validate() ||
        profileImage == null ||
        verificationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload images'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final profileUrl = await _uploadImage(profileImage, 'coach_profiles');
      final certUrl = await _uploadImage(
        verificationImage,
        'coach_certificates',
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'role': 'coach',
          'specialty': specialty,
          'location': location,
          'profileImageUrl': profileUrl,
          'verificationImageUrl': certUrl,
          'verificationStatus':
              'pending', // admin will change to approved/rejected
          'isVerified': false,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted! Waiting for admin approval'),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/waiting'); // or home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Onboarding')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: () => _pickImage(true),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImage != null
                      ? FileImage(File(profileImage!.path))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Specialty (e.g. Fitness Trainer, Nutritionist)',
                ),
                onChanged: (val) => specialty = val,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location (City, Country)',
                ),
                onChanged: (val) => location = val,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Verification Document
              const Text(
                'Upload Certificate / License',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: verificationImage != null
                      ? Image.file(
                          File(verificationImage!.path),
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Text('Tap to upload image')),
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: isLoading ? 'Submitting...' : 'Submit for Verification',
                onPressed: isLoading ? null : _submitCoach,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
