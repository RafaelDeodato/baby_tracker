# App — Flutter (pais)

> Ver `../CLAUDE.md` para o panorama do monorepo. Ver
> `../docs/baby-tracker-style-guide.md` para identidade visual completa
> (cores, tipografia, componentes) — este arquivo não duplica aquele
> conteúdo, só resume as convenções de código.

## Stack

Flutter, sem gerenciador de estado ainda (telas atuais são simples o
suficiente para `StatefulWidget` puro). `http` para chamadas de API,
`shared_preferences` para persistência local, `google_fonts` para
tipografia.

Ao introduzir gerenciamento de estado (provavelmente necessário a partir
da tela de status/histórico), registrar a escolha e o porquê em
`docs/baby-tracker-mvp.md` ou aqui antes de implementar — não decidir
silenciosamente em código.

## Estrutura

```text
lib/
├── main.dart
├── theme/       # AppColors, AppTypography, AppSpacing, AppShapes, AppTheme
├── services/    # ApiService (chamadas HTTP), StorageService (tokens locais)
└── screens/     # uma pasta por fluxo (auth/, babies/, ...)
```

## Tema

Todo valor visual (cor, espaçamento, raio, fonte) vem de `theme/`. **Nunca**
hardcodear hex, padding numérico ou `TextStyle` solto numa tela — sempre
`AppColors.x`, `AppSpacing.spN`, `AppShapes.radiusX`, `AppTypography.x`.
Ver `docs/baby-tracker-style-guide.md` para o significado de cada token e
para componentes ainda não implementados (botões, cards de evento,
estados vazios).

Regra de ouro do style guide: cores pastel são fundo, nunca texto.

## `ApiService`

* Métodos estáticos, um por endpoint, seguindo o padrão já usado
  (`login`, `getBabies`, `startFeeding`, ...). Retornam
  `{'status': int, 'data': dynamic}` — quem chama decide como tratar erro.
* Refresh de token é automático e transparente dentro de `_request`: um
  `401` dispara `_refreshToken()` e reexecuta a chamada original uma vez
  (`isRetry`). Não duplicar essa lógica em outros lugares.
* `_baseUrl` é configurável via `--dart-define=API_BASE_URL=...`, lido
  com `String.fromEnvironment` — escolhido em vez de arquivo de config
  por ambiente porque não exige nenhuma dependência nova nem lógica de
  carregar/parsear arquivo em runtime, e o projeto já não usa nenhum
  gerenciador de estado/injeção de config. Sem o define, cai no IP local
  de dev (hardcoded como `defaultValue`), então `flutter run` sem flags
  extras continua funcionando igual hoje. Pra build de produção:
  `flutter build <alvo> --dart-define=API_BASE_URL=https://SEU-SERVICO.run.app/api/v1`
  (URL real do Cloud Run ainda não existe — preencher quando o deploy do
  backend acontecer).

## `StorageService`

Único responsável por persistir tokens (`shared_preferences`). Nenhuma
outra classe deve chamar `SharedPreferences` diretamente.

## Convenções de tela

* Uma pasta por fluxo em `screens/` (ex: `auth/`, `babies/`).
* Tela não fala com `http` ou `shared_preferences` diretamente — sempre
  via `ApiService`/`StorageService`.
* Textos e mensagens de erro em português, consistente com o restante do
  produto.

## Comandos

```bash
flutter pub get
flutter run
flutter analyze
```