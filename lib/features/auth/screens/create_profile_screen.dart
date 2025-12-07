import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart'; // Ensure this path is correct
import '../data/user_repository.dart';

enum UserRole { architect, shopOwner }

class CreateProfileScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const CreateProfileScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firmController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  UserRole _selectedRole = UserRole.architect;

  @override
  void dispose() {
    _nameController.dispose();
    _firmController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Creating Enterprise Profile...")),
        );

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final roleString = _selectedRole == UserRole.architect ? 'architect' : 'shop';

        // CALL REPO
        await ref.read(userRepositoryProvider).saveUserProfile(
          user: currentUser,
          name: _nameController.text.trim(),
          firmName: _firmController.text.trim(),
          role: roleString,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
        );

        if (!mounted) return;

        // SUCCESS
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
                // 1. Header Info
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
                          Text("Verified Number", style: textTheme.bodySmall?.copyWith(color: kTextSecondary)),
                          Text("+91 ${widget.phoneNumber}", style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                Text("Personal Details", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // Firm
                TextFormField(
                  controller: _firmController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Firm / Shop Name", prefixIcon: Icon(Icons.business_outlined)),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // Location Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: "City", prefixIcon: Icon(Icons.location_city)),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: "State", prefixIcon: Icon(Icons.map)),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.04),

                Text("I am an...", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _buildRoleCard(
                  role: UserRole.architect,
                  title: "Architect",
                  subtitle: "I refer clients.",
                  icon: Icons.architecture,
                ),
                const SizedBox(height: 12),
                _buildRoleCard(
                  role: UserRole.shopOwner,
                  title: "Shop Owner",
                  subtitle: "I sell materials.",
                  icon: Icons.storefront,
                ),

                SizedBox(height: size.height * 0.05),

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

  Widget _buildRoleCard({required UserRole role, required String title, required String subtitle, required IconData icon}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.05) : kBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? kPrimaryColor : kTextPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: kTextSecondary)),
            ]),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }
}