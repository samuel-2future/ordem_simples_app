import 'package:flutter/material.dart';
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

  int totalClientes = 0;
  int ordensAbertas = 0;
  int ordensConcluidas = 0;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    if (UserSession.loginId == null) return;

    try {
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

      setState(() {
        totalClientes = clientesResp;
        ordensAbertas = abertasResp;
        ordensConcluidas = concluidasResp;
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  void _sair(BuildContext context) {
    UserSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
    );
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
            onPressed: () => _sair(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Saudação
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

            // Mini Dashboard
            carregando
                ? const Center(child: CircularProgressIndicator())
                : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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

            const SizedBox(height: 28),

            // Cards principais
            _DashboardCard(
              title: 'Clientes',
              icon: Icons.people,
              color: Colors.blue,
              description:
              'Gerencie seus clientes, cadastre novos e consulte informações.',
              onTap: () => Navigator.pushNamed(context, AppRoutes.clientes),
            ),
            const SizedBox(height: 20),
            _DashboardCard(
              title: 'Ordens de Serviço',
              icon: Icons.assignment,
              color: Colors.green,
              description:
              'Crie, visualize e acompanhe as ordens de serviço cadastradas.',
              onTap: () => Navigator.pushNamed(context, AppRoutes.ordens),
            ),
          ],
        ),
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
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Ícone colorido
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),

              // Texto
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

              // Setinha
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
