import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../main.dart';

import '../core/finance_scope.dart';
import '../services/finance_store.dart';
import '../services/app_lock_service.dart';
import '../services/backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _controller =
      TextEditingController();
  final AppLockService _lockService = AppLockService();

  bool _appLockEnabled = false;
  bool _loadingAppLock = true;

  @override
  void initState() {
    super.initState();
    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final enabled = await _lockService.isEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = enabled;
      _loadingAppLock = false;
    });
  }

  Future<void> _setAppLock(bool enabled) async {
    if (!enabled) {
      await _lockService.setEnabled(false);

      if (!mounted) {
        return;
      }

      setState(() {
        _appLockEnabled = false;
      });

      _showMessage('Kunci aplikasi dinonaktifkan.');
      return;
    }

    final supported = await _lockService.isDeviceSupported();

    if (!mounted) {
      return;
    }

    if (!supported) {
      _showMessage(
        'Perangkat belum mendukung PIN, pola, password, atau biometrik untuk kunci aplikasi.',
      );
      return;
    }

    final authenticated = await _lockService.authenticate();

    if (!mounted) {
      return;
    }

    if (!authenticated) {
      _showMessage(
        'Verifikasi gagal atau dibatalkan. Kunci aplikasi belum diaktifkan.',
      );
      return;
    }

    await _lockService.setEnabled(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = true;
    });

    _showMessage(
      'Kunci aplikasi aktif. Gunakan PIN/kunci perangkat atau sidik jari.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _accountIcon(String? name) {
    final lowerName = (name ?? '').toLowerCase();

    if (lowerName.contains('kantor') ||
        lowerName.contains('usaha') ||
        lowerName.contains('bisnis')) {
      return Icons.business_outlined;
    }

    if (lowerName.contains('rumah') ||
        lowerName.contains('keluarga')) {
      return Icons.home_outlined;
    }

    return Icons.account_balance_wallet_outlined;
  }

  Future<void> _showAddAccountDialog(
    BuildContext context,
    FinanceStore store,
  ) async {
    _controller.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Akun Keuangan'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama akun',
              hintText: 'Contoh: Keuangan Usaha',
              prefixIcon: Icon(
                Icons.account_balance_wallet_outlined,
              ),
            ),
            onSubmitted: (_) async {
              await _saveNewAccount(
                dialogContext,
                store,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await _saveNewAccount(
                  dialogContext,
                  store,
                );
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewAccount(
    BuildContext dialogContext,
    FinanceStore store,
  ) async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nama akun wajib diisi.',
            ),
          ),
        );
      return;
    }

    final success = await store.addAccount(name);

    if (!dialogContext.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Akun gagal ditambahkan. Nama mungkin sudah digunakan.',
            ),
          ),
        );
      return;
    }

    Navigator.of(dialogContext).pop();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$name berhasil ditambahkan.',
          ),
        ),
      );
  }

  Future<void> _showRenameAccountDialog(
    BuildContext context,
    FinanceStore store,
    String oldName,
  ) async {
    _controller.text = oldName;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Nama Akun'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama akun',
              prefixIcon: Icon(
                Icons.edit_outlined,
              ),
            ),
            onSubmitted: (_) async {
              await _saveRenamedAccount(
                dialogContext,
                store,
                oldName,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await _saveRenamedAccount(
                  dialogContext,
                  store,
                  oldName,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRenamedAccount(
    BuildContext dialogContext,
    FinanceStore store,
    String oldName,
  ) async {
    final newName = _controller.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nama akun wajib diisi.',
            ),
          ),
        );
      return;
    }

    if (newName == oldName) {
      Navigator.of(dialogContext).pop();
      return;
    }

    final success = await store.renameAccount(
      oldName,
      newName,
    );

    if (!dialogContext.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nama akun tidak dapat digunakan atau sudah ada.',
            ),
          ),
        );
      return;
    }

    Navigator.of(dialogContext).pop();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Nama akun berhasil diperbarui.',
          ),
        ),
      );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    FinanceStore store,
    String name,
  ) async {
    if (store.accounts.length <= 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Minimal harus ada satu akun keuangan.',
            ),
          ),
        );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Akun?'),
          content: Text(
            'Akun "$name" beserta seluruh transaksi di dalamnya '
            'akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await store.deleteAccount(name);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Akun berhasil dihapus.'
                : 'Akun tidak dapat dihapus.',
          ),
        ),
      );
  }

  void _selectAccount(
    BuildContext context,
    FinanceStore store,
    String name,
  ) {
    if (name == store.activeAccount) {
      return;
    }

    store.setActiveAccount(name);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$name sekarang menjadi akun aktif.',
          ),
        ),
      );
  }

  Future<List<String>> _loadCategories(
    FinanceStore store,
  ) {
    return store.getCategories(
      account: store.activeAccount,
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    FinanceStore store,
  ) async {
    if (store.activeAccount == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    _controller.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Kategori'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama kategori',
              hintText: 'Contoh: Makan',
              prefixIcon: Icon(
                Icons.category_outlined,
              ),
            ),
            onSubmitted: (_) async {
              await _saveNewCategory(
                dialogContext,
                store,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await _saveNewCategory(
                  dialogContext,
                  store,
                );
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewCategory(
    BuildContext dialogContext,
    FinanceStore store,
  ) async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nama kategori wajib diisi.',
            ),
          ),
        );
      return;
    }

    final account = store.activeAccount;

    if (account == null) {
      return;
    }

    final success = await store.addCategory(
      account: account,
      name: name,
    );

    if (!dialogContext.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Kategori gagal ditambahkan. Nama mungkin sudah digunakan.',
            ),
          ),
        );
      return;
    }

    Navigator.of(dialogContext).pop();

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$name berhasil ditambahkan.',
          ),
        ),
      );
  }

  Future<void> _showRenameCategoryDialog(
    BuildContext context,
    FinanceStore store,
    String oldName,
  ) async {
    _controller.text = oldName;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Kategori'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama kategori',
              prefixIcon: Icon(
                Icons.edit_outlined,
              ),
            ),
            onSubmitted: (_) async {
              await _saveRenamedCategory(
                dialogContext,
                store,
                oldName,
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await _saveRenamedCategory(
                  dialogContext,
                  store,
                  oldName,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRenamedCategory(
    BuildContext dialogContext,
    FinanceStore store,
    String oldName,
  ) async {
    final newName = _controller.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nama kategori wajib diisi.',
            ),
          ),
        );
      return;
    }

    if (newName == oldName) {
      Navigator.of(dialogContext).pop();
      return;
    }

    final account = store.activeAccount;

    if (account == null) {
      return;
    }

    final success = await store.renameCategory(
      account: account,
      oldName: oldName,
      newName: newName,
    );

    if (!dialogContext.mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(dialogContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Kategori tidak dapat digunakan atau sudah ada.',
            ),
          ),
        );
      return;
    }

    Navigator.of(dialogContext).pop();

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Kategori berhasil diperbarui.',
          ),
        ),
      );
  }

  Future<void> _showDeleteCategoryDialog(
    BuildContext context,
    FinanceStore store,
    String name,
  ) async {
    final account = store.activeAccount;

    if (account == null) {
      return;
    }

    final used = await store.isCategoryUsed(
      account: account,
      name: name,
    );

    if (!context.mounted) {
      return;
    }

    if (used) {
      _showMessage(
        'Kategori "$name" masih digunakan oleh transaksi. '
        'Edit kategori atau transaksi terlebih dahulu.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kategori?'),
          content: Text(
            'Kategori "$name" akan dihapus dari akun ini.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await store.deleteCategory(
      account: account,
      name: name,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {});

    _showMessage(
      success
          ? 'Kategori berhasil dihapus.'
          : 'Kategori tidak dapat dihapus.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _backupData() async {
    final timestamp = _backupTimestamp(DateTime.now());

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Backup Cimpli Finance',
      fileName: 'cimpli_finance_backup_$timestamp.json',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );

    if (!mounted || outputPath == null || outputPath.isEmpty) {
      return;
    }

    _showMessage('Membuat backup data...');

    try {
      await BackupService().exportBackup(
        outputPath: outputPath,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Backup berhasil disimpan. Data Anda aman untuk dipindahkan atau dipulihkan nanti.',
      );
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Backup gagal: $error');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Backup gagal: $error');
    }
  }

  Future<void> _restoreData(FinanceStore store) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih Backup Cimpli Finance',
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final inputPath = result.files.single.path;

    if (inputPath == null || inputPath.isEmpty) {
      _showMessage(
        'File backup tidak dapat diakses dari perangkat ini.',
      );
      return;
    }

    final backupService = BackupService();

    try {
      final valid = await backupService.isValidBackup(
        inputPath,
      );

      if (!mounted) {
        return;
      }

      if (!valid) {
        _showMessage(
          'File bukan backup Cimpli Finance yang valid.',
        );
        return;
      }

      final itemCount = await backupService.getBackupItemCount(
        inputPath,
      );

      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Restore Data?'),
            content: Text(
              'Data keuangan saat ini akan diganti dengan isi backup. '
              'Backup berisi $itemCount baris data. Tindakan ini tidak dapat dibatalkan.\n\n'
              'Sebaiknya buat backup data saat ini terlebih dahulu.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) {
        return;
      }

      _showMessage('Memulihkan data...');

      await backupService.restoreBackup(
        inputPath: inputPath,
      );

      await store.load();

      if (!mounted) {
        return;
      }

      setState(() {});

      _showMessage(
        'Restore berhasil. Data Cimpli Finance sudah dipulihkan.',
      );
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Restore gagal: $error');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Restore gagal: $error');
    }
  }

  String _backupTimestamp(DateTime dateTime) {
    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${dateTime.year}${twoDigits(dateTime.month)}'
        '${twoDigits(dateTime.day)}_'
        '${twoDigits(dateTime.hour)}${twoDigits(dateTime.minute)}'
        '${twoDigits(dateTime.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final activeAccount = store.activeAccount;
    final colorScheme = Theme.of(context).colorScheme;

    final iconBackground = colorScheme.primaryContainer;
    final iconColor = colorScheme.primary;

    Widget iconBox(IconData icon, {double size = 48}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(size * 0.31),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      );
    }

    Widget sectionTitle(String title, String subtitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Informasi kategori tetap mengikuti warna tema terang/gelap.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kategori yang masih digunakan oleh transaksi '
                    'tidak dapat dihapus. Edit kategori akan otomatis '
                    'memperbarui transaksi yang menggunakannya.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Tampilan
          sectionTitle(
            'Tampilan',
            'Pilih tampilan gelap atau terang untuk Cimpli Finance.',
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final themeController = ThemeControllerScope.of(context);

              return Card(
                child: SwitchListTile(
                  value: themeController.isDarkMode,
                  onChanged: (enabled) async {
                    await themeController.setThemeMode(
                      enabled ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  secondary: Icon(
                    themeController.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Mode Gelap',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    themeController.isDarkMode
                        ? 'Tampilan gelap sedang digunakan.'
                        : 'Tampilan terang sedang digunakan.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 30),

          // Backup & Restore
          sectionTitle(
            'Backup & Restore',
            'Simpan salinan data keuangan untuk ganti HP atau reinstall aplikasi.',
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: iconBox(Icons.backup_outlined),
                    title: const Text(
                      'Backup Data',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Simpan seluruh akun, transaksi, kategori, transaksi berulang, dan anggaran.',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: _backupData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: iconBox(Icons.restore_outlined),
                    title: const Text(
                      'Restore Data',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Pulihkan data dari file backup JSON yang sebelumnya disimpan.',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () async {
                      await _restoreData(store);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 30),

          // Keamanan
          sectionTitle(
            'Keamanan',
            'Lindungi Cimpli Finance dengan kunci perangkat atau sidik jari.',
          ),
          const SizedBox(height: 14),
          Card(
            child: _loadingAppLock
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SwitchListTile(
                    value: _appLockEnabled,
                    onChanged: _setAppLock,
                    secondary: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'Kunci Aplikasi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Gunakan PIN/pola/password perangkat atau sidik jari saat membuka aplikasi.',
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 30),

          // Akun Keuangan
          sectionTitle(
            'Akun Keuangan',
            'Pilih akun aktif dan kelola seluruh keuangan Anda.',
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  iconBox(_accountIcon(activeAccount)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akun Aktif',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeAccount ?? 'Belum ada akun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.settings_outlined,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (store.accounts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada akun keuangan.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ...store.accounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final name = entry.value;
                    final isActive = name == store.activeAccount;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            _selectAccount(context, store, name);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                iconBox(_accountIcon(name), size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isActive
                                            ? 'Sedang digunakan'
                                            : 'Tap untuk menggunakan akun ini',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Menu akun',
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: colorScheme.onSurface,
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'select') {
                                      _selectAccount(context, store, name);
                                    } else if (value == 'rename') {
                                      await _showRenameAccountDialog(
                                        context,
                                        store,
                                        name,
                                      );
                                    } else if (value == 'delete') {
                                      await _showDeleteAccountDialog(
                                        context,
                                        store,
                                        name,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (!isActive)
                                      PopupMenuItem<String>(
                                        value: 'select',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('Gunakan'),
                                          ],
                                        ),
                                      ),
                                    PopupMenuItem<String>(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('Edit nama'),
                                        ],
                                      ),
                                    ),
                                    if (store.accounts.length > 1)
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('Hapus'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (index < store.accounts.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await _showAddAccountDialog(context, store);
            },
            icon: Icon(Icons.add, color: colorScheme.primary),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Tambah Akun Keuangan'),
            ),
          ),
          const SizedBox(height: 34),
          const Divider(),
          const SizedBox(height: 30),

          // Kategori Transaksi
          sectionTitle(
            'Kategori Transaksi',
            activeAccount == null
                ? 'Pilih akun untuk mengelola kategori.'
                : 'Kategori khusus untuk akun "$activeAccount".',
          ),
          const SizedBox(height: 20),
          if (activeAccount == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada akun aktif.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            FutureBuilder<List<String>>(
              future: _loadCategories(store),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('Gagal memuat kategori: ${snapshot.error}'),
                    ),
                  );
                }

                final categories = snapshot.data ?? <String>[];

                if (categories.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 42,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada kategori',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan kategori pertama untuk akun ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showAddCategoryDialog(context, store);
                            },
                            icon: Icon(Icons.add, color: colorScheme.primary),
                            label: const Text('Tambah Kategori'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ...categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final category = entry.value;

                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: iconBox(
                                    Icons.category_outlined,
                                    size: 44,
                                  ),
                                  title: Text(
                                    category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Kategori transaksi',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: 'Menu kategori',
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: colorScheme.onSurface,
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'rename') {
                                        await _showRenameCategoryDialog(
                                          context,
                                          store,
                                          category,
                                        );
                                      } else if (value == 'delete') {
                                        await _showDeleteCategoryDialog(
                                          context,
                                          store,
                                          category,
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem<String>(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('Hapus'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < categories.length - 1)
                                  const Divider(height: 1),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _showAddCategoryDialog(context, store);
                      },
                      icon: Icon(Icons.add, color: colorScheme.primary),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Tambah Kategori'),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 30),

          // Transaksi Berulang dipindahkan menjadi menu Pengaturan,
          // bukan lagi FloatingActionButton.
          sectionTitle(
            'Lainnya',
            'Fitur tambahan untuk mengelola keuangan secara otomatis.',
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: iconBox(Icons.repeat_rounded),
              title: const Text(
                'Transaksi Berulang',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Kelola dan lihat semua transaksi berulang.',
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/recurring-transactions',
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
