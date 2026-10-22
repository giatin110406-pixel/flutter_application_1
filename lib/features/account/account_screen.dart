import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/student_api.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.api});

  final StudentApi api;

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  static const _uehGreen = Color(0xFF006B78);
  static const _uehWifiPortalUrl =
      'http://172.21.192.1/login?dst=http%3A%2F%2Fwww.msftconnecttest.com%2Fredirect';

  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  StudentProfile? _profile;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      if (await widget.api.hasSession()) {
        final profile = await widget.api.getStudentInfo();
        if (mounted) setState(() => _profile = profile);
      }
    } on ApiException catch (error) {
      if (mounted && !error.message.contains('đăng nhập lại')) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể kết nối máy chủ.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) ||
        connectivity.isEmpty) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error =
              'Bạn chưa có kết nối Internet. Hãy kết nối Wi‑Fi UEH để tiếp tục.';
        });
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.api.login(
        mssv: _studentIdController.text,
        password: _passwordController.text,
      );
      final profile = await widget.api.getStudentInfo();
      if (mounted) {
        setState(() {
          _profile = profile;
          _passwordController.clear();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể kết nối máy chủ.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openWifiPortal() async {
    final uri = Uri.parse(_uehWifiPortalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        setState(
          () => _error =
              'Không thể mở trang kết nối Wi‑Fi UEH. Vui lòng truy cập thủ công: $_uehWifiPortalUrl',
        );
      }
    }
  }

  Future<void> logout() async {
    await widget.api.logout();
    if (mounted) {
      setState(() {
        _profile = null;
        _error = null;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _uehGreen));
    }
    final profile = _profile;
    if (profile != null) return _buildProfile(profile);
    return _buildLoginForm();
  }

  Widget _buildLoginForm() {
    return ColoredBox(
      color: const Color(0xFFF4FAFA),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 923 / 500,
              child: Image.asset('images/ueh_campus.jpg', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Chào mừng đến với UEH',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Nơi đào tạo nhà quản lý và doanh nhân thành đạt',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _studentIdController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  'Tên đăng nhập',
                                  'Nhập tên đăng nhập',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Vui lòng nhập tên đăng nhập.'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => login(),
                                decoration:
                                    _inputDecoration(
                                      'Mật khẩu',
                                      'Nhập mật khẩu',
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Hiện mật khẩu'
                                            : 'Ẩn mật khẩu',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Vui lòng nhập mật khẩu.'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFB3261E)),
                          ),
                          if (_error!.contains('kết nối Internet')) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _openWifiPortal,
                              icon: const Icon(Icons.wifi_tethering_rounded),
                              label: const Text('Kết nối Wi‑Fi UEH'),
                            ),
                          ],
                        ],
                        const SizedBox(height: 32),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _uehGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _isSubmitting ? null : login,
                          child: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ĐĂNG NHẬP'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _uehGreen,
                            side: const BorderSide(color: _uehGreen),
                            minimumSize: const Size.fromHeight(54),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đăng nhập bằng email UEH chưa được hỗ trợ.',
                                  ),
                                ),
                              ),
                          child: const Text('ĐĂNG NHẬP BẰNG EMAIL UEH'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _uehGreen, width: 2),
        ),
      );

  Widget _buildProfile(StudentProfile profile) {
    return ColoredBox(
      color: const Color(0xFFF8F8F8),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 68),
                  height: 384,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF007D89), Color(0xFF004E59)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 58, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'SINH VIÊN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFB8E2E4),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              profile.fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ProfileField(
                                    label: 'NGÀY SINH',
                                    value: profile.formattedBirthDate,
                                  ),
                                ),
                                Expanded(
                                  child: _ProfileField(
                                    label: 'GIỚI TÍNH',
                                    value: profile.isMale ? 'Nam' : 'Nữ',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ProfileField(
                                    label: 'KHÓA',
                                    value: profile.cohort,
                                  ),
                                ),
                                Expanded(
                                  child: _ProfileField(
                                    label: 'NƠI SINH',
                                    value: profile.birthPlace,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            _ProfileField(
                              label: 'HỆ ĐÀO TẠO - NIÊN HỌC',
                              value:
                                  '${profile.program}\n-Niên học: ${profile.academicYears}',
                            ),
                            const Spacer(),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 5),
                              child: Text(
                                'UEH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  height: 0.9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Text(
                              'UNIVERSITY',
                              style: TextStyle(
                                color: Color(0xFFB8E2E4),
                                fontSize: 10,
                                height: 0.9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          color: Colors.white,
                          child: QrImageView(
                            data: profile.studentId.isEmpty
                                ? 'UEH'
                                : profile.studentId,
                            size: 68,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile.avatarUrl.isEmpty
                          ? _avatarFallback(profile.fullName)
                          : Image.network(
                              profile.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _avatarFallback(profile.fullName),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => ColoredBox(
    color: const Color(0xFFDDEFF0),
    child: Center(
      child: Text(
        name.isEmpty ? 'UEH' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: _uehGreen,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB8E2E4),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
