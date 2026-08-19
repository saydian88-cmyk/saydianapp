import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/feature_models.dart';
import '../services/app_controller.dart';
import '../services/device_watch_face_market_service.dart';
import 'app_theme.dart';

class DeviceWatchFaceMarketPage extends StatefulWidget {
  const DeviceWatchFaceMarketPage({
    required this.controller,
    this.service,
    super.key,
  });

  final AppController controller;
  final DeviceWatchFaceMarketService? service;

  @override
  State<DeviceWatchFaceMarketPage> createState() =>
      _DeviceWatchFaceMarketPageState();
}

class _DeviceWatchFaceMarketPageState extends State<DeviceWatchFaceMarketPage> {
  late final DeviceWatchFaceMarketService _service;
  final List<DeviceWatchFaceMarketItem> _items = [];
  int _page = 0;
  int _pageCount = 1;
  int _total = 0;
  bool _loading = false;
  DeviceWatchFaceMarketItem? _installing;
  double _downloadProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DeviceWatchFaceMarketService();
    unawaited(_load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    final nextPage = reset ? 1 : _page + 1;
    if (!reset && nextPage > _pageCount) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _pageCount = 1;
      }
    });
    try {
      final result = await _service.loadPage(page: nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.pageIndex;
        _pageCount = result.pageCount;
        _total = result.total;
      });
    } on DeviceWatchFaceMarketException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '表盘商城加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _install(DeviceWatchFaceMarketItem item) async {
    if (_installing != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用这个表盘？'),
        content: const Text('下载后会传送到手表。传送期间请保持手表靠近手机，不要离开当前页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('下载并使用'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _installing = item;
      _downloadProgress = 0;
    });
    try {
      final filePath = await _service.download(
        item,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );
      final saved = await widget.controller.writeDeviceFeature(
        DeviceFeature.watchFaces,
        {
          'operation': 'upload_network',
          'filePath': filePath,
          'name': item.name,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? '表盘已传送并设置完成' : widget.controller.errorMessage ?? '表盘设置失败',
          ),
        ),
      );
    } on DeviceWatchFaceMarketException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('表盘设置失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _installing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表盘商城')),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          key: const Key('watch-face-market-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '为 W9S 精选',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_total > 0)
                      Text(
                        '共 $_total 款',
                        style: const TextStyle(color: SaydianColors.muted),
                      ),
                  ],
                ),
              ),
            ),
            if (_items.isEmpty && _loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.watch_outlined, size: 58),
                        const SizedBox(height: 14),
                        Text(_error ?? '暂无可用表盘', textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _loading ? null : () => _load(reset: true),
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .72,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final installing = identical(_installing, item);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _installing == null
                            ? () => _install(item)
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(
                                item.previewUrl.toString(),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                errorBuilder: (_, _, _) => const ColoredBox(
                                  color: SaydianColors.brandRedSoft,
                                  child: Icon(Icons.watch_outlined, size: 52),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (installing) ...[
                                    LinearProgressIndicator(
                                      value:
                                          _downloadProgress > 0 &&
                                              _downloadProgress < 1
                                          ? _downloadProgress
                                          : null,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _downloadProgress < 1
                                          ? '正在下载'
                                          : '正在传送到手表',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ] else
                                    const Text(
                                      '点击下载并使用',
                                      style: TextStyle(
                                        color: SaydianColors.brandRed,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _page < _pageCount
                      ? OutlinedButton(
                          onPressed: _loading ? null : _load,
                          child: Text(_loading ? '加载中…' : '加载更多'),
                        )
                      : const Center(
                          child: Text(
                            '已经到底了',
                            style: TextStyle(color: SaydianColors.muted),
                          ),
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
