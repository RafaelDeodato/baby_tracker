# Baby Tracker — Especificação Técnica (Backend)

## Visão Geral

Plataforma para auxiliar pais e responsáveis no acompanhamento da rotina de
bebês, começando por recém-nascidos.

O projeto tem dois objetivos principais:

1. Resolver um problema real do dia a dia de pais de recém-nascidos.
2. Servir como projeto de aprendizado e prática de desenvolvimento backend
   com Python.

> **Nota:** Este documento é a fonte de verdade técnica do projeto e serve
> como contexto para desenvolvimento assistido por IA (Claude Code).
> Qualquer decisão arquitetural nova deve ser registrada aqui antes de ser
> implementada. Para o roadmap de versões e funcionalidades futuras, ver
> `baby-tracker-roadmap.md` — este documento cobre apenas o que já foi
> especificado e/ou implementado (V1 fechado).

---

# Problema

Nos primeiros meses de vida do bebê, é comum os pais precisarem responder
perguntas como:

* Quando foi a última mamada?
* Quanto tempo o bebê mamou?
* Há quanto tempo ele está acordado?
* Quanto tempo durou a última soneca?

Essas informações normalmente ficam espalhadas em anotações, aplicativos
complexos ou simplesmente na memória dos responsáveis.

O objetivo é oferecer uma solução simples e intuitiva para registrar e
consultar esses eventos.

---

# Escopo Funcional (V1)

## Funcionalidade 1 - Controle de Mamadas

Permitir registrar:

* Horário de início da mamada
* Horário de término da mamada
* Duração calculada automaticamente (derivada de início/fim, não persistida)
* Edição de `started_at`/`ended_at` de um registro existente

Exibir:

* Histórico de mamadas
* Última mamada registrada
* Tempo decorrido desde a última mamada

---

## Funcionalidade 2 - Controle de Sonecas

Permitir registrar:

* Horário em que o bebê dormiu
* Horário em que acordou
* Duração calculada automaticamente (derivada de início/fim, não persistida)
* Edição de `started_at`/`ended_at` de um registro existente

Exibir:

* Histórico de sonecas
* Última soneca registrada
* Tempo acordado desde a última soneca

---

## Funcionalidade 3 - Status Atual do Bebê

Endpoint consolidado que responde, em uma única chamada, as perguntas
centrais do produto:

* Existe mamada em andamento? Desde quando?
* Existe soneca em andamento? Desde quando?
* Última mamada finalizada (horário e duração)
* Última soneca finalizada (horário e duração)
* Tempo acordado desde a última soneca

Este tende a ser o endpoint mais utilizado pelo frontend (tela inicial do
app).

---

# Requisitos Funcionais

## Usuários

* Cadastro de usuário
* Login
* Logout
* Renovação de sessão (refresh token)
* Consulta de dados do usuário autenticado (`/auth/me`)

## Bebês

* Cadastro de um ou mais bebês por usuário
* Nome do bebê
* Data de nascimento
* Editar dados do bebê
* Excluir bebê (remove histórico de eventos em cascata)

## Mamadas

* Iniciar mamada (aceita `started_at` retroativo, opcional)
* Finalizar mamada (aceita `ended_at` retroativo, opcional)
* Editar `started_at`/`ended_at` de um registro (em andamento ou finalizado)
* Listar histórico (por bebê)
* Excluir registro

## Sonecas

* Iniciar soneca (aceita `started_at` retroativo, opcional)
* Finalizar soneca (aceita `ended_at` retroativo, opcional)
* Editar `started_at`/`ended_at` de um registro (em andamento ou finalizado)
* Listar histórico (por bebê)
* Excluir registro

---

# Regras de Negócio

Estas regras concentram o comportamento dos eventos com estado
aberto/fechado e devem ser implementadas na camada de services.

## Eventos em andamento

* Um evento (mamada ou soneca) está **em andamento** quando possui
  `started_at` preenchido e `ended_at = NULL`.
* Um bebê pode ter **no máximo uma mamada em andamento** por vez.
* Um bebê pode ter **no máximo uma soneca em andamento** por vez.
* Mamada e soneca em andamento **não podem coexistir** para o mesmo bebê
  (bebê mamando não está dormindo). Se o usuário iniciar uma soneca com
  mamada aberta (ou vice-versa), a API retorna erro `409 Conflict` com
  mensagem clara — o usuário decide se finaliza ou exclui o evento aberto.

## Validações de início/fim

* `ended_at` deve ser maior que `started_at`. Caso contrário, erro `422`.
* Finalizar um evento já finalizado retorna `409 Conflict`.
* Finalizar um evento inexistente retorna `404`.
* Eventos com duração improvável (ex: mamada > 3h, soneca > 16h) são
  aceitos, mas a API retorna um campo `warning` na resposta — provavelmente
  o usuário esqueceu de finalizar. Não bloquear, apenas sinalizar.

