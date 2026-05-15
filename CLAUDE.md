# Regras do projeto GAMA (Flutter)

## Design de referência

O design foi criado no Claude Design — link fetchável:

```
https://api.anthropic.com/v1/design/h/ikdyUsV_WCEzgd67TPaawA?open_file=index.html
```

**Direção escolhida: Garage (Direction A)** — industrial moderno, sidebar escura, acento âmbar.

### Tokens e tipografia

Todas as cores estão em `lib/core/theme/app_theme.dart` → `AppColors`. **Nunca use hex hardcoded** — sempre `AppColors.ink`, `AppColors.accent`, `AppColors.danger`, etc.

- **Mono:** use `fontFamily: 'JetBrains Mono'` em placas de veículo, códigos de produto e números técnicos
- **Border-radius padrão:** 10px
- **Sidebar width:** 232px

### Telas mockadas no design
- Login (desktop) · Selecionar oficina (desktop + mobile)
- Dashboard operacional (desktop + mobile)
- Ordens de Serviço: Lista com filtros / Detalhe / Nova OS (desktop + mobile)
- Estoque: lista com KPIs e alertas críticos
- Pagamento (desktop + mobile)
- Dashboard Gerencial (dono, multi-oficina)
- Receitas (financeiro do dono)

> **Nota:** O `app_theme.dart` já está com o Garage completo. Todos os tokens acima estão mapeados em `AppColors`. Sempre use `AppColors.xxx` — nunca cores hardcoded.



## Componentes e widgets

- **Sempre reutilize componentes existentes** antes de criar novos. Verifique `lib/shared/widgets/` primeiro.
- Se não existir um componente adequado, **pergunte antes de criar** — talvez o usuário prefira adaptar um existente ou criar do zero de uma forma específica.

## Navegação

- Use `context.go` para navegar entre rotas dentro do `ShellRoute` (mantém o sidebar).
- Use `Navigator.push` apenas para modais/bottom sheets dentro da mesma tela.
- Nunca use `context.push` para sub-telas — causa bleed do TopBarSlot da tela pai.

## Plataforma

O app roda em **mobile e desktop**, mas mobile **não é uma cópia responsiva do desktop** — tem UX própria. Use `MediaQuery.of(context).size.width >= 800` para diferenciar.

**Regra geral: se o layout mobile de uma tela nova não estiver especificado, pergunte antes de implementar.**

---

### Navegação / Menu

| | Desktop | Mobile |
|---|---|---|
| Componente | `GamaSidebar` — sidebar fixa 232px à esquerda | Bottom navigation bar com 5 itens |
| Itens | Dashboard, Ordens, Clientes, Veículos, Estoque, Equipe, Relatórios | Painel, OS, Clientes, Estoque, Mais |
| Item ativo | Fundo âmbar (`AppColors.accent`) na sidebar | Ícone + label em âmbar |

---

### Header / Topbar

| | Desktop | Mobile |
|---|---|---|
| Componente | `GamaTopBar` — barra horizontal com título + busca + ações | Header escuro (`AppColors.sidebarBg`) com saudação personalizada |
| Conteúdo | Título da tela, barra de busca (quando houver), ações à direita | Nome do usuário, oficina ativa, sino de notificação, KPIs resumidos da tela |
| Sub-telas | Título muda via `TopBarSlot` (back button + título + ações) | A definir caso a caso |

---

### Telas com layout mobile diferente (já definido)

- **Nova OS** — desktop: formulário longo com 5 seções + resumo flutuante à direita. Mobile: stepper passo a passo (Cliente → Serviços → Peças → Resumo) com barra inferior de total + botão "Próximo".
- Demais telas mobile: **a definir** — não implemente sem consultar.

## Layout e header

- **Nunca crie um `Scaffold` ou `AppBar` próprio** dentro de uma sub-tela. Todas as telas vivem dentro do `GamaScaffold` (via ShellRoute).
- Para injetar título, botão voltar ou ações no `GamaTopBar`, use:
  - `TopBarSlotMixin` — em `ConsumerStatefulWidget`
  - `TopBarSlotProvider` — em `ConsumerWidget` (stateless)
- O botão voltar deve usar `BackButton(onPressed: () => context.go('/rota-pai'))`.

## Processos

- Nunca use `taskkill` ou qualquer comando para matar processos. O usuário para o app manualmente.
