# Baby Tracker — Auditoria de Segurança (pré-lançamento)

> Levantamento feito diretamente no código do backend (branch `master`) antes
> de abrir o MVP para usuários reais. Organizado por prioridade de correção,
> não por ordem de descoberta. Cada item referencia o arquivo exato onde foi
> observado, para facilitar a implementação.

---

## Como usar este documento

Os itens da seção 2 (**Corrigir antes do lançamento**) são bloqueantes —
mesmo um MVP com beta fechado (poucos usuários conhecidos) deveria resolver
pelo menos rate limiting e blocklist persistida antes de distribuir
credenciais reais. Os itens da seção 3 são recomendados, mas não bloqueiam
um beta pequeno e controlado. A seção 4 documenta o que já está correto,
para não ser refeito ou "corrigido" por engano.

---

## 1. Infraestrutura (checklist, fora do código)

Não são bugs de código — são configurações/decisões operacionais a
confirmar antes do lançamento:

- [ ] Confirmar que a `DATABASE_URL` do Neon inclui `sslmode=require`
  explicitamente, não depender do default silencioso.
- [ ] Ativar 2FA na conta Google (GCP) e na conta Neon.
- [ ] Confirmar a política de retenção/point-in-time recovery do plano atual
  do Neon — não assumir que o free tier cobre a mesma janela de um plano
  pago.
- [ ] Garantir que `FLASK_DEBUG` **nunca** seja `true` nas variáveis de
  ambiente do Cloud Run em produção (ver item 2.4 — o app já tem o default
  seguro no código, mas isso depende de configuração correta no deploy).
- [ ] Quando o serviço de e-mail (Resend ou outro) for integrado, a API key
  segue a mesma regra de `SECRET_KEY`/`JWT_SECRET_KEY`: variável de
  ambiente, nunca hardcoded, nunca commitada.

---

## 2. Corrigir antes do lançamento (bloqueante)

### 2.1 Rate limiting ausente em `/auth/login` e `/auth/register`

**Onde**: `app/api/v1/auth.py`

Não existe nenhuma proteção contra força bruta hoje. Isso já está planejado
como parte da V2 (Flask-Limiter, em memória, sem infraestrutura nova — ver
`docs/v2-compartilhamento-e-seguranca.md`), mas se o MVP for exposto antes
da V2 estar pronta, este é o item de maior prioridade de todo o documento.

**Ação**: aplicar rate limiting pelo menos em `/login` e `/register` (ex:
5-10 tentativas/minuto por IP) antes de qualquer distribuição pública, mesmo
que o restante do rate limiting da V2 venha depois.

### 2.2 Blocklist de token em memória, não persistida

**Onde**: `app/services/auth_service.py` (`token_blocklist` como `set()` em
memória), consumido em `app/__init__.py` via `token_in_blocklist_loader`.

Isso não é só uma questão de custo/escala (já discutido em
`baby-tracker-precificacao-e-custos.md`) — é uma falha de segurança real:
com o Cloud Run rodando múltiplas instâncias, um token revogado (logout) em
uma instância continua válido em outra que nunca viu essa revogação. Quebra
a expectativa de que "logout" realmente revoga o acesso.

**Ação**: mover `token_blocklist` para uma tabela no Postgres (já planejado
na V2). Priorizar isso independentemente do resto da V2.

### 2.3 CORS totalmente aberto

**Onde**: `app/__init__.py` — `CORS(app)` sem restrição de origem.

Hoje o impacto prático é baixo (cliente é o app mobile, que não é afetado
por CORS — isso só importa para requisições feitas por navegador), mas a
configuração atual permite que qualquer site chame a API a partir do
navegador de qualquer pessoa.

**Ação**: restringir `CORS` aos domínios reais conhecidos (o próprio app,
e futuramente um eventual painel web para profissionais) antes de expor a
API publicamente.

### 2.4 Nenhuma validação de força de senha no registro

**Onde**: `app/services/auth_service.py::register()`

Qualquer string é aceita como senha, sem mínimo de caracteres ou
complexidade.

**Ação**: exigir tamanho mínimo (ex: 8 caracteres) antes de gerar o hash.

---

## 3. Recomendado, não bloqueante para um beta pequeno e controlado

### 3.1 Sem camada de validação de entrada (schema)

**Onde**: todas as rotas em `app/api/v1/` — acesso direto a `data["campo"]`
sem checar presença/tipo antes.

Não é uma falha de segurança grave por si só, já que `Config.DEBUG` vem
`False` por padrão (`core/settings.py`) — mas depende inteiramente de
disciplina operacional (ver item 1, checklist de `FLASK_DEBUG`). Se essa
variável for setada incorretamente em produção, um campo faltante no corpo
da requisição viraria vazamento de stack trace para o cliente.

**Ação**: adotar uma lib de schema (Marshmallow ou Pydantic) para validar o
corpo das requisições antes de acessar os campos.

### 3.2 Enumeração de e-mail no registro

**Onde**: `app/api/v1/auth.py::register()` — retorna explicitamente
`"E-mail já cadastrado."` quando o e-mail já existe.

Permite que qualquer pessoa descubra se um e-mail específico tem conta no
app, testando o endpoint repetidamente. É um trade-off comum (muitos apps
aceitam isso pela UX de cadastro), mas deveria ser uma decisão consciente,
não um efeito colateral não avaliado.

**Ação**: decidir conscientemente se mantém a mensagem específica ou troca
por uma resposta genérica ("se este e-mail já existe, você receberá
instruções" — padrão mais comum em fluxos de recuperação de senha, adaptar
para registro se fizer sentido pro produto).

### 3.3 Sem cabeçalhos de segurança HTTP explícitos

Nenhum header como `X-Content-Type-Options`, `X-Frame-Options` está sendo
setado pela aplicação (o Cloud Run já força HTTPS na borda, isso é
diferente). Baixa urgência para uma API consumida só por app mobile, mas
vale considerar `flask-talisman` ou headers manuais se um cliente web
(painel profissional) entrar no roadmap.

---

## 4. Já está correto (não mexer sem motivo)

Para evitar retrabalho ou "correção" desnecessária:

- **Hash de senha**: `core/security.py` usa
  `werkzeug.security.generate_password_hash` (scrypt por padrão) —
  implementação correta.
- **Segredos**: `SECRET_KEY`, `JWT_SECRET_KEY`, `DATABASE_URL` vêm de
  variável de ambiente via `core/settings.py`; `.env` está no `.gitignore`.
  Nenhum segredo commitado no repo.
- **Autorização por dono do recurso (proteção contra IDOR)**: verificado
  especificamente em `app/repositories/baby_repository.py`
  (`find_by_id_and_user`) — todas as rotas de `babies` e `feedings`
  filtram por `user_id` junto com o ID do recurso. Um usuário autenticado
  não consegue acessar dados de outro usuário só adivinhando o ID.
- **SQL Injection**: não é risco — todo acesso a dados passa pelo
  SQLAlchemy ORM, sem SQL cru concatenado em nenhum lugar do código
  revisado.
- **Expiração de JWT**: 15 min (access) / 30 dias (refresh), explícita em
  `Config` — política razoável para o estágio atual.

---

## 5. Ordem de prioridade sugerida

1. Rate limiting em `/auth/login` e `/auth/register` (2.1)
2. Blocklist de token persistida (2.2)
3. Restringir CORS (2.3)
4. Validação de força de senha (2.4)
5. Camada de validação de entrada / schema (3.1)
6. Decisão consciente sobre enumeração de e-mail (3.2)
7. Cabeçalhos de segurança HTTP (3.3) — só se/quando existir cliente web