## Edição de eventos já registrados

* `PUT /feedings/{id}` e `PUT /naps/{id}` reaplicam a mesma validação de
  `ended_at > started_at` do finish (`422` se violada).
* O novo horário não pode **sobrepor nenhum outro evento do mesmo bebê**,
  nas 4 combinações possíveis: mamada-mamada, mamada-soneca, soneca-soneca,
  soneca-mamada. Violação retorna `409 Conflict`. Evento em andamento (sem
  `ended_at`) é tratado como um intervalo aberto no futuro para efeito
  dessa checagem.
* **Não valida** sobreposição no momento de *iniciar* um evento novo além
  da checagem de "já existe algo em andamento" que já existia — só na
  edição, que é o único fluxo onde um horário arbitrário no passado pode
  ser introduzido.

## Duração

* A duração **não é persistida** no banco. É um dado derivado, calculado
  no service (ou como property no model) a partir de `started_at` e
  `ended_at`.
* Motivo: evita inconsistência caso `ended_at` seja editado futuramente.
  Se houver necessidade de performance em relatórios, avaliar
  materialização nesse momento.

## Autorização

* Todo acesso a bebês e eventos deve validar que o recurso pertence ao
  usuário autenticado (via `user_id` do token JWT).
* Acesso a recurso de outro usuário retorna `404` (não `403`, para não
  vazar existência do recurso).

## Datas e Timezone

* **Todos os timestamps são armazenados em UTC**, usando
  `TIMESTAMP WITH TIME ZONE` (timestamptz) no PostgreSQL.
* A API recebe e retorna datas em ISO 8601 com offset (ex:
  `2026-06-09T03:15:00-03:00`).
* Conversão para o fuso do usuário é responsabilidade do frontend.
* Motivo: o valor central do produto é "há quanto tempo" — bugs de fuso
  horário quebram a proposta do app.

---

# Requisitos Não Funcionais

* Interface simples
* Responsivo para celular
* API REST versionada (`/api/v1`)
* Estrutura preparada para integração futura com aplicativo Flutter
* Containerização com Docker
* Banco de dados PostgreSQL

---

# Stack Tecnológica

## Backend

* Python 3.12+
* Flask
* SQLAlchemy
* Alembic
* Flask-JWT-Extended (access token + refresh token)
* PostgreSQL

## Infraestrutura

* Docker
* Docker Compose

## Frontend

* Flutter (app mobile dos pais, em desenvolvimento)

A arquitetura mantém o backend desacoplado de qualquer client específico —
troca ou adição de frontend (web, app de profissionais) não deve exigir
alteração no backend.

---

# Arquitetura

```text
Frontend
   ↓
API Flask (blueprints em api/v1)
   ↓
Services (regras de negócio)
   ↓
Repositories (acesso a dados)
   ↓
SQLAlchemy
   ↓
PostgreSQL
```

Toda comunicação deverá ocorrer através de endpoints REST.

---

# Estrutura Inicial do Projeto

A estrutura abaixo segue uma separação clara de responsabilidades,
facilitando manutenção, evolução do projeto e gerenciamento das migrations.

```text
backend/
│
├── app/
│   ├── __init__.py          # create_app() — application factory
│   ├── api/
│   │   └── v1/
│   │       ├── __init__.py  # registro dos blueprints
│   │       ├── auth.py
│   │       ├── babies.py
│   │       ├── feedings.py
│   │       └── naps.py
│   ├── services/
│   │   ├── auth_service.py
│   │   ├── baby_service.py
│   │   ├── feeding_service.py
│   │   └── nap_service.py
│   └── repositories/
│       ├── user_repository.py
│       ├── baby_repository.py
│       ├── feeding_repository.py
│       └── nap_repository.py
│
├── core/
│   ├── settings.py
│   ├── logger.py
│   └── security.py
│
├── db/
│   ├── base.py
│   ├── database.py
│   └── models/
│       ├── user.py
│       ├── baby.py
│       ├── feeding.py
│       └── nap.py
│
├── migrations/
│
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── run.py
```

### Observações sobre a arquitetura

#### API (substitui a antiga separação routes/api)

Consolidado em uma única pasta `app/api/v1/`, que:

* Contém os blueprints Flask (camada de rotas)
* Já versiona a API desde o início (`/api/v1/...`), preparando para
  evolução sem breaking changes

#### Models

Os models ficam dentro de `db/models`, pois representam diretamente as
entidades persistidas no banco de dados.

