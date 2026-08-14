import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/feature_models.dart';
import '../domain/models.dart';
import '../services/app_controller.dart';
import 'app_theme.dart';
import 'brand_assets.dart';
import 'device_sdk_badge.dart';
import 'health_trend_page.dart';
import 'prototype_pages.dart';
import 'shop_pages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();
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
    await widget.controller.login(_account.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: saydianSoftGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 160, 26, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 98),
                    TextField(
                      controller: _account,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        hintText: '手机号 / 账号',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_iphone_outlined,
                          color: Color(0xFF9DA1A8),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: '密码',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF9DA1A8),
                          size: 22,
                        ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.isBusy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  settings: const RouteSettings(
                                    name: 'password-recovery',
                                  ),
                                  builder: (_) => const PasswordRecoveryPage(),
                                ),
                              ),
                        child: const Text('忘记密码？'),
                      ),
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _InlineNotice(
                        message: controller.errorMessage!,
                        icon: Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 58),
                    FilledButton(
                      onPressed: controller.isBusy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: controller.isBusy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('登录'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: controller.isBusy
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: 'registration',
                                ),
                                builder: (_) =>
                                    RegistrationPage(controller: controller),
                              ),
                            ),
                      style: TextButton.styleFrom(
                        foregroundColor: SaydianColors.ink,
                        minimumSize: const Size.fromHeight(38),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('注册账户'),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: controller.enterPreview,
                        icon: const CircleAvatar(
                          radius: 14,
                          backgroundColor: SaydianColors.green,
                          child: Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        label: const Text('游客预览'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _AgreementRow(
                      accepted: _accepted,
                      onChanged: (value) =>
                          setState(() => _accepted = value ?? false),
                      onOpenAgreement: _openAgreement,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAgreement({required int id, required String title}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailPage(
          controller: widget.controller,
          article: {'id': id, 'title': title},
          singleArticle: true,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const Center(child: SaydianBrandLockup(width: 190));
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.accepted,
    required this.onChanged,
    required this.onOpenAgreement,
  });

  final bool accepted;
  final ValueChanged<bool?> onChanged;
  final void Function({required int id, required String title}) onOpenAgreement;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      foregroundColor: SaydianColors.blue,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: accepted,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 2),
        const Text('我已阅读并同意', style: TextStyle(fontSize: 12)),
        TextButton(
          onPressed: () => onOpenAgreement(id: 2, title: '用户协议'),
          style: linkStyle,
          child: const Text('用户协议'),
        ),
        const Text('和', style: TextStyle(fontSize: 12)),
        TextButton(
          onPressed: () => onOpenAgreement(id: 3, title: '隐私政策'),
          style: linkStyle,
          child: const Text('隐私政策'),
        ),
      ],
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  static const _titles = ['', '健康', 'AI 智能', '设备', '我的'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: controller),
      HealthPage(controller: controller),
      AiPage(controller: controller),
      DevicePage(controller: controller),
      SettingsPage(controller: controller),
    ];
    return Scaffold(
      appBar: controller.selectedTab == 0
          ? null
          : AppBar(
              title: Text(_titles[controller.selectedTab]),
              actions: const [],
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
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch_rounded),
            label: '设备',
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
      HealthMetric.bloodPressure,
      HealthMetric.bloodGlucose,
      HealthMetric.bloodOxygen,
      HealthMetric.bodyTemperature,
      HealthMetric.ecg,
      HealthMetric.heartRate,
      HealthMetric.hrv,
      HealthMetric.bodyComposition,
      HealthMetric.sleep,
      HealthMetric.bloodComposition,
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.synchronizeCloud,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _DashboardHeader(controller: controller),
            const SizedBox(height: 14),
            _TodayHealthOverview(
              latest: latest,
              stepTarget: controller.stepGoal.toDouble(),
              distanceTarget: controller.distanceGoal,
              calorieTarget: controller.calorieGoal.toDouble(),
              onSetGoal: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GoalSettingsPage(controller: controller),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FeatureEntryGrid(
              onCare: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('远程关爱')),
                    body: CarePage(controller: controller),
                  ),
                ),
              ),
              onAssistant: () => controller.selectTab(2),
              onWarning: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'health-warnings'),
                  builder: (_) => HealthWarningPage(controller: controller),
                ),
              ),
              onMall: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'shop-home'),
                  builder: (_) => ShopHomePage(
                    controller: controller,
                    ordersPageBuilder: (_) =>
                        OrdersPage(controller: controller, initialStatus: null),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: '健康数据',
              subtitle: DateFormat('M月d日').format(DateTime.now()),
              actionLabel: '全部数据',
              onAction: () => controller.selectTab(1),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 184 + (textScale - 1) * 36,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _MetricCard(
                  controller: controller,
                  metric: metric,
                  record: latest[metric],
                );
              },
            ),
            const SizedBox(height: 18),
            _DeviceHero(controller: controller),
            const SizedBox(height: 14),
            _StatusCard(
              title: '数据同步',
              message: controller.cloudSyncStatus,
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
          alignment: Alignment.center,
          child: const SaydianBrandMark(size: 42),
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
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NotificationsPage(controller: controller),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _TodayHealthOverview extends StatelessWidget {
  const _TodayHealthOverview({
    required this.latest,
    required this.stepTarget,
    required this.distanceTarget,
    required this.calorieTarget,
    required this.onSetGoal,
  });

  final Map<HealthMetric, HealthRecord> latest;
  final double stepTarget;
  final double distanceTarget;
  final double calorieTarget;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('dashboard-today-health'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F7ED), Color(0xFFF3F8E8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今日健康',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '坚持完成每日活动目标',
                          style: TextStyle(
                            color: SaydianColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onSetGoal,
                    icon: const Icon(Icons.track_changes_rounded, size: 18),
                    label: const Text('目标'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
            child: Column(
              children: [
                _GoalProgressRow(
                  metric: HealthMetric.steps,
                  record: latest[HealthMetric.steps],
                  target: stepTarget,
                  color: const Color(0xFF80BAF5),
                ),
                const SizedBox(height: 16),
                _GoalProgressRow(
                  metric: HealthMetric.distance,
                  record: latest[HealthMetric.distance],
                  target: distanceTarget,
                  color: const Color(0xFF6CDE53),
                ),
                const SizedBox(height: 16),
                _GoalProgressRow(
                  metric: HealthMetric.calories,
                  record: latest[HealthMetric.calories],
                  target: calorieTarget,
                  color: const Color(0xFFFF9949),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.metric,
    required this.record,
    required this.target,
    required this.color,
  });

  final HealthMetric metric;
  final HealthRecord? record;
  final double target;
  final Color color;

  num? get _value {
    if (record == null || record!.values.isEmpty) return null;
    return record!.values['value'] ?? record!.values.values.first;
  }

  String _format(num value) {
    if (metric == HealthMetric.distance) return value.toStringAsFixed(2);
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final progress = value == null
        ? 0.0
        : (value.toDouble() / target).clamp(0.0, 1.0).toDouble();
    final unit = switch (metric) {
      HealthMetric.distance => '公里',
      HealthMetric.calories => '千卡',
      _ => metric.defaultUnit,
    };
    final currentText = value == null ? '--' : _format(value);
    final targetText = _format(target);

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 34,
          child: Text(
            metric.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 106,
          child: Text(
            '$currentText/$targetText$unit',
            textAlign: TextAlign.right,
            maxLines: 1,
            style: const TextStyle(
              color: SaydianColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureEntryGrid extends StatelessWidget {
  const _FeatureEntryGrid({
    required this.onCare,
    required this.onAssistant,
    required this.onWarning,
    required this.onMall,
  });

  final VoidCallback onCare;
  final VoidCallback onAssistant;
  final VoidCallback onWarning;
  final VoidCallback onMall;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('dashboard-functions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: _FeatureEntry(
                label: '远程关爱',
                icon: Icons.family_restroom_rounded,
                color: const Color(0xFFFF8E70),
                onTap: onCare,
              ),
            ),
            Expanded(
              child: _FeatureEntry(
                label: '智能管家',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF6F8FF8),
                onTap: onAssistant,
              ),
            ),
            Expanded(
              child: _FeatureEntry(
                label: '健康预警',
                icon: Icons.health_and_safety_rounded,
                color: const Color(0xFFEF6E78),
                onTap: onWarning,
              ),
            ),
            Expanded(
              child: _FeatureEntry(
                label: '赛电商城',
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF46BC82),
                onTap: onMall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureEntry extends StatelessWidget {
  const _FeatureEntry({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device?.name ?? '尚未连接手表',
                        style: const TextStyle(
                          color: SaydianColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (device != null) ...[
                      const SizedBox(width: 8),
                      DeviceSdkBadge(source: device.sdkSource, compact: true),
                    ],
                  ],
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
            onPressed: () => controller.selectTab(3),
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
  const _MetricCard({
    required this.controller,
    required this.metric,
    required this.record,
  });

  final AppController controller;
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
      HealthMetric.bloodGlucose => Icons.bloodtype_outlined,
      HealthMetric.bodyTemperature => Icons.thermostat_outlined,
      HealthMetric.ecg => Icons.monitor_heart_outlined,
      HealthMetric.hrv => Icons.show_chart_rounded,
      HealthMetric.bodyComposition => Icons.accessibility_new_rounded,
      HealthMetric.bloodComposition => Icons.science_outlined,
      _ => Icons.monitor_heart_outlined,
    };
    final color = switch (metric) {
      HealthMetric.steps => SaydianColors.green,
      HealthMetric.sleep => const Color(0xFF8C7CF0),
      HealthMetric.heartRate => SaydianColors.pink,
      HealthMetric.bloodOxygen => SaydianColors.blue,
      HealthMetric.bloodPressure => SaydianColors.orange,
      HealthMetric.bloodGlucose => SaydianColors.green,
      HealthMetric.bodyTemperature => SaydianColors.cyan,
      HealthMetric.ecg => const Color(0xFF6E8DF5),
      HealthMetric.hrv => const Color(0xFF8C7CF0),
      HealthMetric.bodyComposition => SaydianColors.cyan,
      HealthMetric.bloodComposition => SaydianColors.pink,
      _ => SaydianColors.green,
    };
    return GestureDetector(
      key: ValueKey('health-metric-${metric.name}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              HealthTrendPage(controller: controller, metric: metric),
        ),
      ),
      child: Card(
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
                  Expanded(
                    child: Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _healthDisplayValue(record, controller),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _healthDisplayUnit(metric, record, controller),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HealthMetricMiniChart(
                controller: controller,
                metric: metric,
                color: color,
              ),
              const Spacer(),
              Text(
                record == null
                    ? '暂无趋势数据'
                    : '更新于 ${DateFormat('HH:mm').format(record!.measuredAt.toLocal())}',
                style: const TextStyle(
                  color: SaydianColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
    HealthMetric.bloodGlucose,
    HealthMetric.bodyTemperature,
    HealthMetric.ecg,
    HealthMetric.hrv,
    HealthMetric.bodyComposition,
    HealthMetric.bloodComposition,
    HealthMetric.steps,
    HealthMetric.distance,
    HealthMetric.calories,
    HealthMetric.sleep,
  ];

  @override
  Widget build(BuildContext context) {
    final latest = controller.latestByMetric;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          controller.synchronizeCloud(),
          controller.refreshSportRecords(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SportEntryPanel(controller: controller),
          const SizedBox(height: 16),
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
              controller: controller,
              metric: metric,
              record: latest[metric],
              supported: controller.capabilities?.supports(metric),
              connected: controller.connectedDevice != null,
              onMeasure:
                  const {
                    HealthMetric.heartRate,
                    HealthMetric.bloodOxygen,
                    HealthMetric.bloodPressure,
                    HealthMetric.bloodGlucose,
                    HealthMetric.bodyTemperature,
                    HealthMetric.ecg,
                    HealthMetric.bodyComposition,
                    HealthMetric.bloodComposition,
                  }.contains(metric)
                  ? () => _showHealthMeasurementDialog(
                      context,
                      controller,
                      metric,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'bp-calibration'),
                      builder: (_) => const HealthCalibrationPage(
                        metric: HealthMetric.bloodPressure,
                      ),
                    ),
                  ),
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('血压校准'),
                  subtitle: const Text('按手表支持的方式进行校准'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(indent: 56),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: 'glucose-calibration',
                      ),
                      builder: (_) => const HealthCalibrationPage(
                        metric: HealthMetric.bloodGlucose,
                      ),
                    ),
                  ),
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('血糖校准'),
                  subtitle: const Text('按手表支持的方式进行校准'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showHealthMeasurementDialog(
  BuildContext context,
  AppController controller,
  HealthMetric metric,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _HealthMeasurementDialog(controller: controller, metric: metric),
);

class _HealthMeasurementDialog extends StatefulWidget {
  const _HealthMeasurementDialog({
    required this.controller,
    required this.metric,
  });

  final AppController controller;
  final HealthMetric metric;

  @override
  State<_HealthMeasurementDialog> createState() =>
      _HealthMeasurementDialogState();
}

class _HealthMeasurementDialogState extends State<_HealthMeasurementDialog> {
  late final DateTime _startedAt = DateTime.now();
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.startMeasurement(widget.metric));
  }

  Future<void> _finish() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await widget.controller.stopMeasurement(widget.metric);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.metric.label}测量'),
      content: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final record = widget.controller.latestByMetric[widget.metric];
          final isNew = record != null && record.measuredAt.isAfter(_startedAt);
          final failed =
              widget.controller.deviceState == DeviceConnectionState.error;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNew
                    ? Icons.check_circle_rounded
                    : Icons.monitor_heart_rounded,
                color: isNew ? SaydianColors.green : SaydianColors.pink,
                size: 54,
              ),
              const SizedBox(height: 14),
              Text(
                isNew
                    ? '${_healthDisplayValue(record, widget.controller)} ${_healthDisplayUnit(widget.metric, record, widget.controller)}'
                    : failed
                    ? widget.controller.errorMessage ?? '测量未完成'
                    : '请保持正确佩戴并静止，等待手表返回结果',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isNew ? 24 : 14,
                  fontWeight: isNew ? FontWeight.w900 : FontWeight.w500,
                  height: 1.5,
                ),
              ),
              if (!isNew && !failed) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _stopping ? null : _finish,
          child: Text(_stopping ? '正在停止' : '结束测量'),
        ),
      ],
    );
  }
}

class _SportEntryPanel extends StatelessWidget {
  const _SportEntryPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('health-sport-entries'),
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9F2FC), Color(0xFFF4F5F7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final mode in SportMode.values)
                Expanded(
                  child: _SportEntry(
                    mode: mode,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SportSessionPage(
                          controller: controller,
                          mode: mode,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SportRecordsPage(controller: controller),
                ),
              ),
              leading: const _SettingsIcon(
                icon: Icons.history_rounded,
                color: SaydianColors.blue,
              ),
              title: const Text(
                '运动记录',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                controller.connectedDevice == null
                    ? '连接手表后读取运动记录'
                    : '已读取 ${controller.sportRecords.length} 条记录',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportEntry extends StatelessWidget {
  const _SportEntry({required this.mode, required this.onTap});

  final SportMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      SportMode.running => Icons.directions_run_rounded,
      SportMode.walking => Icons.directions_walk_rounded,
      SportMode.cycling => Icons.directions_bike_rounded,
      SportMode.hiking => Icons.hiking_rounded,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF1D3B6F),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              mode.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class SportSessionPage extends StatefulWidget {
  const SportSessionPage({
    required this.controller,
    required this.mode,
    super.key,
  });

  final AppController controller;
  final SportMode mode;

  @override
  State<SportSessionPage> createState() => _SportSessionPageState();
}

class _SportSessionPageState extends State<SportSessionPage> {
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  int _elapsedSeconds = 0;
  DateTime? _startedAt;
  final List<SportRoutePoint> _routePoints = [];
  double _routeDistanceKm = 0;
  String _locationStatus = '开始后可记录前台户外轨迹';

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_positionSubscription?.cancel());
    super.dispose();
  }

  Future<void> _toggleSport() async {
    if (widget.controller.activeSport != null) {
      final startedAt = _startedAt;
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      await widget.controller.stopSport();
      _timer?.cancel();
      if (startedAt != null && _elapsedSeconds > 0) {
        await widget.controller.saveLocalSportRecord(
          SportRecord(
            id: 'local:${startedAt.toUtc().toIso8601String()}',
            mode: widget.mode,
            startedAt: startedAt,
            durationSeconds: _elapsedSeconds,
            distanceKm: _routeDistanceKm,
            calories: 0,
            routePoints: List.unmodifiable(_routePoints),
          ),
        );
      }
      if (mounted) setState(() {});
      return;
    }
    final started = await widget.controller.startSport(widget.mode);
    if (!started || !mounted) return;
    _startedAt = DateTime.now();
    _elapsedSeconds = 0;
    _routePoints.clear();
    _routeDistanceKm = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(
          () => _elapsedSeconds = DateTime.now()
              .difference(_startedAt!)
              .inSeconds,
        );
      }
    });
    setState(() {});
    unawaited(_startLocationTracking());
  }

  Future<void> _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _locationStatus = '定位服务未开启，仍会记录手表运动数据');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationStatus = '未允许位置权限，仍会记录手表运动数据');
      return;
    }
    if (mounted) setState(() => _locationStatus = '正在记录前台户外轨迹');
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            if (position.accuracy > 80 || !mounted) return;
            final point = SportRoutePoint(
              latitude: position.latitude,
              longitude: position.longitude,
              recordedAt: position.timestamp,
              accuracy: position.accuracy,
            );
            if (_routePoints.isNotEmpty) {
              final previous = _routePoints.last;
              final meters = Geolocator.distanceBetween(
                previous.latitude,
                previous.longitude,
                point.latitude,
                point.longitude,
              );
              if (meters < 500) _routeDistanceKm += meters / 1000;
            }
            setState(() => _routePoints.add(point));
          },
          onError: (_) {
            if (mounted) setState(() => _locationStatus = '轨迹读取中断，手表运动仍在继续');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.controller.activeSport == widget.mode;
    final duration = Duration(seconds: _elapsedSeconds);
    final time = [
      duration.inHours,
      duration.inMinutes.remainder(60),
      duration.inSeconds.remainder(60),
    ].map((value) => value.toString().padLeft(2, '0')).join(':');
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.label)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D3B6F), Color(0xFF385D9C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Icon(
                  active ? Icons.directions_run_rounded : Icons.route_rounded,
                  color: Colors.white,
                  size: 70,
                ),
                const SizedBox(height: 22),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  active
                      ? '${widget.mode.label}进行中'
                      : '准备开始${widget.mode.label}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InlineNotice(
            message: widget.controller.connectedDevice == null
                ? '请先在设备页连接手表，运动模式将由手表记录。'
                : '已连接 ${widget.controller.connectedDevice!.name}（${widget.controller.connectedDevice!.sdkSource.shortLabel}）。$_locationStatus',
            icon: Icons.watch_rounded,
            color: SaydianColors.blue,
          ),
          if (_routePoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            SportRoutePreview(
              points: _routePoints,
              distanceKm: _routeDistanceKm,
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: widget.controller.connectedDevice == null
                ? null
                : _toggleSport,
            style: FilledButton.styleFrom(
              backgroundColor: active ? Colors.red : SaydianColors.ink,
            ),
            icon: Icon(active ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(active ? '结束运动' : '开始${widget.mode.label}'),
          ),
        ],
      ),
    );
  }
}

