// ignore_for_file: use_build_context_synchronously

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
import 'package:wallet/pages/support_screen.dart';
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
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              SmoothPageRoute(page: const SupportScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.pink.shade300,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(13),
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
                  ? Colors.white.withAlpha(26)
                  : Colors.black.withAlpha(38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final result = await Navigator.push(
              context,
              SmoothPageRoute(
                page: AddCardScreen(initialTabIndex: effectiveIndex),
              ),
            );
            if (result == true && mounted) {
              context.read<WalletProvider>().fetchWallets();
              context.read<LoyaltyProvider>().fetchLoyalties();
              context.read<IdentityProvider>().fetchIdentities();
            }
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: IndexedStack(
          key: ValueKey(effectiveIndex),
          index: effectiveIndex,
          children: [
            _buildPaymentsTab(context),
            _buildLoyaltyTab(context),
            _buildIdentityTab(context),
          ],
        ),
      ),
      bottomNavigationBar: isHiddenMode
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(13),
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: effectiveIndex,
                onDestinationSelected: _onItemTapped,
                animationDuration: const Duration(milliseconds: 400),
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

    return Selector<WalletProvider, List<Wallet>>(
      selector: (_, provider) => provider.wallets,
      builder: (context, wallets, child) {
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
                        ? Colors.white.withAlpha(15)
                        : Colors.black.withAlpha(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(26)
                          : Colors.black.withAlpha(15),
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
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final wallet = filteredWallets[index];
                  return _AnimatedListItem(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Slidable(
                        key: ValueKey(wallet.id),
                        endActionPane: ActionPane(
                          motion: const BehindMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                HapticFeedback.mediumImpact();
                                await context
                                    .read<WalletProvider>()
                                    .deleteWallet(wallet.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Card deleted')),
                                );
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
    return Selector<LoyaltyProvider, List<Loyalty>>(
      selector: (_, provider) => provider.loyalties,
      builder: (context, loyalties, child) {
        if (loyalties.isEmpty) {
          return _buildEmptyState(
            context,
            "No loyalty cards added yet.\nTap the '+' to add one.",
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: loyalties.length,
          itemBuilder: (context, index) {
            final loyalty = loyalties[index];
            return _AnimatedListItem(
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
    return Selector<IdentityProvider, List<Identity>>(
      selector: (_, provider) => provider.identities,
      builder: (context, identities, child) {
        if (identities.isEmpty) {
          return _buildEmptyState(
            context,
            "No identity cards added yet.\nTap the '+' to add one.",
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: identities.length,
          itemBuilder: (context, index) {
            final identity = identities[index];
            return _AnimatedListItem(
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
class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    // Stagger: delay based on index, but cap at 5 to avoid long waits
    final delay = Duration(milliseconds: (widget.index.clamp(0, 5)) * 60);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
