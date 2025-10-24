import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/routes/app_routes.dart';
import '../../core/user_session.dart';
import '../views/login_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _db = Supabase.instance.client;

  bool _carregandoDashboard = true;
  int totalClientes = 0;
  int ordensAbertas = 0;
  int ordensConcluidas = 0;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    if (UserSession.loginId == null) {
      setState(() => _carregandoDashboard = false);
      return;
    }

    try {
      setState(() => _carregandoDashboard = true);
      final loginId = UserSession.loginId!;

      final clientesResp = await _db
          .from('clientes')
          .count(CountOption.exact)
          .eq('login_id', loginId);

      final abertasResp = await _db
          .from('ordens_servico')
          .count(CountOption.exact)
          .eq('login_id', loginId)
          .eq('status', 'Aberta');

      final concluidasResp = await _db
          .from('ordens_servico')
          .count(CountOption.exact)
          .eq('login_id', loginId)
          .eq('status', 'Concluída');

      if (mounted) {
        setState(() {
          totalClientes = clientesResp;
          ordensAbertas = abertasResp;
          ordensConcluidas = concluidasResp;
          _carregandoDashboard = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
      if (mounted) setState(() => _carregandoDashboard = false);
    }
  }

  /// 🔒 Exibe popup de confirmação antes de sair
  Future<void> _confirmarSaida(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do aplicativo'),
        content: const Text('Deseja realmente sair e encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _sair(context);
    }
  }

  void _sair(BuildContext context) {
    UserSession.clear();
    _limparSessaoSalva();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
    );
  }

  Future<void> _limparSessaoSalva() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
  }

  String _getPrimeiroNome(String? nome) {
    if (nome == null || nome.trim().isEmpty) return '';
    return nome.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final empresa = UserSession.nomeEmpresa ?? 'Minha Empresa';
    final responsavel = _getPrimeiroNome(UserSession.nomeCompleto ?? 'Usuário');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ordem Simples'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Olá, $responsavel 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            empresa,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          /// 🔁 Dashboard com RefreshIndicator
          RefreshIndicator(
            onRefresh: _carregarDashboard,
            child: SizedBox(
              height: 140,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _carregandoDashboard
                        ? Center(
                      key: const ValueKey('loading'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )
                        : Card(
                      key: const ValueKey('dashboard'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.blue.shade50,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              icon: Icons.people,
                              label: 'Clientes',
                              value: totalClientes.toString(),
                              color: Colors.blue.shade700,
                            ),
                            _InfoChip(
                              icon: Icons.assignment_outlined,
                              label: 'Abertas',
                              value: ordensAbertas.toString(),
                              color: Colors.red.shade600,
                            ),
                            _InfoChip(
                              icon: Icons.check_circle_outline,
                              label: 'Concluídas',
                              value: ordensConcluidas.toString(),
                              color: Colors.green.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          _DashboardCard(
            title: 'Clientes',
            icon: Icons.people,
            color: Colors.blue,
            description:
            'Gerencie seus clientes, cadastre novos e consulte informações.',
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.clientes);
              if (mounted) _carregarDashboard();
            },
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            title: 'Ordens de Serviço',
            icon: Icons.assignment,
            color: Colors.green,
            description:
            'Crie, visualize e acompanhe as ordens de serviço cadastradas.',
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.ordens);
              if (mounted) _carregarDashboard();
            },
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
