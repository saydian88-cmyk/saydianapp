import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/feature_models.dart';
import '../domain/models.dart';
import '../services/app_controller.dart';
import '../services/device_weather_service.dart';
import 'app_theme.dart';
import 'brand_assets.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _distributor = TextEditingController();
  bool _accepted = false;
  bool _obscure = true;

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    _confirmation.dispose();
    _distributor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mobile = _mobile.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(mobile)) {
      _message('请输入正确的中国大陆手机号');
      return;
    }
    if (_password.text.length < 6) {
      _message('密码至少需要 6 位');
      return;
    }
    if (_password.text != _confirmation.text) {
      _message('两次输入的密码不一致');
      return;
    }
    if (!_accepted) {
      _message('请先阅读并同意用户协议与隐私政策');
      return;
    }
    final success = await widget.controller.register(mobile, _password.text);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _message(widget.controller.errorMessage ?? '注册失败，请稍后重试');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            const Center(child: SaydianBrandLockup(width: 154)),
            const SizedBox(height: 28),
            TextField(
              key: const Key('registration-mobile'),
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '手机号'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '设置密码',
                helperText: '至少 6 位',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmation,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: '确认密码'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distributor,
              decoration: const InputDecoration(
                labelText: '经销商编号（选填）',
                helperText: '没有可不填',
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('我已阅读并同意用户协议与隐私政策'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('registration-submit'),
              onPressed: widget.controller.isBusy ? null : _submit,
              child: widget.controller.isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('注册'),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _mobile = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  void _continue() {
    if (!RegExp(r'^1\d{10}$').hasMatch(_mobile.text.trim())) {
      setState(() => _message = '请输入正确的中国大陆手机号');
      return;
    }
    setState(() => _message = '此功能暂时无法使用，请稍后再试');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 72,
            color: SaydianColors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            '验证手机号',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '输入注册手机号，验证通过后可重新设置密码。',
            textAlign: TextAlign.center,
            style: TextStyle(color: SaydianColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          TextField(
            key: const Key('password-recovery-mobile'),
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '手机号'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            FeatureStateCard(
              message: _message!,
              icon: Icons.info_outline_rounded,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _continue, child: const Text('下一步')),
        ],
      ),
    );
  }
}

class HealthWarningPage extends StatelessWidget {
  const HealthWarningPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康预警')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          FeatureStateCard(
            message: '当前暂无健康预警',
            detail: '这里只显示已确认的提醒，不会根据单次测量自行判断疾病。',
            icon: Icons.health_and_safety_outlined,
            color: SaydianColors.green,
          ),
          SizedBox(height: 14),
          FeatureStateCard(
            message: '如有明显不适，请及时咨询专业医务人员',
            detail: '手表测量结果用于日常健康管理参考。',
            icon: Icons.medical_information_outlined,
          ),
        ],
      ),
    );
  }
}

class SharingManagementPage extends StatelessWidget {
  const SharingManagementPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('共享管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FeatureStateCard(
            message: '默认不共享任何健康数据',
            detail: '家人接受邀请并选择允许的健康项目后，对方才能查看。',
            icon: Icons.privacy_tip_outlined,
            color: SaydianColors.green,
          ),
          const SizedBox(height: 14),
          if (controller.careMembers.isEmpty)
            const FeatureStateCard(
              message: '暂无共享成员',
              detail: '可返回远程关爱页面邀请家人。',
              icon: Icons.group_outlined,
            )
          else
            for (final member in controller.careMembers)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    '${member['nickname'] ?? member['mobile'] ?? '关爱成员'}',
                  ),
                  subtitle: const Text('仅显示对方已允许查看的内容'),
                ),
              ),
        ],
      ),
    );
  }
}

class HealthCalibrationPage extends StatelessWidget {
  const HealthCalibrationPage({required this.metric, super.key});

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${metric.label}校准')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: FeatureStateCard(
          message: '此功能暂时无法使用，请稍后再试',
          detail: '校准需要与手表支持的方式完全一致，当前不会写入未经确认的数据。',
          icon: Icons.tune_rounded,
        ),
      ),
    );
  }
}

class HealthRecordDetailPage extends StatelessWidget {
  const HealthRecordDetailPage({
    required this.controller,
    required this.record,
    super.key,
  });