#### Repositories

A camada de repositories é responsável por encapsular o acesso ao banco de
dados, evitando que queries SQLAlchemy fiquem espalhadas pelos services ou
pelas rotas.

```text
Route → Service → Repository → Database
```

**Nota de aprendizado:** com SQLAlchemy, a session já se comporta
parcialmente como um repository. Existe o risco da camada virar apenas
"passthrough". A regra prática: se um método do repository só faz
`session.query(X).get(id)`, tudo bem ser fino — o valor está em centralizar
e dar nome às queries (`find_open_feeding_by_baby`,
`list_by_baby_ordered`), não em abstrair o ORM.

#### Services

Os services concentram as regras de negócio da aplicação (ver seção
**Regras de Negócio**):

* Calcular duração de mamadas e sonecas
* Validar estados de início/fim de eventos (evento em andamento, conflitos,
  sobreposição na edição)
* Validar propriedade do recurso (bebê pertence ao usuário)
* Regras futuras de estatísticas e relatórios

#### Core

A pasta `core` centraliza componentes compartilhados da aplicação:
configurações, variáveis de ambiente, logger, segurança, utilitários
globais.

#### Database

A pasta `db` concentra toda a configuração relacionada ao banco: criação da
engine, session factory, base declarativa do SQLAlchemy, models. Isso
facilita a integração com Alembic e mantém a infraestrutura de persistência
organizada.

#### Schemas

Neste primeiro momento, a pasta `schemas` não é utilizada — validações são
feitas diretamente nas rotas ou services. Caso a API cresça e seja
necessário padronizar serialização e validação de entrada/saída, poderá
ser introduzido posteriormente (Marshmallow ou Pydantic), sem impacto
significativo na arquitetura.

#### Extensions

Não utilizada por enquanto — configuração do banco fica em `db`, projeto
mantido simples.

---

# Modelo de Dados

Todos os campos de data/hora usam `TIMESTAMP WITH TIME ZONE` e são
armazenados em UTC.

## users

```sql
id              SERIAL PRIMARY KEY
name            VARCHAR NOT NULL
email           VARCHAR UNIQUE NOT NULL
password_hash   VARCHAR NOT NULL
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

## babies

```sql
id              SERIAL PRIMARY KEY
user_id         INTEGER NOT NULL REFERENCES users(id)
name            VARCHAR NOT NULL
birth_date      DATE NOT NULL
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

## feedings

