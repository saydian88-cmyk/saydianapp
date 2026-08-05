import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';

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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: saydianSoftGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 30),
                    Text(
                      _registering ? '创建赛电账号' : '欢迎使用 Saydian 赛电',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '连接智能手表，管理个人健康趋势。测量结果仅供健康参考，不用于诊断或治疗。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SaydianColors.muted,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _account,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        hintText: _registering ? '手机号' : '手机号 / 账号',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: _registering
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: '密码',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (value) =>
                          setState(() => _accepted = value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        '我已阅读并同意《用户协议》和《隐私政策》',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (controller.errorMessage != null) ...[
                      _InlineNotice(
                        message: controller.errorMessage!,
                        icon: Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: controller.isBusy ? null : _submit,
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
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: controller.isBusy
                          ? null
                          : () => setState(() {
                              _registering = !_registering;
                              controller.clearError();
                            }),
                      child: Text(_registering ? '返回登录' : '注册账户'),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: controller.enterPreview,
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('游客模式 · 本地预览'),
                      ),
                    ],
                  ],
                ),
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
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            color: SaydianColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 14),
        const Text(
          '赛 电',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'SAYDIAN HEALTH',
          style: TextStyle(
            color: SaydianColors.muted,
            letterSpacing: 2.2,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  static const _titles = ['', '健康数据', '设备管理', '远程关爱', '我的'];

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
      appBar: controller.selectedTab == 0
          ? null
          : AppBar(
              title: Text(_titles[controller.selectedTab]),
              actions: [
                if (controller.isPreviewMode)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _PreviewBadge(),
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
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: '健康',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch_rounded),
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

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SaydianColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '本地预览',
        style: TextStyle(color: Colors.white, fontSize: 11),
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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.synchronizeCloud,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _DashboardHeader(controller: controller),
            const SizedBox(height: 18),
            _DeviceHero(controller: controller),
            const SizedBox(height: 22),
            _SectionTitle(
              title: '今日健康',
              subtitle: DateFormat('M月d日').format(DateTime.now()),
              actionLabel: '全部数据',
              onAction: () => controller.selectTab(1),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.06,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _MetricCard(metric: metric, record: latest[metric]);
              },
            ),
            const SizedBox(height: 14),
            _StatusCard(
              title: '数据同步',
              message: controller.syncStatus,
              icon: Icons.cloud_done_outlined,
              action: IconButton(
                onPressed: controller.synchronizeCloud,
                icon: const Icon(Icons.sync_rounded),
              ),
            ),
            const SizedBox(height: 12),
            const _InlineNotice(
              message: '测量结果仅供健康管理参考，如有不适请咨询专业医务人员。',
              icon: Icons.health_and_safety_outlined,
              color: SaydianColors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final name = controller.session?.displayName ?? '赛电用户';
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: SaydianColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 25),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你好，$name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '今天也要保持好状态',
                style: TextStyle(color: SaydianColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (controller.isPreviewMode) const _PreviewBadge(),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: () => controller.selectTab(4),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
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
          colors: [Color(0xFFEAF6FF), Color(0xFFF5F3E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SaydianColors.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.watch_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device?.name ?? '尚未连接手表',
                  style: const TextStyle(
                    color: SaydianColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  device == null
                      ? '连接后同步真实健康数据'
                      : '${device.model ?? '赛电设备'} · ${controller.syncStatus}',
                  style: const TextStyle(
                    color: SaydianColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => controller.selectTab(2),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(device == null ? '连接' : '管理'),
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
    final color = switch (metric) {
      HealthMetric.steps => SaydianColors.green,
      HealthMetric.sleep => const Color(0xFF8C7CF0),
      HealthMetric.heartRate => SaydianColors.pink,
      HealthMetric.bloodOxygen => SaydianColors.blue,
      HealthMetric.bloodPressure => SaydianColors.orange,
      HealthMetric.bodyTemperature => SaydianColors.cyan,
      _ => SaydianColors.green,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 8),
                Text(
                  metric.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record?.displayValue ?? '--',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
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
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                12,
                (index) => Expanded(
                  child: Container(
                    height:
                        4 + ((index * 7 + metric.index * 3) % 16).toDouble(),
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.22 + index / 26),
                      borderRadius: BorderRadius.circular(3),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(color: SaydianColors.muted, fontSize: 12),
        ),
        const Spacer(),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SaydianColors.ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '健康数据总览',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '点击支持的指标可开始测量',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  color: SaydianColors.green,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
        const SizedBox(height: 4),
        const _InlineNotice(
          message: 'ECG、HRV、身体及血液成分将在目标型号真机验证后启用。',
          icon: Icons.lock_clock_outlined,
          color: SaydianColors.orange,
        ),
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
    final icon = switch (metric) {
      HealthMetric.heartRate => Icons.favorite_rounded,
      HealthMetric.bloodOxygen => Icons.water_drop_rounded,
      HealthMetric.bloodPressure => Icons.speed_rounded,
      HealthMetric.bodyTemperature => Icons.thermostat_rounded,
      HealthMetric.steps => Icons.directions_walk_rounded,
      HealthMetric.distance => Icons.location_on_rounded,
      HealthMetric.calories => Icons.local_fire_department_rounded,
      HealthMetric.sleep => Icons.bedtime_rounded,
      _ => Icons.monitor_heart_rounded,
    };
    final color = switch (metric) {
      HealthMetric.heartRate => SaydianColors.pink,
      HealthMetric.bloodOxygen => SaydianColors.blue,
      HealthMetric.bloodPressure => SaydianColors.orange,
      HealthMetric.bodyTemperature => SaydianColors.cyan,
      HealthMetric.sleep => const Color(0xFF8C7CF0),
      _ => SaydianColors.green,
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: connected && supported == true ? onMeasure : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SaydianColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record?.displayValue ?? '--',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    record?.unit ?? metric.defaultUnit,
                    style: const TextStyle(
                      color: SaydianColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (onMeasure != null) ...[
                const SizedBox(width: 7),
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: connected && supported == true
                      ? SaydianColors.ink
                      : const Color(0xFFD1D4D9),
                ),
              ],
            ],
          ),
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
        if (connected != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9F9EF), Color(0xFFEAF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: SaydianColors.ink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.watch_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connected.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${connected.model ?? '型号未识别'} · ${connected.firmwareVersion ?? '固件未识别'}',
                            style: const TextStyle(
                              color: SaydianColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ConnectionBadge(
                            label: _deviceStateLabel(controller.deviceState),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.synchronizeCloud,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('同步数据'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.disconnectDevice,
                        child: const Text('断开连接'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDCEBFF), Color(0xFFEEF5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.watch_outlined,
                      color: SaydianColors.blue,
                      size: 62,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '添加智能设备',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请开启手机蓝牙并将手表靠近手机',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SaydianColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          controller.deviceState ==
                              DeviceConnectionState.scanning
                          ? null
                          : controller.scanDevices,
                      icon:
                          controller.deviceState ==
                              DeviceConnectionState.scanning
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.radar_rounded),
                      label: Text(
                        controller.deviceState == DeviceConnectionState.scanning
                            ? '正在查找设备…'
                            : '开始查找',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final device in controller.scannedDevices)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  backgroundColor: SaydianColors.ink,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.watch_rounded),
                ),
                title: Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${device.model ?? '未知型号'} · 信号 ${device.rssi ?? '--'}',
                ),
                trailing: FilledButton(
                  onPressed: () => controller.connectDevice(device),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                  child: const Text('连接'),
                ),
              ),
            ),
        ],
        const SizedBox(height: 14),
        _StatusCard(
          title: '设备服务',
          message: controller.sdkStatus,
          icon: Icons.bluetooth_connected_rounded,
          action: _ConnectionBadge(
            label: _deviceStateLabel(controller.deviceState),
          ),
        ),
        const SizedBox(height: 12),
        const _InlineNotice(
          message: '请允许附近设备/蓝牙权限；设备指令会按顺序执行，连接时请保持手表靠近手机。',
          icon: Icons.info_outline_rounded,
          color: SaydianColors.blue,
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

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SaydianColors.green.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF16823A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CarePage extends StatelessWidget {
  const CarePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final memberCount = controller.careMembers.length;
    return RefreshIndicator(
      onRefresh: controller.refreshCare,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEEF1), Color(0xFFF2F1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: SaydianColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: SaydianColors.pink,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '守护家人健康',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        memberCount == 0
                            ? '添加关爱成员后查看授权数据'
                            : '正在关爱 $memberCount 位家人',
                        style: const TextStyle(
                          color: SaydianColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed:
                      controller.session == null || controller.isPreviewMode
                      ? null
                      : () => _showAddCareDialog(context, controller),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '关爱成员',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (controller.careMembers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: SaydianColors.pink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        size: 38,
                        color: SaydianColors.pink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      controller.isPreviewMode ? '预览模式没有关爱成员' : '暂无关爱成员',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '通过手机号邀请家人，对方接受并授权后才会共享健康数据。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SaydianColors.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEDF2),
                      foregroundColor: SaydianColors.pink,
                      child: Icon(Icons.person_rounded),
                    ),
                    title: Text(
                      '${member['nickname'] ?? member['mobile'] ?? '关爱成员'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('查看已授权健康数据'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
          const SizedBox(height: 4),
          const _InlineNotice(
            message: '默认不共享任何数据；成员可按指标授权并随时撤销。',
            icon: Icons.privacy_tip_outlined,
            color: SaydianColors.green,
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: saydianSoftGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: SaydianColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.session?.displayName ??
                          (controller.isPreviewMode ? '本地预览用户' : '赛电用户'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.session == null
                          ? '健康档案仅保存在本机'
                          : '会员 ID：${controller.session!.memberId}',
                      style: const TextStyle(
                        color: SaydianColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '数据与服务',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const _SettingsIcon(
                  icon: Icons.storage_outlined,
                  color: SaydianColors.blue,
                ),
                title: const Text('本地健康数据'),
                subtitle: Text(controller.storageStatus),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              const Divider(indent: 64),
              ListTile(
                leading: const _SettingsIcon(
                  icon: Icons.cloud_done_outlined,
                  color: SaydianColors.green,
                ),
                title: const Text('云端同步'),
                subtitle: Text(controller.syncStatus),
                trailing: IconButton(
                  onPressed: controller.synchronizeCloud,
                  icon: const Icon(Icons.sync_rounded),
                ),
              ),
              const Divider(indent: 64),
              const ListTile(
                leading: _SettingsIcon(
                  icon: Icons.notifications_none_rounded,
                  color: SaydianColors.orange,
                ),
                title: Text('消息推送'),
                subtitle: Text('未配置'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '关于赛电',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: _SettingsIcon(
                  icon: Icons.description_outlined,
                  color: SaydianColors.cyan,
                ),
                title: Text('用户协议'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              Divider(indent: 64),
              ListTile(
                leading: _SettingsIcon(
                  icon: Icons.shield_outlined,
                  color: SaydianColors.green,
                ),
                title: Text('隐私政策'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              Divider(indent: 64),
              ListTile(
                leading: _SettingsIcon(
                  icon: Icons.headset_mic_outlined,
                  color: SaydianColors.pink,
                ),
                title: Text('联系客服'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: controller.isBusy ? null : controller.logout,
          child: Text(controller.isPreviewMode ? '退出预览' : '退出登录'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: controller.session == null
              ? null
              : () => _confirmDelete(context),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('注销账号'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Saydian 赛电 · 内测版 0.1.0',
            style: TextStyle(color: SaydianColors.muted, fontSize: 11),
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

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 21),
    );
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
