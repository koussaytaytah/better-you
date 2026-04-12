import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class DoctorOnboardingScreen extends ConsumerStatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  ConsumerState<DoctorOnboardingScreen> createState() =>
      _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState
    extends ConsumerState<DoctorOnboardingScreen> {
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

  Future<void> _submitDoctor() async {
    if (!_formKey.currentState!.validate() ||
        profileImage == null ||
        verificationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload both images'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final profileUrl = await _uploadImage(profileImage, 'doctor_profiles');
      final certUrl = await _uploadImage(
        verificationImage,
        'doctor_certificates',
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'role': 'doctor',
          'specialty': specialty,
          'location': location,
          'profileImageUrl': profileUrl,
          'verificationImageUrl': certUrl,
          'verificationStatus': 'pending', // Admin will review
          'isVerified': false,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted successfully! Waiting for admin approval',
            ),
          ),
        );
        // Go to waiting screen or home
        Navigator.of(context).pushReplacementNamed('/waiting-for-approval');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
      appBar: AppBar(title: const Text('Doctor Onboarding')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete Your Doctor Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Your information will be reviewed by admin'),
              const SizedBox(height: 32),

              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profileImage != null
                        ? FileImage(File(profileImage!.path))
                        : null,
                    child: profileImage == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                decoration: const InputDecoration(
                  labelText:
                      'Specialty (e.g. Cardiologist, General Practitioner, Nutritionist)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => specialty = val,
                validator: (val) =>
                    val!.isEmpty ? 'Specialty is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location (City, Country)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => location = val,
                validator: (val) =>
                    val!.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 24),

              // Verification Document
              const Text(
                'Upload Medical License / Certificate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: verificationImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(verificationImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 50,
                                color: Colors.grey,
                              ),
                              Text('Tap to upload certificate'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: isLoading
                    ? 'Submitting...'
                    : 'Submit for Admin Verification',
                onPressed: isLoading ? null : _submitDoctor,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