  final AppController controller;
  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final time = record.measuredAt.toLocal();
    final date =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final values = <MapEntry<String, num>>[...record.values.entries];
    return Scaffold(
      appBar: AppBar(title: Text('${record.metric.label}详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    record.displayValue,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    record.unit,
                    style: const TextStyle(color: SaydianColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    date,
                    style: const TextStyle(color: SaydianColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (values.length > 1) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (var index = 0; index < values.length; index++) ...[
                    ListTile(
                      title: Text(_recordValueLabel(values[index].key)),
                      trailing: Text(
                        '${values[index].value} ${record.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (index != values.length - 1) const Divider(indent: 16),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const FeatureStateCard(
            message: '查看长期趋势更有参考价值',
            detail: '单次测量可能受佩戴方式、运动和环境影响；如有不适，请咨询专业医务人员。',
            icon: Icons.health_and_safety_outlined,
            color: SaydianColors.green,
          ),
        ],
      ),
    );
  }

  String _recordValueLabel(String key) => switch (key) {
    'systolic' => '收缩压',
    'diastolic' => '舒张压',
    _ => record.metric.label,
  };
}

class DeviceFeaturePage extends StatefulWidget {
  const DeviceFeaturePage({
    required this.controller,
    required this.feature,
    super.key,
  });

  final AppController controller;
  final DeviceFeature feature;

  @override
  State<DeviceFeaturePage> createState() => _DeviceFeaturePageState();
}

class _DeviceFeaturePageState extends State<DeviceFeaturePage>
    with WidgetsBindingObserver {
  DeviceScreenSettings? _screen;
  Map<String, Object?> _featureData = const {};
  bool _finding = false;
  CameraController? _camera;
  XFile? _lastPhoto;
  String? _cameraMessage;
  bool _takingPhoto = false;
  bool _cameraRemoteStarted = false;
  int _seenCameraShutter = 0;
  XFile? _dialPhoto;
  final DeviceWeatherService _weatherService = DeviceWeatherService();
  bool _weatherRefreshing = false;
  String? _weatherMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seenCameraShutter = widget.controller.cameraShutterSequence;
    widget.controller.addListener(_handleControllerEvent);
    if (widget.controller.availabilityFor(widget.feature).isReady) {
      if (widget.feature == DeviceFeature.screenDisplay) {
        unawaited(_loadScreen());
      } else if (widget.feature == DeviceFeature.camera) {
        unawaited(_initializeCamera());
      } else if (widget.feature != DeviceFeature.findWatch) {
        unawaited(_loadFeature());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleControllerEvent);
    if (_cameraRemoteStarted) {
      unawaited(
        widget.controller.triggerDeviceAction(
          DeviceFeature.camera,
          enabled: false,
        ),
      );
    }
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.feature == DeviceFeature.notifications &&
        widget.controller.availabilityFor(widget.feature).isReady) {
      unawaited(_loadFeature());
    }
  }

  void _handleControllerEvent() {
    if (!mounted) return;
    if (widget.feature == DeviceFeature.camera) {
      final sequence = widget.controller.cameraShutterSequence;
      if (sequence > _seenCameraShutter) {
        _seenCameraShutter = sequence;
        unawaited(_takePhoto());
      }
    }
    final latest = widget.controller.deviceFeatureData[widget.feature];
    final progress = latest?['progress'];
    if (progress != null && progress != _featureData['progress']) {
      setState(() => _featureData = {..._featureData, 'progress': progress});
    }
  }

  Future<void> _loadFeature() async {
    final value = await widget.controller.readDeviceFeature(widget.feature);
    if (mounted && value.isNotEmpty) setState(() => _featureData = value);
  }

  Future<void> _loadScreen() async {
    final value = await widget.controller.readDeviceFeature(widget.feature);
    if (mounted && value.isNotEmpty) {
      setState(() => _screen = DeviceScreenSettings.fromMap(value));
    }
  }

  Future<void> _saveScreen() async {
    final screen = _screen;
    if (screen == null) return;
    final saved = await widget.controller.writeDeviceFeature(
      widget.feature,
      screen.toMap(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? '屏幕设置已保存' : '屏幕设置保存失败，请稍后重试')),
    );
  }

  Future<bool> _saveFeature(
    Map<String, Object?> values,
    String successMessage, {
    bool reload = true,
  }) async {
    final saved = await widget.controller.writeDeviceFeature(
      widget.feature,
      values,
    );
    if (!mounted) return saved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? successMessage
              : widget.controller.errorMessage ?? '保存失败，请稍后重试',
        ),
      ),
    );
    if (saved && reload) await _loadFeature();
    return saved;
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraMessage = '手机没有可用的相机');
        return;
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      final started = await widget.controller.triggerDeviceAction(
        DeviceFeature.camera,
      );
      if (!mounted) return;
      setState(() {
        _cameraRemoteStarted = started;
        _cameraMessage = started
            ? '可点击手机按钮，也可在手表上点击拍照'
            : widget.controller.errorMessage ?? '手表相机遥控暂时无法开启';
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraMessage = error.code == 'CameraAccessDenied'
            ? '允许相机权限后使用'
            : '手机相机暂时无法使用，请稍后重试';
      });
    } catch (_) {
      if (mounted) setState(() => _cameraMessage = '手机相机暂时无法使用，请稍后重试');
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _takingPhoto) return;
    setState(() => _takingPhoto = true);
    try {
      final photo = await camera.takePicture();
      if (mounted) {
        setState(() {
          _lastPhoto = photo;
          _cameraMessage = '照片已拍摄并保存在本次相机页面';
        });
      }
    } on CameraException {
      if (mounted) setState(() => _cameraMessage = '拍照失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _toggleFind() async {
    final next = !_finding;
    final success = await widget.controller.triggerDeviceAction(
      widget.feature,
      enabled: next,
    );
    if (!mounted) return;
    if (success) setState(() => _finding = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (next ? '手表正在响铃或振动' : '已停止查找')
              : widget.controller.errorMessage ?? '暂时无法查找手表',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final availability = widget.controller.availabilityFor(widget.feature);
        final busy = widget.controller.deviceFeatureBusy.contains(
          widget.feature,
        );
        return Scaffold(
          appBar: AppBar(title: Text(widget.feature.label)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DeviceFeatureHeader(feature: widget.feature),
              const SizedBox(height: 14),
              if (!availability.isReady)
                FeatureStateCard(
                  message: availability.message,
                  detail: _deviceFeatureDescription(widget.feature),
                  icon: _deviceFeatureIcon(widget.feature),
                )
              else if (widget.feature == DeviceFeature.findWatch)
                _FindWatchPanel(
                  finding: _finding,
                  busy: busy,
                  onPressed: _toggleFind,
                )
              else if (widget.feature == DeviceFeature.screenDisplay)
                _ScreenSettingsPanel(
                  settings: _screen,
                  busy: busy,
                  onReload: _loadScreen,
                  onChanged: (value) => setState(() => _screen = value),
                  onSave: _saveScreen,
                )
              else
                _buildReadyContent(busy),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadyContent(bool busy) => switch (widget.feature) {
    DeviceFeature.watchFaces => _buildWatchFacesPanel(busy),
    DeviceFeature.photoWatchFace => _buildPhotoWatchFacePanel(busy),
    DeviceFeature.camera => _buildCameraPanel(),
    DeviceFeature.phoneCalls => _buildPhoneCallsPanel(busy),
    DeviceFeature.contacts => _buildContactsPanel(busy),
    DeviceFeature.notifications => _buildNotificationsPanel(busy),
    DeviceFeature.alarms => _buildAlarmsPanel(busy),
    DeviceFeature.weather => _buildWeatherPanel(busy),
    DeviceFeature.worldClock => _buildWorldClocksPanel(busy),
    DeviceFeature.healthReminders => _buildHealthRemindersPanel(busy),
    DeviceFeature.healthAssessment => _buildHealthAssessmentPanel(busy),
    _ => FeatureStateCard(
      message: '此功能暂时无法使用，请稍后再试',
      detail: _deviceFeatureDescription(widget.feature),
      icon: _deviceFeatureIcon(widget.feature),
    ),
  };

  List<Map<String, Object?>> get _items {
    final raw = _featureData['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Widget _loadingCard(bool busy, String label) => FeatureStateCard(
    message: busy ? '正在读取$label' : '暂时未读取到$label',
    detail: '请保持手表靠近手机后重试。',
    icon: _deviceFeatureIcon(widget.feature),
    actionLabel: busy ? null : '重新读取',
    onAction: busy ? null : _loadFeature,
  );

  Widget _buildWatchFacesPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '手表表盘');
    final faces = _items;
    final progress = (_featureData['progress'] as num?)?.toInt();
    return Column(
      children: [
        if (busy && progress != null && progress > 0) ...[
          LinearProgressIndicator(value: progress.clamp(0, 100) / 100),
          const SizedBox(height: 10),
          Text('正在读取表盘 $progress%'),
          const SizedBox(height: 12),
        ],
        Card(
          child: faces.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('手表中暂未读取到可切换的表盘')),
                )
              : Column(
                  children: [
                    for (var index = 0; index < faces.length; index++) ...[
                      ListTile(
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: SaydianColors.blue.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            faces[index]['type'] == 'photo'
                                ? Icons.photo_outlined
                                : Icons.watch_later_outlined,
                            color: SaydianColors.blue,
                          ),
                        ),
                        title: Text('${faces[index]['name'] ?? '手表表盘'}'),
                        subtitle: Text(
                          faces[index]['isCurrent'] == true ? '当前使用' : '已安装在手表',
                        ),
                        trailing: faces[index]['isCurrent'] == true
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: SaydianColors.green,
                              )
                            : TextButton(
                                onPressed: busy
                                    ? null
                                    : () => _switchWatchFace(faces[index]),
                                child: const Text('使用'),
                              ),
                      ),
                      if (index != faces.length - 1) const Divider(indent: 72),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : _loadFeature,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('刷新手表表盘'),
          ),
        ),
      ],
    );
  }

  Future<void> _switchWatchFace(Map<String, Object?> face) async {
    await _saveFeature({
      'operation': 'switch',
      'id': '${face['id'] ?? ''}',
      'type': '${face['type'] ?? ''}',
      'index': (face['index'] as num?)?.toInt() ?? 0,
    }, '表盘已切换');
  }

  Widget _buildPhotoWatchFacePanel(bool busy) {
    final progress = (_featureData['progress'] as num?)?.toInt() ?? 0;
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: .82,
                child: _dialPhoto == null
                    ? Container(
                        color: const Color(0xffeef3f8),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 58),
                            SizedBox(height: 10),
                            Text('选择一张照片制作表盘'),
                          ],
                        ),
                      )
                    : Image.file(File(_dialPhoto!.path), fit: BoxFit.cover),
              ),
              if (busy) ...[
                LinearProgressIndicator(
                  value: progress > 0 ? progress.clamp(0, 100) / 100 : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(progress > 0 ? '正在传送到手表 $progress%' : '正在准备照片表盘'),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _pickDialPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_dialPhoto == null ? '选择照片' : '更换照片'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy || _dialPhoto == null
                            ? null
                            : _uploadDialPhoto,
                        child: const Text('设为表盘'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '传送时请保持手表靠近手机，并避免切换到其他页面。',
          textAlign: TextAlign.center,
          style: TextStyle(color: SaydianColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickDialPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (photo != null && mounted) setState(() => _dialPhoto = photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('允许照片权限后使用')));
    }
  }

  Future<void> _uploadDialPhoto() async {
    final photo = _dialPhoto;
    if (photo == null) return;
    await _saveFeature(
      {'operation': 'upload_photo', 'imagePath': photo.path},
      '照片表盘已设置',
      reload: false,
    );
  }

  Widget _buildCameraPanel() {
    final camera = _camera;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (camera != null && camera.value.isInitialized)
            AspectRatio(
              aspectRatio: camera.value.aspectRatio,
              child: CameraPreview(camera),
            )
          else
            Container(
              height: 280,
              color: Colors.black,
              alignment: Alignment.center,
              child: _cameraMessage == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.white70,
                      size: 54,
                    ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  _cameraMessage ?? '正在打开相机',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SaydianColors.muted),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 74,
                  height: 74,
                  child: FilledButton(
                    onPressed: camera == null || _takingPhoto
                        ? null
                        : _takePhoto,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _takingPhoto
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 30),
                  ),
                ),
                if (_lastPhoto != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_lastPhoto!.path),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCallsPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '通话设置');
    final status = switch (_featureData['connectionStatus']) {
      'connected' => '通话连接已建立',
      'broadcasting' => '等待手机配对',
      _ => '通话连接未建立',
    };
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bluetooth_audio_rounded),
            title: Text(status),
            subtitle: Text(
              _featureData['paired'] == true ? '手机已保存配对信息' : '请在手机蓝牙设置中完成配对',
            ),
            trailing: IconButton(
              onPressed: busy ? null : _loadFeature,
              tooltip: '刷新',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const Divider(indent: 56),
          _featureSwitch(
            title: '手表蓝牙通话',
            subtitle: '允许手表接听和拨打电话',
            keyName: 'enabled',
            busy: busy,
          ),
          const Divider(indent: 56),
          _featureSwitch(
            title: '通话与媒体声音',
            subtitle: '在手表播放电话和手机音频',
            keyName: 'audioEnabled',
            busy: busy,
          ),
          const Divider(indent: 56),
          _featureSwitch(
            title: '自动连接',
            subtitle: '手表靠近手机时自动恢复通话连接',
            keyName: 'autoConnect',
            busy: busy,
          ),
        ],
      ),
    );
  }

  Widget _featureSwitch({
    required String title,
    required String subtitle,
    required String keyName,
    required bool busy,
    bool supported = true,
  }) => SwitchListTile(
    title: Text(title),
    subtitle: Text(supported ? subtitle : '当前手表不支持此项'),
    value: _featureData[keyName] == true,
    onChanged: busy || !supported
        ? null
        : (value) =>
              _saveFeature({..._featureData, keyName: value}, '$title已保存'),
  );

  Widget _buildNotificationsPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '消息通知设置');
    final supported = (_featureData['supportedKeys'] as List?)
        ?.map((value) => '$value')
        .toSet();
    final entries = <(String, String, String)>[
      ('incomingCall', '来电提醒', '有电话时在手表提醒'),
      ('sms', '短信', '在手表显示短信提醒'),
      ('wechat', '微信', '在手表显示微信消息提醒'),
      ('qq', 'QQ', '在手表显示 QQ 消息提醒'),
      ('whatsapp', 'WhatsApp', '在手表显示 WhatsApp 消息提醒'),
      ('dingtalk', '钉钉', '在手表显示钉钉消息提醒'),
      ('wecom', '企业微信', '在手表显示企业微信消息提醒'),
      ('tiktok', '抖音', '在手表显示抖音消息提醒'),
      ('telegram', 'Telegram', '在手表显示 Telegram 消息提醒'),
      ('otherApps', '其他应用', '接收其他已允许应用的消息提醒'),
    ];
    final access = _featureData['notificationAccess'] == true;
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              access ? Icons.verified_user_rounded : Icons.security_rounded,
              color: access ? SaydianColors.green : SaydianColors.orange,
            ),
            title: Text(access ? '手机通知权限已允许' : '还需允许手机通知权限'),
            subtitle: Text(access ? '已开启的应用消息可以发送到手表' : '允许后，手表才能显示手机收到的应用消息'),
            trailing: TextButton(
              onPressed: busy
                  ? null
                  : access
                  ? _loadFeature
                  : _openNotificationSettings,
              child: Text(access ? '重新检查' : '去设置'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                _featureSwitch(
                  keyName: entries[index].$1,
                  title: entries[index].$2,
                  subtitle: entries[index].$3,
                  busy: busy,
                  supported: supported?.contains(entries[index].$1) ?? true,
                ),
                if (index != entries.length - 1) const Divider(indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openNotificationSettings() async {
    final opened = await widget.controller.triggerDeviceAction(
      DeviceFeature.notifications,
    );
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.errorMessage ?? '无法打开系统设置')),
    );
  }

  Widget _buildWeatherPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '天气设置');
    final city = '${_featureData['city'] ?? ''}'.trim();
    final updatedAt = (_featureData['updatedAt'] as num?)?.toInt() ?? 0;
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              _featureSwitch(
                keyName: 'enabled',
                title: '在手表显示天气',
                subtitle: '开启后可在手表查看天气信息',
                busy: busy || _weatherRefreshing,
              ),
              const Divider(indent: 56),
              SwitchListTile(
                title: const Text('使用摄氏度'),
                subtitle: Text(
                  _featureData['useCelsius'] == true ? '温度显示为 ℃' : '温度显示为 ℉',
                ),
                value: _featureData['useCelsius'] == true,
                onChanged: busy || _weatherRefreshing
                    ? null
                    : (value) => _saveFeature({
                        ..._featureData,
                        'useCelsius': value,
                      }, '温度单位已保存'),
              ),
              if (city.isNotEmpty) ...[
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(city),
                  subtitle: Text(
                    updatedAt > 0
                        ? '上次更新 ${_weatherTimeLabel(updatedAt)}'
                        : '已同步到手表',
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy || _weatherRefreshing
                            ? null
                            : _syncWeather,
                        icon: _weatherRefreshing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_outlined),
                        label: Text(_weatherRefreshing ? '正在更新天气' : '更新当前位置天气'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy || _weatherRefreshing
                            ? null
                            : _chooseWeatherCity,
                        icon: const Icon(Icons.location_city_outlined),
                        label: const Text('选择城市'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_weatherMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _weatherMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SaydianColors.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseWeatherCity() async {
    final cityController = TextEditingController();
    final city = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择城市'),
        content: TextField(
          controller: cityController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '城市名称',
            hintText: '例如：深圳',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = cityController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    cityController.dispose();
    if (city == null || !mounted) return;
    await _syncWeather(city: city);
  }

  Future<void> _syncWeather({String? city}) async {
    setState(() {
      _weatherRefreshing = true;
      _weatherMessage = null;
    });
    try {
      final forecast = city == null
          ? await _weatherService.loadCurrentLocation()
          : await _weatherService.loadCity(city);
      final values = forecast.toFeatureValues(
        useCelsius: _featureData['useCelsius'] != false,
      );
      final saved = await _saveFeature(values, '天气已同步到手表', reload: false);
      if (saved && mounted) {
        setState(() {
          _featureData = {..._featureData, ...values};
          _weatherMessage = '${forecast.city}天气已更新';
        });
      }
    } on DeviceWeatherException catch (error) {
      if (!mounted) return;
      setState(() => _weatherMessage = error.message);
      if (error.openSettings) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () {
                if (error.locationSettings) {
                  unawaited(Geolocator.openLocationSettings());
                } else {
                  unawaited(Geolocator.openAppSettings());
                }
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _weatherMessage = '天气更新失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _weatherRefreshing = false);
    }
  }

  String _weatherTimeLabel(int milliseconds) {
    final value = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${value.month}月${value.day}日 '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAlarmsPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '闹钟');
    final alarms = _items;
    return Column(
      children: [
        Card(
          child: alarms.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('手表中还没有闹钟')),
                )
              : Column(
                  children: [
                    for (var index = 0; index < alarms.length; index++) ...[
                      _alarmTile(alarms[index], busy),
                      if (index != alarms.length - 1) const Divider(indent: 56),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : () => _showAlarmEditor(),
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('添加闹钟'),
          ),
        ),
      ],
    );
  }

  Widget _alarmTile(Map<String, Object?> alarm, bool busy) {
    final hour = (alarm['hour'] as num?)?.toInt() ?? 0;
    final minute = (alarm['minute'] as num?)?.toInt() ?? 0;
    final enabled = alarm['enabled'] == true;
    final label = alarm['label']?.toString().trim() ?? '';
    final repeatLabel = _repeatDaysLabel(alarm['repeatDays']);
    return ListTile(
      onTap: busy ? null : () => _showAlarmEditor(alarm),
      leading: const Icon(Icons.alarm_rounded),
      title: Text(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(label.isEmpty ? repeatLabel : '$label · $repeatLabel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: enabled,
            onChanged: busy
                ? null
                : (value) => _saveFeature({
                    ...alarm,
                    'operation': 'update',
                    'enabled': value,
                  }, value ? '闹钟已开启' : '闹钟已关闭'),
          ),
          IconButton(
            onPressed: busy ? null : () => _deleteAlarm(alarm),
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlarmEditor([Map<String, Object?>? alarm]) async {
    var time = TimeOfDay(
      hour: (alarm?['hour'] as num?)?.toInt() ?? 8,
      minute: (alarm?['minute'] as num?)?.toInt() ?? 0,
    );
    final repeatDays =
        (alarm?['repeatDays'] as List?)
            ?.whereType<num>()
            .map((day) => day.toInt())
            .toSet() ??
        <int>{1, 2, 3, 4, 5, 6, 7};
    var enabled = alarm?['enabled'] != false;
    var label = alarm?['label']?.toString().trim() ?? '闹钟';
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(alarm == null ? '添加闹钟' : '编辑闹钟'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('提醒时间'),
                  subtitle: Text(time.format(context)),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: dialogContext,
                      initialTime: time,
                    );
                    if (selected != null) setDialogState(() => time = selected);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用闹钟'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                ),
                TextFormField(
                  initialValue: label,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: '提醒名称',
                    hintText: '例如：吃药、起床',
                  ),
                  onChanged: (value) => label = value.trim(),
                ),
                const SizedBox(height: 8),
                const Text('重复'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(
                          const ['一', '二', '三', '四', '五', '六', '日'][day - 1],
                        ),
                        selected: repeatDays.contains(day),
                        onSelected: (selected) => setDialogState(() {
                          if (selected) {
                            repeatDays.add(day);
                          } else {
                            repeatDays.remove(day);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, <String, Object?>{
                if (alarm?['id'] != null) 'id': alarm!['id'],
                'operation': alarm == null ? 'add' : 'update',
                'hour': time.hour,
                'minute': time.minute,
                'enabled': enabled,
                'label': label.isEmpty ? '闹钟' : label,
                'repeatDays': repeatDays.toList()..sort(),
              }),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (values != null) await _saveFeature(values, '闹钟已保存');
  }

  Future<void> _deleteAlarm(Map<String, Object?> alarm) async {
    final confirmed = await _confirm('删除闹钟', '确定删除这个闹钟吗？');
    if (!confirmed) return;
    await _saveFeature({...alarm, 'operation': 'delete'}, '闹钟已删除');
  }

  String _repeatDaysLabel(Object? raw) {
    final days =
        (raw as List?)?.whereType<num>().map((day) => day.toInt()).toSet() ??
        {};
    if (days.isEmpty) return '仅一次';
    if (days.length == 7) return '每天';
    if (days.length == 5 && days.containsAll([1, 2, 3, 4, 5])) return '工作日';
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final sorted = days.toList()..sort();
    return sorted.map((day) => labels[day - 1]).join('、');
  }

  Widget _buildContactsPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '联系人');
    final contacts = _items;
    return Column(
      children: [
        Card(
          child: contacts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('手表中还没有常用联系人')),
                )
              : Column(
                  children: [
                    for (var index = 0; index < contacts.length; index++) ...[
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(_contactInitial(contacts[index])),
                        ),
                        title: Text('${contacts[index]['name'] ?? ''}'),
                        subtitle: Text(
                          contacts[index]['isEmergency'] == true
                              ? '${contacts[index]['phone'] ?? ''} · 紧急联系人'
                              : '${contacts[index]['phone'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (contacts[index]['supportsEmergency'] == true)
                              IconButton(
                                onPressed: busy
                                    ? null
                                    : () => _toggleEmergencyContact(
                                        contacts[index],
                                      ),
                                tooltip: contacts[index]['isEmergency'] == true
                                    ? '取消紧急联系人'
                                    : '设为紧急联系人',
                                icon: Icon(
                                  contacts[index]['isEmergency'] == true
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: contacts[index]['isEmergency'] == true
                                      ? SaydianColors.orange
                                      : null,
                                ),
                              ),
                            IconButton(
                              onPressed: busy
                                  ? null
                                  : () => _deleteContact(contacts[index]),
                              tooltip: '删除',
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                      if (index != contacts.length - 1)
                        const Divider(indent: 56),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy || contacts.length >= 10
                ? null
                : _showContactEditor,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(contacts.length >= 10 ? '联系人已满' : '添加联系人'),
          ),
        ),
      ],
    );
  }

  Future<void> _showContactEditor() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加联系人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 12,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '电话号码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || phone.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, <String, Object?>{
                'operation': 'add',
                'name': name.text.trim(),
                'phone': phone.text.trim(),
              });
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    if (values != null) await _saveFeature(values, '联系人已添加');
  }

  Future<void> _deleteContact(Map<String, Object?> contact) async {
    final confirmed = await _confirm('删除联系人', '确定从手表删除这个联系人吗？');
    if (!confirmed) return;
    await _saveFeature({...contact, 'operation': 'delete'}, '联系人已删除');
  }

  Future<void> _toggleEmergencyContact(Map<String, Object?> contact) async {
    final enabled = contact['isEmergency'] != true;
    await _saveFeature({
      ...contact,
      'operation': 'emergency',
      'isEmergency': enabled,
    }, enabled ? '已设为紧急联系人' : '已取消紧急联系人');
  }

  String _contactInitial(Map<String, Object?> contact) {
    final name = '${contact['name'] ?? '联'}'.trim();
    return name.isEmpty ? '联' : name.substring(0, 1);
  }

  Widget _buildWorldClocksPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '世界时钟');
    final clocks = _items;
    return Column(
      children: [
        Card(
          child: clocks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('手表中还没有世界时钟')),
                )
              : Column(
                  children: [
                    for (var index = 0; index < clocks.length; index++) ...[
                      ListTile(
                        leading: const Icon(Icons.public_rounded),
                        title: Text('${clocks[index]['city'] ?? ''}'),
                        subtitle: Text(
                          _utcLabel(
                            (clocks[index]['utcOffsetMinutes'] as num?)
                                    ?.toInt() ??
                                0,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: busy
                              ? null
                              : () => _deleteWorldClock(clocks[index]),
                          tooltip: '删除',
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                      if (index != clocks.length - 1) const Divider(indent: 56),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy || clocks.length >= 10
                ? null
                : _showWorldClockEditor,
            icon: const Icon(Icons.add_rounded),
            label: Text(clocks.length >= 10 ? '世界时钟已满' : '添加城市'),
          ),
        ),
      ],
    );
  }

  Future<void> _showWorldClockEditor() async {
    const cities = <(String, int)>[
      ('北京', 480),
      ('东京', 540),
      ('新加坡', 480),
      ('迪拜', 240),
      ('伦敦', 0),
      ('巴黎', 60),
      ('纽约', -300),
      ('洛杉矶', -480),
      ('悉尼', 600),
    ];
    var selected = cities.first;
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加世界时钟'),
          content: DropdownButtonFormField<(String, int)>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: '城市'),
            items: [
              for (final city in cities)
                DropdownMenuItem(
                  value: city,
                  child: Text('${city.$1}  ${_utcLabel(city.$2)}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => selected = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, <String, Object?>{
                'operation': 'add',
                'city': selected.$1,
                'utcOffsetMinutes': selected.$2,
                'enabled': true,
              }),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    if (values != null) await _saveFeature(values, '世界时钟已添加');
  }

  Future<void> _deleteWorldClock(Map<String, Object?> clock) async {
    final confirmed = await _confirm('删除世界时钟', '确定从手表删除这个城市吗？');
    if (!confirmed) return;
    await _saveFeature({...clock, 'operation': 'delete'}, '世界时钟已删除');
  }

  String _utcLabel(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    return 'UTC$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:${(absolute % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildHealthRemindersPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '健康提醒');
    final reminders = _items;
    return Card(
      child: reminders.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('当前手表没有可设置的健康提醒')),
            )
          : Column(
              children: [
                for (var index = 0; index < reminders.length; index++) ...[
                  ListTile(
                    onTap: busy
                        ? null
                        : () => _showReminderEditor(reminders[index]),
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text('${reminders[index]['label'] ?? '健康提醒'}'),
                    subtitle: Text(
                      '${_minutesLabel((reminders[index]['startMinutes'] as num?)?.toInt() ?? 0)}–'
                      '${_minutesLabel((reminders[index]['endMinutes'] as num?)?.toInt() ?? 0)}，'
                      '每 ${(reminders[index]['intervalMinutes'] as num?)?.toInt() ?? 60} 分钟',
                    ),
                    trailing: Switch(
                      value: reminders[index]['enabled'] == true,
                      onChanged: busy
                          ? null
                          : (value) => _saveFeature({
                              ...reminders[index],
                              'enabled': value,
                            }, value ? '提醒已开启' : '提醒已关闭'),
                    ),
                  ),
                  if (index != reminders.length - 1) const Divider(indent: 56),
                ],
              ],
            ),
    );
  }

  Future<void> _showReminderEditor(Map<String, Object?> reminder) async {
    var startMinutes = (reminder['startMinutes'] as num?)?.toInt() ?? 480;
    var endMinutes = (reminder['endMinutes'] as num?)?.toInt() ?? 1320;
    var interval = (reminder['intervalMinutes'] as num?)?.toInt() ?? 60;
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${reminder['label'] ?? '健康提醒'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开始时间'),
                trailing: Text(_minutesLabel(startMinutes)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay(
                      hour: startMinutes ~/ 60,
                      minute: startMinutes % 60,
                    ),
                  );
                  if (time != null) {
                    setDialogState(
                      () => startMinutes = time.hour * 60 + time.minute,
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('结束时间'),
                trailing: Text(_minutesLabel(endMinutes)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay(
                      hour: endMinutes ~/ 60,
                      minute: endMinutes % 60,
                    ),
                  );
                  if (time != null) {
                    setDialogState(
                      () => endMinutes = time.hour * 60 + time.minute,
                    );
                  }
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: interval,
                decoration: const InputDecoration(labelText: '提醒间隔'),
                items: const [30, 45, 60, 90, 120]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes 分钟'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => interval = value ?? interval),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, <String, Object?>{
                ...reminder,
                'startMinutes': startMinutes,
                'endMinutes': endMinutes,
                'intervalMinutes': interval,
              }),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (values != null) await _saveFeature(values, '健康提醒已保存');
  }

  Widget _buildHealthAssessmentPanel(bool busy) {
    if (_featureData.isEmpty) return _loadingCard(busy, '辅助评估设置');
    final items = _items;
    if (items.isEmpty) {
      return const FeatureStateCard(
        message: '当前手表没有可设置的辅助评估',
        detail: '不同型号支持的项目可能不同，请以手表实际显示为准。',
        icon: Icons.assignment_turned_in_outlined,
      );
    }
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.health_and_safety_outlined),
                  title: Text('${items[index]['label'] ?? '健康辅助功能'}'),
                  subtitle: const Text('开启后由手表提供日常趋势参考'),
                  value: items[index]['enabled'] == true,
                  onChanged: busy
                      ? null
                      : (value) => _saveFeature({
                          ...items[index],
                          'enabled': value,
                        }, value ? '已开启' : '已关闭'),
                ),
                if (index != items.length - 1) const Divider(indent: 56),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '辅助评估仅供日常健康管理参考，不用于诊断或治疗。',
          textAlign: TextAlign.center,
          style: TextStyle(color: SaydianColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  String _minutesLabel(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ) ??
      false;
}

class _DeviceFeatureHeader extends StatelessWidget {
  const _DeviceFeatureHeader({required this.feature});

  final DeviceFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SaydianColors.blue.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_deviceFeatureIcon(feature), color: SaydianColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _deviceFeatureDescription(feature),
                  style: const TextStyle(
                    color: SaydianColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FindWatchPanel extends StatelessWidget {
  const _FindWatchPanel({
    required this.finding,
    required this.busy,
    required this.onPressed,
  });

  final bool finding;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              finding
                  ? Icons.notifications_active_rounded
                  : Icons.watch_rounded,
              size: 68,
              color: finding ? SaydianColors.orange : SaydianColors.ink,
            ),
            const SizedBox(height: 14),
            Text(
              finding ? '请留意附近响铃或振动的手表' : '让手表响铃或振动，帮助你快速找到它',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : onPressed,
                child: Text(finding ? '停止查找' : '开始查找'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenSettingsPanel extends StatelessWidget {
  const _ScreenSettingsPanel({
    required this.settings,
    required this.busy,
    required this.onReload,
    required this.onChanged,
    required this.onSave,
  });

  final DeviceScreenSettings? settings;
  final bool busy;
  final VoidCallback onReload;
  final ValueChanged<DeviceScreenSettings> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final value = settings;
    if (value == null) {
      return FeatureStateCard(
        message: busy ? '正在读取手表设置' : '暂时未读取到屏幕设置',
        detail: '请保持手表靠近手机后重试。',
        icon: Icons.brightness_6_outlined,
        actionLabel: busy ? null : '重新读取',
        onAction: busy ? null : onReload,
      );
    }
    final maximum = value.maximumBrightness.clamp(1, 10);
    final current = value.brightness.clamp(1, maximum);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('自动调节亮度'),
              subtitle: const Text('由手表根据时间自动调节'),
              value: value.automaticBrightness,
              onChanged: busy
                  ? null
                  : (enabled) =>
                        onChanged(value.copyWith(automaticBrightness: enabled)),
            ),
            const Divider(),
            const SizedBox(height: 12),
            Text('屏幕亮度  $current / $maximum'),
            Slider(
              value: current.toDouble(),
              min: 1,
              max: maximum.toDouble(),
              divisions: maximum > 1 ? maximum - 1 : 1,
              onChanged: busy || value.automaticBrightness
                  ? null
                  : (next) =>
                        onChanged(value.copyWith(brightness: next.round())),
            ),
            if (value.durationSeconds != null &&
                value.minimumDurationSeconds != null &&
                value.maximumDurationSeconds != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text('亮屏时长  ${value.durationSeconds} 秒'),
              Slider(
                value: value.durationSeconds!.toDouble().clamp(
                  value.minimumDurationSeconds!.toDouble(),
                  value.maximumDurationSeconds!.toDouble(),
                ),
                min: value.minimumDurationSeconds!.toDouble(),
                max: value.maximumDurationSeconds!.toDouble(),
                divisions:
                    (value.maximumDurationSeconds! -
                            value.minimumDurationSeconds!) >
                        0
                    ? value.maximumDurationSeconds! -
                          value.minimumDurationSeconds!
                    : 1,
                onChanged: busy
                    ? null
                    : (next) => onChanged(
                        value.copyWith(durationSeconds: next.round()),
                      ),
              ),
            ],
            if (value.raiseToWakeSupported) ...[
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('抬腕亮屏'),
                subtitle: const Text('抬起手腕时自动点亮屏幕'),
                value: value.raiseToWakeEnabled,
                onChanged: busy
                    ? null
                    : (enabled) => onChanged(
                        value.copyWith(raiseToWakeEnabled: enabled),
                      ),
              ),
              if (value.raiseToWakeCustomTimeSupported) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('生效时间'),
                  subtitle: Text(
                    '${_timeLabel(value.raiseToWakeStartMinutes)}–${_timeLabel(value.raiseToWakeEndMinutes)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: busy
                      ? null
                      : () => _pickRaiseTime(context, value, onChanged),
                ),
                Text('抬腕灵敏度  ${value.raiseToWakeSensitivity} / 10'),
                Slider(
                  value: value.raiseToWakeSensitivity.toDouble().clamp(1, 10),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: busy
                      ? null
                      : (next) => onChanged(
                          value.copyWith(raiseToWakeSensitivity: next.round()),
                        ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : onSave,
                child: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRaiseTime(
    BuildContext context,
    DeviceScreenSettings value,
    ValueChanged<DeviceScreenSettings> onChanged,
  ) async {
    final start = await showTimePicker(
      context: context,
      helpText: '选择开始时间',
      initialTime: TimeOfDay(
        hour: value.raiseToWakeStartMinutes ~/ 60,
        minute: value.raiseToWakeStartMinutes % 60,
      ),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: '选择结束时间',
      initialTime: TimeOfDay(
        hour: value.raiseToWakeEndMinutes ~/ 60,
        minute: value.raiseToWakeEndMinutes % 60,
      ),
    );
    if (end == null) return;
    onChanged(
      value.copyWith(
        raiseToWakeStartMinutes: start.hour * 60 + start.minute,
        raiseToWakeEndMinutes: end.hour * 60 + end.minute,
      ),
    );
  }

  String _timeLabel(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _content = TextEditingController();
  final _contact = TextEditingController();
  String _category = '功能建议';
  String? _result;

  @override
  void dispose() {
    _content.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() {
    if (_content.text.trim().length < 5) {
      setState(() => _result = '请至少填写 5 个字的问题说明');
      return;
    }
    setState(() => _result = '此功能暂时无法使用，请稍后再试');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助与反馈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '问题类型'),
            items: const [
              DropdownMenuItem(value: '功能建议', child: Text('功能建议')),
              DropdownMenuItem(value: '设备连接', child: Text('设备连接')),
              DropdownMenuItem(value: '数据问题', child: Text('数据问题')),
              DropdownMenuItem(value: '商城订单', child: Text('商城订单')),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('feedback-content'),
            controller: _content,
            minLines: 5,
            maxLines: 8,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: '问题说明',
              hintText: '请描述遇到的问题和出现步骤',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(
              labelText: '联系方式（选填）',
              hintText: '手机号或邮箱',
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 14),
            FeatureStateCard(message: _result!, icon: Icons.info_outline),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: _submit, child: const Text('提交反馈')),
        ],
      ),
    );
  }
}

class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('联系客服')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: FeatureStateCard(
          message: '此功能暂时无法使用，请稍后再试',
          detail: '客服联系方式确认后会在这里提供，请勿向陌生账号发送个人健康信息。',
          icon: Icons.headset_mic_outlined,
        ),
      ),
    );
  }
}

class AboutSaydianPage extends StatelessWidget {
  const AboutSaydianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于我们')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
        children: const [
          Center(child: SaydianBrandLockup(width: 176)),
          SizedBox(height: 26),
          Text(
            '赛电健康',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            '记录日常健康趋势，连接家人与设备，让健康管理更简单。',
            textAlign: TextAlign.center,
            style: TextStyle(color: SaydianColors.muted, height: 1.6),
          ),
          SizedBox(height: 24),
          FeatureStateCard(
            message: '版本 0.1.8',
            detail: '测量结果仅供健康管理参考，不用于诊断或治疗。',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class SecurityCenterPage extends StatelessWidget {
  const SecurityCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号与安全')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PasswordRecoveryPage(),
                    ),
                  ),
                  leading: const Icon(Icons.password_rounded),
                  title: const Text('重置密码'),
                  subtitle: const Text('验证手机号后重新设置'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(indent: 56),
                const ListTile(
                  leading: Icon(Icons.phonelink_lock_outlined),
                  title: Text('登录保护'),
                  subtitle: Text('此功能暂时无法使用，请稍后再试'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: FeatureStateCard(
          message: '购物车暂时无法使用',
          detail: '你可以从商品详情页直接选择规格并购买。',
          icon: Icons.shopping_cart_outlined,
        ),
      ),
    );
  }
}

class AfterSalesPage extends StatelessWidget {
  const AfterSalesPage({this.orderNumber, super.key});

  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('申请售后')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FeatureStateCard(
          message: '此功能暂时无法使用，请稍后再试',
          detail: orderNumber == null
              ? '售后服务开通后，可从订单详情提交申请。'
              : '订单 $orderNumber 的售后服务开通后，可在这里提交申请。',
          icon: Icons.support_agent_rounded,
        ),
      ),
    );
  }
}

class FeatureStateCard extends StatelessWidget {
  const FeatureStateCard({
    required this.message,
    required this.icon,
    this.detail,
    this.color = SaydianColors.blue,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? detail;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SaydianColors.muted, height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _deviceFeatureIcon(DeviceFeature feature) => switch (feature) {
  DeviceFeature.watchFaces => Icons.watch_later_outlined,
  DeviceFeature.photoWatchFace => Icons.photo_outlined,
  DeviceFeature.findWatch => Icons.notifications_active_outlined,
  DeviceFeature.camera => Icons.camera_alt_outlined,
  DeviceFeature.phoneCalls => Icons.call_outlined,
  DeviceFeature.contacts => Icons.contacts_outlined,
  DeviceFeature.notifications => Icons.notifications_none_rounded,
  DeviceFeature.alarms => Icons.alarm_rounded,
  DeviceFeature.weather => Icons.cloud_outlined,
  DeviceFeature.worldClock => Icons.public_rounded,
  DeviceFeature.healthReminders => Icons.event_available_outlined,
  DeviceFeature.healthMonitoring => Icons.monitor_heart_outlined,
  DeviceFeature.healthAssessment => Icons.assignment_turned_in_outlined,
  DeviceFeature.screenDisplay => Icons.brightness_6_outlined,
};

String _deviceFeatureDescription(DeviceFeature feature) => switch (feature) {
  DeviceFeature.watchFaces => '选择并管理手表表盘',
  DeviceFeature.photoWatchFace => '用自己的照片制作表盘',
  DeviceFeature.findWatch => '让附近的手表响铃或振动',
  DeviceFeature.camera => '使用手表控制手机拍照',
  DeviceFeature.phoneCalls => '管理手表通话相关设置',
  DeviceFeature.contacts => '管理手表中的常用联系人',
  DeviceFeature.notifications => '选择需要在手表上提醒的消息',
  DeviceFeature.alarms => '管理手表闹钟和重复日期',
  DeviceFeature.weather => '把所在城市天气同步到手表',
  DeviceFeature.worldClock => '在手表上查看其他城市时间',
  DeviceFeature.healthReminders => '设置久坐、饮水和日常提醒',
  DeviceFeature.healthMonitoring => '设置自动检测和健康提醒',
  DeviceFeature.healthAssessment => '查看手表支持的辅助评估',
  DeviceFeature.screenDisplay => '调节亮度和亮屏方式',
};
