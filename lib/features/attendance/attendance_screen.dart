import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/student_api.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.api});

  final StudentApi api;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _uehGreen = Color(0xFF006B78);
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openScanner(String title) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => _CodeScannerScreen(title: title),
      ),
    );
    if (code != null && mounted) {
      setState(() {
        _codeController.text = code.trim().toUpperCase();
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Vui lòng nhập hoặc quét mã điểm danh.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final receipt = await _submitAttendanceForCode(code);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Color(0xFF2E7D32),
            size: 38,
          ),
          title: const Text('Điểm danh thành công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.sessionName),
              const SizedBox(height: 8),
              Text(receipt.fullName),
              if (receipt.checkedInAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Thời gian: ${receipt.checkedInAt}'),
              ],
              const SizedBox(height: 8),
              Text('Lần điểm danh: ${receipt.checkInNumber}'),
              if (receipt.distanceMeters != null) ...[
                const SizedBox(height: 8),
                Text('Khoảng cách: ${receipt.distanceMeters} m'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (mounted) _codeController.clear();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể kết nối máy chủ.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<AttendanceReceipt> _submitAttendanceForCode(String code) async {
    final position = await _getCurrentPosition();
    return widget.api.submitAttendance(
      code,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<Position> _getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Quyền vị trí đã bị từ chối. Hãy cấp quyền trong Cài đặt ứng dụng.',
      );
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Quyền vị trí đã bị từ chối. Hãy cấp quyền trong Cài đặt ứng dụng.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException('Cần cấp quyền vị trí để điểm danh.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('Vui lòng bật GPS/vị trí trên điện thoại.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const ApiException(
        'Không lấy được vị trí. Hãy bật GPS và thử lại ở nơi thoáng.',
      );
    }
  }

  void _showFaceRecognitionNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API hiện chưa hỗ trợ xác thực khuôn mặt.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFAFC),
      // Nội dung căn giữa theo chiều dọc để không chừa khoảng trắng lớn bên dưới.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Vui lòng nhập hoặc quét mã để điểm danh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _uehGreen,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 52),
                      const Text(
                        'Nhập mã điểm danh',
                        style: TextStyle(
                          color: Color(0xFF88838A),
                          fontSize: 15,
                        ),
                      ),
                      TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã ở đây',
                          hintStyle: TextStyle(
                            color: Color(0xFFD5D0D4),
                            fontSize: 18,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFCFC9CD)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _uehGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text(
                        'Hoặc',
                        style: TextStyle(
                          color: Color(0xFFA9A3A7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ScanButton(
                        icon: FontAwesomeIcons.qrcode,
                        label: 'Quét mã QR Code',
                        onPressed: () => _openScanner('Quét mã QR Code'),
                      ),
                      const SizedBox(height: 12),
                      _ScanButton(
                        icon: FontAwesomeIcons.barcode,
                        label: 'Quét mã Barcode',
                        onPressed: () => _openScanner('Quét mã Barcode'),
                      ),
                      const SizedBox(height: 12),
                      _ScanButton(
                        icon: FontAwesomeIcons.userCheck,
                        label: 'Xác thực khuôn mặt',
                        onPressed: _showFaceRecognitionNotice,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _uehGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF5B8990),
                            elevation: 2,
                          ),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Điểm danh',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF006B78),
          side: const BorderSide(color: Color(0xFF006B78)),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _CodeScannerScreen extends StatefulWidget {
  const _CodeScannerScreen({required this.title});

  final String title;

  @override
  State<_CodeScannerScreen> createState() => _CodeScannerScreenState();
}

class _CodeScannerScreenState extends State<_CodeScannerScreen> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF006B78),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              String? code;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  code = value;
                  break;
                }
              }
              if (code == null) return;
              _hasScanned = true;
              Navigator.of(context).pop(code);
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Text(
              'Đưa mã vào khung để quét',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
