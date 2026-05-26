# Loja Online Simples — Flutter/Dart

Projeto didático para Android Studio, inspirado na apostila **Loja Online Simples com Flutter e Dart**.

 - Prof. Alexandre Garcez Vieira
 - Escola Técnica Estadual Juscelino Kubitschek de Oliveira
 - Diadema / SP

## O que o app demonstra

- Página Inicial com botões **Ver Produtos** e **Carrinho**.
- Página de Produtos com cards, preço, descrição curta, estoque e botão **Selecionar**.
- Página de Detalhes do Produto com ID, preço, estoque, descrição longa, botão **Adicionar ao Carrinho** e botão **Ver Mais Produtos**.
- Carrinho com ID, nome, preço unitário, quantidade, subtotal, frete, impostos e total.
- Validação de estoque: o app mostra erro se a quantidade solicitada ultrapassar o estoque.
- Cancelamento do pedido, zerando quantidades e total.
- Finalização do pedido com endereço de cobrança, endereço de entrega e número de confirmação.
- Inventário em arquivo externo: `assets/products.json`.

## Como executar no Android Studio

1. Extraia o arquivo ZIP.
2. Abra a pasta `loja_online_simples_flutter_aprimorado` no Android Studio.
3. Confirme que o Flutter SDK está configurado.
4. Execute:

```bash
flutter pub get
flutter run
```

Caso o Android Studio solicite recriar arquivos de plataforma, use:

```bash
flutter create .
flutter pub get
flutter run
```

## Estrutura principal

```text
lib/main.dart             Código completo do aplicativo
assets/products.json      Inventário externo de produtos
pubspec.yaml              Configuração do projeto Flutter
```

## Observação pedagógica

Este app usa dados em memória e JSON local para facilitar o aprendizado. Em um projeto profissional, o inventário, o carrinho e os pedidos poderiam ser integrados a uma API ou banco de dados, como Supabase/PostgreSQL.
