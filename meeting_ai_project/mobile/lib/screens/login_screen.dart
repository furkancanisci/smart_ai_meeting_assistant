import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // MainContainer'a erişim için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLogin = true; // Login mi Register mı?
  bool _isLoading = false;
  
  // Controller'lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (!_isLogin && name.isEmpty) return;

    setState(() => _isLoading = true);

    bool success = false;
    String? errorMessage;

    if (_isLogin) {
      // GİRİŞ YAP
      success = await _apiService.login(email, password);
      if (!success) errorMessage = "Giriş başarısız. Bilgileri kontrol edin.";
    } else {
      // KAYIT OL
      success = await _apiService.register(name, email, password);
      if (success) {
        // Kayıt başarılıysa otomatik giriş yap
        success = await _apiService.login(email, password);
      } else {
        errorMessage = "Kayıt olunamadı. Email kullanımda olabilir.";
      }
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Başarılı -> Ana Sayfaya Git
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MainContainer())
      );
    } else if (mounted && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LOGO & BAŞLIK
                  const Center(
                    child: Icon(Icons.graphic_eq, size: 60, color: Color(0xFF6C63FF)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _isLogin ? "Tekrar Hoşgeldin!" : "Hesap Oluştur",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
                    ),
                  ),
                  Center(
                    child: Text(
                      _isLogin ? "Toplantılarını yönetmek için giriş yap." : "Smart ile toplantılarını asiste et.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // FORM ALANLARI
                  if (!_isLogin) ...[
                    _buildTextField(_nameController, "Ad Soyad", Icons.person_outline),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(_emailController, "E-posta", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, "Şifre", Icons.lock_outline, isPassword: true),
                  
                  const SizedBox(height: 30),

                  // BUTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLogin ? "Giriş Yap" : "Kayıt Ol",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),

                  // ALT METİN (Giriş/Kayıt Geçişi)
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Hesabın yok mu?" : "Zaten üye misin?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Kayıt Ol" : "Giriş Yap",
                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
