# Baby Tracker - Style Guide / Identidade Visual

> Documento de identidade visual do app Flutter. Assim como a spec técnica e o roadmap, serve de fonte de verdade para desenvolvimento assistido por IA: **toda decisão visual no código deve referenciar os tokens definidos aqui**. Nada de cores ou raios "soltos" hardcoded nos widgets.

---

# Personalidade da Marca

O app deve transmitir: **acolhimento, leveza, segurança e carinho**.

É usado por pais exaustos, muitas vezes de madrugada, com uma mão só. A identidade infantil não é só estética — é funcional: tons suaves cansam menos a vista, formas arredondadas reduzem a sensação de "ferramenta fria", e a ausência de cores agressivas (vermelho de alerta) evita ansiedade num contexto já estressante.

**Palavras-guia:** suave · arredondado · quentinho · simples · confiável
**O que evitar:** cores saturadas/vibrantes, cantos retos, vermelho puro, preto puro, visual "corporativo", densidade de informação.

---

# Paleta de Cores

## Princípio

Toda a interface usa **tons pastéis sobre fundo creme**. Cada cor funcional tem três variações:

* **Surface** — o tom pastel claro, usado como fundo do componente
* **Border/Ink** — um tom mais escuro da mesma família, usado em bordas e ícones
* **Text** — tom escuro o suficiente para contraste de leitura

> ⚠️ **Regra de acessibilidade (inegociável):** pastel sobre pastel não tem contraste de leitura. Texto **nunca** usa a cor pastel — sempre usa o tom Text da família ou o Ink neutro. Alvo: contraste mínimo WCAG AA (4.5:1 para texto normal).

## Cores Base

| Token | Hex | Uso |
|---|---|---|
| `background` | `#FFFBF2` | Fundo geral do app (creme quase branco) |
| `surface` | `#FFFFFF` | Cards e superfícies elevadas |
| `ink` | `#5C5346` | Texto principal (marrom-acinzentado quente — substitui o preto) |
| `inkSoft` | `#8C8275` | Texto secundário, placeholders, legendas |
| `outline` | `#E8DFD0` | Divisores e bordas neutras sutis |

## Cor Primária — Amarelo Manteiga

| Token | Hex | Uso |
|---|---|---|
| `primarySurface` | `#FFEFC2` | Fundo de botões primários, destaques |
| `primaryBorder` | `#E8C76B` | Borda dos componentes primários |
| `primaryText` | `#7A6320` | Texto/ícone sobre o amarelo |

## Cores Funcionais (substituem as cores "de sistema")

| Função | Em apps comuns | Aqui | Surface | Border | Text |
|---|---|---|---|---|---|
| Destrutiva (excluir, cancelar) | Vermelho | **Rosa pastel** | `#FFD9E1` | `#E58CA0` | `#A14D63` |
| Sucesso (confirmar, salvar) | Verde forte | **Verde menta** | `#D4EDD9` | `#86C295` | `#3F7A4F` |
| Informação (links, status neutro) | Azul forte | **Azul céu** | `#D3E7F7` | `#85B6DC` | `#3D6A92` |
| Atenção (avisos leves) | Laranja/amarelo | **Pêssego** | `#FFE0CC` | `#EBA877` | `#9C5A2B` |

## Cores Semânticas de Eventos

Cada tipo de registro tem sua cor própria, usada consistentemente em ícones, cards e gráficos futuros. Nenhuma cor de evento reaproveita uma cor funcional ou a cor primária — são famílias exclusivas, pra manter reconhecimento visual rápido sem ambiguidade de significado.

| Evento | Família | Surface | Border | Text |
|---|---|---|---|---|
| 🍼 Mamada | Cinza-azulado ("leite") | `#E9EDEF` | `#A9B4B9` | `#47545A` |
| 😴 Soneca | Lilás lavanda | `#E6DCF5` | `#B49BD8` | `#6B4F94` |
| 🧷 Fralda | Marrom-café | `#DCC7B0` | `#A9825F` | `#5C3E23` |
| (futuro) Saúde/medicação | Pêssego | `#FFE0CC` | `#EBA877` | `#9C5A2B` |

> **Mamada** usava o amarelo manteiga (cor primária do app) até esta revisão — reaproveitar a cor primária numa categoria de evento fazia ela se misturar com botões e destaques em geral, sem identidade própria. O cinza-azulado foi escolhido por ser o único tom **frio** da paleta: contra um app inteiro construído em tons quentes (creme, amarelo, marrom), ele se destaca em vez de se camuflar — e reforça a associação com leite.
>
> **Fralda** usava o mesmo verde menta da cor de Sucesso até esta revisão — reaproveitar uma cor funcional (confirmar/salvar) numa categoria de evento diluía o significado dela (ex: card de fralda verde ao lado de um snackbar "Salvo com sucesso!", também verde). O marrom-café foi escolhido deliberadamente mais neutro/acinzentado que o Pêssego (que é mais alaranjado/vivo e já está reservado para Atenção e Saúde), evitando que as duas fiquem parecidas.
>
> O lilás da soneca não muda — remete a noite/calma sem usar azul escuro, e já estava validado.

