# V2 — Compartilhamento de bebês e segurança

## Objetivo

Permitir que mais de um usuário acesse o mesmo bebê (ex: os dois pais,
cada um com sua própria conta, mais outras pessoas de confiança), via
convite por `@username` e aceite através de uma caixa de notificações
interna ao app — sem depender de e-mail. Junto, três melhorias de
segurança que não exigem infraestrutura nova.

## `@username`

* Novo campo em `users`: `username`, `string`, **único**, obrigatório no
  cadastro.
* Armazenado **sem** o `@` (só a string). O `@` é só um prefixo visual na
  interface — não faz parte do dado nem da validação.
* Busca por `username` é **sempre por correspondência exata**. Não expor
  endpoint de busca parcial/prefixo — isso vira um mini-diretório de
  pessoas, o que não é desejado numa feature de convite familiar.
* Se o `username` buscado não existir, retornar erro genérico ("usuário
  não encontrado"), sem diferenciar de outros motivos de falha.

## Cadastro sem verificação de e-mail (decisão desta versão)

* Login/identidade giram inteiramente em torno de `username` + senha —
  **sem verificação nenhuma** por enquanto (nem e-mail, nem telefone).
  Adequado para a fase de validação com poucas famílias (você + esposa,
  depois até ~10 famílias reais).
* Manter um campo `email` em `users`, **opcional e não verificado** —
  só armazenado, sem uso funcional ainda. Motivo: evitar precisar
  contatar cada família manualmente pra coletar esse dado depois, quando
  a verificação de fato for implementada (ver "Fora de escopo").
* Recuperação de senha, nesta fase, é manual (reset direto no banco a
  pedido do usuário) — aceitável no volume de usuários desta versão.

## Níveis de permissão

Três níveis, aplicados por bebê (cada convite define o nível daquela
pessoa para aquele bebê específico):

| Nível | Editar rotina (mamada/soneca/fralda) | Editar/excluir bebê | Convidar/remover pessoas |
|---|---|---|---|
| `adm` | ✅ | ✅ | ✅ |
| `tutor` | ✅ | ❌ | ❌ |
| `visualizador` | ❌ | ❌ | ❌ |

* **Sem limite de quantos `adm` um bebê pode ter.** "Convidar pai/mãe" é
  só um atalho de UX que pré-seleciona `adm` e sugere o título "Pai" ou
  "Mãe" (editável) — não é um nível de permissão à parte.
* Qualquer `adm` pode convidar, remover, ou promover/rebaixar o nível de
  qualquer outra pessoa (inclusive outro `adm`) — não existe um "dono
  original" com poder que os demais `adm` não têm.

## Título livre por convite

Além do nível de permissão, cada convite tem um campo de texto livre
opcional — `titulo` (ex: "Tio", "Vovó", "Dindo", "Amiga da família") —
puramente de exibição, sem efeito nenhum na permissão. Quem convida
digita o que fizer sentido para aquela pessoa; sem lista fixa de opções.

## Modelo de dados

### `baby_users` (substitui o `user_id` direto em `babies`)

```sql
id            SERIAL PRIMARY KEY
baby_id       INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
role          VARCHAR NOT NULL DEFAULT 'tutor'   -- 'adm' | 'tutor' | 'visualizador'
titulo        VARCHAR NULL                        -- texto livre, opcional
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()

UNIQUE (baby_id, user_id)
```

> Compartilhamento continua **por bebê**, não por família — uma entidade
> "Família" foi cogitada e descartada nesta versão: casos reais (guarda
> compartilhada, meio-irmãos, cuidadora que atende famílias sem
> parentesco) não se encaixam bem numa unidade rígida de "família", e
> modelar isso corretamente é mais custoso do que o benefício justifica
> agora. Só existe uma linha aqui quando o acesso já está **ativo** —
> convite pendente/recusado vive isolado em `baby_invites`, não aqui.
> Isso mantém toda checagem de autorização simples: "existe uma linha em
> `baby_users` para este `user_id` e `baby_id`?", sem filtrar por status
> em lugar nenhum.

Migration: para bebês já existentes, criar uma linha em `baby_users` com
`role = 'adm'` a partir do `user_id` atual de cada `Baby`, depois remover
a coluna `user_id` de `babies`.

### `baby_invites`

```sql
id              SERIAL PRIMARY KEY
baby_id         INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
invited_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
invited_by_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
role            VARCHAR NOT NULL            -- 'adm' | 'tutor' | 'visualizador' — nível oferecido no convite
titulo          VARCHAR NULL                 -- copiado para baby_users ao aceitar
status          VARCHAR NOT NULL DEFAULT 'pending'  -- 'pending' | 'accepted' | 'declined'
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
resolved_at     TIMESTAMPTZ NULL
```

* Convite exige que o usuário convidado **já tenha conta** — se o
  `username` não existir, a API retorna erro pedindo pra essa pessoa se
  cadastrar primeiro.
* Não permitir criar um novo convite para o mesmo `baby_id` +
  `invited_user_id` se já existir um com `status = pending`.

### `notifications`

Tabela genérica — motivada pelo convite, mas reaproveitável por qualquer
aviso futuro (ex: lembrete de medicamento na V3.3).

```sql
id              SERIAL PRIMARY KEY
user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
type            VARCHAR NOT NULL   -- 'baby_invite_received' | 'baby_invite_accepted' | 'baby_invite_declined'
reference_id    INTEGER NULL       -- id do registro que originou (ex: baby_invites.id)
read            BOOLEAN NOT NULL DEFAULT false
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

* `baby_invite_received` — criada para o convidado quando um convite é
  enviado
* `baby_invite_accepted` / `baby_invite_declined` — criada para quem
  enviou o convite, quando o convidado responde
* **Não** criar notificação para "convite enviado com sucesso" — feedback
  imediato na própria tela (snackbar), não precisa de notificação.
* **Não** transformar o alerta de "evento incompleto" (V3) em
  notificação — continua passivo, descoberto ao abrir o Histórico.

## API

### Username

```text
GET  /users/search?username={exato}   → dados públicos mínimos (id, name, username), ou 404 genérico
```

### Convites

```text
POST   /babies/{id}/invites            body: { username, role, titulo? }
        → 404 genérico se username não existir
        → 422 se role inválido
        → 409 se já existe convite pending para esse baby+usuário
        → 403/404 se quem chama não for 'adm' do bebê (só adm convida)

GET    /invites                        → lista convites pendentes recebidos pelo usuário autenticado

POST   /invites/{id}/accept            → cria linha em baby_users com o role/titulo do convite,
                                          marca invite como accepted,
                                          cria notification (baby_invite_accepted) para quem convidou

POST   /invites/{id}/decline           → marca invite como declined,
                                          cria notification (baby_invite_declined) para quem convidou
```

### Gerenciar acesso (só `adm`)

```text
GET    /babies/{id}/users              → lista quem tem acesso ao bebê (nome, username, role, titulo)
PUT    /babies/{id}/users/{user_id}    body: { role?, titulo? }   → alterar nível/título de alguém
DELETE /babies/{id}/users/{user_id}    → remover acesso de alguém
```

### Notificações

```text
GET    /notifications                  → lista notificações do usuário autenticado, mais recentes primeiro
POST   /notifications/{id}/read        → marca como lida
```

### Autorização (reescrever em todos os endpoints existentes)

Toda checagem hoje baseada em `baby.user_id == current_user_id` passa a
ser: existe uma linha em `baby_users` para `baby_id` + `current_user_id`?
Isso vale para `babies`, `feedings`, `naps`, `diapers`.

* `adm`: acesso total, incluindo editar/excluir bebê e gerenciar acessos.
* `tutor`: pode registrar/editar/excluir mamada, soneca e fralda; não
  pode editar/excluir o bebê nem gerenciar quem tem acesso.
* `visualizador`: só leitura em tudo.

## Segurança (sem infraestrutura nova) ✅ *implementado*

Os quatro itens abaixo foram implementados e testados (ver
`baby-tracker-auditoria-seguranca.md` para o levantamento que motivou
priorizá-los independentemente do resto da V2).

### Complexidade mínima de senha

`core/security.py::is_password_strong` — mínimo 8 caracteres, exige ao
menos uma letra e um número. Validado em `auth_service.register()`,
retorna `422` (`weak_password`) se não atender.

### Blocklist de token persistida

Tabela `revoked_tokens` (`jti` VARCHAR PRIMARY KEY, `revoked_at`
TIMESTAMPTZ) substituiu o `set()` em memória. `logout` grava o `jti` via
`revoked_token_repository`; o `token_in_blocklist_loader` do
Flask-JWT-Extended consulta a tabela em vez da variável em memória.

### Rate limiting em autenticação

`Flask-Limiter` em memória (`core/limiter.py`), limitando `POST
/auth/login` e `POST /auth/register` a 5 tentativas/minuto por IP,
retornando `429`. Resposta de erro do limiter sobrescrita para JSON
(`error`/`message`) — o formato HTML padrão da lib quebraria o contrato
de resposta que o resto da API segue.

### CORS restrito

`CORS_ALLOWED_ORIGINS` (variável de ambiente, lista separada por
vírgula) substitui `CORS(app)` sem restrição. Vazio por padrão — nega
CORS pra qualquer origem de navegador até existir um cliente web real
(o app mobile não é afetado por CORS).

## Ideias registradas para versões futuras (não implementar agora)

### Perfil profissional com título pré-definido

Ideia discutida e propositalmente adiada: um campo opcional
`titulo_profissional` no próprio perfil do usuário (ex: "Consultora de
Amamentação"). Quando uma família convidasse por `@username` alguém com
esse campo preenchido, a interface sugeriria automaticamente esse título
no convite (a família ainda poderia sobrescrever). Não implementar nesta
versão — nem sequer expor um nível de permissão "profissional" na tela de
convite ainda (usar só `adm`/`tutor`/`visualizador`). Revisitar quando a
V5+ (público profissional) estiver realmente sendo construída, e só se
nesse momento continuar fazendo sentido de negócio e técnico.

## Fora de escopo (decisão explícita, não esquecimento)

* **Verificação de e-mail/telefone por token** — fica para quando o
  cadastro for aberto além da família e das ~10 famílias de validação.
  Exige e-mail transacional de verdade (ex: Resend) ou SMS — SMTP direto
  não é confiável em plataformas serverless como Cloud Run.
* **Push notification** (avisar com o app fechado) — o inbox desta
  versão só aparece quando o app está aberto e consultando a API.
* **Convidar alguém sem conta** — convite exige `username` já existente.
* **Entidade Família** — descartada nesta versão (ver nota em
  `baby_users` acima).