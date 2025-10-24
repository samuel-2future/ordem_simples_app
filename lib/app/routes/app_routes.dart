import 'package:flutter/material.dart';
import 'package:ordem_simples_app/presentation/views/assinaturas_view.dart';
import '../../presentation/views/splash_view.dart';
import '../../presentation/views/home_view.dart';
import '../../presentation/views/clientes_view.dart';
import '../../presentation/views/novo_cliente_view.dart';
import '../../presentation/views/ordens_view.dart';
import '../../presentation/views/nova_ordem_view.dart';
import '../../presentation/views/assinatura_view.dart';

class AppRoutes {
  static const home = '/home';
  static const clientes = '/clientes';
  static const novoCliente = '/novoCliente';
  static const ordens = '/ordens';
  static const novaOrdem = '/novaOrdem';
  static const assinatura = '/assinatura';
  static const assinaturas = '/assinaturas';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeView(),
    clientes: (context) => const ClientesView(),
    novoCliente: (context) => const NovoClienteView(),
    ordens: (context) => const OrdensView(),
    novaOrdem: (context) => const NovaOrdemView(),
    assinatura: (context) => const AssinaturaView(),
    assinaturas: (context) => const AssinaturasView(),
  };
}
