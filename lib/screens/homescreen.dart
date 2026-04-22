import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/pages/add_card_screen.dart';
import 'package:wallet/pages/settings_page.dart';
import 'package:wallet/screens/barcode_card_details_screen.dart';
import 'package:wallet/screens/summary.dart';
import 'package:wallet/widgets/barcode_card.dart';
import 'package:wallet/widgets/glass_credit_card.dart';
import 'package:wallet/widgets/liquid_glass.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dataentry.dart';
import '../models/db_helper.dart';
import '../models/provider_helper.dart';
import '../models/theme_provider.dart';
import '../pages/walletdetails.dart';

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

  late final TextEditingController _searchController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<LoyaltyProvider>().fetchLoyalties();
      context.read<IdentityProvider>().fetchIdentities();

      // Initialize selected index from startup settings
      final startupProvider = context.read<StartupSettingsProvider>();
      if (startupProvider.hideIdentityAndLoyalty) {
        setState(() => _selectedIndex = 0);
      } else {
        setState(() => _selectedIndex = startupProvider.defaultScreenIndex);
      }
    });

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showBarcodeDeleteConfirmationDialog({
    required int id,
    required String name,
    required BarcodeCardType type,
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
            'Delete Card?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
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
                if (type == BarcodeCardType.loyalty) {
                  context.read<LoyaltyProvider>().deleteLoyalty(id);
                } else {
                  context.read<IdentityProvider>().deleteIdentity(id);
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Card Deleted!')));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card number copied!')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Force index to 0 (Payments) if Identity/Loyalty are hidden
    final isHiddenMode = startupProvider.hideIdentityAndLoyalty;
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
                  ? Colors.white.withValues(alpha: 0.102)
                  : Colors.black.withValues(alpha: 0.149),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final walletProvider = context.read<WalletProvider>();
            final loyaltyProvider = context.read<LoyaltyProvider>();
            final identityProvider = context.read<IdentityProvider>();
            final result = await Navigator.push(
              context,
              SmoothPageRoute(
                page: AddCardScreen(initialTabIndex: effectiveIndex),
              ),
            );
            if (result == true && mounted) {
              await walletProvider.fetchWallets();
              await loyaltyProvider.fetchLoyalties();
              await identityProvider.fetchIdentities();
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
          _buildLoyaltyTab(context),
          _buildIdentityTab(context),
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
                    icon: Icon(Icons.loyalty_outlined),
                    selectedIcon: Icon(Icons.loyalty),
                    label: 'Loyalty',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge),
                    label: 'Identity',
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
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 16,
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
                      hintText: 'Search by name, number, issuer...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
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
            // Cards list — using SliverList for lazy loading
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
            else if (_searchQuery.isEmpty && _selectedFilter == 'all')
              SliverReorderableList(
                itemCount: filteredWallets.length,
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
                          endActionPane: ActionPane(
                            motion: const BehindMotion(),
                            extentRatio: 0.50,
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  _copyToClipboard(wallet.number);
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
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Card deleted'),
                                      ),
                                    );
                                  }
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
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final wallet = filteredWallets[index];
                  return _AnimatedListItem(
                    key: ValueKey('anim_${wallet.id}'),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Slidable(
                        key: ValueKey(wallet.id),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: 0.50,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _copyToClipboard(wallet.number);
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
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Card deleted'),
                                    ),
                                  );
                                }
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
                  );
                }, childCount: filteredWallets.length),
              ),

            // Financial Summary button
            if (_selectedFilter == 'all')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: LiquidGlassContainer(
                    padding: EdgeInsets.zero,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const Summary()),
                      );
                    },
                    child: ListTile(
                      leading: null,
                      title: Text(
                        'View Financial Summary',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildLoyaltyTab(BuildContext context) {
    return Consumer<LoyaltyProvider>(
      builder: (context, provider, child) {
        final loyalties = provider.loyalties;
        if (loyalties.isEmpty) {
          return _buildEmptyState(
            context,
            "No loyalty cards added yet.\nTap the '+' to add one.",
          );
        }
        return ReorderableListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: loyalties.length,
          onReorder: (oldIndex, newIndex) {
            HapticFeedback.lightImpact();
            context.read<LoyaltyProvider>().reorderLoyalties(
              oldIndex,
              newIndex,
            );
          },
          itemBuilder: (context, index) {
            final loyalty = loyalties[index];
            return _AnimatedListItem(
              key: ValueKey(loyalty.id),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Slidable(
                  key: ValueKey(loyalty.id),
                  endActionPane: ActionPane(
                    motion: const BehindMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (context) =>
                            _showBarcodeDeleteConfirmationDialog(
                              id: loyalty.id!,
                              name: loyalty.loyaltyName,
                              type: BarcodeCardType.loyalty,
                            ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.red,
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: BarcodeCard(
                    loyalty: loyalty,
                    cardType: BarcodeCardType.loyalty,
                    onCardTap: () => Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: BarcodeCardDetailScreen(loyalty: loyalty),
                      ),
                    ),
                    onCopyTap: () => _copyToClipboard(loyalty.loyaltyNumber),
                    onDeleteTap: () => _showBarcodeDeleteConfirmationDialog(
                      id: loyalty.id!,
                      name: loyalty.loyaltyName,
                      type: BarcodeCardType.loyalty,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIdentityTab(BuildContext context) {
    return Consumer<IdentityProvider>(
      builder: (context, provider, child) {
        final identities = provider.identities;
        if (identities.isEmpty) {
          return _buildEmptyState(
            context,
            "No identity cards added yet.\nTap the '+' to add one.",
          );
        }
        return ReorderableListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: identities.length,
          onReorder: (oldIndex, newIndex) {
            HapticFeedback.lightImpact();
            context.read<IdentityProvider>().reorderIdentities(
              oldIndex,
              newIndex,
            );
          },
          itemBuilder: (context, index) {
            final identity = identities[index];
            return _AnimatedListItem(
              key: ValueKey(identity.id),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Slidable(
                  key: ValueKey(identity.id),
                  endActionPane: ActionPane(
                    motion: const BehindMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (context) =>
                            _showBarcodeDeleteConfirmationDialog(
                              id: identity.id!,
                              name: identity.identityName,
                              type: BarcodeCardType.identity,
                            ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.red,
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: BarcodeCard(
                    identity: identity,
                    cardType: BarcodeCardType.identity,
                    onCardTap: () => Navigator.push(
                      context,
                      SmoothPageRoute(
                        page: BarcodeCardDetailScreen(identity: identity),
                      ),
                    ),
                    onCopyTap: () => _copyToClipboard(identity.identityNumber),
                    onDeleteTap: () => _showBarcodeDeleteConfirmationDialog(
                      id: identity.id!,
                      name: identity.identityName,
                      type: BarcodeCardType.identity,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Staggered slide-up + fade-in animation for list items
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