class SportRecordsPage extends StatefulWidget {
  const SportRecordsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<SportRecordsPage> createState() => _SportRecordsPageState();
}

class _SportRecordsPageState extends State<SportRecordsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.refreshSportRecords());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('运动记录')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final records = widget.controller.sportRecords;
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  widget.controller.connectedDevice == null
                      ? '请先连接手表后读取运动记录'
                      : '手表中暂无运动记录',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SaydianColors.muted),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: widget.controller.refreshSportRecords,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _SportRecordTile(
                controller: widget.controller,
                record: records[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SportRecordTile extends StatelessWidget {
  const _SportRecordTile({required this.controller, required this.record});

  final AppController controller;
  final SportRecord record;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: record.durationSeconds);
    final durationText = duration.inHours > 0
        ? '${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟'
        : '${duration.inMinutes}分钟';
    final usesMiles = controller.distanceUnit == '英里';
    final distance = usesMiles
        ? record.distanceKm * 0.621371
        : record.distanceKm;
    final distanceUnit = usesMiles ? '英里' : '公里';
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                SportRecordDetailPage(controller: controller, record: record),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F1FF),
          foregroundColor: Color(0xFF1D3B6F),
          child: Icon(Icons.route_rounded),
        ),
        title: Text(
          record.mode.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${distance.toStringAsFixed(2)} $distanceUnit · '
          '${record.calories.toStringAsFixed(1)} 千卡 · $durationText',
        ),
        trailing: Text(
          record.startedAt == null
              ? '--'
              : DateFormat('MM/dd').format(record.startedAt!.toLocal()),
          style: const TextStyle(color: SaydianColors.muted),
        ),
      ),
    );
  }
}

