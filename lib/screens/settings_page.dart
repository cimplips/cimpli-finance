import 'package:flutter/material.dart';

import '../core/finance_scope.dart';
import '../services/finance_store.dart';

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
    FinanceStore store,
  ) async {
    _controller.clear();

    final name = await showDialog<String>(
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
            onSubmitted: (_) {
              final value = _controller.text.trim();

              if (value.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(value);
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
              onPressed: () {
                final value = _controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    final success = await store.addAccount(name.trim());

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? '${name.trim()} berhasil ditambahkan.'
          : 'Akun gagal ditambahkan. Nama mungkin sudah digunakan.',
    );
  }

  Future<void> _showRenameAccountDialog(
    FinanceStore store,
    String oldName,
  ) async {
    _controller.text = oldName;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    final newName = await showDialog<String>(
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
            onSubmitted: (_) {
              final value = _controller.text.trim();

              if (value.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(value);
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
              onPressed: () {
                final value = _controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty || !mounted) {
      return;
    }

    final trimmedName = newName.trim();

    if (trimmedName == oldName) {
      return;
    }

    final success = await store.renameAccount(
      oldName,
      trimmedName,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Nama akun berhasil diperbarui.'
          : 'Nama akun tidak dapat digunakan atau sudah ada.',
    );
  }

  Future<void> _showDeleteAccountDialog(
    FinanceStore store,
    String name,
  ) async {
    if (store.accounts.length <= 1) {
      _showMessage(
        'Minimal harus ada satu akun keuangan.',
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

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await store.deleteAccount(name);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Akun berhasil dihapus.'
          : 'Akun tidak dapat dihapus.',
    );
  }

  void _selectAccount(
    FinanceStore store,
    String name,
  ) {
    if (name == store.activeAccount) {
      return;
    }

    store.setActiveAccount(name);

    _showMessage(
      '$name sekarang menjadi akun aktif.',
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
    FinanceStore store,
  ) async {
    if (store.activeAccount == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    _controller.clear();

    final name = await showDialog<String>(
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
            onSubmitted: (_) {
              final value = _controller.text.trim();

              if (value.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(value);
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
              onPressed: () {
                final value = _controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    final trimmedName = name.trim();

    final success = await store.addCategory(
      account: store.activeAccount,
      name: trimmedName,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});
    }

    _showMessage(
      success
          ? '$trimmedName berhasil ditambahkan.'
          : 'Kategori gagal ditambahkan. Nama mungkin sudah digunakan.',
    );
  }

  Future<void> _showRenameCategoryDialog(
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
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    final newName = await showDialog<String>(
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
            onSubmitted: (_) {
              final value = _controller.text.trim();

              if (value.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(value);
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
              onPressed: () {
                final value = _controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty || !mounted) {
      return;
    }

    final trimmedName = newName.trim();

    if (trimmedName == oldName) {
      return;
    }

    final success = await store.renameCategory(
      account: store.activeAccount,
      oldName: oldName,
      newName: trimmedName,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});
    }

    _showMessage(
      success
          ? 'Kategori berhasil diperbarui.'
          : 'Kategori tidak dapat digunakan atau sudah ada.',
    );
  }

  Future<void> _showDeleteCategoryDialog(
    FinanceStore store,
    String name,
  ) async {
    final account = store.activeAccount;

    if (account == null) {
      _showMessage(
        'Pilih akun terlebih dahulu.',
      );
      return;
    }

    final used = await store.isCategoryUsed(
      account: account,
      name: name,
    );

    if (!mounted) {
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

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await store.deleteCategory(
      account: account,
      name: name,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});
    }

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
                            overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 24),
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
              ...store.accounts.map(
                (name) {
                  final isActive =
                      name == store.activeAccount;

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(22),
                        onTap: () {
                          _selectAccount(
                            store,
                            name,
                          );
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFF30343A,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),
                                child: Icon(
                                  _accountIcon(name),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isActive
                                          ? 'Sedang digunakan'
                                          : 'Tap untuk menggunakan akun ini',
                                      style: TextStyle(
                                        color: isActive
                                            ? const Color(
                                                0xFFB8BCC2,
                                              )
                                            : const Color(
                                                0xFF777B82,
                                              ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Menu akun',
                                onSelected: (value) async {
                                  if (value == 'select') {
                                    _selectAccount(
                                      store,
                                      name,
                                    );
                                  } else if (value ==
                                      'rename') {
                                    await _showRenameAccountDialog(
                                      store,
                                      name,
                                    );
                                  } else if (value ==
                                      'delete') {
                                    await _showDeleteAccountDialog(
                                      store,
                                      name,
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!isActive)
                                    const PopupMenuItem<String>(
                                      value: 'select',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .check_circle_outline,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Gunakan'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem<String>(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Edit nama'),
                                      ],
                                    ),
                                  ),
                                  if (store.accounts.length >
                                      1)
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .delete_outline,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Hapus'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await _showAddAccountDialog(
                  store,
                );
              },
              icon: const Icon(Icons.add),
              label: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  'Tambah Akun Keuangan',
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Divider(),
            const SizedBox(height: 30),
            const Text(
              'Kategori Transaksi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeAccount == null
                  ? 'Pilih akun untuk mengelola kategori.'
                  : 'Kategori khusus untuk akun "$activeAccount".',
              style: const TextStyle(
                color: Color(0xFF9A9DA3),
              ),
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Gagal memuat kategori: '
                          '${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final categories =
                      snapshot.data ?? <String>[];

                  if (categories.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 42,
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
                            const Text(
                              'Tambahkan kategori pertama untuk '
                              'akun ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9A9DA3),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _showAddCategoryDialog(
                                  store,
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Tambah Kategori',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...categories.map(
                        (category) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: Card(
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                      0xFF30343A,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.category_outlined,
                                  ),
                                ),
                                title: Text(
                                  category,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Kategori transaksi',
                                  style: TextStyle(
                                    color:
                                        Color(0xFF777B82),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing:
                                    PopupMenuButton<String>(
                                  tooltip:
                                      'Menu kategori',
                                  onSelected:
                                      (value) async {
                                    if (value == 'rename') {
                                      await _showRenameCategoryDialog(
                                        store,
                                        category,
                                      );
                                    } else if (value ==
                                        'delete') {
                                      await _showDeleteCategoryDialog(
                                        store,
                                        category,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem<String>(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .edit_outlined,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .delete_outline,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Hapus'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _showAddCategoryDialog(
                            store,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          child: Text(
                            'Tambah Kategori',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Color(0xFF9A9DA3),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kategori yang masih digunakan oleh transaksi '
                      'tidak dapat dihapus. Edit kategori akan otomatis '
                      'memperbarui transaksi yang menggunakannya.',
                      style: TextStyle(
                        color: Color(0xFF9A9DA3),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
