# Baby Tracker — Roadmap

> Este documento cobre versões e funcionalidades futuras. Para o que já
> foi especificado/implementado (V1), ver `baby-tracker-backend-spec.md`.

## Como ler este roadmap

Duas trilhas:

* **Trilha principal** (`V1`, `V2`, `V3`...) — sequencial, cada versão
  assume que a anterior está pronta. A ordem aqui importa.
* **Trilha opcional** (`V3.1`, `V3.2`...) — o número indica **onde a ideia
  se encaixa conceitualmente**, não quando ela precisa ser implementada.
  Itens da trilha opcional podem ser feitos antes, durante ou depois da
  versão principal correspondente, em qualquer ordem entre si.

---

## Trilha Principal

### V1 — MVP de rotina ✅ *fechado*

* Cadastro de usuário, login JWT com refresh token, `/auth/me`
* Cadastro de bebê (criar/editar/excluir)
* Registro de mamadas e sonecas (iniciar/finalizar/editar/excluir)
* Histórico de eventos
* Endpoint de status consolidado
* Sessão persistente (auto-login) + tratamento de sessão expirada

Objetivo: validar se pais utilizariam a aplicação diariamente.

**Adicionado durante o desenvolvimento** (não estava no desenho original,
mas avaliado como necessário antes de considerar o V1 pronto — detalhado em
`baby-tracker-backend-spec.md`): `GET /auth/me`, editar/excluir bebê,
`ON DELETE CASCADE` em `feedings`/`naps`, `PUT` de edição de eventos com
validação de sobreposição, sessão persistente.

### V2 — Fraldas + compartilhamento entre usuários ✅ *fechado*

* ✅ Registro de troca de fraldas
* ✅ Compartilhamento de bebês entre usuários: relação bebê↔usuário passa a
  ser N:N. Convite feito por **`@username`** (campo único por usuário,
  busca por correspondência exata — sem busca parcial/prefixo, pra não
  virar um diretório de pessoas). Quem recebe o convite aceita ou recusa
  pela própria caixa de notificações do app (ver abaixo) — sem depender
  de e-mail. Três níveis de permissão por bebê: `adm` (acesso total,
  sem limite de quantos por bebê — "pai/mãe" é só um atalho de UX pra
  esse nível), `tutor` (gerencia rotina, não gerencia acesso) e
  `visualizador` (só leitura). Cada convite também tem um título livre
  opcional (ex: "Vovó", "Dindo") — só de exibição, sem efeito na
  permissão. Compartilhamento continua por bebê, não por família (uma
  entidade Família foi cogitada e descartada — casos reais como guarda
  compartilhada não se encaixam bem numa unidade rígida). Nível
  "profissional" ainda **não** aparece nesta versão — ver ideia adiada
  abaixo. Público desta versão: coparentais, avós, cuidadores familiares
* ✅ **Notificações internas (inbox, não push)**: infraestrutura genérica
  de notificações dentro do app, motivada pelo fluxo de convite mas
  desenhada pra ser reaproveitada por qualquer aviso futuro (ver nota na
  V3.4, que já nasce parcialmente resolvida por conta disso)
* ✅ **Segurança**, feita junto por não exigir infraestrutura nova:
  exigência mínima de complexidade de senha no cadastro; lista de tokens
  revogados (logout) persistida no banco (`revoked_tokens`) em vez de em
  memória — sem isso, um token revogado voltaria a valer depois que uma
  instância do Cloud Run reiniciasse; rate limiting (Flask-Limiter) nos
  endpoints de autenticação; CORS restrito por variável de ambiente (nega
  todas as origens de navegador por padrão, até existir um cliente web
  real). Detalhes em `baby-tracker-auditoria-seguranca.md`.
* ❌ **Verificação de e-mail por token — decisão explícita de adiar**,
  não esquecimento: só faz sentido quando o cadastro deixar de ser
  restrito à família (exige e-mail transacional de verdade, ex: Resend —
  SMTP direto não é confiável em plataformas serverless como Cloud Run).
  Registrar aqui pra não reabrir essa discussão sem necessidade.

Objetivo de arquitetura: validar o modelo de permissão N:N com um público
de baixo risco antes de abrir para profissionais pagantes (V5+).

Detalhamento técnico completo (schema, endpoints, regras) em
`v2-compartilhamento-e-seguranca.md`.

**Ideia registrada, não implementada nesta versão:** perfil profissional
com um campo de título pré-definido (ex: "Consultora de Amamentação"),
que seria sugerido automaticamente quando uma família convidasse aquele
`@username`. Revisitar quando a V5+ (público profissional) estiver
realmente sendo construída — só implementar se, nesse momento, continuar
fazendo sentido de negócio e técnico.