class SportRecordDetailPage extends StatelessWidget {
  const SportRecordDetailPage({
    required this.controller,
    required this.record,
    super.key,
  });

  final AppController controller;
  final SportRecord record;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: record.durationSeconds);
    final distance = controller.distanceUnit == '英里'
        ? record.distanceKm * 0.621371
        : record.distanceKm;
    final unit = controller.distanceUnit == '英里' ? '英里' : '公里';
    return Scaffold(
      appBar: AppBar(title: Text('${record.mode.label}详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (record.routePoints.length >= 2)
            SportRoutePreview(
              points: record.routePoints,
              distanceKm: record.distanceKm,
            )
          else
            const _InlineNotice(
              message: '该记录没有手机前台轨迹，仍保留手表运动数据。',
              icon: Icons.route_outlined,
              color: SaydianColors.orange,
            ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('运动时长'),
                  trailing: Text(
                    '${duration.inHours.toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('距离'),
                  trailing: Text('${distance.toStringAsFixed(2)} $unit'),
                ),
                if (record.calories > 0) ...[
                  const Divider(indent: 16),
                  ListTile(
                    title: const Text('热量'),
                    trailing: Text('${record.calories.toStringAsFixed(1)} 千卡'),
                  ),
                ],
                if (record.startedAt != null) ...[
                  const Divider(indent: 16),
                  ListTile(
                    title: const Text('开始时间'),
                    trailing: Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(record.startedAt!.toLocal()),
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
}

class SportRoutePreview extends StatelessWidget {
  const SportRoutePreview({
    required this.points,
    required this.distanceKm,
    super.key,
  });

  final List<SportRoutePoint> points;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: CustomPaint(
              painter: _RoutePainter(points),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Text(
              '真实轨迹形状 · ${points.length} 个定位点 · ${distanceKm.toStringAsFixed(2)} 公里\n无地图服务配置时不显示虚假底图',
              style: const TextStyle(
                color: SaydianColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<SportRoutePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF0F4F3),
    );
    if (points.length < 2) return;
    final minLat = points.map((point) => point.latitude).reduce(math.min);
    final maxLat = points.map((point) => point.latitude).reduce(math.max);
    final minLng = points.map((point) => point.longitude).reduce(math.min);
    final maxLng = points.map((point) => point.longitude).reduce(math.max);
    final latSpan = math.max(maxLat - minLat, 0.00001);
    final lngSpan = math.max(maxLng - minLng, 0.00001);
    const padding = 24.0;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x =
          padding +
          (point.longitude - minLng) / lngSpan * (size.width - padding * 2);
      final y =
          size.height -
          padding -
          (point.latitude - minLat) / latSpan * (size.height - padding * 2);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = SaydianColors.blue
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points != points;
}

String _healthDisplayValue(HealthRecord? record, AppController controller) {
  if (record == null) return '--';
  final value =
      record.values['value'] ??
      (record.values.isEmpty ? null : record.values.values.first);
  if (value == null) return record.displayValue;
  if (record.metric == HealthMetric.distance &&
      controller.distanceUnit == '英里') {
    return (value * 0.621371).toStringAsFixed(2);
  }
  if (record.metric == HealthMetric.bodyTemperature &&
      controller.temperatureUnit == '华氏度（℉）') {
    return (value * 9 / 5 + 32).toStringAsFixed(1);
  }
  return record.displayValue;
}

String _healthDisplayUnit(
  HealthMetric metric,
  HealthRecord? record,
  AppController controller,
) {
  if (metric == HealthMetric.distance && controller.distanceUnit == '英里') {
    return 'mi';
  }
  if (metric == HealthMetric.bodyTemperature &&
      controller.temperatureUnit == '华氏度（℉）') {
    return '℉';
  }
  return record?.unit ?? metric.defaultUnit;
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.controller,
    required this.metric,
    required this.record,
    required this.supported,
    required this.connected,
    required this.onMeasure,
  });

  final AppController controller;
  final HealthMetric metric;
  final HealthRecord? record;
  final bool? supported;
  final bool connected;
  final VoidCallback? onMeasure;

  @override
  Widget build(BuildContext context) {
    final status = !connected
        ? '连接手表后使用'
        : supported == false
        ? '当前手表不支持此功能'
        : record == null
        ? '暂无测量记录'
        : '最近 ${DateFormat('MM-dd HH:mm').format(record!.measuredAt.toLocal())}';
    final icon = switch (metric) {
      HealthMetric.heartRate => Icons.favorite_rounded,
      HealthMetric.bloodOxygen => Icons.water_drop_rounded,
      HealthMetric.bloodPressure => Icons.speed_rounded,
      HealthMetric.bloodGlucose => Icons.water_drop_outlined,
      HealthMetric.bodyTemperature => Icons.thermostat_rounded,
      HealthMetric.ecg => Icons.monitor_heart_outlined,
      HealthMetric.hrv => Icons.show_chart_rounded,
      HealthMetric.bodyComposition => Icons.accessibility_new_rounded,
      HealthMetric.bloodComposition => Icons.bloodtype_outlined,
      HealthMetric.steps => Icons.directions_walk_rounded,
      HealthMetric.distance => Icons.location_on_rounded,
      HealthMetric.calories => Icons.local_fire_department_rounded,
      HealthMetric.sleep => Icons.bedtime_rounded,
    };
    final color = switch (metric) {
      HealthMetric.heartRate => SaydianColors.pink,
      HealthMetric.bloodOxygen => SaydianColors.blue,
      HealthMetric.bloodPressure => SaydianColors.orange,
      HealthMetric.bloodGlucose => SaydianColors.green,
      HealthMetric.bodyTemperature => SaydianColors.cyan,
      HealthMetric.ecg => const Color(0xFF6E8DF5),
      HealthMetric.hrv => const Color(0xFF8C7CF0),
      HealthMetric.bodyComposition => SaydianColors.cyan,
      HealthMetric.bloodComposition => SaydianColors.pink,
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
                    _healthDisplayValue(record, controller),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _healthDisplayUnit(metric, record, controller),
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
              IconButton(
                tooltip: '历史数据',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HealthHistoryPage(
                      controller: controller,
                      metric: metric,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthHistoryPage extends StatelessWidget {
  const HealthHistoryPage({
    required this.controller,
    required this.metric,
    super.key,
  });

  final AppController controller;
  final HealthMetric metric;

  @override
  Widget build(BuildContext context) =>
      HealthTrendPage(controller: controller, metric: metric);
}

class AiPage extends StatelessWidget {
  const AiPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshAiArticles,
      child: ListView(
        key: const Key('ai-page'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE7EFFF), Color(0xFFF8FAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF516392),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 健康管家',
                            style: TextStyle(
                              color: Color(0xFF27479C),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '我是您的健康管家，有任何问题都可以跟我提问哦~',
                            style: TextStyle(
                              color: Color(0xFF516392),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _openChat(context, app: 1),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('马上提问'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: InkWell(
              onTap: () => _openChat(context, app: 2),
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi，我是你的运动管家',
                            style: TextStyle(
                              color: Color(0xFF27479C),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            '我可以帮助你提升健身和运动水平！',
                            style: TextStyle(
                              color: Color(0xFF6881C1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFDDE9FF),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFF27479C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                '健康百科',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                controller.aiStatus,
                style: const TextStyle(
                  color: SaydianColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.aiArticles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('暂无健康百科内容')),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < controller.aiArticles.take(5).length;
                    index++
                  ) ...[
                    _ArticleTile(
                      article: controller.aiArticles[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ArticleDetailPage(
                            controller: controller,
                            article: controller.aiArticles[index],
                          ),
                        ),
                      ),
                    ),
                    if (index < controller.aiArticles.take(5).length - 1)
                      const Divider(indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, {required int app}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiChatPage(controller: controller, app: app),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.onTap});

  final Map<String, Object?> article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = '${article['title'] ?? '健康百科'}';
    final created = article['created_at'];
    String date = '';
    if (created is num) {
      date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.fromMillisecondsSinceEpoch(created.toInt() * 1000));
    } else if (created != null) {
      date = '$created';
    }
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F7ED),
        foregroundColor: Color(0xFF258A4A),
        child: Icon(Icons.menu_book_rounded),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: date.isEmpty ? null : Text(date),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({
    required this.controller,
    required this.article,
    this.singleArticle = false,
    super.key,
  });

  final AppController controller;
  final Map<String, Object?> article;
  final bool singleArticle;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Map<String, Object?> _article;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    final id = int.tryParse('${widget.article['id'] ?? ''}');
    if (id != null) unawaited(_load(id));
  }

  Future<void> _load(int id) async {
    final article = widget.singleArticle
        ? await widget.controller.loadSingleArticle(id)
        : await widget.controller.loadArticle(id);
    if (mounted && article.isNotEmpty) setState(() => _article = article);
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_article['title'] ?? '健康百科'}';
    final raw = '${_article['content'] ?? _article['description'] ?? ''}';
    final content = _plainTextFromHtml(raw);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            content.isEmpty ? '文章详情暂未返回正文内容。' : content,
            style: const TextStyle(fontSize: 15, height: 1.75),
          ),
        ],
      ),
    );
  }
}

String _plainTextFromHtml(String raw) => raw
    .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
    .replaceAll(
      RegExp(r'</\s*(p|li|h[1-6]|div)\s*>', caseSensitive: false),
      '\n',
    )
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
    .trim();

class AiChatPage extends StatefulWidget {
  const AiChatPage({required this.controller, required this.app, super.key});

  final AppController controller;
  final int app;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.refreshAiMessages(app: widget.app));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _input.text;
    final sent = await widget.controller.sendAiMessage(
      app: widget.app,
      message: message,
    );
    if (sent) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.app == 2 ? '运动管家' : 'AI 健康管家')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => Column(
          children: [
            Expanded(
              child: widget.controller.aiMessages.isEmpty
                  ? const Center(
                      child: Text(
                        '你好，有什么可以帮你？',
                        style: TextStyle(color: SaydianColors.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.controller.aiMessages.length,
                      itemBuilder: (context, index) {
                        final message = widget.controller.aiMessages[index];
                        final mine =
                            message['my'] == 1 || message['role'] == 'user';
                        final failed = message['send_failed'] == true;
                        final text =
                            '${message['message'] ?? message['content'] ?? ''}';
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? SaydianColors.ink
                                  : const Color(0xFFE8EFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : SaydianColors.ink,
                                    height: 1.45,
                                  ),
                                ),
                                if (failed) ...[
                                  const SizedBox(height: 5),
                                  const Text(
                                    '发送失败，请检查网络后重试',
                                    style: TextStyle(
                                      color: Color(0xFFFFB4B4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: '请输入消息…'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    IconButton.filled(
                      onPressed: widget.controller.isBusy ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
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
        if (connected != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9F9EF), Color(0xFFEAF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  connected.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              DeviceSdkBadge(
                                source: connected.sdkSource,
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _deviceSummary(connected),
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
                        onPressed: controller.isDeviceSyncing
                            ? null
                            : controller.syncDeviceData,
                        icon: controller.isDeviceSyncing
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          controller.isDeviceSyncing
                              ? '同步中 ${(controller.deviceSyncProgress * 100).round()}%'
                              : '同步数据',
                        ),
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
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DeviceSearchPage(controller: controller),
                        ),
                      ),
                      icon: const Icon(Icons.radar_rounded),
                      label: const Text('开始查找'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          '表盘',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _deviceFeatureTile(context, DeviceFeature.watchFaces),
              const Divider(indent: 56),
              _deviceFeatureTile(context, DeviceFeature.photoWatchFace),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '设备功能',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < _primaryFeatures.length; index++) ...[
                _deviceFeatureTile(context, _primaryFeatures[index]),
                if (index != _primaryFeatures.length - 1)
                  const Divider(indent: 56),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                onTap: connected == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: 'device-about'),
                          builder: (_) =>
                              DeviceInfoPage(controller: controller),
                        ),
                      ),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('关于设备'),
                subtitle: Text(connected == null ? '连接手表后使用' : '查看设备信息和支持功能'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              const Divider(indent: 56),
              ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: 'connection-help'),
                    builder: (_) => const _InfoPage(
                      title: '连接说明',
                      message:
                          '1. 打开手机蓝牙并允许查找附近设备。\n'
                          '2. 将手表充电激活，并放在手机旁边。\n'
                          '3. 点击“开始查找”，选择自己的手表。\n'
                          '4. 如果手表弹出确认，请及时确认。',
                    ),
                  ),
                ),
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('连接说明'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _InlineNotice(
          message: '连接或同步时，请让手表保持电量充足并靠近手机。',
          icon: Icons.info_outline_rounded,
          color: SaydianColors.blue,
        ),
      ],
    );
  }

  static const _primaryFeatures = <DeviceFeature>[
    DeviceFeature.findWatch,
    DeviceFeature.camera,
    DeviceFeature.phoneCalls,
    DeviceFeature.contacts,
    DeviceFeature.notifications,
    DeviceFeature.alarms,
    DeviceFeature.weather,
    DeviceFeature.worldClock,
    DeviceFeature.healthReminders,
    DeviceFeature.healthMonitoring,
    DeviceFeature.healthAssessment,
    DeviceFeature.screenDisplay,
  ];

  Widget _deviceFeatureTile(BuildContext context, DeviceFeature feature) {
    final availability = controller.availabilityFor(feature);
    final icon = switch (feature) {
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
    return ListTile(
      onTap: () {
        if (feature == DeviceFeature.healthMonitoring) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'device-health-monitoring'),
              builder: (_) => PermissionManagementPage(
                controller: controller,
                healthOnly: true,
              ),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: RouteSettings(name: 'device-${feature.wireName}'),
            builder: (_) =>
                DeviceFeaturePage(controller: controller, feature: feature),
          ),
        );
      },
      leading: Icon(icon),
      title: Text(feature.label),
      subtitle: Text(availability.message),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  String _deviceSummary(DeviceInfo device) {
    final values = <String>[
      if (device.model?.trim().isNotEmpty ?? false) device.model!.trim(),
      if (device.firmwareVersion?.trim().isNotEmpty ?? false)
        '版本 ${device.firmwareVersion!.trim()}',
    ];
    return values.isEmpty ? '手表已连接' : values.join(' · ');
  }

  String _deviceStateLabel(DeviceConnectionState state) => switch (state) {
    DeviceConnectionState.disconnected => '未连接',
    DeviceConnectionState.scanning => '正在搜索',
    DeviceConnectionState.connecting => '连接中',
    DeviceConnectionState.authenticating => '等待确认',
    DeviceConnectionState.syncing => '正在同步',
    DeviceConnectionState.ready => '已连接',
    DeviceConnectionState.measuring => '测量中',
    DeviceConnectionState.error => '需要处理',
  };
}

class DeviceSearchPage extends StatefulWidget {
  const DeviceSearchPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<DeviceSearchPage> createState() => _DeviceSearchPageState();
}

class _DeviceSearchPageState extends State<DeviceSearchPage> {
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startScan());
    });
  }

  @override
  void dispose() {
    unawaited(widget.controller.stopDeviceScan());
    if (_connectingDeviceId != null) {
      unawaited(widget.controller.disconnectDevice());
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_connectingDeviceId != null) return;
    widget.controller.clearError();
    await widget.controller.scanDevices();
  }

  Future<void> _connect(DeviceInfo device) async {
    if (_connectingDeviceId != null) return;
    setState(() => _connectingDeviceId = device.id);
    await widget.controller.connectDevice(device);
    if (!mounted) return;
    if (widget.controller.connectedDevice?.id == device.id &&
        widget.controller.deviceState == DeviceConnectionState.ready) {
      _connectingDeviceId = null;
      Navigator.of(context).pop();
      return;
    }
    setState(() => _connectingDeviceId = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final devices = controller.scannedDevices;
        final scanning =
            controller.deviceState == DeviceConnectionState.scanning;
        final connecting = _connectingDeviceId != null;
        return PopScope(
          canPop: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('添加设备'),
              actions: [
                IconButton(
                  tooltip: '重新搜索',
                  onPressed: scanning || connecting ? null : _startScan,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: devices.isEmpty
                  ? _DeviceSearchEmpty(
                      scanning: scanning,
                      errorMessage: controller.errorMessage,
                      onRetry: scanning || connecting ? null : _startScan,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        const Text(
                          '已发现设备',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          scanning ? '正在持续搜索，请将手表靠近手机' : '请选择需要连接的手表',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SaydianColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        if (scanning) ...[
                          const SizedBox(height: 14),
                          const LinearProgressIndicator(minHeight: 3),
                        ],
                        if (controller.errorMessage?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 14),
                          _InlineNotice(
                            message: controller.errorMessage!,
                            icon: Icons.error_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                        const SizedBox(height: 18),
                        for (final device in devices)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: connecting
                                    ? null
                                    : () => _connect(device),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    15,
                                    12,
                                    15,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: SaydianColors.ink,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.watch_rounded,
                                          color: Colors.white,
                                          size: 29,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    device.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                DeviceSdkBadge(
                                                  source: device.sdkSource,
                                                  compact: true,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              device.identifierLabel,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _signalIcon(device.rssi),
                                                size: 18,
                                                color: SaydianColors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${device.rssi ?? '--'}',
                                                style: const TextStyle(
                                                  color: SaydianColors.muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 7),
                                          if (_connectingDeviceId == device.id)
                                            const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            const Text(
                                              '连接',
                                              style: TextStyle(
                                                color: SaydianColors.blue,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (connecting) ...[
                          const SizedBox(height: 8),
                          _InlineNotice(
                            message:
                                controller.deviceState ==
                                        DeviceConnectionState.connecting ||
                                    controller.deviceState ==
                                        DeviceConnectionState.authenticating
                                ? '正在连接；如手表弹出确认，请在 12 秒内确认，并保持手表靠近手机…'
                                : '正在${_deviceStateLabel(controller.deviceState)}，请保持手表靠近手机…',
                            icon: Icons.bluetooth_connected_rounded,
                            color: SaydianColors.blue,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  IconData _signalIcon(int? rssi) {
    if (rssi == null || rssi < -85) return Icons.signal_cellular_alt_1_bar;
    if (rssi < -65) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt;
  }

  String _deviceStateLabel(DeviceConnectionState state) => switch (state) {
    DeviceConnectionState.connecting => '连接',
    DeviceConnectionState.authenticating => '认证',
    DeviceConnectionState.syncing => '同步数据',
    _ => '连接设备',
  };
}

class _DeviceSearchEmpty extends StatelessWidget {
  const _DeviceSearchEmpty({
    required this.scanning,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool scanning;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 58, 28, 32),
      children: [
        Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 74),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDCEBFF), Color(0xFFF0F6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            scanning ? Icons.radar_rounded : Icons.watch_off_outlined,
            color: SaydianColors.blue,
            size: 76,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          scanning ? '正在搜索附近手表' : '未发现设备',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          scanning
              ? '请取出设备、充电激活，并将手表靠近手机'
              : (errorMessage?.trim().isNotEmpty ?? false)
              ? errorMessage!
              : '请确认手表有电且未连接其他手机，然后重新搜索',
          textAlign: TextAlign.center,
          style: const TextStyle(color: SaydianColors.muted, height: 1.5),
        ),
        if (scanning) ...[
          const SizedBox(height: 24),
          const LinearProgressIndicator(),
        ] else ...[
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新搜索'),
          ),
          const SizedBox(height: 20),
          const _InlineNotice(
            message: '可尝试重新打开手机蓝牙、让手表靠近手机，或先在其他手机上断开该手表。',
            icon: Icons.info_outline_rounded,
            color: SaydianColors.blue,
          ),
        ],
      ],
    );
  }
}

class DeviceInfoPage extends StatelessWidget {
  const DeviceInfoPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.connectedDevice;
    final capabilities = controller.capabilities;
    return Scaffold(
      appBar: AppBar(title: const Text('关于设备')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('设备名称'),
                  trailing: Text(device?.name ?? '--'),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('接入方案'),
                  trailing: device == null
                      ? const Text('--')
                      : DeviceSdkBadge(source: device.sdkSource),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('设备型号'),
                  trailing: Text(device?.model ?? '--'),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('固件版本'),
                  trailing: Text(device?.firmwareVersion ?? '--'),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: Text(
                    device?.macAddress != null
                        ? 'MAC 地址'
                        : defaultTargetPlatform == TargetPlatform.iOS
                        ? 'iOS 设备标识'
                        : '设备标识',
                  ),
                  subtitle: Text(
                    device?.macAddress ?? device?.nativeId ?? '--',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('支持的健康项目'),
                  subtitle: Text(
                    capabilities == null || capabilities.metrics.isEmpty
                        ? '暂时未读取到相关信息'
                        : capabilities.metrics
                              .map((metric) => metric.label)
                              .join('、'),
                  ),
                ),
                const Divider(indent: 16),
                ListTile(
                  title: const Text('支持的设备功能'),
                  subtitle: Text(
                    capabilities == null || capabilities.features.isEmpty
                        ? '暂时未读取到相关信息'
                        : capabilities.features
                              .map((feature) => feature.label)
                              .join('、'),
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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.refreshNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final values = widget.controller.notifications;
          if (values.isEmpty) {
            return Center(
              child: Text(
                widget.controller.notificationStatus,
                style: const TextStyle(color: SaydianColors.muted),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: widget.controller.refreshNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = values[index];
                final id = int.tryParse('${item['id'] ?? ''}');
                return Card(
                  child: ListTile(
                    onTap: id == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NotificationDetailPage(
                                controller: widget.controller,
                                id: id,
                                initial: item,
                              ),
                            ),
                          ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.notifications_none_rounded),
                    ),
                    title: Text(
                      '${item['title'] ?? item['name'] ?? '系统消息'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${item['created_at'] ?? item['createdAt'] ?? ''}',
                      maxLines: 1,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({
    required this.controller,
    required this.id,
    required this.initial,
    super.key,
  });

  final AppController controller;
  final int id;
  final Map<String, Object?> initial;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late Map<String, Object?> _value = widget.initial;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await widget.controller.loadNotification(widget.id);
    if (mounted && value.isNotEmpty) setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_value['title'] ?? _value['name'] ?? '消息详情'}';
    final raw = '${_value['content'] ?? _value['description'] ?? ''}';
    final content = _plainTextFromHtml(raw);
    return Scaffold(
      appBar: AppBar(title: const Text('消息详情')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            content.isEmpty ? '暂无消息正文' : content,
            style: const TextStyle(height: 1.7),
          ),
        ],
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
      onRefresh: () async {
        await Future.wait([
          controller.refreshCare(),
          controller.refreshCareInvitations(),
        ]);
      },
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
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'sharing-management'),
                  builder: (_) => SharingManagementPage(controller: controller),
                ),
              ),
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('共享管理'),
              subtitle: const Text('查看成员和数据授权说明'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'care-invitations'),
                  builder: (_) => CareInvitationsPage(controller: controller),
                ),
              ),
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: const Text('关爱邀请'),
              subtitle: Text(
                controller.careInvitations.isEmpty
                    ? controller.careStatus == '服务暂不可用'
                          ? '服务暂不可用'
                          : '暂无待处理邀请'
                    : '${controller.careInvitations.length} 条邀请',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
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
                      controller.isPreviewMode ? '当前暂无关爱成员' : '暂无关爱成员',
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
                    onTap: () {
                      final id = int.tryParse('${member['id'] ?? ''}');
                      if (id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CareMemberPage(
                            controller: controller,
                            member: member,
                            careId: id,
                          ),
                        ),
                      );
                    },
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

class CareMemberPage extends StatefulWidget {
  const CareMemberPage({
    required this.controller,
    required this.member,
    required this.careId,
    super.key,
  });

  final AppController controller;
  final Map<String, Object?> member;
  final int careId;

  @override
  State<CareMemberPage> createState() => _CareMemberPageState();
}

class _CareMemberPageState extends State<CareMemberPage> {
  Map<String, Object?> _data = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await widget.controller.loadCareMemberPreview(widget.careId);
    if (mounted) {
      setState(() {
        _data = value;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        '${widget.member['nickname'] ?? widget.member['mobile'] ?? '关爱成员'}';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_data.isEmpty)
                    const _InlineNotice(
                      message: '对方尚未授权健康数据，或当前日期没有数据。',
                      icon: Icons.privacy_tip_outlined,
                      color: SaydianColors.orange,
                    )
                  else
                    for (final entry in _data.entries)
                      Card(
                        child: ListTile(
                          title: Text(_careDataLabel(entry.key)),
                          subtitle: Text(_careDataText(entry.value)),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  String _careDataLabel(String key) => switch (key) {
    'jrjk' => '今日健康',
    'daily' => '活动与睡眠',
    _ => key,
  };

  String _careDataText(Object? value) {
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}：${entry.value}')
          .join('\n');
    }
    if (value is List) return value.join('\n');
    return '$value';
  }
}

class _AddCareDialog extends StatefulWidget {
  const _AddCareDialog();

  @override
  State<_AddCareDialog> createState() => _AddCareDialogState();
}

class _AddCareDialogState extends State<_AddCareDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_mobileController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('添加关爱'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _mobileController,
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
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _submit, child: const Text('发送')),
    ],
  );
}

Future<void> _showAddCareDialog(
  BuildContext context,
  AppController controller,
) async {
  final mobile = await showDialog<String>(
    context: context,
    builder: (_) => const _AddCareDialog(),
  );
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
    final profile = controller.memberProfile;
    final name =
        '${profile['nickname'] ?? controller.session?.displayName ?? (controller.isPreviewMode ? '体验用户' : '赛电用户')}';
    final memberId =
        '${profile['promo_code'] ?? controller.session?.memberId ?? '--'}';
    return ListView(
      key: const Key('my-page'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        GestureDetector(
          onTap: () =>
              _openPage(context, ProfileEditPage(controller: controller)),
          child: Container(
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
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        controller.session == null
                            ? '健康档案仅保存在本机'
                            : 'ID：$memberId',
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
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      '我的订单',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openOrders(context, null),
                      child: const Text('全部'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _OrderEntry(
                        label: '待支付',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => _openOrders(context, 0),
                      ),
                    ),
                    Expanded(
                      child: _OrderEntry(
                        label: '待发货',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => _openOrders(context, 1),
                      ),
                    ),
                    Expanded(
                      child: _OrderEntry(
                        label: '待收货',
                        icon: Icons.local_shipping_outlined,
                        onTap: () => _openOrders(context, 2),
                      ),
                    ),
                    Expanded(
                      child: _OrderEntry(
                        label: '售后',
                        icon: Icons.support_agent_rounded,
                        onTap: () => _openPage(context, const AfterSalesPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MySettingCard(
                title: '单位设置',
                subtitle: '设置系统数据单位',
                icon: Icons.straighten_rounded,
                color: SaydianColors.blue,
                onTap: () => _openPage(
                  context,
                  UnitSettingsPage(controller: controller),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MySettingCard(
                title: '目标设置',
                subtitle: '调整您的每日目标',
                icon: Icons.track_changes_rounded,
                color: SaydianColors.green,
                onTap: () => _openPage(
                  context,
                  GoalSettingsPage(controller: controller),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 14),
                    child: Text(
                      '我的服务',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _MyServiceEntry(
                        label: '账号设置',
                        icon: Icons.manage_accounts_outlined,
                        onTap: () => _openPage(
                          context,
                          AccountSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _MyServiceEntry(
                        label: '权限管理',
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () => _openPage(
                          context,
                          PermissionManagementPage(controller: controller),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _MyServiceEntry(
                        label: '帮助反馈',
                        icon: Icons.help_outline_rounded,
                        onTap: () => _openPage(context, const FeedbackPage()),
                      ),
                    ),
                    Expanded(
                      child: _MyServiceEntry(
                        label: '联系客服',
                        icon: Icons.headset_mic_outlined,
                        onTap: () =>
                            _openPage(context, const CustomerServicePage()),
                      ),
                    ),
                    Expanded(
                      child: _MyServiceEntry(
                        label: '关于我们',
                        icon: Icons.info_outline_rounded,
                        onTap: () => _openPage(
                          context,
                          AboutSaydianPage(controller: controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openOrders(BuildContext context, int? status) {
    _openPage(
      context,
      OrdersPage(controller: controller, initialStatus: status),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _OrderEntry extends StatelessWidget {
  const _OrderEntry({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: SaydianColors.ink, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MySettingCard extends StatelessWidget {
  const _MySettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _SettingsIcon(icon: icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        color: SaydianColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyServiceEntry extends StatelessWidget {
  const _MyServiceEntry({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF516392), size: 25),
            const SizedBox(height: 7),
            Text(label, maxLines: 1, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    required this.controller,
    required this.initialStatus,
    super.key,
  });

  final AppController controller;
  final int? initialStatus;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late int? _status;
  static const _filters = <(int?, String)>[
    (null, '全部'),
    (0, '待支付'),
    (1, '待发货'),
    (2, '待收货'),
    (3, '已完成'),
    (-1, '售后'),
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    unawaited(widget.controller.loadOrders(_status == -1 ? null : _status));
  }

  void _selectStatus(int? value) {
    if (_status == value) return;
    setState(() => _status = value);
    unawaited(widget.controller.loadOrders(value == -1 ? null : value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final filter in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.$2),
                      selected: _status == filter.$1,
                      onSelected: (_) => _selectStatus(filter.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final orders = _status == -1
                    ? widget.controller.orders.where((order) {
                        final status = int.tryParse(
                          '${order['order_status'] ?? ''}',
                        );
                        return status != null && status < 0;
                      }).toList()
                    : widget.controller.orders;
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      widget.controller.orderStatus,
                      style: const TextStyle(color: SaydianColors.muted),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => widget.controller.loadOrders(
                    _status == -1 ? null : _status,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _OrderCard(
                      controller: widget.controller,
                      order: orders[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.controller, required this.order});

  final AppController controller;
  final Map<String, Object?> order;

  @override
  Widget build(BuildContext context) {
    final products = order['product'] is List
        ? order['product'] as List
        : const [];
    final status = switch (int.tryParse('${order['order_status'] ?? ''}')) {
      0 => '待付款',
      1 => '待发货',
      2 => '待收货',
      3 => '待评价',
      4 => '已完成',
      -1 => '申请退款',
      -2 => '退款中',
      -3 => '已退款',
      _ => '订单处理中',
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final id = int.tryParse('${order['id'] ?? ''}');
          if (id == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailPage(controller: controller, id: id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '订单 ${order['order_sn'] ?? order['id'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    status,
                    style: const TextStyle(
                      color: SaydianColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              for (final product in products.whereType<Map>()) ...[
                const Divider(height: 24),
                Text(
                  '${product['product_name'] ?? '商品'} × ${product['num'] ?? 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['sku_name'] ?? ''}',
                  style: const TextStyle(color: SaydianColors.muted),
                ),
              ],
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '实付款 ¥${order['pay_money'] ?? '--'}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    required this.controller,
    required this.id,
    super.key,
  });

  final AppController controller;
  final int id;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, Object?> _order = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await widget.controller.loadOrderDetail(widget.id);
    if (mounted) {
      setState(() {
        _order = value;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _order['product'] is List
        ? _order['product'] as List
        : const [];
    final status = int.tryParse('${_order['order_status'] ?? ''}');
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_order.isEmpty)
                    const _InlineNotice(
                      message: '订单详情加载失败，请稍后重试。',
                      icon: Icons.error_outline_rounded,
                      color: SaydianColors.orange,
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '订单 ${_order['order_sn'] ?? widget.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('下单时间：${_order['created_at'] ?? '--'}'),
                            Text(
                              '收货人：${_order['receiver_name'] ?? _order['realname'] ?? '--'}',
                            ),
                            Text(
                              '联系电话：${_order['receiver_mobile'] ?? _order['mobile'] ?? '--'}',
                            ),
                            Text(
                              '收货地址：${_order['receiver_address'] ?? _order['address'] ?? '--'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final product in products.whereType<Map>())
                      Card(
                        child: ListTile(
                          title: Text('${product['product_name'] ?? '商品'}'),
                          subtitle: Text('${product['sku_name'] ?? ''}'),
                          trailing: Text('× ${product['num'] ?? 1}'),
                        ),
                      ),
                    Card(
                      child: ListTile(
                        title: const Text('实付款'),
                        trailing: Text(
                          '¥${_order['pay_money'] ?? '--'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (status == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ShopPaymentStatusPage(
                                  controller: widget.controller,
                                  orderId: widget.id,
                                  ordersPageBuilder: (_) => OrdersPage(
                                    controller: widget.controller,
                                    initialStatus: 0,
                                  ),
                                ),
                              ),
                            ),
                            child: const Text('查看支付状态'),
                          ),
                        ),
                      ),
                    if (status != null && status >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ShopExpressPage(
                                  controller: widget.controller,
                                  orderId: widget.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: const Text('查看物流'),
                          ),
                        ),
                      ),
                    if (status != null && status > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: 'after-sales',
                                ),
                                builder: (_) => AfterSalesPage(
                                  orderNumber:
                                      '${_order['order_sn'] ?? widget.id}',
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.support_agent_outlined),
                            label: const Text('申请售后'),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class UnitSettingsPage extends StatefulWidget {
  const UnitSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<UnitSettingsPage> createState() => _UnitSettingsPageState();
}

class _UnitSettingsPageState extends State<UnitSettingsPage> {
  late String _distance = widget.controller.distanceUnit;
  late String _temperature = widget.controller.temperatureUnit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单位设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: RadioGroup<String>(
              groupValue: _distance,
              onChanged: (value) {
                setState(() => _distance = value!);
                widget.controller.setUnits(distance: value);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: '公里',
                    title: Text('公里'),
                    subtitle: Text('距离使用 km'),
                  ),
                  RadioListTile<String>(
                    value: '英里',
                    title: Text('英里'),
                    subtitle: Text('距离使用 mi'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: RadioGroup<String>(
              groupValue: _temperature,
              onChanged: (value) {
                setState(() => _temperature = value!);
                widget.controller.setUnits(temperature: value);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(value: '摄氏度（℃）', title: Text('摄氏度（℃）')),
                  RadioListTile<String>(value: '华氏度（℉）', title: Text('华氏度（℉）')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _InlineNotice(
            message: '单位选择会立即生效。重新安装应用后可能需要再次设置。',
            icon: Icons.info_outline_rounded,
            color: SaydianColors.blue,
          ),
        ],
      ),
    );
  }
}

class GoalSettingsPage extends StatefulWidget {
  const GoalSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends State<GoalSettingsPage> {
  late final TextEditingController _steps;
  late final TextEditingController _distance;
  late final TextEditingController _calories;

  @override
  void initState() {
    super.initState();
    _steps = TextEditingController(text: '${widget.controller.stepGoal}');
    _distance = TextEditingController(
      text: '${widget.controller.distanceGoal}',
    );
    _calories = TextEditingController(text: '${widget.controller.calorieGoal}');
  }

  @override
  void dispose() {
    _steps.dispose();
    _distance.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final steps = int.tryParse(_steps.text);
    final distance = double.tryParse(_distance.text);
    final calories = int.tryParse(_calories.text);
    if (steps == null ||
        distance == null ||
        calories == null ||
        steps <= 0 ||
        distance <= 0 ||
        calories <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的目标数值')));
      return;
    }
    final saved = await widget.controller.saveActivityGoals(
      steps: steps,
      distance: distance,
      calories: calories,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? '目标已保存' : widget.controller.errorMessage ?? '保存失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目标设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _steps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '每日步数目标（步）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '每日距离目标（公里）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '每日热量目标（千卡）'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.controller.isBusy ? null : _save,
            child: const Text('保存目标'),
          ),
        ],
      ),
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileEditPage(controller: controller),
                    ),
                  ),
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('个人资料'),
                  subtitle: const Text('昵称、性别、生日、身高和体重'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(indent: 56),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ShopAddressBookPage(controller: controller),
                    ),
                  ),
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('收货地址'),
                  subtitle: const Text('查看账号中的收货地址'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(indent: 56),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'account-security'),
                      builder: (_) => const SecurityCenterPage(),
                    ),
                  ),
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('账号与安全'),
                  subtitle: const Text('密码与登录保护'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(indent: 56),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArticleDetailPage(
                        controller: controller,
                        article: const {'id': 3, 'title': '隐私协议'},
                        singleArticle: true,
                      ),
                    ),
                  ),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('隐私协议'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: controller.isBusy ? null : controller.logout,
            child: Text(controller.isPreviewMode ? '退出体验' : '退出登录'),
          ),
          TextButton(
            onPressed: controller.session == null
                ? null
                : () => _confirmDeleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('注销账号'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销账号？'),
        content: const Text('账号及相关数据删除成功后，本机会退出登录。'),
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
    if (confirmed == true) await controller.deleteAccount();
  }
}

class AddressPage extends StatefulWidget {
  const AddressPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.loadAddresses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收货地址')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final addresses = widget.controller.addresses;
          if (addresses.isEmpty) {
            return const Center(
              child: Text(
                '暂无收货地址',
                style: TextStyle(color: SaydianColors.muted),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: widget.controller.loadAddresses,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const CircleAvatar(
                      child: Icon(Icons.location_on_outlined),
                    ),
                    title: Text(
                      '${address['realname'] ?? ''}  ${address['mobile'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${address['address_name'] ?? address['region'] ?? ''}'
                        '${address['address_details'] ?? ''}',
                      ),
                    ),
                    trailing: '${address['is_default']}' == '1'
                        ? const Chip(label: Text('默认'))
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nickname;
  late final TextEditingController _birthday;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late int _gender;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.memberProfile;
    _nickname = TextEditingController(text: '${profile['nickname'] ?? ''}');
    _birthday = TextEditingController(text: '${profile['birthday'] ?? ''}');
    _height = TextEditingController(text: '${profile['height'] ?? ''}');
    _weight = TextEditingController(text: '${profile['weight'] ?? ''}');
    _gender = int.tryParse('${profile['gender'] ?? 1}') ?? 1;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _birthday.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final initial = DateTime.tryParse(_birthday.text) ?? DateTime(1990);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      _birthday.text = DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  Future<void> _save() async {
    final height = double.tryParse(_height.text);
    final weight = double.tryParse(_weight.text);
    if (_nickname.text.trim().isEmpty ||
        _birthday.text.isEmpty ||
        height == null ||
        height < 50 ||
        height > 300 ||
        weight == null ||
        weight < 10 ||
        weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写资料，身高 50~300 cm、体重 10~500 kg')),
      );
      return;
    }
    final saved = await widget.controller.saveMemberProfile(
      nickname: _nickname.text.trim(),
      gender: _gender,
      birthday: _birthday.text,
      height: height,
      weight: weight,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? '个人资料已保存' : widget.controller.errorMessage ?? '保存失败',
        ),
      ),
    );
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nickname,
            decoration: const InputDecoration(labelText: '昵称'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: '性别'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('男')),
              DropdownMenuItem(value: 2, child: Text('女')),
            ],
            onChanged: (value) => setState(() => _gender = value ?? 1),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _birthday,
            readOnly: true,
            onTap: _selectBirthday,
            decoration: const InputDecoration(
              labelText: '出生日期',
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '身高（cm）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '体重（kg）'),
          ),
          const SizedBox(height: 18),
          const _InlineNotice(
            message: '这些信息用于更准确地计算运动和健康数据；保存时会保留现有头像。',
            icon: Icons.privacy_tip_outlined,
            color: SaydianColors.blue,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: widget.controller.isBusy ? null : _save,
            child: const Text('保存资料'),
          ),
        ],
      ),
    );
  }
}

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({
    required this.controller,
    this.healthOnly = false,
    super.key,
  });

  final AppController controller;
  final bool healthOnly;

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  Map<Permission, PermissionStatus> _statuses = const {};

  List<Permission> get _permissions =>
      defaultTargetPlatform == TargetPlatform.android
      ? [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
          Permission.notification,
          Permission.photos,
          Permission.camera,
          Permission.contacts,
        ]
      : [
          Permission.bluetooth,
          Permission.locationWhenInUse,
          Permission.notification,
          Permission.photos,
          Permission.camera,
          Permission.contacts,
        ];

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    unawaited(widget.controller.refreshDeviceSettings());
  }

  Future<void> _refresh() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in _permissions) {
      statuses[permission] = await permission.status;
    }
    if (mounted) setState(() => _statuses = statuses);
  }

  Future<void> _request(Permission permission) async {
    await permission.request();
    await _refresh();
  }

  String _name(Permission permission) {
    if (permission == Permission.bluetoothScan) return '附近设备扫描';
    if (permission == Permission.bluetoothConnect) return '蓝牙设备连接';
    if (permission == Permission.bluetooth) return '蓝牙';
    if (permission == Permission.locationWhenInUse) return '位置';
    if (permission == Permission.photos) return '照片';
    if (permission == Permission.camera) return '相机';
    if (permission == Permission.contacts) return '联系人';
    return '通知';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.healthOnly ? '健康监测' : '权限管理')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '手表健康检测',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: widget.controller.connectedDevice == null
                      ? null
                      : widget.controller.refreshDeviceSettings,
                  tooltip: '从手表刷新',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            Text(
              widget.controller.deviceSettingsStatus,
              style: const TextStyle(color: SaydianColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _deviceAutoSwitch(
                    type: 'heartRate',
                    title: '心率自动检测',
                    icon: Icons.favorite_outline_rounded,
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: SaydianColors.orange,
                    ),
                    title: const Text('心率过高预警'),
                    subtitle: Text(
                      widget.controller.heartRateWarningSupported
                          ? '达到阈值后由手表提醒'
                          : '当前设备不支持此功能',
                    ),
                    trailing: DropdownButton<int>(
                      value: widget.controller.heartRateWarning,
                      items: [
                        for (var value = 70; value < 190; value += 5)
                          DropdownMenuItem(
                            value: value,
                            child: Text('$value 次/分'),
                          ),
                      ],
                      onChanged:
                          widget.controller.connectedDevice == null ||
                              !widget.controller.heartRateWarningSupported
                          ? null
                          : (value) {
                              if (value != null) {
                                unawaited(
                                  widget.controller.setHeartRateWarning(value),
                                );
                              }
                            },
                    ),
                  ),
                  const Divider(indent: 56),
                  _deviceAutoSwitch(
                    type: 'bloodPressure',
                    title: '血压自动检测',
                    icon: Icons.speed_rounded,
                  ),
                  const Divider(indent: 56),
                  _deviceAutoSwitch(
                    type: 'bloodGlucose',
                    title: '血糖自动检测',
                    icon: Icons.water_drop_outlined,
                  ),
                  const Divider(indent: 56),
                  _deviceAutoSwitch(
                    type: 'bodyTemperature',
                    title: '体温自动检测',
                    icon: Icons.thermostat_rounded,
                  ),
                ],
              ),
            ),
            if (!widget.healthOnly) ...[
              const SizedBox(height: 20),
              const Text(
                'App 系统权限',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final permission in _permissions) ...[
                      ListTile(
                        leading: Icon(
                          _statuses[permission]?.isGranted == true
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: _statuses[permission]?.isGranted == true
                              ? SaydianColors.green
                              : SaydianColors.orange,
                        ),
                        title: Text(_name(permission)),
                        subtitle: Text(
                          _statuses[permission]?.isGranted == true
                              ? '已允许'
                              : '未允许',
                        ),
                        trailing: TextButton(
                          onPressed: () => _request(permission),
                          child: const Text('设置'),
                        ),
                      ),
                      if (permission != _permissions.last)
                        const Divider(indent: 56),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('打开系统应用设置'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _deviceAutoSwitch({
    required String type,
    required String title,
    required IconData icon,
  }) {
    final settings = widget.controller.autoMeasureSettings;
    final supported = settings.containsKey(type);
    return SwitchListTile(
      secondary: Icon(icon, color: SaydianColors.pink),
      title: Text(title),
      subtitle: Text(
        widget.controller.connectedDevice == null
            ? '请先连接手表'
            : supported
            ? ((settings[type] ?? false) ? '已开启' : '已关闭')
            : '当前设备不支持此功能',
      ),
      value: settings[type] ?? false,
      onChanged: supported
          ? (value) {
              unawaited(widget.controller.setAutoMeasureSetting(type, value));
            }
          : null,
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.7),
          ),
        ),
      ),
    );
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
