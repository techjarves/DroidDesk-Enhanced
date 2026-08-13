import 'dart:async';

import 'package:droiddesk/services/platform_bridge.dart';
import 'package:droiddesk/state/app_state.dart';
import 'package:droiddesk/theme/droid_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppCatalogScreen extends StatefulWidget {
  const AppCatalogScreen({super.key});

  @override
  State<AppCatalogScreen> createState() => _AppCatalogScreenState();
}

class _AppCatalogScreenState extends State<AppCatalogScreen>
    with SingleTickerProviderStateMixin {
  static const _featured = [
    _FeaturedApp(
      'firefox',
      'Firefox',
      'Fast, private desktop web browser.',
      Icons.public_rounded,
      Color(0xFFFF7139),
    ),
    _FeaturedApp(
      'code-oss',
      'Code OSS',
      'Powerful desktop code editor and IDE.',
      Icons.code_rounded,
      Color(0xFF23A8F2),
    ),
    _FeaturedApp(
      'libreoffice',
      'LibreOffice',
      'Documents, spreadsheets, and presentations.',
      Icons.description_rounded,
      Color(0xFF18A303),
    ),
    _FeaturedApp(
      'gimp',
      'GIMP',
      'Professional image editing and design tools.',
      Icons.brush_rounded,
      Color(0xFF9A7654),
    ),
    _FeaturedApp(
      'blender',
      'Blender',
      'Complete open-source 3D creation suite.',
      Icons.view_in_ar_rounded,
      Color(0xFFF5792A),
    ),
    _FeaturedApp(
      'vlc',
      'VLC',
      'Play almost every audio and video format.',
      Icons.play_circle_rounded,
      Color(0xFFFF8800),
    ),
    _FeaturedApp(
      'nodejs',
      'Node.js + npm',
      'JavaScript runtime and package manager.',
      Icons.javascript_rounded,
      Color(0xFF68A063),
    ),
    _FeaturedApp(
      'python',
      'Python',
      'Popular programming language and tools.',
      Icons.terminal_rounded,
      Color(0xFFFFD43B),
    ),
    _FeaturedApp(
      'imagemagick',
      'ImageMagick',
      'Image conversion and processing toolkit.',
      Icons.image_rounded,
      DroidTheme.primaryLight,
    ),
  ];

  late final TabController _tabs;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<_PackageItem> _searchResults = const [];
  List<_PackageItem> _installedPackages = const [];
  bool _searching = true;
  bool _loadingInstalled = true;
  String? _activePackage;
  double _operationProgress = 0;
  String _operationStatus = '';
  String _operationLog = '';
  bool _cancelRequested = false;
  bool _cancelling = false;

  Set<String> get _installedNames =>
      _installedPackages.map((package) => package.name).toSet();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && _tabs.index == 2) {
        _loadInstalled();
      }
    });
    DroidDeskPlatform.onPackageOperationProgress = _onProgress;
    DroidDeskPlatform.onPackageOperationLog = _onLog;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshOptionalApps();
      _loadInstalled();
      _search('');
    });
  }

  @override
  void dispose() {
    if (_activePackage != null) {
      unawaited(DroidDeskPlatform.cancelNativePackageOperation());
    }
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabs.dispose();
    DroidDeskPlatform.onPackageOperationProgress = null;
    DroidDeskPlatform.onPackageOperationLog = null;
    super.dispose();
  }

  void _onProgress(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _operationProgress = progress.clamp(0, 1);
      _operationStatus = status;
    });
  }

  void _onLog(String text) {
    if (!mounted) return;
    setState(() {
      _operationLog += text;
      if (_operationLog.length > 12000) {
        _operationLog = _operationLog.substring(_operationLog.length - 12000);
      }
    });
  }

  Future<void> _loadInstalled() async {
    if (mounted) setState(() => _loadingInstalled = true);
    try {
      final packages = await DroidDeskPlatform.getInstalledNativePackages();
      if (!mounted) return;
      setState(() {
        _installedPackages = packages.map(_PackageItem.fromMap).toList();
        _loadingInstalled = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInstalled = false);
    }
  }

  void _queueSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    if (mounted) setState(() => _searching = true);
    try {
      final packages = await DroidDeskPlatform.searchNativePackages(query);
      if (!mounted || query != _searchController.text.trim()) return;
      setState(() {
        _searchResults = packages.map(_PackageItem.fromMap).toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _install(String packageName) async {
    if (_activePackage != null) return;
    setState(() {
      _activePackage = packageName;
      _operationProgress = 0;
      _operationStatus = 'Preparing $packageName...';
      _operationLog = '';
      _cancelRequested = false;
      _cancelling = false;
    });
    final ok = await DroidDeskPlatform.installNativePackage(packageName);
    await _loadInstalled();
    if (!mounted) return;
    final cancelled = _cancelRequested;
    setState(() {
      _activePackage = null;
      _cancelling = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cancelled
              ? '$packageName installation cancelled'
              : ok
              ? '$packageName installed'
              : '$packageName installation failed',
        ),
        backgroundColor: cancelled
            ? DroidTheme.surfaceLight
            : ok
            ? DroidTheme.success
            : DroidTheme.error,
      ),
    );
  }

  Future<void> _cancelOperation() async {
    if (_activePackage == null || _cancelling) return;
    setState(() {
      _cancelRequested = true;
      _cancelling = true;
      _operationStatus = 'Cancelling installation...';
    });
    await DroidDeskPlatform.cancelNativePackageOperation();
  }

  Future<void> _remove(_PackageItem package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${package.displayName}?'),
        content: const Text('Dependent packages may also be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || _activePackage != null) return;
    setState(() {
      _activePackage = package.name;
      _operationProgress = 0;
      _operationStatus = 'Preparing removal...';
      _operationLog = '';
      _cancelRequested = false;
      _cancelling = false;
    });
    final ok = await DroidDeskPlatform.removeNativePackage(package.name);
    await _loadInstalled();
    if (!mounted) return;
    setState(() => _activePackage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '${package.displayName} removed' : 'Removal failed'),
        backgroundColor: ok ? DroidTheme.success : DroidTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linux App Store'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Featured'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Browse'),
            Tab(icon: Icon(Icons.download_done_rounded), text: 'Installed'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: DroidTheme.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabs,
          children: [_featuredView(), _browseView(), _installedView()],
        ),
      ),
      bottomNavigationBar: _activePackage == null ? null : _operationPanel(),
    );
  }

  Widget _featuredView() {
    final state = context.watch<AppState>();
    final apps = [
      ..._featured,
      if (!state.hasRoot)
        const _FeaturedApp(
          'proot_debian',
          'Debian Compatibility',
          'Run packages unavailable in native repositories.',
          Icons.inventory_2_rounded,
          Color(0xFFD70A53),
          optional: true,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text('Popular Linux applications', style: DroidTheme.headingMd),
        const SizedBox(height: 5),
        Text(
          'Hand-picked apps tested for DroidDesk.',
          style: DroidTheme.bodyMd,
        ),
        const SizedBox(height: 18),
        for (final app in apps) ...[
          _packageCard(
            _PackageItem(
              name: app.packageName,
              description: app.description,
              installed: app.optional
                  ? state.optionalApps[app.packageName] == true
                  : _installedNames.contains(app.packageName),
            ),
            featured: app,
            onInstall: app.optional
                ? () => state.installOptionalApp(app.packageName)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _browseView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _queueSearch,
            decoration: InputDecoration(
              hintText: 'Search packages, apps, and tools',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              filled: true,
              fillColor: DroidTheme.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty && !_searching
              ? const Center(child: Text('No matching packages found'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) =>
                      _packageCard(_searchResults[index]),
                ),
        ),
      ],
    );
  }

  Widget _installedView() {
    if (_loadingInstalled) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadInstalled,
      child: _installedPackages.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 220),
                Center(child: Text('No packages installed yet')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              itemCount: _installedPackages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, index) =>
                  _packageCard(_installedPackages[index], allowRemove: true),
            ),
    );
  }

  Widget _packageCard(
    _PackageItem package, {
    _FeaturedApp? featured,
    bool allowRemove = false,
    Future<void> Function()? onInstall,
  }) {
    final installed =
        package.installed || _installedNames.contains(package.name);
    final busy = _activePackage != null;
    final active = _activePackage == package.name;
    final color = featured?.color ?? _categoryColor(package.section);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DroidTheme.cardBg,
        borderRadius: BorderRadius.circular(DroidTheme.radiusMd),
        border: Border.all(
          color: installed
              ? DroidTheme.success.withValues(alpha: .4)
              : DroidTheme.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              featured?.icon ?? _categoryIcon(package.section, package.gui),
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featured?.name ?? package.displayName,
                  style: DroidTheme.headingSm,
                ),
                const SizedBox(height: 3),
                Text(
                  package.description.isEmpty
                      ? 'Linux package'
                      : package.description,
                  style: DroidTheme.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    if (package.version.isNotEmpty) package.version,
                    package.gui ? 'GUI app' : package.section,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  style: DroidTheme.monoSm,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (active)
            const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (installed && allowRemove && package.removable)
            IconButton(
              onPressed: busy ? null : () => _remove(package),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Remove',
            )
          else if (installed)
            const Icon(Icons.check_circle_rounded, color: DroidTheme.success)
          else
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (onInstall != null) {
                        await onInstall();
                        if (mounted) setState(() {});
                      } else {
                        await _install(package.name);
                      }
                    },
              child: const Text('Install'),
            ),
        ],
      ),
    );
  }

  Widget _operationPanel() {
    final clean = _operationLog.replaceAll(
      RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'),
      '',
    );
    final tail = clean
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList()
        .reversed
        .take(2)
        .toList()
        .reversed
        .join('\n');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF080D18),
        border: Border(top: BorderSide(color: DroidTheme.surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _operationStatus,
                    style: DroidTheme.headingSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(_operationProgress * 100).round()}%',
                  style: DroidTheme.monoSm,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _operationProgress > 0 ? _operationProgress : null,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOperation,
                icon: _cancelling
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded, size: 18),
                label: Text(_cancelling ? 'Cancelling' : 'Cancel installation'),
              ),
            ),
            if (tail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tail,
                style: DroidTheme.monoSm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String section, bool gui) {
    final value = section.toLowerCase();
    if (value.contains('internet')) return Icons.public_rounded;
    if (value.contains('develop')) return Icons.code_rounded;
    if (value.contains('graphic')) return Icons.palette_rounded;
    if (value.contains('media')) return Icons.movie_rounded;
    if (value.contains('office')) return Icons.description_rounded;
    return gui ? Icons.apps_rounded : Icons.terminal_rounded;
  }

  Color _categoryColor(String section) {
    final value = section.toLowerCase();
    if (value.contains('internet')) return const Color(0xFF39A0FF);
    if (value.contains('develop')) return const Color(0xFF9B7BFF);
    if (value.contains('graphic')) return const Color(0xFFFF6B9E);
    if (value.contains('media')) return const Color(0xFFFF9F43);
    if (value.contains('office')) return const Color(0xFF38C793);
    return DroidTheme.primaryLight;
  }
}

class _PackageItem {
  final String name;
  final String description;
  final String version;
  final String section;
  final bool installed;
  final bool gui;
  final bool removable;

  const _PackageItem({
    required this.name,
    this.description = '',
    this.version = '',
    this.section = 'System',
    this.installed = false,
    this.gui = false,
    this.removable = true,
  });

  factory _PackageItem.fromMap(Map<String, dynamic> map) => _PackageItem(
    name: map['name']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    version: map['version']?.toString() ?? '',
    section: map['section']?.toString() ?? 'System',
    installed: map['installed'] == true,
    gui: map['gui'] == true,
    removable: map['removable'] != false,
  );

  String get displayName => name
      .split('-')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _FeaturedApp {
  final String packageName;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool optional;

  const _FeaturedApp(
    this.packageName,
    this.name,
    this.description,
    this.icon,
    this.color, {
    this.optional = false,
  });
}