### V3 — Complementação de dados de rotina ✅ *fechado*

Enriquecer os eventos que já existem (mamada, soneca, fralda) com campos
adicionais — não são categorias novas de evento, são metadados a mais.

**Mamadas** (maior valor pra consultoras de amamentação):
* Tipo: peito / mamadeira (fórmula) / mamadeira (leite ordenhado)
* Lado (esquerdo / direito / ambos) — só quando tipo = peito
* Volume em ml — só quando tipo = mamadeira
* Observação livre (opcional)

**Sonecas** (maior valor pra sleep coaches):
* Local do sono: berço / colo / carrinho / cama dos pais / carro (bebê
  conforto)
* Ambiente: claro/escuro, ruído branco sim/não
* Observação livre (opcional)

**Fraldas** (relevância pediátrica):
* Tipo: só urina / só fezes / ambos
* Consistência das fezes (líquida / pastosa / sólida)
* Observação livre (opcional)

Cada tipo tem um campo **estrutural** (dispara o estado de "incompleto"
se ausente) e os demais são **refinamentos** (sempre opcionais). Detalhes
em `v3-complementacao-dados-rotina.md`.

### V4 — Caderneta digital

Inspirado na Caderneta da Criança (SUS/OMS), dentro do app.

* Registro formal de consultas (peso, altura, perímetro cefálico por
  consulta médica — distinto do registro livre da V3.1)
* Controle de vacinação
* Marcos de desenvolvimento
* (Futuro distante, fora de escopo por ora) informativos que hoje existem
  na caderneta física

### V5 — Introdução alimentar + nutricionistas

* Registro de introdução alimentar (marco por alimento, reações, aceitação)
* Painel/funcionalidades voltadas a nutricionistas pediátricas

### V6 — Pré-parto + doulas

* Nova entidade: gestação (rastreia período anterior ao nascimento, com
  transição para registro de bebê no momento do parto — não é extensão do
  model de bebê existente)
* Funcionalidades voltadas a doulas

### V7 — Modo cuidador / creches

* Papéis de acesso voltados a instituições (creches, clínicas)

### V8 — Diretório + marketplace

* Diretório de profissionais
* Conexão entre famílias e profissionais autônomos/instituições

---

## Trilha Opcional

### V3.1 — Peso e altura (registro livre)

Registro complementar de peso/altura fora do formulário formal de consulta
da V4 — pra quando o pai quer registrar sem esperar uma consulta médica.
Pode futuramente se conectar com introdução alimentar (V5). Avaliado como
simples; pode ser implementado antes da própria V3/V4 se fizer sentido no
momento.

### V3.2 — Fotos

Foto de perfil do usuário, foto de perfil do bebê, foto associada a um
registro de fralda. Agrupado separadamente por exigir decisão de
infraestrutura de armazenamento de arquivo (ambiente de desenvolvimento e
produção) antes de qualquer feature de foto poder ser implementada — é
pré-requisito técnico comum a todas elas, não uma decisão de produto.

### V3.3 — Medicamentos

Lembretes de medicação e registro de rotina (se o bebê foi medicado ou
não), na mesma lógica de mamada/soneca/fralda. O lembrete em si consome a
infraestrutura de notificações que já existe a partir da V2 (ver abaixo) —
só precisa adicionar o tipo de notificação e o agendamento, não construir
o mecanismo do zero.

### V3.4 — Notificações *(infraestrutura antecipada na V2)*

A tabela genérica de notificações (inbox interno) já é construída na V2,
motivada pelo fluxo de convite de compartilhamento — não pelo lembrete de
medicamento, como estava previsto originalmente aqui. O que resta pra
este item, quando a V3.3 for implementada, é só adicionar o tipo de
notificação de lembrete e o agendamento (algo que "acorda" e cria a
notificação em um horário programado) — a infraestrutura de exibir,
marcar como lida e listar já vai existir. Mecanismo de **push** (avisar
mesmo com o app fechado) continua fora de escopo — o inbox da V2 é só
para quando a pessoa abre o app.

### V4.1 — Dashboards e estatísticas

Gráficos e relatórios de sono/alimentação/rotina. Não é crítico pro
funcionamento do app, mas está previsto desde o início. Uma versão simples
pra pais pode nascer aqui; uma versão robusta pro painel profissional é
esperada a partir da V5+.

---

## Nota sobre monetização

A partir da V2 (compartilhamento) o modelo de permissão N:N já está em
produção — isso é o alicerce técnico que sustenta a entrada de
profissionais pagantes a partir da V5 em diante. Famílias usam o app
gratuitamente, sem anúncios, sempre. Profissionais autônomos e instituições
são os segmentos pagantes.