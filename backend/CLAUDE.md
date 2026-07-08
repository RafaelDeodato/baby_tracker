# Backend — Flask

> Ver `../CLAUDE.md` para o panorama do monorepo. Ver
> `../docs/baby-tracker-mvp.md` para a spec técnica completa, regras de
> negócio e modelo de dados — este arquivo não duplica aquele conteúdo,
> só resume as convenções de código.

## Stack

Python 3.12+, Flask, SQLAlchemy, Alembic, Flask-JWT-Extended, PostgreSQL,
Docker.

## Arquitetura

```text
Route (app/api/v1) → Service (app/services) → Repository (app/repositories) → SQLAlchemy → PostgreSQL
```

* **Rotas** (`app/api/v1/`): blueprints Flask, já versionados. Só orquestram
  request/response — nenhuma regra de negócio aqui.
* **Services** (`app/services/`): concentram toda a regra de negócio
  (cálculo de duração, validação de estados, autorização). Ver seção
  "Regras de Negócio" em `docs/baby-tracker-mvp.md` antes de mexer aqui.
* **Repositories** (`app/repositories/`): único ponto de acesso ao banco.
  Podem ser finos (`session.query(X).get(id)`) — o valor está em dar nome
  às queries (`find_open_feeding_by_baby`), não em abstrair o ORM.
* **Models** (`db/models/`): representação pura das entidades. Sem lógica
  de negócio.
* **Core** (`core/`): configuração, variáveis de ambiente, logger,
  segurança — compartilhado por toda a aplicação.

`schemas/` (Marshmallow/Pydantic) ainda não existe — validação fica direto
em rota/service. Só introduzir se a API crescer a ponto de justificar.

## Convenções de código

* `create_app()` como application factory — permite múltiplas configs por
  ambiente.
* Type hints em todas as funções de services e repositories.
* Erros de negócio retornam JSON padronizado:
  `{"error": "codigo_legivel", "message": "descrição"}`.
* Códigos HTTP: `409` para conflito de estado (ex: evento já em andamento),
  `422` para validação, `404` para não encontrado **ou** não autorizado
  (nunca `403` — não vazar existência do recurso de outro usuário).
* Toda alteração de schema passa por migration Alembic. Nunca `create_all`
  em produção.
* Dados deriváveis (ex: duração de mamada/soneca) não são persistidos —
  calculados a partir de `started_at`/`ended_at`. Não persistir um dado
  derivável sem justificativa de performance documentada.
* Todo acesso a bebês/eventos valida que o recurso pertence ao usuário
  autenticado (via `user_id` do JWT).

## Fluxo de implementação

Uma funcionalidade por vez, nesta ordem: model → migration → repository →
service → rota. Antes de criar um arquivo novo, checar se a estrutura já
prevista em `docs/baby-tracker-mvp.md` define o local correto.

## Comandos

### Desenvolvimento local

```bash
# subir banco (Postgres + pgAdmin) local
docker-compose up -d

# rodar migrations
alembic upgrade head

# criar nova migration
alembic revision --autogenerate -m "descrição"

# rodar a API localmente
python run.py
```

### Produção (Docker + gunicorn)

`python run.py` é só pro dev local — em produção a API roda via
`gunicorn` dentro do `Dockerfile` na raiz de `backend/`. Alvo é o Cloud
Run: a porta vem da variável de ambiente `PORT` (padrão `8080` se não
definida).

```bash
# build da imagem
docker build -t baby-tracker-backend .

# rodar localmente pra testar a imagem de produção (variáveis de
# ambiente reais entram via -e ou --env-file, nunca hardcoded na imagem)
docker run -p 8080:8080 --env-file .env baby-tracker-backend
```

Migrations não rodam automaticamente no `CMD` da imagem — seguem sendo
um passo manual (`alembic upgrade head`) antes ou depois do deploy,
igual já é hoje em dev.