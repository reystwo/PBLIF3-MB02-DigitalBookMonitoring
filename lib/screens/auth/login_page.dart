import 'package:flutter/material.dart';
import 'package:digital_book_connect/config/api_config.dart';
import 'package:digital_book_connect/main.dart';
import 'package:digital_book_connect/screens/admin/admin_main_page.dart';
import 'package:digital_book_connect/screens/guru/guru_main_page.dart';
import 'package:digital_book_connect/screens/orang_tua/orang_tua_main_page.dart';
import 'package:digital_book_connect/services/app_repository.dart';

enum UserRole {
  guru('Guru', Icons.school_outlined),
  orangTua('Orang Tua / Wali', Icons.family_restroom_outlined),
  admin('Admin', Icons.admin_panel_settings_outlined);

  final String label;
  final IconData icon;
  const UserRole(this.label, this.icon);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.guru;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showServerSettingsDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _ServerSettingsDialog(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server API diatur ke: $result'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final roleStr = switch (_selectedRole) {
      UserRole.guru => 'guru',
      UserRole.orangTua => 'orang_tua',
      UserRole.admin => 'admin',
    };

    final response = await AppRepository.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      role: roleStr,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.isSuccess) {
      final user = response.data;
      final role = user?.role ?? roleStr;

      final Widget dashboard = switch (role) {
        'guru' => const GuruMainPage(),
        'orang_tua' => const OrangTuaMainPage(),
        'admin' => const AdminMainPage(),
        _ => switch (_selectedRole) {
          UserRole.guru => const GuruMainPage(),
          UserRole.orangTua => const OrangTuaMainPage(),
          UserRole.admin => const AdminMainPage(),
        },
      };

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => dashboard),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hiasan lingkaran hijau di pojok kiri atas (identik dengan HomePage)
          Positioned(top: -70, left: -90, child: _blob(220, AppColors.blob)),
          Positioned(top: -30, left: -40, child: _blob(140, AppColors.blobSoft)),
          // Hiasan lingkaran hijau di pojok kanan bawah (identik dengan HomePage)
          Positioned(bottom: -80, right: -80, child: _blob(200, AppColors.blob)),
          Positioned(bottom: -30, right: -30, child: _blob(120, AppColors.blobSoft)),

          // Konten utama
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Baris atas: Tombol Kembali & Pengaturan Server API
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        InkWell(
                          key: const Key('serverSettingsButton'),
                          onTap: _showServerSettingsDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Tooltip(
                              message: 'Pengaturan Server API',
                              child: Icon(
                                Icons.settings_ethernet_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Logo: buku terbuka + daun (identik dengan HomePage)
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Icon(Icons.menu_book_rounded, size: 80, color: AppColors.primary),
                          Positioned(
                            top: 8,
                            child: Icon(Icons.eco, size: 26, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selamat Datang Kembali',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Silakan masuk dengan akun Anda untuk melanjutkan akses ke Buku Penghubung.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // Pemilihan Role
                    const Text(
                      'Pilih Peran / Role',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RoleSelector(
                      selectedRole: _selectedRole,
                      onRoleSelected: (role) {
                        setState(() {
                          _selectedRole = role;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Form Input Username
                    const Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan username',
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Form Input Password
                    const Text(
                      'Kata Sandi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi',
                        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Tombol Masuk
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Masuk',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.login_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// Komponen Pemilihan Role
class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleSelected;

  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = role == selectedRole;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => onRoleSelected(role),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      role.icon,
                      size: 26,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ServerSettingsDialog extends StatefulWidget {
  const _ServerSettingsDialog();

  @override
  State<_ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<_ServerSettingsDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _testMessage;
  bool? _isSuccess;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTest() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _isSuccess = null;
    });

    final ok = await ApiConfig.testConnection(url);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isSuccess = ok;
      _testMessage = ok
          ? 'Koneksi Berhasil! Server Laravel terjangkau (status: ok)'
          : 'Gagal terhubung ke server. Pastikan server menyala (php artisan serve --host=0.0.0.0) atau kabel USB terpasang.';
    });
  }

  Future<void> _handleAutoDetect() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _isSuccess = null;
    });

    await ApiConfig.resetBaseUrl();
    final discovered = await ApiConfig.discoverWorkingBaseUrl();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      if (discovered != null) {
        _controller.text = discovered;
        _isSuccess = true;
        _testMessage = 'Server aktif berhasil dideteksi: $discovered';
      } else {
        _controller.text = ApiConfig.baseUrl;
        _isSuccess = false;
        _testMessage = 'Tidak ada kandidat server yang merespons. Gunakan alamat manual.';
      }
    });
  }

  Future<void> _handleSave() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    await ApiConfig.setCustomBaseUrl(url);
    if (!mounted) return;
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_ethernet_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pengaturan Server API',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Alamat Base URL Laravel backend untuk HP fisik, emulator, atau browser:',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              style: const TextStyle(fontSize: 13.5, fontFamily: 'monospace'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link, size: 18, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => _controller.clear(),
                ),
                hintText: 'http://192.168.1.7:8000/api',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pilihan Cepat:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildQuickChip('USB (127.0.0.1)', 'http://127.0.0.1:8000/api'),
                _buildQuickChip('Wi-Fi (192.168.1.7)', 'http://192.168.1.7:8000/api'),
                _buildQuickChip('Emulator (10.0.2.2)', 'http://10.0.2.2:8000/api'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _handleTest,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check_rounded, size: 16),
                    label: const Text('Tes Koneksi', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _handleAutoDetect,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Auto Detect', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isSuccess ?? false)
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_isSuccess ?? false)
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (_isSuccess ?? false)
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: (_isSuccess ?? false)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: (_isSuccess ?? false)
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: AppColors.textGrey)),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Simpan URL'),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, String url) {
    final isCurrent = _controller.text == url;
    return InkWell(
      onTap: () {
        setState(() {
          _controller.text = url;
          _testMessage = null;
          _isSuccess = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.primary : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
