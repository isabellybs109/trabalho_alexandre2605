
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const LojaOnlineApp());
}

/// Modelo de dados do produto.
///
/// Os produtos são carregados do arquivo externo assets/products.json.
/// Isso deixa o exemplo mais organizado e aproxima o projeto de uma situação real,
/// em que os dados poderiam vir de um banco de dados ou API.
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String icon;
  final String shortDescription;
  final String longDescription;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.icon,
    required this.shortDescription,
    required this.longDescription,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      icon: json['icon'] as String,
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String,
    );
  }
}

/// Controlador central do aplicativo.
///
/// Esta classe guarda os produtos, o carrinho e o número de confirmação.
/// Ela usa ChangeNotifier para avisar as telas quando algum valor muda.
class StoreController extends ChangeNotifier {
  final Map<String, int> _cart = <String, int>{};

  List<Product> products = <Product>[];
  bool loading = true;
  String? loadError;
  String? confirmationNumber;

  Future<void> loadProducts() async {
    try {
      final String jsonText = await rootBundle.loadString('assets/products.json');
      final List<dynamic> decoded = json.decode(jsonText) as List<dynamic>;
      products = decoded
          .map((dynamic item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      loadError = 'Não foi possível carregar o inventário: $error';
      notifyListeners();
    }
  }

  Map<String, int> get cart => Map.unmodifiable(_cart);

  int get cartItemCount => _cart.values.fold(0, (int total, int q) => total + q);

  Product productById(String id) => products.firstWhere((Product product) => product.id == id);

  int quantityOf(String productId) => _cart[productId] ?? 0;

  List<Product> get cartProducts => _cart.keys.map(productById).toList();

  bool addToCart(Product product) {
    final int nextQuantity = quantityOf(product.id) + 1;
    if (nextQuantity > product.stock) {
      return false;
    }
    _cart[product.id] = nextQuantity;
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  bool updateQuantity(Product product, int quantity) {
    if (quantity < 0) return true;
    if (quantity > product.stock) return false;

    if (quantity == 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = quantity;
    }
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  void cancelOrder() {
    _cart.clear();
    confirmationNumber = null;
    notifyListeners();
  }

  String finishOrder() {
    final String number = 'PED-${DateTime.now().year}-${100000 + Random().nextInt(900000)}';
    confirmationNumber = number;
    notifyListeners();
    return number;
  }

  double get subtotal {
    double total = 0;
    _cart.forEach((String productId, int quantity) {
      total += productById(productId).price * quantity;
    });
    return total;
  }

  /// Regra didática de frete.
  /// Frete grátis acima de R$ 300,00; abaixo disso, R$ 29,90.
  double get shipping => subtotal == 0 ? 0 : (subtotal >= 200 ? 0 : 19.90);

  /// Regra didática de imposto.
  /// Este valor é apenas uma simulação para a atividade escolar.
  double get taxes => subtotal * 0.08;

  double get total => subtotal + shipping + taxes;
}

class LojaOnlineApp extends StatefulWidget {
  const LojaOnlineApp({super.key});

  @override
  State<LojaOnlineApp> createState() => _LojaOnlineAppState();
}

class _LojaOnlineAppState extends State<LojaOnlineApp> {
  final StoreController controller = StoreController();

  @override
  void initState() {
    super.initState();
    controller.loadProducts();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Festa & Alegria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: const Color(0xFFFFF0F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          if (controller.loading) {
            return const LoadingPage();
          }
          if (controller.loadError != null) {
            return ErrorPage(message: controller.loadError!);
          }
          return HomePage(controller: controller);
        },
      ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryDark = Color(0xFF7B1050);
  static const Color success = Color(0xFF2EAD55);
  static const Color warning = Color(0xFFE53935);
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String message;

  const ErrorPage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class StoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final StoreController controller;
  final String title;
  final bool showBack;

  const StoreAppBar({
    required this.controller,
    required this.title,
    this.showBack = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      actions: <Widget>[
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                label: Text('${controller.cartItemCount}'),
                isLabelVisible: controller.cartItemCount > 0,
                child: IconButton(
                  tooltip: 'Carrinho de Compras',
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => openCart(context, controller),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

void openCart(BuildContext context, StoreController controller) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => CartPage(controller: controller)),
  );
}

void openProducts(BuildContext context, StoreController controller, {bool replace = false}) {
  final MaterialPageRoute<void> route = MaterialPageRoute<void>(
    builder: (_) => ProductsPage(controller: controller),
  );
  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}

void showAppMessage(BuildContext context, String message, {bool success = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? AppColors.success : null,
      content: Text(message),
    ),
  );
}

/// Passo 1 – Página Inicial.
class HomePage extends StatelessWidget {
  final StoreController controller;

  const HomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(controller: controller, title: 'Festa & Alegria'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const ProductHero(),
            const SizedBox(height: 20),
            Text(
              'Bem-vindo à Festa & Alegria! 🎉',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tudo para sua festa ficar inesquecível! Balões, decorações, velas e muito mais.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Ver Produtos', style: TextStyle(fontSize: 18)),
              onPressed: () => openProducts(context, controller),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Carrinho', style: TextStyle(fontSize: 18)),
              onPressed: () => openCart(context, controller),
            ),
            const SizedBox(height: 20),
            const DidacticNote(
              title: 'O que esta tela ensina?',
              text: 'A Página Inicial apresenta a loja de materiais de festa, com acesso rápido aos produtos e ao carrinho de compras.',
            ),
          ],
        ),
      ),
    );
  }
}

class ProductHero extends StatelessWidget {
  const ProductHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFE4F2), Color(0xFFFFF9FB)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          HeroIcon(icon: Icons.cake, size: 64),
          HeroIcon(icon: Icons.celebration, size: 54),
          HeroIcon(icon: Icons.card_giftcard, size: 58),
        ],
      ),
    );
  }
}

class HeroIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const HeroIcon({required this.icon, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Icon(icon, size: size, color: AppColors.primaryDark),
    );
  }
}

/// Passo 2 – Página de Produtos.
class ProductsPage extends StatelessWidget {
  final StoreController controller;

  const ProductsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(controller: controller, title: 'Festa & Alegria', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              const PageHeader(
                title: 'Página de Produtos',
                subtitle: 'Escolha um produto e toque em Selecionar para ver os detalhes.',
              ),
              for (final Product product in controller.products)
                ProductCard(
                  product: product,
                  onSelect: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsPage(controller: controller, product: product),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSelect;

  const ProductCard({required this.product, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ProductIcon(product: product, size: 76),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(product.shortDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('Estoque: ${product.stock}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatMoney(product.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: onSelect,
                  child: const Text('Selecionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Passo 3 – Detalhes do Produto.
class ProductDetailsPage extends StatelessWidget {
  final StoreController controller;
  final Product product;

  const ProductDetailsPage({required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(controller: controller, title: 'Festa & Alegria', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProductIcon(product: product, size: 132),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text('ID: ${product.id}'),
                    const SizedBox(height: 8),
                    Text(product.shortDescription),
                    const SizedBox(height: 14),
                    Text(
                      formatMoney(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Em estoque: ${product.stock} unidades'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Text('Descrição', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(product.longDescription, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar ao Carrinho', style: TextStyle(fontSize: 16)),
            onPressed: () {
              final bool added = controller.addToCart(product);
              if (added) {
                showAppMessage(context, 'Produto adicionado ao carrinho com sucesso!', success: true);
              } else {
                showAppMessage(context, 'Quantidade solicitada excede o estoque disponível.');
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Ver Mais Produtos', style: TextStyle(fontSize: 16)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
          const DidacticNote(
            title: 'Regra de negócio',
            text: 'O botão Adicionar ao Carrinho só deve funcionar enquanto a quantidade escolhida não ultrapassar o estoque do produto.',
          ),
        ],
      ),
    );
  }
}

/// Passo 4 – Carrinho de Compras.
class CartPage extends StatelessWidget {
  final StoreController controller;

  const CartPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(controller: controller, title: 'Festa & Alegria', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: <Widget>[
              PageHeader(
                title: 'Carrinho de Compras (${controller.cartItemCount} itens)',
                subtitle: 'Revise os produtos, ajuste as quantidades e acompanhe o total.',
              ),
              if (controller.cartProducts.isEmpty)
                const EmptyCartCard()
              else ...<Widget>[
                for (final Product product in controller.cartProducts)
                  CartItemCard(controller: controller, product: product),
                const SizedBox(height: 8),
                SummaryCard(controller: controller),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Finalizar Pedido'),
                onPressed: controller.cartProducts.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => CheckoutPage(controller: controller)),
                        );
                      },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cancelar Pedido'),
                onPressed: () {
                  controller.cancelOrder();
                  showAppMessage(context, 'Pedido cancelado. As quantidades e o total foram zerados.');
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Ver Mais Produtos'),
                onPressed: () => openProducts(context, controller, replace: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmptyCartCard extends StatelessWidget {
  const EmptyCartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            const Text('Carrinho vazio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Clique em Ver Mais Produtos para adicionar itens ao carrinho.'),
          ],
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final StoreController controller;
  final Product product;

  const CartItemCard({required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final int quantity = controller.quantityOf(product.id);
    final double itemSubtotal = product.price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            ProductIcon(product: product, size: 64),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('ID: ${product.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatMoney(product.price)),
                  const SizedBox(height: 6),
                  QuantityControl(
                    quantity: quantity,
                    onDecrease: () => controller.updateQuantity(product, quantity - 1),
                    onIncrease: () {
                      final bool ok = controller.updateQuantity(product, quantity + 1);
                      if (!ok) {
                        showAppMessage(context, 'Quantidade solicitada excede o estoque. Estoque disponível: ${product.stock} unidades.');
                      }
                    },
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Text('Subtotal', style: TextStyle(fontSize: 12)),
                Text(formatMoney(itemSubtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF48CB6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: onDecrease,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.remove, size: 18, color: AppColors.primary),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: Color(0xFFF48CB6))),
            ),
            child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          InkWell(
            onTap: onIncrease,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.add, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final StoreController controller;

  const SummaryCard({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Resumo da compra', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SummaryRow(label: 'Subtotal', value: formatMoney(controller.subtotal)),
            SummaryRow(label: 'Frete', value: formatMoney(controller.shipping)),
            SummaryRow(label: 'Impostos (8%)', value: formatMoney(controller.taxes)),
            const Divider(),
            SummaryRow(label: 'Total', value: formatMoney(controller.total), highlight: true),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const SummaryRow({required this.label, required this.value, this.highlight = false, super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      fontSize: highlight ? 18 : 15,
      color: highlight ? AppColors.primary : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style.copyWith(color: Colors.black87)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Passo 5 – Finalização do Pedido.
class CheckoutPage extends StatefulWidget {
  final StoreController controller;

  const CheckoutPage({required this.controller, super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController billingName = TextEditingController(text: 'João da Silva');
  final TextEditingController billingStreet = TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController billingCity = TextEditingController(text: 'São Paulo');
  final TextEditingController billingState = TextEditingController(text: 'SP');
  final TextEditingController billingZip = TextEditingController(text: '01234-567');
  final TextEditingController billingPhone = TextEditingController(text: '(11) 99999-9999');

  final TextEditingController shippingName = TextEditingController(text: 'João da Silva');
  final TextEditingController shippingStreet = TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController shippingCity = TextEditingController(text: 'São Paulo');
  final TextEditingController shippingState = TextEditingController(text: 'SP');
  final TextEditingController shippingZip = TextEditingController(text: '01234-567');

  bool useSameAddress = true;

  @override
  void dispose() {
    billingName.dispose();
    billingStreet.dispose();
    billingCity.dispose();
    billingState.dispose();
    billingZip.dispose();
    billingPhone.dispose();
    shippingName.dispose();
    shippingStreet.dispose();
    shippingCity.dispose();
    shippingState.dispose();
    shippingZip.dispose();
    super.dispose();
  }

  void copyBillingToShipping() {
    shippingName.text = billingName.text;
    shippingStreet.text = billingStreet.text;
    shippingCity.text = billingCity.text;
    shippingState.text = billingState.text;
    shippingZip.text = billingZip.text;
  }

  void confirmOrder() {
    if (widget.controller.cartProducts.isEmpty) {
      showAppMessage(context, 'O carrinho está vazio. Adicione produtos antes de finalizar.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      showAppMessage(context, 'Preencha corretamente os endereços de cobrança e entrega.');
      return;
    }
    if (useSameAddress) copyBillingToShipping();
    final String number = widget.controller.finishOrder();
    showAppMessage(context, 'Pedido confirmado: $number', success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoreAppBar(controller: widget.controller, title: 'Festa & Alegria', showBack: true),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, Widget? child) {
          return Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                const PageHeader(
                  title: 'Finalização do Pedido',
                  subtitle: 'Informe os endereços, revise o resumo e confirme a compra simulada.',
                ),
                AddressSection(
                  title: 'Endereço de cobrança',
                  icon: Icons.location_on,
                  controllers: <TextEditingController>[billingName, billingStreet, billingCity, billingState, billingZip, billingPhone],
                  labels: const <String>['Nome', 'Rua e número', 'Cidade', 'UF', 'CEP', 'Telefone'],
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  child: CheckboxListTile(
                    value: useSameAddress,
                    onChanged: (bool? value) {
                      setState(() {
                        useSameAddress = value ?? false;
                        if (useSameAddress) copyBillingToShipping();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Usar o mesmo endereço de cobrança'),
                  ),
                ),
                if (!useSameAddress) ...<Widget>[
                  const SizedBox(height: 12),
                  AddressSection(
                    title: 'Endereço de entrega',
                    icon: Icons.local_shipping,
                    controllers: <TextEditingController>[shippingName, shippingStreet, shippingCity, shippingState, shippingZip],
                    labels: const <String>['Nome', 'Rua e número', 'Cidade', 'UF', 'CEP'],
                  ),
                ],
                const SizedBox(height: 12),
                CheckoutOrderSummary(controller: widget.controller),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Confirmar Pedido'),
                  onPressed: confirmOrder,
                ),
                if (widget.controller.confirmationNumber != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ConfirmationCard(number: widget.controller.confirmationNumber!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddressSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<TextEditingController> controllers;
  final List<String> labels;

  const AddressSection({
    required this.title,
    required this.icon,
    required this.controllers,
    required this.labels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < controllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: labels[i],
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CheckoutOrderSummary extends StatelessWidget {
  final StoreController controller;

  const CheckoutOrderSummary({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Resumo do pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            for (final Product product in controller.cartProducts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    ProductIcon(product: product, size: 40),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${product.name}\nQtd: ${controller.quantityOf(product.id)}')),
                    Text(formatMoney(product.price * controller.quantityOf(product.id))),
                  ],
                ),
              ),
            const Divider(),
            SummaryRow(label: 'Subtotal', value: formatMoney(controller.subtotal)),
            SummaryRow(label: 'Frete', value: formatMoney(controller.shipping)),
            SummaryRow(label: 'Impostos (8%)', value: formatMoney(controller.taxes)),
            SummaryRow(label: 'Total', value: formatMoney(controller.total), highlight: true),
          ],
        ),
      ),
    );
  }
}

class ConfirmationCard extends StatelessWidget {
  final String number;

  const ConfirmationCard({required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEAF7EF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.success),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              backgroundColor: AppColors.success,
              child: Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pedido confirmado: $number\nEnviamos os detalhes para o e-mail cadastrado.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({required this.title, required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}

class DidacticNote extends StatelessWidget {
  final String title;
  final String text;

  const DidacticNote({required this.title, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF48CB6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.school, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: '$title\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductIcon extends StatelessWidget {
  final Product product;
  final double size;

  const ProductIcon({required this.product, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4F2),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(productIcon(product.icon), size: size * 0.55, color: AppColors.primaryDark),
    );
  }
}

IconData productIcon(String icon) {
  switch (icon) {
    case 'balloon':
      return Icons.celebration;
    case 'party':
      return Icons.party_mode;
    case 'cake':
      return Icons.cake;
    case 'gift':
      return Icons.card_giftcard;
    case 'table':
      return Icons.table_restaurant;
    default:
      return Icons.celebration;
  }
}

String formatMoney(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
