# V2 — Compartilhamento de bebês e segurança

## Objetivo

Permitir que mais de um usuário acesse o mesmo bebê (ex: os dois pais,
cada um com sua própria conta), via convite por `@username` e aceite
através de uma caixa de notificações interna ao app — sem depender de
e-mail. Junto, três melhorias de segurança que não exigem infraestrutura
nova.

## `@username`

* Novo campo em `users`: `username`, `string`, **único**, obrigatório no
  cadastro.
* Armazenado **sem** o `@` (só a string). O `@` é só um prefixo visual na
  interface — não faz parte do dado nem da validação.
* Busca por `username` é **sempre por correspondência exata**. Não expor
  endpoint de busca parcial/prefixo — isso vira um mini-diretório de
  pessoas, o que não é desejado numa feature de convite familiar.
* Se o `username` buscado não existir, retornar erro genérico ("usuário
  não encontrado"), sem diferenciar de outros motivos de falha — mesma
  lógica de não vazar existência que já vale pra outros recursos no
  backend.

## Modelo de dados

### `baby_users` (substitui o `user_id` direto em `babies`)

```sql
id            SERIAL PRIMARY KEY
baby_id       INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
role          VARCHAR NOT NULL DEFAULT 'guest'   -- 'owner' | 'guest'
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()

UNIQUE (baby_id, user_id)
```

> Só existe uma linha aqui quando o acesso já está **ativo**. Convite
> pendente/recusado **não** vive nesta tabela — fica isolado em
> `baby_invites` (ver abaixo). Isso é deliberado: toda checagem de
> autorização em bebê/mamada/soneca/fralda passa a ser simplesmente "existe
> uma linha em `baby_users` para este `user_id` e `baby_id`?", sem
> precisar filtrar por status em lugar nenhum — elimina a classe de erro
> "esqueci de filtrar por status aceito nesse endpoint".

Migration: para bebês já existentes, criar uma linha em `baby_users` com
`role = 'owner'` a partir do `user_id` atual de cada `Baby`, depois
remover a coluna `user_id` de `babies`.

### `baby_invites`

```sql
id              SERIAL PRIMARY KEY
baby_id         INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
invited_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
invited_by_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
status          VARCHAR NOT NULL DEFAULT 'pending'  -- 'pending' | 'accepted' | 'declined'
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
resolved_at     TIMESTAMPTZ NULL
```

* Convite exige que o usuário convidado **já tenha conta** — se o
  `username` não existir, a API retorna erro pedindo pra essa pessoa se
  cadastrar primeiro. Convidar alguém que ainda não tem conta (convite
  "pendente" vinculado só a um e-mail) fica fora de escopo da V2.
* Não permitir criar um novo convite para o mesmo `baby_id` +
  `invited_user_id` se já existir um com `status = pending` (evitar
  espamar convite repetido).

### `notifications`

Tabela genérica — não específica de convite. Motivada pelo convite, mas
desenhada para ser reaproveitada por qualquer aviso futuro (ex: lembrete
de medicamento na V3.3).

```sql
id              SERIAL PRIMARY KEY
user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
type            VARCHAR NOT NULL   -- 'baby_invite_received' | 'baby_invite_accepted' | 'baby_invite_declined'
reference_id    INTEGER NULL       -- id do registro que originou (ex: baby_invites.id)
read            BOOLEAN NOT NULL DEFAULT false
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

Tipos usados nesta versão:

* `baby_invite_received` — criada para o convidado quando um convite é
  enviado
* `baby_invite_accepted` / `baby_invite_declined` — criada para quem
  enviou o convite, quando o convidado responde

**Não** criar notificação para "convite enviado com sucesso" — quem envia
já está com o app aberto no momento do envio, isso é feedback imediato na
própria tela (snackbar), não precisa de infraestrutura assíncrona.

**Não** transformar o alerta de "evento incompleto" (V3, borda + ícone no
Histórico) em notificação — continua um estado passivo, descoberto ao
abrir a tela, sem entrada na tabela de notificações. Isso não muda nesta
versão.

## API

### Username

```text
GET  /users/search?username={exato}   → dados públicos mínimos do usuário (id, name, username), ou 404 genérico
```

### Convites

```text
POST   /babies/{id}/invites            body: { username }
        → cria baby_invites (pending) + notification (baby_invite_received) para o convidado
        → 404 genérico se username não existir
        → 409 se já existe convite pending para esse baby+usuário
        → 403/404 se quem chama não for owner do bebê (só owner convida)

GET    /invites                        → lista convites pendentes recebidos pelo usuário autenticado

POST   /invites/{id}/accept            → cria linha em baby_users (role='guest'), marca invite como accepted,
                                          cria notification (baby_invite_accepted) para quem convidou

POST   /invites/{id}/decline           → marca invite como declined,
                                          cria notification (baby_invite_declined) para quem convidou
```

### Notificações

```text
GET    /notifications                  → lista notificações do usuário autenticado, mais recentes primeiro
POST   /notifications/{id}/read        → marca como lida
```

### Autorização (reescrever em todos os endpoints existentes)

Toda checagem hoje baseada em `baby.user_id == current_user_id` passa a
ser: existe uma linha em `baby_users` para `baby_id` + `current_user_id`?
Isso vale para `babies`, `feedings`, `naps`, `diapers` — todos os
endpoints que hoje verificam propriedade do bebê.

* Ações de "dono" (editar nome/data de nascimento do bebê, excluir bebê,
  enviar convite) exigem `role = 'owner'`.
* Ações de rotina (registrar/editar/excluir mamada, soneca, fralda) estão
  disponíveis para qualquer papel (`owner` ou `guest`) — não há
  granularidade de permissão nesta versão.

## Segurança (sem infraestrutura nova)

### Complexidade mínima de senha

No `register`: mínimo 8 caracteres, exigir ao menos uma letra e um
número. Validar no service, retornar `422` com mensagem clara se não
atender.

### Blocklist de token persistida

Hoje `token_blocklist` é um `set()` em memória no processo Python — se
perde a cada reinício de instância. Como o deploy é Cloud Run (escala a
zero, reinicia instâncias com frequência), um token revogado no logout
pode voltar a funcionar depois de um reinício. Substituir por uma tabela:

```sql
revoked_tokens
  jti           VARCHAR PRIMARY KEY
  revoked_at    TIMESTAMPTZ NOT NULL DEFAULT now()
```

`logout` grava o `jti` aqui em vez de adicionar a um `set()`; a checagem
do JWT (`token_in_blocklist_loader` do Flask-JWT-Extended) consulta a
tabela em vez da variável em memória.

### Rate limiting em autenticação

Adicionar `Flask-Limiter` (nova dependência, mas sem infraestrutura
externa — funciona em memória por instância, suficiente para este
estágio). Limitar `POST /auth/login` e `POST /auth/register` a, por
exemplo, 5 tentativas por minuto por IP. Retornar `429` ao exceder.

## Fora de escopo (decisão explícita, não esquecimento)

* **Verificação de e-mail por token** — fica para quando o cadastro for
  aberto além da família. Exige e-mail transacional de verdade (ex:
  Resend) — SMTP direto não é confiável em plataformas serverless como
  Cloud Run, então não vale montar essa infraestrutura antes de precisar
  dela de fato.
* **Push notification** (avisar com o app fechado) — o inbox desta
  versão só aparece quando o app está aberto e consultando a API. Push
  real (Firebase Cloud Messaging) é infraestrutura maior, fora de escopo
  aqui.
* **Convidar alguém sem conta** — convite exige `username` já existente.
* **Granularidade de permissão** (visualizar vs. editar) — todo `guest`
  tem acesso total de leitura/escrita nesta versão.