---

# Tipografia

## Fontes

| Papel | Fonte | Justificativa |
|---|---|---|
| **Funcional** (corpo, botões, formulários, labels) | **Nunito** | Sem serifa, terminais arredondados, excelente legibilidade em tamanhos pequenos. Transmite suavidade sem perder seriedade. |
| **Display** (títulos, números grandes, destaques) | **Fredoka** | Geométrica e gordinha, com curvas generosas — par natural da Nunito. Em pesos Medium/SemiBold dá personalidade infantil aos títulos sem virar "fonte de festa". |

> Alternativas avaliadas para display, caso a Fredoka não agrade na prática: **Baloo 2** (mais gordinha ainda, ótima para números grandes) e **Quicksand** (mais discreta, se quiser suavizar a personalidade). Todas no Google Fonts, disponíveis via package `google_fonts` no Flutter.

## Escala Tipográfica

| Token | Fonte | Peso | Tamanho | Uso |
|---|---|---|---|---|
| `displayLarge` | Fredoka | SemiBold | 32 | Números-herói (ex: tempo desde a última mamada) |
| `headlineMedium` | Fredoka | Medium | 24 | Título de telas |
| `titleMedium` | Fredoka | Medium | 18 | Título de cards e seções |
| `bodyLarge` | Nunito | Regular | 16 | Texto padrão |
| `bodyMedium` | Nunito | Regular | 14 | Texto secundário |
| `labelLarge` | Nunito | Bold | 16 | Texto de botões |
| `labelSmall` | Nunito | SemiBold | 12 | Legendas, timestamps |

Regras:

* Texto de corpo nunca abaixo de 14 — o público usa o app cansado e no escuro.
* Números de tempo/duração são sempre Fredoka — são a informação-herói do app.
* Evitar caixa alta em textos longos; permitida apenas em `labelSmall`.

---

# Formas e Bordas

A assinatura visual do app: **tudo arredondado, com borda visível mais grossa que o habitual**.

## Raios de Borda

| Token | Valor | Uso |
|---|---|---|
| `radiusSmall` | 12 | Chips, tags, badges |
| `radiusMedium` | 16 | Botões, inputs |
| `radiusLarge` | 24 | Cards, bottom sheets, dialogs |
| `radiusFull` | 999 (pill) | Botões de ação flutuante, toggles, avatar |

## Espessura de Borda

| Token | Valor | Uso |
|---|---|---|
| `borderRegular` | 2.0 | Padrão para botões, inputs e cards |
| `borderEmphasis` | 2.5 | Estado focado/ativo de inputs e seleções |

Regras:

* A borda usa sempre o tom **Border** da família de cor do componente (nunca preto, nunca cinza frio).
* A borda grossa **substitui a sombra** como recurso de delimitação: sombras são mínimas (`elevation` 0 a 1) ou inexistentes. O visual é "flat fofo", não "material elevado".
* Cantos retos não existem no app. Nenhuma exceção.

---

# Componentes

## Botões

| Tipo | Fundo | Borda | Texto | Uso |
|---|---|---|---|---|
| Primário | `primarySurface` | 2px `primaryBorder` | `primaryText` | Ação principal da tela |
| Secundário | transparente | 2px `primaryBorder` | `primaryText` | Ações alternativas |
| Destrutivo | `#FFD9E1` | 2px `#E58CA0` | `#A14D63` | Excluir, cancelar evento |
| Sucesso | `#D4EDD9` | 2px `#86C295` | `#3F7A4F` | Finalizar/confirmar |

* Altura mínima: **52px** (alvo de toque generoso — uso com uma mão segurando bebê).
* Raio: `radiusMedium` (16) ou `radiusFull` para os botões-herói de iniciar/parar evento.
* Texto: `labelLarge` (Nunito Bold 16).
* Estado pressionado: escurecer o surface ~8% (sem ripple cinza do Material).
* **Exceção — botões de iniciar evento lado a lado:** quando a tela oferece ações de iniciar mais de um tipo de evento ao mesmo tempo (ex: "Iniciar mamada", "Iniciar soneca", "Registrar fralda" na tela de status), cada botão usa a cor semântica do próprio evento (cinza-azulado para mamada, lilás para soneca, marrom-café para fralda — ver Cores Semânticas de Eventos) em vez do Primário genérico. Objetivo: diferenciar visualmente as ações à primeira vista, já que o texto sozinho compete por atenção num app usado de madrugada. Quando existe só uma ação de iniciar na tela, usar Primário normalmente.

## Inputs / Formulários

* Fundo `surface` (branco), borda 2px `outline`; ao focar, borda 2.5px `primaryBorder`.
* Raio `radiusMedium`, padding interno generoso (16 horizontal, 14 vertical).
* Label acima do campo em `labelSmall`, erro em rosa (`#A14D63`) — nunca vermelho.

