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
  bool _agreeTerms = true;
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 24, color: Color(0xFF0F172A)),
                onPressed: widget.onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(height: 14),

              // Mockup Header: Getting Started / Create an account to continue!
              Text(
                'Getting Started',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create an account to continue!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 24),

              // 1. Full Name Molded Clay Input
              Container(
                decoration: ClayTheme.input(radius: 18),
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Full Name',
                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Phone Number Molded Clay Input
              Container(
                decoration: ClayTheme.input(radius: 18),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Phone Number',
                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Email Address Molded Clay Input
              Container(
                decoration: ClayTheme.input(radius: 18),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Email Address',
                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Password Molded Clay Input with Eye Toggle
              Container(
                decoration: ClayTheme.input(radius: 18),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Password',
                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13.5),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 5. Barangay / Address Molded Clay Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: ClayTheme.input(radius: 18),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBarangay,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
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

              // 6. Terms & Conditions Toggle Row (Matching Mockup Right Screen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 38,
                    height: 24,
                    child: Switch(
                      value: _agreeTerms,
                      activeTrackColor: const Color(0xFF059669),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() => _agreeTerms = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(text: 'By creating an account, you agree to our '),
                          TextSpan(
                            text: 'Terms',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Conditions',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location Option Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: ClayTheme.insetBox(radius: 14),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Accurate GPS location for collection updates',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: Switch(
                        value: _useCurrentLocation,
                        activeTrackColor: const Color(0xFF059669),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() => _useCurrentLocation = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 7. Primary Inflated Clay Button: Sign Up
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

                  if (!_agreeTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please agree to the Terms and Conditions.')),
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
                  decoration: ClayTheme.buttonPrimary(radius: 20),
                  child: Center(
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 8. Footer: Already have an account? Login
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onGoToLogin,
                      child: Text(
                        'Login',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 9. "Or continue with" Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or continue with',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),

              const SizedBox(height: 16),

              // 10. Secondary Inflated Clay Button: Continue with Google
              GestureDetector(
                onTap: widget.onRegisterSuccess,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: ClayTheme.buttonSecondary(radius: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(20, 20),
                        painter: _GoogleIconPainter(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final double radius = w / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4)..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..strokeWidth = 3.0..style = PaintingStyle.stroke;
    final redPaint = Paint()..color = const Color(0xFFEA4335)..strokeWidth = 3.0..style = PaintingStyle.stroke;

    final rect = Rect.fromCircle(center: center, radius: radius - 1.5);
    const pi = 3.141592653589793;

    canvas.drawArc(rect, -pi / 4, pi / 2, false, bluePaint);
    canvas.drawArc(rect, pi / 4, pi / 2, false, greenPaint);
    canvas.drawArc(rect, 3 * pi / 4, pi / 2, false, yellowPaint);
    canvas.drawArc(rect, 5 * pi / 4, pi / 2, false, redPaint);

    final fillBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.42, w * 0.48, 3.0), fillBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
