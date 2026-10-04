import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_store.dart';
import '../theme/clay_theme.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRegisterSuccess;
  final VoidCallback onGoToLogin;

  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onRegisterSuccess,
    required this.onGoToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Juan Dela Cruz');
  final TextEditingController _phoneController = TextEditingController(text: '0912 345 6789');
  final TextEditingController _emailController = TextEditingController(text: 'juan@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'secret123');

  bool _showPassword = false;
  bool _useCurrentLocation = true;
  String _selectedBarangay = 'Barangay 1, Sipalay City';

  final List<String> _barangays = const [
    'Barangay 1, Sipalay City',
    'Barangay 2, Sipalay City',
    'Barangay 3, Sipalay City',
    'Barangay 4, Sipalay City',
    'Barangay 5, Sipalay City',
    'Barangay Gil Montilla, Sipalay City',
    'Barangay Cabadiangan, Sipalay City',
    'Barangay Camindangan, Sipalay City',
    'Barangay Canturay, Sipalay City',
    'Barangay Cartagena, Sipalay City',
    'Barangay Cayhagan, Sipalay City',
    'Barangay Mambaroto, Sipalay City',
    'Barangay Manlucahoc, Sipalay City',
    'Barangay Maricalum, Sipalay City',
    'Barangay Nabulao, Sipalay City',
    'Barangay Nauhang, Sipalay City',
    'Barangay San Jose, Sipalay City',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF334155)),
                onPressed: widget.onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(height: 12),

              // Header
              Text(
                'Create Your Account',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join SUNDO and be part of a cleaner and greener Sipalay.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 20),

              // Form
              // 1. Full Name
              _buildFieldLabel('Full Name'),
              const SizedBox(height: 6),
              Container(
                decoration: ClayTheme.input(),
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Juan Dela Cruz',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Mobile Number
              _buildFieldLabel('Mobile Number'),
              const SizedBox(height: 6),
              Container(
                decoration: ClayTheme.input(),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0912 345 6789',
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Email Address
              _buildFieldLabel('Email Address'),
              const SizedBox(height: 6),
              Container(
                decoration: ClayTheme.input(),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'juan@gmail.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Password
              _buildFieldLabel('Password'),
              const SizedBox(height: 6),
              Container(
                decoration: ClayTheme.input(),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 5. Barangay / Address Dropdown
              _buildFieldLabel('Barangay / Address'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: ClayTheme.input(),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBarangay,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          items: _barangays.map((b) {
                            return DropdownMenuItem<String>(
                              value: b,
                              child: Text(b, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBarangay = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // "Use my current location" Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use my current location',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Helps us give accurate updates for your area.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useCurrentLocation,
                      activeThumbColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setState(() => _useCurrentLocation = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create Account Primary Button
              GestureDetector(
                onTap: () async {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final phone = _phoneController.text.trim();
                  final pass = _passwordController.text;

                  if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please complete all required fields.')),
                    );
                    return;
                  }

                  if (pass.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters.')),
                    );
                    return;
                  }

                  await AppStore.setName(name);
                  await AppStore.setEmail(email);
                  await AppStore.setPhone(phone);
                  await AppStore.setBarangay(_selectedBarangay);

                  widget.onRegisterSuccess();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: ClayTheme.buttonPrimary(),
                  child: Center(
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Footer: Already have an account? Log In
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    GestureDetector(
                      onTap: widget.onGoToLogin,
                      child: Text(
                        'Log In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF047857),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF334155),
      ),
    );
  }
}
