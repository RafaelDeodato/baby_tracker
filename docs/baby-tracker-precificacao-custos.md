# Baby Tracker — Precificação e Custos

> Este documento consolida a análise de viabilidade financeira do app: custo
> real de infraestrutura por usuário, controles técnicos necessários pra manter
> esse custo baixo, e o modelo de monetização (freemium família + profissional).
> Complementa `baby-tracker-roadmap.md` — aqui não se discute *o quê* construir,
> e sim *quanto custa* construir e *como* isso se paga.

---

## Resumo executivo

Com a arquitetura escolhida (Cloud Run + Neon, ambos com scale-to-zero) e os
controles técnicos descritos abaixo, o app sustenta **~250-300 famílias ativas
em produção com R$ 0 de custo de infraestrutura**, mesmo com todas as versões
do roadmap (V1-V8) implementadas. Acima disso, o custo cresce em **centavos
por família/mês**, não em reais — o que significa que uma taxa de conversão
baixíssima para o plano pago (família ou profissional) já cobre a
infraestrutura de milhares de usuários gratuitos.

O fator limitante do negócio não é técnico — é comercial (aquisição e
conversão). A arquitetura não é o gargalo.

---

## 1. Stack e por que ela é barata

* **API**: Flask no Cloud Run — escala a zero, cobra por segundo de CPU
  ativo. Sem servidor "sempre ligado" custando parado.
* **Banco**: PostgreSQL no Neon (fora do GCP) — mesmo princípio de
  scale-to-zero, free tier permanente sem cartão (100 CU-hours + 0,5 GB/mês).
  Cloud SQL foi descartado por não ter free tier permanente.
* **Fotos e relatórios**: Cloud Storage — cobrado por GB armazenado + operação,
  não por instância parada.
* **E-mail**: Resend — free até 3.000 envios/mês (cap de 100/dia).

Essa combinação só é barata **se** os controles da seção 2 forem respeitados.
Sem eles, o mesmo stack pode gerar custo crescente e imprevisível.

---

## 2. Controles técnicos obrigatórios (reduções de custo)

Cada item abaixo já foi identificado em algum ponto da análise como
necessário pra manter o custo baixo e previsível. Tratar como requisito não
funcional, não como otimização opcional.

### 2.1 Paginação nos endpoints de listagem

**Problema atual**: `list_by_baby()` (feedings, naps, diapers) retorna o
histórico inteiro do bebê, sem `LIMIT` nem filtro de data. Isso faz o tempo de
CPU por requisição e o volume de egress crescerem com o **tempo de uso** de
cada família, não com o número de usuários — ao contrário do resto do
sistema, esse item não tem teto natural.

**Ação**: adicionar paginação (`limit`/`offset` ou cursor) e/ou filtro de
período (`?from=&to=`) nesses endpoints antes de abrir para usuários reais.
Vale também para os futuros painéis profissionais/institucionais (V4.1, V5,
V7), onde o problema se multiplica pelo número de bebês sob gestão de uma
única conta.

### 2.2 Cleanup policy no Artifact Registry

Cada deploy no Cloud Run empilha uma nova versão de imagem Docker no
Artifact Registry. Sem uma política de limpeza, o free tier de 0,5 GB estoura
em poucos deploys — **mesmo com zero usuários no app**.

**Ação**: configurar uma cleanup policy mantendo só as últimas 2-3 versões,
antes do primeiro deploy.

### 2.3 Fotos (V3.2) — cota + retenção, não armazenamento ilimitado

Diferente de dados de rotina (texto), fotos não têm teto natural de
acumulação — cada uma pesa ordens de magnitude mais que uma linha de evento.
Se o uso virar hábito (ex: foto em toda troca de fralda), o custo de storage
deixa de ser desprezível e passa a crescer indefinidamente.

**Ação obrigatória, não opcional:**

* **Compressão/resize no client antes do upload** — nunca subir a foto
  original do celular (pode ter 3-8 MB). Redimensionar pra um teto razoável
  (ex: 800px de largura, JPEG) antes de enviar. Isso sozinho é a diferença
  entre um custo insignificante e um custo real.
