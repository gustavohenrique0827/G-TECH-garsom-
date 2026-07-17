/// Centralized route paths. Keep in sync with [appRouterProvider].
class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';

  // Public client PWA — reached only via QR Code or NFC, both encoding the
  // exact same URL. No auth, no distinction between the two access methods.
  static const clientTable = '/r/:companyId/m/:tableId';
  static const clientMenu = '/r/:companyId/m/:tableId/cardapio';

  static String clientTablePath(String companyId, String tableId) =>
      '/r/$companyId/m/$tableId';

  static String clientMenuPath(String companyId, String tableId) =>
      '/r/$companyId/m/$tableId/cardapio';

  // Waiter — receive-only call queue, history, profile.
  static const waiterCalls = '/garcom';
  static const waiterHistory = '/garcom/historico';
  static const waiterProfile = '/garcom/perfil';

  // Restaurant admin.
  static const adminDashboard = '/admin';
  static const adminTables = '/admin/mesas';
  static const adminMenu = '/admin/cardapio';
  static const adminWaiters = '/admin/garcons';
  static const adminSettings = '/admin/configuracoes';

  // GTech master admin.
  static const gtechDashboard = '/gtech';
  static const gtechCompanies = '/gtech/empresas';
  static const gtechPlans = '/gtech/planos';
}
