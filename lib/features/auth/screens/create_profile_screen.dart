import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/screens/home_screen.dart';

// Define the Roles enum here for now (We will move it to a model later)
enum UserRole { architect, shopOwner }

class CreateProfileScreen extends ConsumerStatefulWidget {
  final String phoneNumber; // We pass the verified phone number here

  const CreateProfileScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firmController = TextEditingController();

  // Default role selection
  UserRole _selectedRole = UserRole.architect;

  @override
  void dispose() {
    _nameController.dispose();
    _firmController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show Loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Setting up your account...")),
        );

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        // 1. Determine Role String
        final roleString = _selectedRole == UserRole.architect ? 'architect' : 'shop';

        // 2. Call Repository to Save
        await ref.read(userRepositoryProvider).saveUserProfile(
          user: currentUser,
          name: _nameController.text.trim(),
          firmName: _firmController.text.trim(),
          role: roleString,
        );

        // 3. Success! Navigate to Dashboard
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Created Successfully!")),
        );

        // NAVIGATE TO HOME SCREEN
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Profile"),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Phone Number Display (Read Only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, color: kTextSecondary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Verified Number",
                            style: textTheme.bodySmall?.copyWith(color: kTextSecondary),
                          ),
                          Text(
                            "+91 ${widget.phoneNumber}", // Display the number passed in
                            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // 2. Personal Details
                Text("Personal Details", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    hintText: "e.g. Ankit Goyal",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val!.isEmpty ? "Name is required" : null,
                ),

                const SizedBox(height: 20),

                // Firm Name Input
                TextFormField(
                  controller: _firmController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Firm / Shop Name",
                    hintText: "e.g. Goyal Architects",
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (val) => val!.isEmpty ? "Firm name is required" : null,
                ),

                SizedBox(height: size.height * 0.04),

                // 3. Role Selection (The "Identity" Decision)
                Text("I am an...", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Architect Option
                _buildRoleCard(
                  role: UserRole.architect,
                  title: "Architect / Interior Designer",
                  subtitle: "I refer clients and manage projects.",
                  icon: Icons.architecture,
                ),

                const SizedBox(height: 12),

                // Shop Owner Option
                _buildRoleCard(
                  role: UserRole.shopOwner,
                  title: "Shop Owner / Supplier",
                  subtitle: "I sell materials and track referrals.",
                  icon: Icons.storefront,
                ),

                SizedBox(height: size.height * 0.05),

                // 4. Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    child: const Text("COMPLETE REGISTRATION"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the selection cards
  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.05) : kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor.withOpacity(0.1) : kSurfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? kPrimaryColor : kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }
}