* **Cota mensal no plano gratuito** (ex: ~12-15 fotos/mês por família).
* **Retenção limitada pra quem não é Plus** (ex: fotos com mais de 6 meses
  saem de circulação/são removidas). Isso transforma o storage de "cresce
  pra sempre" em "se estabiliza num patamar fixo" — mesmo princípio de um
  buffer circular.
* Fotos ilimitadas e sem expurgo ficam reservadas ao plano Plus.

### 2.4 Relatórios em PDF — expiração automática, não permanência

**Arquitetura**: gerar o PDF → subir num bucket do Cloud Storage → devolver
uma *signed URL* com expiração (ex: 7 dias) → avisar o prazo por e-mail.

**Ação obrigatória**: configurar uma **lifecycle rule no bucket** que apaga o
objeto automaticamente após o prazo (ex: 7-10 dias). Sem isso, relatórios se
comportam como fotos — acumulam pra sempre. Com isso, o volume armazenado em
um dado momento é só "relatórios gerados nos últimos N dias", não "todos os
relatórios já gerados". É a diferença entre custo fixo e custo crescente.

### 2.5 Sem VPC Connector

Por escolha de manter o banco no Neon (fora do GCP, acessado via connection
string pública) em vez de Cloud SQL com IP privado, não é necessário um
Serverless VPC Access connector — que teria custo próprio por hora, sem free
tier relevante. Manter essa decisão enquanto o banco permanecer fora do GCP.

### 2.6 Rate limiting em memória (V2) — ciente da limitação

Flask-Limiter em memória, por instância, sem infraestrutura externa (Redis)
— decisão correta pro estágio atual, mantém custo zero. Ciente de que isso
não é perfeitamente preciso com múltiplas instâncias do Cloud Run rodando em
paralelo (cada instância tem seu próprio contador). Revisitar se algum dia o
volume de tentativas de login justificar um limitador centralizado — não é
uma preocupação de custo, é de precisão da proteção.

### 2.7 Blocklist de token persistida (V2)

Já planejada: mover de `set()` em memória para tabela `revoked_tokens` no
Postgres. Necessário porque o Cloud Run recicla instâncias (scale-to-zero),
e um token revogado em memória "esquece" a revogação a cada reinício. Sem
custo adicional relevante — é mais uma tabela pequena.

### 2.8 Pré-agregação/cache nos painéis profissionais e institucionais

**Problema em potencial**: um profissional (V5) ou uma instituição (V7) pode
gerenciar dezenas a centenas de bebês. Se os dashboards recalcularem
agregações "na raça" a cada carregamento — o mesmo padrão problemático do
item 2.1, multiplicado pelo número de bebês da conta —, o custo de CPU por
requisição de uma conta profissional pode ficar 10-50x o de uma família.

**Ação**: ao construir V4.1 (estatísticas) e os painéis de V5/V7, usar uma
tabela de resumo pré-computada (atualizada em background, ex: diariamente)
em vez de recalcular sobre o histórico bruto a cada acesso. Não é urgente
hoje (V4.1 ainda não existe), mas deve ser decisão de arquitetura desde o
design inicial dessas telas — corrigir depois é mais caro que desenhar certo
desde o início.

### 2.9 Cloud Scheduler para lembretes de medicamento (V3.3)

Necessário 1 job periódico (ex: a cada 15 min) checando lembretes vencidos.
Cabe tranquilamente no free tier (3 jobs/conta). Sem custo adicional.

### 2.10 Billing account com cartão cadastrado preventivamente

Tanto GCP quanto Neon (ao migrar de plano free pra pago) suspendem o serviço
ao bater o teto do free tier, em vez de cobrar automaticamente. Cadastrar
cartão **antes** de se aproximar do teto (não depois) evita indisponibilidade
súbita quando a base de usuários crescer.

---

## 3. Estimativa de escala (com os controles acima aplicados)

| Recurso | Free tier do provedor | Gargalo estimado (famílias) |
|---|---|---|
| Cloud Run (compute) | 180.000 vCPU-seg/mês | ~200-300 |
| Neon (storage — dados de texto, todas as versões) | 0,5 GB | ~1.000-2.000 famílias-ano |
| Cloud Storage (fotos, com cota + retenção de 6 meses) | 5 GB | **~300-350** |
| Cloud Storage (relatórios, expiração 7 dias) | 5 GB (compartilhado com fotos) | não é gargalo — uso desprezível em regime |
| Resend (e-mail) | 3.000 envios/mês | ~1.500-3.000 |

