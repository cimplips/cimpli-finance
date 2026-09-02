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

    if (confirmed != true || !mounted) {
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
                            context,
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
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
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
                                onSelected:
                                    (value) async {
                                  if (value == 'select') {
                                    _selectAccount(
                                      context,
                                      store,
                                      name,
                                    );
                                  } else if (value ==
                                      'rename') {
                                    await _showRenameAccountDialog(
                                      context,
                                      store,
                                      name,
                                    );
                                  } else if (value ==
                                      'delete') {
                                    await _showDeleteAccountDialog(
                                      context,
                                      store,
                                      name,
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!isActive)
                                    const PopupMenuItem<
                                        String>(
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
                                    const PopupMenuItem<
                                        String>(
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
                  context,
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
            const SizedBox(height: 30),
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
                      'Menghapus akun juga akan menghapus seluruh transaksi yang tersimpan pada akun tersebut.',
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
