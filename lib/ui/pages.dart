import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../services/app_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _accepted = false;
  bool _obscure = true;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_accepted) {
      widget.controller.clearError();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先阅读并同意用户协议与隐私政策')));
      return;
    }
    if (_registering) {
      await widget.controller.register(_account.text, _password.text);
    } else {
      await widget.controller.login(_account.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 36),
                  Text(
                    _registering ? '创建赛电账号' : '欢迎使用 Saydian 赛电',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '连接智能手表，管理个人健康趋势。测量结果仅供健康参考，不用于诊断或治疗。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _account,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: _registering ? '手机号' : '手机号 / 账号',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: _registering
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (value) =>
                        setState(() => _accepted = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      '我已阅读并同意《用户协议》和《隐私政策》',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      '当前线上协议文本尚未完成，正式内测前必须替换。',
                      style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                    ),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _InlineNotice(
                      message: controller.errorMessage!,
                      icon: Icons.error_outline,
                      color: Colors.red,
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: controller.isBusy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: controller.isBusy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_registering ? '注册并登录' : '登录'),
                  ),
                  TextButton(
                    onPressed: controller.isBusy
                        ? null
                        : () => setState(() {
                            _registering = !_registering;
                            controller.clearError();
                          }),
                    child: Text(_registering ? '已有账号，返回登录' : '没有账号，立即注册'),
                  ),
                  if (kDebugMode) ...[
                    const Divider(height: 28),
                    OutlinedButton.icon(
                      onPressed: controller.enterPreview,
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('进入本地内测预览（不上传数据）'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAYDIAN',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            Text('赛电健康', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  static const _titles = ['健康首页', '健康趋势', '我的设备', '远程关爱', '我的'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: controller),
      HealthPage(controller: controller),
      DevicePage(controller: controller),
      CarePage(controller: controller),
      SettingsPage(controller: controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[controller.selectedTab]),
        centerTitle: false,
        actions: [
          if (controller.isPreviewMode)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                avatar: Icon(Icons.science_outlined, size: 17),
                label: Text('本地预览'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (controller.errorMessage != null)
            MaterialBanner(
              content: Text(controller.errorMessage!),
              leading: const Icon(Icons.info_outline, color: Colors.deepOrange),
              actions: [
                TextButton(
                  onPressed: controller.clearError,
                  child: const Text('知道了'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: controller.selectedTab, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTab,
        onDestinationSelected: controller.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '健康',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch),
            label: '设备',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '关爱',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestByMetric;
    final metrics = [
      HealthMetric.steps,
      HealthMetric.sleep,
      HealthMetric.heartRate,
      HealthMetric.bloodOxygen,
      HealthMetric.bloodPressure,
      HealthMetric.bodyTemperature,
    ];
    return RefreshIndicator(
      onRefresh: controller.synchronizeCloud,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DeviceHero(controller: controller),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日健康',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => controller.selectTab(1),
                child: const Text('查看趋势'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return _MetricCard(metric: metric, record: latest[metric]);
            },
          ),
          const SizedBox(height: 18),
          _StatusCard(
            title: '数据同步',
            message: controller.syncStatus,
            icon: Icons.cloud_sync_outlined,
            action: TextButton(
              onPressed: controller.synchronizeCloud,
              child: const Text('立即同步'),
            ),
          ),
          const SizedBox(height: 12),
          const _InlineNotice(
            message: '所有测量结果仅供健康管理参考。如有不适或异常，请咨询专业医务人员。',
            icon: Icons.health_and_safety_outlined,
            color: Color(0xFF116B68),
          ),
        ],
      ),
    );
  }
}

class _DeviceHero extends StatelessWidget {
  const _DeviceHero({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.connectedDevice;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF116B68), Color(0xFF184B67)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.watch, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device?.name ?? '尚未连接手表',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  device == null
                      ? '连接后同步真实健康数据'
                      : '${device.model ?? '赛电设备'} · ${controller.syncStatus}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => controller.selectTab(2),
            child: Text(device == null ? '去连接' : '管理'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.record});

  final HealthMetric metric;
  final HealthRecord? record;

  @override
  Widget build(BuildContext context) {
    final icon = switch (metric) {
      HealthMetric.steps => Icons.directions_walk,
      HealthMetric.sleep => Icons.bedtime_outlined,
      HealthMetric.heartRate => Icons.favorite_outline,
      HealthMetric.bloodOxygen => Icons.water_drop_outlined,
      HealthMetric.bloodPressure => Icons.speed_outlined,
      HealthMetric.bodyTemperature => Icons.thermostat_outlined,
      _ => Icons.monitor_heart_outlined,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(metric.label),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record?.displayValue ?? '--',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    record?.unit ?? metric.defaultUnit,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              record == null
                  ? '等待设备同步'
                  : DateFormat(
                      'MM-dd HH:mm',
                    ).format(record!.measuredAt.toLocal()),
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthPage extends StatelessWidget {
  const HealthPage({required this.controller, super.key});

  final AppController controller;

  static const coreMetrics = [
    HealthMetric.heartRate,
    HealthMetric.bloodOxygen,
    HealthMetric.bloodPressure,
    HealthMetric.bodyTemperature,
    HealthMetric.steps,
    HealthMetric.distance,
    HealthMetric.calories,
    HealthMetric.sleep,
  ];

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestByMetric;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _InlineNotice(
          message: 'ECG、HRV、身体及血液成分将在目标型号与后台结构完成真机验证后启用。',
          icon: Icons.lock_clock_outlined,
          color: Colors.deepOrange,
        ),
        const SizedBox(height: 14),
        for (final metric in coreMetrics) ...[
          _HealthRow(
            metric: metric,
            record: latest[metric],
            supported: controller.capabilities?.supports(metric),
            connected: controller.connectedDevice != null,
            onMeasure:
                metric == HealthMetric.steps ||
                    metric == HealthMetric.distance ||
                    metric == HealthMetric.calories ||
                    metric == HealthMetric.sleep
                ? null
                : () => controller.startMeasurement(metric),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.metric,
    required this.record,
    required this.supported,
    required this.connected,
    required this.onMeasure,
  });

  final HealthMetric metric;
  final HealthRecord? record;
  final bool? supported;
  final bool connected;
  final VoidCallback? onMeasure;

  @override
  Widget build(BuildContext context) {
    final status = !connected
        ? '等待连接设备'
        : supported == false
        ? '设备不支持'
        : record == null
        ? '暂无测量记录'
        : '最近 ${DateFormat('MM-dd HH:mm').format(record!.measuredAt.toLocal())}';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Icon(
            metric == HealthMetric.bloodPressure
                ? Icons.speed_outlined
                : Icons.monitor_heart_outlined,
          ),
        ),
        title: Text(metric.label),
        subtitle: Text(status),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record == null ? '--' : '${record!.displayValue} ${record!.unit}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (onMeasure != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: '开始测量',
                onPressed: connected && supported == true ? onMeasure : null,
                icon: const Icon(Icons.play_circle_outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DevicePage extends StatelessWidget {
  const DevicePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final connected = controller.connectedDevice;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _StatusCard(
          title: '原生设备服务',
          message: controller.sdkStatus,
          icon: Icons.bluetooth_outlined,
          action: Chip(label: Text(_deviceStateLabel(controller.deviceState))),
        ),
        const SizedBox(height: 12),
        if (connected != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('型号：${connected.model ?? '未识别'}'),
                  Text('固件：${connected.firmwareVersion ?? '未识别'}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: controller.synchronizeCloud,
                        icon: const Icon(Icons.sync),
                        label: const Text('同步数据'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: controller.disconnectDevice,
                        child: const Text('断开连接'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else ...[
          const _InlineNotice(
            message: '请确保手机蓝牙已开启，并允许“附近设备/蓝牙”权限。iOS 不要求位置权限。',
            icon: Icons.info_outline,
            color: Color(0xFF116B68),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.deviceState == DeviceConnectionState.scanning
                ? null
                : controller.scanDevices,
            icon: const Icon(Icons.radar),
            label: Text(
              controller.deviceState == DeviceConnectionState.scanning
                  ? '正在扫描…'
                  : '扫描附近手表',
            ),
          ),
          const SizedBox(height: 16),
          if (controller.scannedDevices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.watch_off_outlined,
                      size: 48,
                      color: Colors.black26,
                    ),
                    SizedBox(height: 12),
                    Text('尚未发现设备', style: TextStyle(color: Colors.black45)),
                  ],
                ),
              ),
            ),
          for (final device in controller.scannedDevices)
            Card(
              child: ListTile(
                leading: const Icon(Icons.watch_outlined),
                title: Text(device.name),
                subtitle: Text(
                  '${device.model ?? '未知型号'} · 信号 ${device.rssi ?? '--'}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => controller.connectDevice(device),
                  child: const Text('连接'),
                ),
              ),
            ),
        ],
        const SizedBox(height: 18),
        const _InlineNotice(
          message:
              'Veepoo AAR/Framework 与量产样机尚未提供，因此当前构建保留真实原生接口，但不会模拟扫描结果或健康数据。',
          icon: Icons.construction_outlined,
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  String _deviceStateLabel(DeviceConnectionState state) => switch (state) {
    DeviceConnectionState.disconnected => '未连接',
    DeviceConnectionState.scanning => '扫描中',
    DeviceConnectionState.connecting => '连接中',
    DeviceConnectionState.authenticating => '认证中',
    DeviceConnectionState.syncing => '同步中',
    DeviceConnectionState.ready => '已就绪',
    DeviceConnectionState.measuring => '测量中',
    DeviceConnectionState.error => '需要处理',
  };
}

class CarePage extends StatelessWidget {
  const CarePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshCare,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _InlineNotice(
            message: '隐私默认：未接受邀请前不共享任何健康指标；接受后也需逐项授权，并可随时撤销。',
            icon: Icons.privacy_tip_outlined,
            color: Color(0xFF116B68),
          ),
          const SizedBox(height: 14),
          if (controller.careMembers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_outline,
                      size: 52,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      controller.isPreviewMode ? '预览模式没有关爱成员' : '暂无关爱成员',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '输入手机号添加关爱成员，对方审核后再按指标授权共享。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed:
                          controller.session == null || controller.isPreviewMode
                          ? null
                          : () => _showAddCareDialog(context, controller),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('添加关爱'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final member in controller.careMembers)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    '${member['nickname'] ?? member['mobile'] ?? '关爱成员'}',
                  ),
                  subtitle: const Text('共享范围以服务端授权记录为准'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
        ],
      ),
    );
  }
}

Future<void> _showAddCareDialog(
  BuildContext context,
  AppController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();
  final mobile = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('添加关爱'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: mobileController,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '对方手机号',
            hintText: '请输入手机号',
          ),
          validator: (value) =>
              RegExp(r'^\d{6,20}$').hasMatch(value?.trim() ?? '')
              ? null
              : '请输入正确的手机号',
          onFieldSubmitted: (_) {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(dialogContext).pop(mobileController.text.trim());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(dialogContext).pop(mobileController.text.trim());
            }
          },
          child: const Text('发送'),
        ),
      ],
    ),
  );
  mobileController.dispose();
  if (mobile == null || !context.mounted) return;

  final success = await controller.addCare(mobile);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? '关爱请求已发送' : controller.errorMessage ?? '发送失败'),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(
              controller.session?.displayName ??
                  (controller.isPreviewMode ? '本地预览用户' : '赛电用户'),
            ),
            subtitle: Text(
              controller.session == null
                  ? '未连接线上账号'
                  : '会员 ID：${controller.session!.memberId}',
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('本地健康数据'),
                subtitle: Text(controller.storageStatus),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('云端同步'),
                subtitle: Text(controller.syncStatus),
                trailing: TextButton(
                  onPressed: controller.synchronizeCloud,
                  child: const Text('同步'),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('消息推送'),
                subtitle: Text('未配置'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('用户协议'),
                subtitle: Text('线上内容待替换，正式内测阻断'),
                trailing: Icon(Icons.warning_amber, color: Colors.deepOrange),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('隐私政策'),
                subtitle: Text('线上内容为空，正式内测阻断'),
                trailing: Icon(Icons.warning_amber, color: Colors.deepOrange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: controller.isBusy ? null : controller.logout,
          child: Text(controller.isPreviewMode ? '退出预览' : '退出登录'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.session == null
              ? null
              : () => _confirmDelete(context),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('注销账号'),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Saydian 赛电 · 内测版 0.1.0',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销账号？'),
        content: const Text('注销将请求服务端删除账号和关联数据。当前服务端注销接口尚未配置，未成功前不会在本地伪装为已注销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteAccount();
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(message),
        trailing: action,
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