**Gargalo real: ~250-300 famílias ativas para custo R$ 0.** Acima disso, custo
marginal na casa de centavos de real por família/mês. Referência: em
2.000-3.000 famílias ativas sustentadas, custo total de infra estimado em
**R$ 40-90/mês no total** (não por usuário).

---

## 4. Custos de loja (Google Play / App Store)

Categoria separada da infraestrutura — não é GCP, é taxa de distribuição.

| Item | Custo | Recorrência |
|---|---|---|
| Google Play Console | US$ 25 | único, nunca renova |
| Apple Developer Program | US$ 99 | anual |
| Comissão sobre assinatura (Google Play Billing / Apple IAP) | 15% da receita (até US$ 1M/ano) | por transação |

A comissão de 15% não é custo de infra — é receita que nunca chega até nós.
Precisa entrar no cálculo de precificação do plano Plus (ex: R$ 14,90/mês
vira ~R$ 12,70 líquido).

Google exige teste fechado com 12 testadores reais por 14 dias antes de
liberar produção — processo, não custo, resolvível com rede própria
(família, consultoras da validação).

---

## 5. Modelo de monetização

### Princípio geral

Duas fontes de receita que coexistem, não competem: profissionais/instituições
(V5+) e um plano família opcional ("Família Plus"). Critério pra decidir o
que é pago:

1. **Nunca gatear dado bruto do próprio filho** (histórico completo, export
   simples/CSV) — é dado do usuário, não é onde a monetização deveria morar.
2. **Gatear primeiro o que tem custo variável real pra nós** — fotos e
   volume de relatório, exatamente os itens da seção 2.3 e 2.4. O assinante
   financia o próprio custo que gera.
3. **Depois, gatear conveniência/profundidade construída sobre dado que já
   guardamos de graça** — estatística avançada, export formatado.

### Família Free vs. Família Plus

| Funcionalidade | Free (pra sempre) | Plus (pago) |
|---|---|---|
| Registro de rotina completo (mamada/soneca/fralda + V3) | ✅ | — |
| Histórico completo, sem limite de tempo | ✅ | — |
| Export simples dos dados (CSV) | ✅ | — |
| Compartilhamento entre usuários (V2) | ✅ sem limite de convidados | — |
| Peso/altura livre (V3.1), medicamentos (V3.3) | ✅ | — |
| Caderneta digital (V4) — registro e consulta | ✅ | Export formatado em PDF |
| Introdução alimentar (V5) | ✅ | — |
| Fotos | cota mensal modesta (~12-15) + retenção de 6 meses | ilimitadas, sem expurgo |
| Relatório em PDF | 1-2/mês, formato simples | ilimitado + versão avançada (tendências, período customizável) |
| Estatísticas (V4.1) | contagens básicas | tendências, comparação entre semanas |

### Profissionais (V5+)

Conta gratuita com teto de clientes vinculados; plano pago libera clientes
ilimitados, geração de relatório para os clientes e posição no futuro
diretório (V8).

### Preço

Não fixado — assim como o plano de validação de 15 entrevistas foi feito
para o segmento profissional, o mesmo processo de validação (entrevista,
teste de disposição a pagar) ainda precisa ser feito para o família Plus.
Faixa de referência do mercado brasileiro de apps de consumo por assinatura:
R$ 9,90-24,90/mês — ponto de partida para testar, não número final.

---

## 6. Itens em aberto

* Validar disposição a pagar da família Plus (equivalente ao processo já
  feito com consultoras/profissionais).
* Decidir cota exata de fotos/relatórios do plano free com base em uso real
  observado, não só estimativa.
* Definir janela de retenção de fotos para o plano free (sugestão: 6 meses).
* Revisitar rate limiting centralizado se o volume de tentativas de login
  justificar.
* Implementar pré-agregação de dashboards **antes** de lançar V4.1/V5/V7, não
  depois.