## Cards de Evento

* Fundo `surface`, borda 2px na cor da família do evento (mamada = cinza-azulado, soneca = lilás, fralda = marrom-café).
* Raio `radiusLarge` (24).
* Ícone do evento dentro de um círculo com o Surface da família.
* Duração em Fredoka, metadados em Nunito `bodyMedium` com `inkSoft`.

## Estados Vazios e Feedback

* Estados vazios sempre com ilustração ou ícone grande + frase acolhedora ("Nenhuma soneca ainda hoje 💤") — nunca tela branca seca.
* Toasts/snackbars seguem as famílias funcionais (sucesso menta, erro rosa).

---

# Iconografia

* Estilo: **outline arredondado, traço 2px** — coerente com as bordas dos componentes.
* Sugestões de conjuntos compatíveis: Phosphor Icons (peso *regular/bold*) ou Lucide (que já tem traço arredondado).
* Ícones funcionais sempre na cor **Ink** ou no **Text** da família do componente; nunca pastel puro (contraste).
* Emojis são permitidos como reforço afetivo em estados vazios e títulos informais — com moderação.

---

# Espaçamento

Escala base de 4px:

| Token | Valor |
|---|---|
| `space2` | 8 |
| `space3` | 12 |
| `space4` | 16 (padding padrão de tela e cards) |
| `space6` | 24 (entre seções) |
| `space8` | 32 (respiros grandes) |

Princípio: **respiro generoso**. Telas com poucos elementos grandes, nunca densas.

---

# Implementação no Flutter

## Pacotes

```yaml
dependencies:
  google_fonts: ^6.0.0   # Nunito + Fredoka
```

## Estrutura sugerida

```text
lib/
└── theme/
    ├── app_colors.dart      # todos os tokens de cor deste guia
    ├── app_typography.dart  # escala tipográfica
    ├── app_shapes.dart      # raios e espessuras de borda
    ├── app_spacing.dart     # escala de espaçamento
    └── app_theme.dart       # ThemeData montando tudo
```

## Tokens de cor de evento (adicionar em `app_colors.dart`)

```dart
// Mamada — cinza-azulado ("leite")
static const feedS = Color(0xFFE9EDEF);
static const feedB = Color(0xFFA9B4B9);
static const feedT = Color(0xFF47545A);

// Fralda — marrom-café
static const diaperS = Color(0xFFDCC7B0);
static const diaperB = Color(0xFFA9825F);
static const diaperT = Color(0xFF5C3E23);
```

> Segue a mesma convenção já usada em `napS`/`napB`/`napT`. `primaryS`/`primaryB`/`primaryT` deixam de ser usados como cor de mamada em qualquer widget — a mamada passa a referenciar exclusivamente `feedS`/`feedB`/`feedT`.

## Esqueleto do tema

```dart
// app_theme.dart (resumo ilustrativo)
final theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background, // #FFFBF2
  colorScheme: ColorScheme.light(
    primary: AppColors.primarySurface,
    onPrimary: AppColors.primaryText,
    error: AppColors.dangerSurface,      // rosa pastel
    onError: AppColors.dangerText,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
  ),
  textTheme: AppTypography.textTheme,    // Nunito + Fredoka via google_fonts
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
        side: BorderSide(color: AppColors.primaryBorder, width: 2),
      ),
    ),
  ),
);
```

## Regras para o desenvolvimento (Claude Code)

* Nenhuma cor, raio ou espaçamento hardcoded em widget — sempre via tokens do `theme/`.
* Novo componente visual → primeiro verificar se este guia já define o padrão; se não definir, propor a adição **aqui** antes de implementar.
* Qualquer texto sobre fundo pastel deve usar o token Text da família correspondente (verificação de contraste é parte do code review).

---

# Fora de Escopo (por enquanto)

* **Dark mode** — relevante para o público (uso noturno!), mas fica para depois do MVP. A estrutura de tokens já deixa a migração simples: basta criar um segundo mapa de cores.
* **Ilustrações customizadas** — estados vazios usam ícones grandes no MVP; ilustrações próprias entram com a maturidade do produto.
* **Animações/microinterações** — definir linguagem de movimento em versão futura deste guia.

---

# Resumo Rápido (cola para o dia a dia)

```text
Fundo:        creme #FFFBF2          Texto: marrom quente #5C5346
Primária:     amarelo manteiga       Destrutivo: rosa pastel (nunca vermelho)
Sucesso:      verde menta            Info: azul céu
Mamada:       cinza-azulado          Soneca: lilás          Fralda: marrom-café
Fontes:       Fredoka (títulos/números) + Nunito (todo o resto)
Bordas:       2px visíveis, na cor da família — sem sombras
Raios:        12 / 16 / 24 / pill — canto reto não existe
Toque:        botões ≥ 52px de altura
Regra de ouro: pastel é fundo, nunca texto.
```