# Baby Tracker — Modelos de Cobrança (Família e Profissional)

> Complementa `baby-tracker-precificacao-e-custos.md` (que cobre custo de
> infraestrutura) e `baby-tracker-go-to-market.md` (validação com
> profissionais). Este documento foca em **quanto cobrar, de quem, e quanto
> isso pode gerar** — família e profissional, lado a lado.

---

## Princípio geral

Duas fontes de receita que coexistem, não competem entre si:

1. **Família (freemium)** — fonte de receita primária e mais previsível.
   Produto de consumo, decisão de compra individual e emocional, validada
   por concorrência real cobrando por menos produto que o nosso.
2. **Profissional (assinatura B2B2C)** — objetivo principal de negócio.
   Ticket maior, ciclo de venda mais concentrado (mercado pequeno e
   identificável), e efeito colateral valioso: cada profissional pagante
   traz famílias de graça via compartilhamento (V2), sem custo de aquisição.

Nenhum dos dois substitui o outro — a decisão atual é **investir com foco
principal em profissional**, mantendo família como caminho de receita
paralelo e mais fácil de validar sozinho.

---

## 1. Família — Free vs. Plus

### Critério para decidir o que é pago

1. **Nunca gatear dado bruto do próprio filho** (histórico completo, export
   simples/CSV) — é dado do usuário, não é onde a monetização deveria morar.
2. **Gatear primeiro o que tem custo variável real pra nós** — fotos e
   volume de relatório são os únicos itens do sistema com custo que cresce
   com o uso (ver seção 2.3 e 2.4 de `baby-tracker-precificacao-e-custos.md`).
   O assinante financia o próprio custo que gera.
3. **Depois, gatear conveniência/profundidade** construída sobre dado que já
   guardamos de graça — estatística avançada, export formatado.

### Tabela Free vs. Plus

| Funcionalidade | Free (pra sempre) | Plus (pago) |
|---|---|---|
| Registro de rotina completo (mamada/soneca/fralda + V3) | ✅ | — |
| Histórico completo, sem limite de tempo | ✅ | — |
| Export simples dos dados (CSV) | ✅ | — |
| Compartilhamento entre usuários (V2) | ✅ sem limite de convidados | — |
| Peso/altura livre (V3.1), medicamentos (V3.3) | ✅ | — |
| Caderneta digital (V4) — registro e consulta | ✅ | Export formatado em PDF |
| Introdução alimentar (V5) | ✅ | — |
| Fotos | cota mensal (~12-15/mês) + retenção de 6 meses | ilimitadas, sem expurgo |
| Relatório em PDF | 1-2/mês, formato simples | ilimitado + versão avançada (tendências, período customizável) |
| Estatísticas (V4.1) | contagens básicas | tendências, comparação entre semanas |

### Preço e estimativa de receita

Referência de mercado: apps de assinatura de consumo no Brasil, faixa
**R$ 9,90-24,90/mês**. Concorrente direto (App Meu Bebê) cobra R$ 14,90/mês
por um produto mais raso que o nosso — ponto de partida razoável.

Modelo de conversão freemium B2C costuma girar em **2-5%** de usuários
gratuitos virando pagantes (produtos maduros); adotar o piso (2%) como
premissa conservadora até termos dado real.

| Famílias ativas (free) | Conversão | Pagantes | Receita mensal (R$ 14,90) |
|---|---|---|---|
| 500 | 2% | 10 | ~R$ 150 |
| 2.500 | 2% | 50 | ~R$ 745 |
| 5.000 | 2% | 100 | ~R$ 1.490 |

**Leitura**: como o custo de infraestrutura por família é centavos (ver doc
de custos), qualquer conversão residual já cobre a operação com folga. A
variável que decide se o família-only escala é **custo de aquisição**, não
custo de servir — família não tem canal de aquisição gratuito equivalente
ao do profissional (ver seção 3), então depende de mídia paga (Meta Ads) ou
do próprio efeito de indicação do profissional.

---

## 2. Profissional — assinatura B2B2C

