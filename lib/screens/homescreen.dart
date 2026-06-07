import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/pages/add_card_screen.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/screens/barcode_card_details_screen.dart';
import 'package:wallet/services/encryption_service.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../pages/walletdetails.dart';
import 'package:wallet/widgets/barcode_card_entry_form.dart';

/// Smooth route builder — used across the app for premium transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';
  String _selectedPassFilter = 'all';

  late final TextEditingController _searchController;
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<PassProvider>().fetchPasses();

      // Initialize selected index from startup settings
      final startupProvider = context.read<StartupSettingsProvider>();
      if (startupProvider.paymentsOnlyMode) {
        setState(() => _selectedIndex = 0);
      } else {
        setState(() => _selectedIndex = startupProvider.defaultScreenIndex);
      }
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _searchQuery != _searchController.text) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _scanAndImport() async {
    try {
      final scanResult = await BarcodeScanner.scan();
      if (scanResult.type != ResultType.Barcode) return;

      final encryptedData = scanResult.rawContent;
      final decryptedJson = EncryptionService.instance.decryptFromTransfer(encryptedData);

      if (decryptedJson == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or corrupted sharing code.')),
          );
        }
        return;
      }

      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final type = payload['type'];
      final data = payload['data'] as Map<String, dynamic>;

      if (type == 'pass') {
        final newPass = Pass.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newPass.organizationName, 'Pass');
          if (confirm == true) {
            await PassDatabaseHelper.instance.insertPass(newPass);
            if (mounted) {
              context.read<PassProvider>().fetchPasses();
              _showSuccessSnackBar('Pass imported successfully!');
            }
          }
        }
      } else if (type == 'wallet') {
        final newWallet = Wallet.fromMap(data);
        if (mounted) {
          final confirm = await _showImportConfirmation(newWallet.name, 'Payment Card');
          if (confirm == true) {
            await DatabaseHelper.instance.insertWallet(newWallet);
            if (mounted) {
              context.read<WalletProvider>().fetchWallets();
              _showSuccessSnackBar('Payment card imported successfully!');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('QR Scan error: $e');
    }
  }

  Future<bool?> _showImportConfirmation(String name, String typeLabel) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white,
        title: Text('Import Shared $typeLabel'),
        content: Text('Do you want to import "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPassDeleteConfirmationDialog({
    required int id,
    required String name,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          title: Text(
            'Delete Pass?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<PassProvider>().deletePass(id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Pass Deleted!')));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Force index to 0 (Payments) if hidden mode is on
    final isHiddenMode = startupProvider.paymentsOnlyMode;
    final effectiveIndex = isHiddenMode ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: Icon(
              Icons.star,
              color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              const url = 'https://github.com/sidhant947/Wallet';
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.078) : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded, color: isDark ? Colors.white : Colors.black),
              tooltip: 'Scan to Import',
              onPressed: () {
                HapticFeedback.mediumImpact();
                _scanAndImport();
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.078)
                  : Colors.black.withValues(alpha: 0.051),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final walletProvider = context.read<WalletProvider>();
            final passProvider = context.read<PassProvider>();
            final result = await Navigator.push(
              context,
              SmoothPageRoute(
                page: AddCardScreen(initialTabIndex: effectiveIndex),
              ),
            );
            if (result == true && mounted) {
              await walletProvider.fetchWallets();
              await passProvider.fetchPasses();
            }
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: IndexedStack(
        key: ValueKey(effectiveIndex),
        index: effectiveIndex,
        children: [
          _buildPaymentsTab(context),
          _buildPassesTab(context),
        ],
      ),
      bottomNavigationBar: isHiddenMode
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.078)
                        : Colors.black.withValues(alpha: 0.051),
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: effectiveIndex,
                onDestinationSelected: _onItemTapped,
                animationDuration: Duration.zero,
                elevation: 0,
                destinations: const <Widget>[
                  NavigationDestination(
                    icon: Icon(Icons.credit_card_outlined),
                    selectedIcon: Icon(Icons.credit_card),
                    label: 'Payments',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.confirmation_number_outlined),
                    selectedIcon: Icon(Icons.confirmation_number),
                    label: 'Passes',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        final wallets = provider.wallets;
        if (wallets.isEmpty) {
          return _buildEmptyState(
            context,
            "No credit or debit cards yet.\nTap the '+' to add one.",
          );
        }

        // 1. First, filter by the search query.
        final List<Wallet> searchedWallets = _searchQuery.isEmpty
            ? wallets
            : wallets.where((wallet) {
                final query = _searchQuery.toLowerCase();
                return (wallet.name.toLowerCase().contains(query)) ||
                    (wallet.number.contains(query)) ||
                    (wallet.network?.toLowerCase().contains(query) ?? false) ||
                    (wallet.issuer?.toLowerCase().contains(query) ?? false) ||
                    (wallet.cardtype?.toLowerCase().contains(query) ?? false);
              }).toList();

        // 2. Then, filter the result by the network button.
        final List<Wallet> filteredWallets = searchedWallets.where((wallet) {
          if (_selectedFilter == 'all') return true;
          return wallet.network?.toLowerCase() == _selectedFilter;
        }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.059)
                        : Colors.black.withValues(alpha: 0.031),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.102)
                          : Colors.black.withValues(alpha: 0.059),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Search cards...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'all', label: Text('ALL')),
                      ButtonSegment<String>(value: 'visa', label: Text('VISA')),
                      ButtonSegment<String>(
                        value: 'mastercard',
                        label: Text('MASTERCARD'),
                      ),
                      ButtonSegment<String>(
                        value: 'rupay',
                        label: Text('RUPAY'),
                      ),
                      ButtonSegment<String>(value: 'amex', label: Text('AMEX')),
                      ButtonSegment<String>(
                        value: 'discover',
                        label: Text('DISCOVER'),
                      ),
                    ],
                    showSelectedIcon: false,
                    selected: <String>{_selectedFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = newSelection.first);
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Cards list
            if (filteredWallets.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      'No cards found.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverReorderableList(
                itemCount: filteredWallets.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.lightImpact();
                  context.read<WalletProvider>().reorderWallets(
                    oldIndex,
                    newIndex,
                  );
                },
                itemBuilder: (context, index) {
                  final wallet = filteredWallets[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(wallet.id),
                    index: index,
                    child: _AnimatedListItem(
                      key: ValueKey('anim_${wallet.id}'),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Slidable(
                          key: ValueKey(wallet.id),
                          startActionPane: ActionPane(
                            motion: const BehindMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (ctx) {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    SmoothPageRoute(
                                      page: WalletEditScreen(wallet: wallet),
                                    ),
                                  );
                                },
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.blue,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const BehindMotion(),
                            extentRatio: 0.45,
                            children: [
                              SlidableAction(
                                onPressed: (ctx) {
                                  HapticFeedback.mediumImpact();
                                  Clipboard.setData(
                                    ClipboardData(text: wallet.number),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Card number copied!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.blue,
                                icon: Icons.copy_rounded,
                                label: 'Copy',
                              ),
                              SlidableAction(
                                onPressed: (ctx) async {
                                  HapticFeedback.mediumImpact();
                                  await context
                                      .read<WalletProvider>()
                                      .deleteWallet(wallet.id!);
                                },
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.red,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: GlassCreditCard(
                            wallet: wallet,
                            isMasked: true,
                            onCardTap: () => Navigator.push(
                              context,
                              SmoothPageRoute(
                                page: WalletDetailScreen(wallet: wallet),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildPassesTab(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Consumer<PassProvider>(
      builder: (context, provider, child) {
        final passes = provider.passes;
        if (passes.isEmpty) {
          return _buildEmptyState(
            context,
            "No passes added yet.\nTap the '+' to add one.",
          );
        }

        final searchedPasses = provider.searchPasses(_searchQuery);
        final filteredPasses = searchedPasses.where((pass) {
          if (_selectedPassFilter == 'all') return true;
          return pass.type == _selectedPassFilter;
        }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withValues(alpha: 0.059) : Colors.black.withValues(alpha: 0.031),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.102) : Colors.black.withValues(alpha: 0.059)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Search passes...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.black45),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'all', label: Text('ALL')),
                      ButtonSegment<String>(value: 'boardingPass', label: Text('BOARDING PASSES')),
                      ButtonSegment<String>(value: 'eventTicket', label: Text('EVENT TICKETS')),
                      ButtonSegment<String>(value: 'coupon', label: Text('COUPONS')),
                      ButtonSegment<String>(value: 'storeCard', label: Text('STORE CARDS')),
                      ButtonSegment<String>(value: 'generic', label: Text('OTHER')),
                    ],
                    showSelectedIcon: false,
                    selected: <String>{_selectedPassFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPassFilter = newSelection.first);
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Passes list
            if (filteredPasses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      'No passes found.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ),
              )
            else
              SliverReorderableList(
              itemCount: filteredPasses.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.lightImpact();
                context.read<PassProvider>().reorderPasses(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final pass = filteredPasses[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(pass.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Slidable(
                      key: ValueKey(pass.id),
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) async {
                              HapticFeedback.lightImpact();
                              final result = await Navigator.push(
                                ctx,
                                SmoothPageRoute(
                                  page: Scaffold(
                                    appBar: AppBar(title: const Text('Edit Pass')),
                                    body: BarcodeCardEntryForm(existingPass: pass),
                                  ),
                                ),
                              );
                              if (result == true && ctx.mounted) {
                                ctx.read<PassProvider>().fetchPasses();
                              }
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.45,
                        children: [
                          SlidableAction(
                            onPressed: (ctx) {
                              HapticFeedback.mediumImpact();
                              Clipboard.setData(
                                ClipboardData(text: pass.barcodeValue),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Pass data copied!'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.blue,
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                          ),
                          SlidableAction(
                            onPressed: (context) => _showPassDeleteConfirmationDialog(
                              id: pass.id!,
                              name: pass.organizationName,
                            ),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.red,
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: BarcodeCard(
                        pass: pass,
                        onCardTap: () async {
                          HapticFeedback.selectionClick();
                          final passProvider = Provider.of<PassProvider>(context, listen: false);
                          final result = await Navigator.push(
                            context,
                            SmoothPageRoute(page: BarcodeCardDetailScreen(pass: pass)),
                          );
                          if (result == true && mounted) {
                            await passProvider.fetchPasses();
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

class _AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