```sql
id              SERIAL PRIMARY KEY
baby_id         INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
started_at      TIMESTAMPTZ NOT NULL
ended_at        TIMESTAMPTZ NULL          -- NULL = mamada em andamento
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

> `duration` é calculada (`ended_at - started_at`), não persistida.

## naps

```sql
id              SERIAL PRIMARY KEY
baby_id         INTEGER NOT NULL REFERENCES babies(id) ON DELETE CASCADE
started_at      TIMESTAMPTZ NOT NULL
ended_at        TIMESTAMPTZ NULL          -- NULL = soneca em andamento
created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
```

> `duration` é calculada (`ended_at - started_at`), não persistida.

> **`ON DELETE CASCADE`** — a versão inicial da FK não tinha; excluir um
> bebê com mamadas/sonecas já registradas quebrava com erro de integridade
> referencial. O histórico é removido junto: não existe caso de uso pra
> manter mamadas/sonecas "órfãs" de um bebê que não existe mais.

### Índices recomendados

```sql
CREATE INDEX idx_feedings_baby_started ON feedings (baby_id, started_at DESC);
CREATE INDEX idx_naps_baby_started ON naps (baby_id, started_at DESC);
```

---

# API

Prefixo base: `/api/v1`

## Auth

```text
POST   /auth/register
POST   /auth/login          → retorna access_token + refresh_token
GET    /auth/me             → dados do usuário autenticado (nome, e-mail)
POST   /auth/refresh        → renova access_token usando refresh_token
POST   /auth/logout         → revoga refresh_token (blocklist)
```

> `GET /auth/me` — necessário pra tela de perfil e pra checar sessão salva
> no `SplashScreen` do app sem reinventar essa checagem em outro endpoint.

## Babies

```text
GET    /babies
POST   /babies
GET    /babies/{id}
PUT    /babies/{id}
DELETE /babies/{id}
GET    /babies/{id}/status      → status consolidado (Funcionalidade 3)
```

## Feedings (escopados por bebê)

```text
GET    /babies/{baby_id}/feedings           → histórico completo (sem paginação por enquanto)
POST   /babies/{baby_id}/feedings/start
POST   /feedings/{id}/finish
PUT    /feedings/{id}                       → corrige started_at/ended_at de um registro existente
DELETE /feedings/{id}
```

## Naps (escopados por bebê)

```text
GET    /babies/{baby_id}/naps               → histórico completo (sem paginação por enquanto)
POST   /babies/{baby_id}/naps/start
POST   /naps/{id}/finish
PUT    /naps/{id}                           → corrige started_at/ended_at de um registro existente
DELETE /naps/{id}
```

### Observações

* Listagens de eventos são **escopadas por bebê** (e não globais como
  `GET /feedings`), pois o usuário pode ter múltiplos bebês. Isso também
  simplifica a autorização.
* Ações sobre um evento específico (`finish`, `delete`, `update`) usam o id
  do evento diretamente — a propriedade é validada via join até o
  `user_id`.
* `start` aceita opcionalmente um `started_at` no body (registro
  retroativo); se omitido, usa o horário atual do servidor (UTC).
* `finish` aceita opcionalmente um `ended_at` no body; se omitido, usa o
  horário atual.
* A listagem foi desenhada para paginação, mas isso não foi implementado
  no V1 — o volume de dados de um bebê não justificou ainda. Reavaliar se
  o histórico crescer a ponto de pesar.
* `PUT /feedings/{id}` e `PUT /naps/{id}` cobrem registro retroativo (o pai
  só registra a mamada um tempo depois que ela começou) e correção
  pós-fato (esqueceu de finalizar e o evento ficou aberto por horas). Os
  dois casos usam o mesmo endpoint — a única diferença é qual campo fica
  editável (só `started_at` se o evento ainda está em andamento; os dois
  se já foi finalizado). Ver regra de sobreposição em "Regras de Negócio".

### Exemplo de resposta — `GET /babies/{id}/status`

```json
{
  "baby_id": 1,
  "current_feeding": null,
  "current_nap": {
    "id": 42,
    "started_at": "2026-06-09T14:30:00+00:00",
    "elapsed_minutes": 35
  },
  "last_feeding": {
    "id": 41,
    "started_at": "2026-06-09T12:00:00+00:00",
    "ended_at": "2026-06-09T12:25:00+00:00",
    "duration_minutes": 25,
    "minutes_since_end": 160
  },
  "last_nap": {
    "id": 40,
    "started_at": "2026-06-09T10:00:00+00:00",
    "ended_at": "2026-06-09T11:30:00+00:00",
    "duration_minutes": 90
  },
  "awake_minutes": null
}
```

> `awake_minutes` é `null` quando há soneca em andamento.

---

# Boas Práticas

* Utilizar migrations com Alembic para qualquer alteração estrutural.
* Seguir o fluxo Route → Service → Repository.
* Manter regras de negócio isoladas nos services (rotas apenas orquestram
  request/response).
* Centralizar acesso ao banco nos repositories.
* Utilizar variáveis de ambiente para configurações sensíveis.
* Manter o backend desacoplado do frontend.
* Manter os models focados apenas na representação dos dados.
* Armazenar todos os timestamps em UTC.
* Nunca persistir dados deriváveis sem justificativa de performance
  documentada.

---

# Convenções de Desenvolvimento (para uso com Claude Code)

Estas convenções orientam o desenvolvimento assistido por IA neste
repositório.

## Fluxo de trabalho

* Implementar **uma funcionalidade por vez**, na ordem: model → migration
  → repository → service → rota.
* Toda alteração de schema passa por migration Alembic (nunca
  `create_all` em produção).
* Antes de criar um arquivo novo, verificar se a estrutura definida neste
  documento já prevê o local correto.
* Em caso de dúvida arquitetural, propor a mudança neste documento antes
  de implementar.

## Código

* Application factory (`create_app()`) para permitir múltiplas
  configurações por ambiente.
* Type hints em todas as funções de services e repositories.
* Erros de negócio retornam JSON padronizado:
  `{"error": "codigo_legivel", "message": "descrição"}`.
* Códigos HTTP conforme as Regras de Negócio (409 para conflito de estado,
  422 para validação, 404 para não encontrado/não autorizado).

## Aprendizado

* Ao implementar um padrão novo (ex: blocklist de JWT, paginação), incluir
  comentário breve explicando o porquê, não apenas o como.

---

# Objetivo de Aprendizado

Este projeto também é um laboratório para praticar:

* Flask
* SQLAlchemy
* Alembic
* PostgreSQL
* Docker
* Arquitetura em camadas
* Repository Pattern
* APIs REST
* Organização de projetos Python
* Boas práticas de desenvolvimento backend
* Desenvolvimento assistido por IA com documentação como fonte de verdade

A prioridade é simplicidade e entrega incremental, evitando complexidade
desnecessária antes que a versão correspondente do roadmap exija.