### Por que assinatura fixa, não cobrança por cliente atendido

Pesquisa de mercado (consultoria de sono/lactação no Brasil) mostra que
essas profissionais já vendem **pacote fechado por acompanhamento**, não
cobrança por hora ou por unidade. Cobrar do profissional "por bebê ativo"
cria atrito psicológico (parece taxa sobre o crescimento dela) e não bate
com o hábito de precificação que ela já tem no próprio negócio.

**Modelo escolhido: assinatura fixa mensal, por profissional, sem limite
por cliente atendido no plano pago.**

### Ancoragem de preço

Cursos de formação nesse mercado vendem a promessa de faturamento de
**R$ 5.000-13.000/mês** para profissionais estabelecidas. Uma ferramenta
que custe 1-3% disso é decisão de rotina, não de orçamento — define o teto
psicológico de preço antes mesmo de perguntar diretamente a elas.

### Tabela de planos

| Plano | Limite | Preço sugerido/mês | Racional |
|---|---|---|---|
| Free | até 3-5 bebês vinculados | R$ 0 | Isca de entrada, baixo risco de decisão |
| Pro | Bebês ilimitados + relatório PDF ilimitado + estatística agregada | **R$ 59-89** (ponto de partida: R$ 69-79) | ~1-2% do faturamento dela |
| Institucional (V7 — creches/berçários) | Por unidade, sob consulta | **R$ 199-499** (varia por porte) | Ticket maior, ciclo de venda mais longo |

### Estimativa de receita por penetração de mercado

Universo endereçável: **5-7 mil profissionais no Brasil**, ~4-5 mil
concentrados em SP/RJ/MG/RS/SC (já mapeado no plano de go-to-market).
Rodando R$ 79/mês contra diferentes níveis de penetração desse mercado
concentrado (base: 4-5 mil):

| Cenário | % do mercado concentrado | Profissionais pagantes | Receita mensal | Receita anual |
|---|---|---|---|---|
| Conservador | 1% | ~40-50 | ~R$ 3.200-4.000 | ~R$ 38-48 mil |
| Moderado | 3% | ~120-150 | ~R$ 9.500-11.900 | ~R$ 114-142 mil |
| Otimista | 8% | ~320-400 | ~R$ 25.300-31.600 | ~R$ 303-379 mil |

**Leitura**: mesmo o cenário conservador já cobre a infraestrutura inteira
do app com folga. O cenário moderado (3%) já é um negócio de verdade.

### Upside não incluso na tabela: institucional (V7)

Cada creche/berçário fechado no plano institucional vale, sozinho, o
equivalente a 3-6 profissionais autônomas no plano Pro, com venda mais
concentrada (um contrato, uma fatura) — mais eficiente em esforço comercial
por real de receita, ainda que o ciclo de venda seja mais longo. Ainda não
modelado numericamente por depender de V7, mais adiante no roadmap.

---

## 3. O que ainda precisa de validação real

Estas são estimativas ancoradas em benchmark de mercado, não garantias.
Itens a confirmar nas 15 entrevistas já planejadas no go-to-market:

* **Reação direta ao preço**: perguntar explicitamente "R$ 79/mês seria um
  não-pensamento ou motivo pra hesitar?", condicionado ao ganho estrutural
  identificado (visão consolidada de múltiplos clientes + fim da cobrança
  manual de registro — ver discussão sobre ganho estrutural vs. conveniência).
* **Taxa de conversão real família free → Plus**, só obtida rodando o
  produto de verdade — a faixa de 2-5% é benchmark genérico de mercado, não
  específico do nosso público.
* **Custo de aquisição por assinante pagante** (família), que só aparece
  depois de uma campanha de mídia paga real rodando (ver plano de
  marketing/aquisição em fases já discutido).
* **Se o gargalo estrutural do profissional é de fato "gerenciar múltiplos
  clientes sem virar trabalho de organização"** — se confirmado, o painel
  profissional (V4.1/V5/V7) deixa de ser refinamento tardio e vira
  prioridade técnica antecipada.