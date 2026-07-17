import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../admin/presentation/pages/admin_login_page.dart';
import '../../../demo/presentation/pages/client_demo_page.dart';
import '../../../demo/presentation/pages/waiter_demo_page.dart';
import '../../../demo/theme/chama_garcom_theme.dart';
import '../../../gtech/presentation/pages/gtech_home_page.dart';

enum HomeTab {
  cliente,
  garcom,
  admin,
  gtech,
}

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  HomeTab _tab = HomeTab.cliente;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            _TopSwitcher(
              active: _tab,
              onChange: (tab) => setState(() => _tab = tab),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: switch (_tab) {
                    HomeTab.cliente => const ClientDemoPage(),
                    HomeTab.garcom => const WaiterDemoPage(),
                    HomeTab.admin => const AdminLoginPage(),
                    HomeTab.gtech => const GtechHomePage(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSwitcher extends StatelessWidget {
  final HomeTab active;
  final ValueChanged<HomeTab> onChange;

  const _TopSwitcher({
    required this.active,
    required this.onChange,
  });

  static const _tabs = [
    (
      HomeTab.cliente,
      "Página do Cliente",
      false,
    ),
    (
      HomeTab.garcom,
      "App do Garçom",
      true,
    ),
    (
      HomeTab.admin,
      "Painel Admin",
      false,
    ),
    (
      HomeTab.gtech,
      "Painel GTech",
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ChamaGarcomTheme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.ink2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: theme.line),
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: _tabs
              .map(
                (tab) => _SwitchChip(
                  label: tab.$2,
                  dot: tab.$3,
                  isActive: active == tab.$1,
                  theme: theme,
                  onTap: () => onChange(tab.$1),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SwitchChip extends StatelessWidget {
  final String label;
  final bool dot;
  final bool isActive;
  final VoidCallback onTap;
  final ChamaGarcomTheme theme;

  const _SwitchChip({
    required this.label,
    required this.dot,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? theme.brassBright
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.coral,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isActive
                      ? theme.ink
                      : theme.textDimColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}