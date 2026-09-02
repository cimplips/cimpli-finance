import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../models/transaction.dart';
import '../services/app_lock_service.dart';
import '../services/finance_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Future<void> _toggleAppLock(
    bool enabled,
  ) async {
    if (enabled) {
      final supported =
          await _lockService.isDeviceSupported();

      if (!mounted) {
        return;
      }

      if (!supported) {
        _showMessage(
          'Perangkat tidak mendukung kunci aplikasi.',
        );
        return;
      }

      final authenticated =
          await _lockService.authenticate();

      if (!mounted) {
        return;
      }

      if (!authenticated) {
        _showMessage(
          'Autentikasi gagal. Kunci aplikasi belum diaktifkan.',
        );
        return;
      }
    }

    await _lockService.setEnabled(enabled);

    if (!mounted) {
      return;
    }

    setState(() {
      _appLockEnabled = enabled;
    });

    _showMessage(
      enabled
          ? 'Kunci aplikasi berhasil diaktifkan.'
          : 'Kunci aplikasi berhasil dinonaktifkan.',
    );
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
          title: const Text('Tambah Akun'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama akun',
              hintText: 'Contoh: Pribadi',
            ),
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
              child: const Text('Simpan'),
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

    if (!context.mounted) {
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
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah Nama Akun'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama akun',
            ),
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

    if (!context.mounted) {
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
          title: const Text('Hapus Akun'),
          content: Text(
            'Hapus akun "$name" beserta seluruh transaksi, '
            'kategori, dan transaksi berulang di akun ini?',
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
            decoration: const InputDecoration(
              labelText: 'Nama kategori',
              hintText: 'Contoh: Makanan',
            ),
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
              child: const Text('Simpan'),
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

    final success = await store.addCategory(
      account: store.activeAccount!,
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

    if (!context.mounted) {
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
    if (store.activeAccount == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    _controller.text = oldName;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah Kategori'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama kategori',
            ),
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

    final success = await store.renameCategory(
      account: store.activeAccount!,
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
              'Nama kategori tidak dapat digunakan atau sudah ada.',
            ),
          ),
        );
      return;
    }

    Navigator.of(dialogContext).pop();

    if (!context.mounted) {
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
    if (store.activeAccount == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    final used = await store.isCategoryUsed(
      account: store.activeAccount!,
      name: name,
    );

    if (!mounted) {
      return;
    }

    if (used) {
      _showMessage(
        'Kategori "$name" masih digunakan oleh transaksi.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text(
            'Hapus kategori "$name"?',
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

    if (!mounted || confirmed != true) {
      return;
    }

    final success = await store.deleteCategory(
      account: store.activeAccount!,
      name: name,
    );

    if (!mounted) {
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

  IconData _accountIcon(String? account) {
    final value = account?.toLowerCase() ?? '';

    if (value.contains('bisnis') ||
        value.contains('usaha')) {
      return Icons.business_center_rounded;
    }

    if (value.contains('tabungan')) {
      return Icons.savings_rounded;
    }

    if (value.contains('cash') ||
        value.contains('tunai')) {
      return Icons.payments_rounded;
    }

    return Icons.account_balance_wallet_rounded;
  }

  Widget _buildAppLockSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF30343A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kunci Aplikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gunakan sidik jari atau kunci perangkat '
                    'saat membuka aplikasi.',
                    style: TextStyle(
                      color: Color(0xFF9A9DA3),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _loadingAppLock
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Switch(
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection(
    BuildContext context,
  ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/recurring-transactions',
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF30343A),
                    borderRadius: BorderRadius.all(
                      Radius.circular(16),
                    ),
                  ),
                  child: Icon(
                    Icons.repeat_rounded,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Berulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola pemasukan dan pengeluaran otomatis '
                      'setiap minggu, bulan, atau tahun.',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    FinanceStore store,
  ) {
    final activeAccount = store.activeAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Akun Keuangan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih akun aktif dan kelola seluruh keuangan Anda.',
          style: TextStyle(
            color: Color(0xFF9A9DA3),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30343A),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _accountIcon(activeAccount),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akun Aktif',
                        style: TextStyle(
                          color: Color(0xFF9A9DA3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeAccount ?? 'Belum ada akun',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (store.accounts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Belum ada akun keuangan.',
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (final name in store.accounts)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF30343A),
                        child: Icon(
                          _accountIcon(name),
                        ),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      subtitle: name ==
                              store.activeAccount
                          ? const Text(
                              'Akun aktif',
                              style: TextStyle(
                                color:
                                    Color(0xFF9A9DA3),
                              ),
                            )
                          : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'select') {
                            _selectAccount(
                              context,
                              store,
                              name,
                            );
                          } else if (value == 'rename') {
                            _showRenameAccountDialog(
                              context,
                              store,
                              name,
                            );
                          } else if (value == 'delete') {
                            _showDeleteAccountDialog(
                              context,
                              store,
                              name,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (name != store.activeAccount)
                            const PopupMenuItem<String>(
                              value: 'select',
                              child: Text(
                                'Jadikan akun aktif',
                              ),
                            ),
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text(
                              'Ubah nama',
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              'Hapus akun',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            _showAddAccountDialog(
              context,
              store,
            );
          },
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'Tambah Akun',
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    FinanceStore store,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola kategori pemasukan dan pengeluaran.',
          style: TextStyle(
            color: Color(0xFF9A9DA3),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<String>>(
          future: _loadCategories(store),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final categories =
                snapshot.data ?? <String>[];

            if (categories.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada kategori.',
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (final name in categories)
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor:
                              Color(0xFF30343A),
                          child: Icon(
                            Icons.category_rounded,
                          ),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameCategoryDialog(
                                context,
                                store,
                                name,
                              );
                            } else if (value == 'delete') {
                              _showDeleteCategoryDialog(
                                context,
                                store,
                                name,
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'rename',
                              child: Text(
                                'Ubah nama',
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus kategori',
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
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            _showAddCategoryDialog(
              context,
              store,
            );
          },
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'Tambah Kategori',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceScope.of(context);
    final activeAccount = store.activeAccount;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Akun Keuangan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih akun aktif dan kelola seluruh keuangan Anda.',
              style: TextStyle(
                color: Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 20),
            _buildAccountSection(
              context,
              store,
            ),
            const SizedBox(height: 32),
            const Text(
              'Keamanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lindungi data keuangan Anda.',
              style: TextStyle(
                color: Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 20),
            _buildAppLockSection(),
            const SizedBox(height: 32),
            const Text(
              'Transaksi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur transaksi yang dibuat secara otomatis.',
              style: TextStyle(
                color: Color(0xFF9A9DA3),
              ),
            ),
            const SizedBox(height: 20),
            _buildRecurringSection(
              context,
            ),
            const SizedBox(height: 32),
            _buildCategorySection(
              context,
              store,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF30343A),
                          borderRadius:
                              BorderRadius.all(
                            Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cimpli Finance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeAccount == null
                                ? 'Belum ada akun aktif'
                                : 'Akun aktif: $activeAccount',
                            style: const TextStyle(
                              color: Color(0xFF9A9DA3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
