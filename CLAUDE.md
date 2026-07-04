# Baby Tracker

> Este é o `CLAUDE.md` raiz. Ele dá o panorama do monorepo. Para convenções
> específicas de código, ver `app/CLAUDE.md` (Flutter) e `backend/CLAUDE.md`
> (Flask) — o Claude Code já carrega o mais próximo da pasta em que estiver
> trabalhando.

## O que é

App para acompanhar a rotina de bebês recém-nascidos (mamadas e sonecas).
V1 é o MVP: um app mobile para os pais. Ver roadmap completo em
`docs/baby-tracker-mvp.md`.

Duplo objetivo: resolver um problema real do dia a dia de pais de recém-nascidos,
e servir como projeto de aprendizado prático de backend (Python/Flask) e
mobile (Flutter) para o autor.

## Estrutura do monorepo

```text
/
├── app/          # Flutter — app mobile dos pais (V1, em desenvolvimento)
├── backend/       # Flask — API REST, única fonte de dados para todos os clients
└── docs/
    ├── baby-tracker-mvp.md          # spec técnica + regras de negócio do backend
    └── baby-tracker-style-guide.md  # identidade visual, cores, tipografia
```

Monorepo por decisão deliberada nesta fase: só existe 1 client até agora, e
separar prematuramente teria custo sem benefício. Quando o app dos
profissionais ou a plataforma web nascerem, reavaliar se cada um merece
repo próprio ou se entram como novos pacotes aqui dentro.

## Fonte de verdade

Decisões de arquitetura, regras de negócio e identidade visual vivem nos
documentos em `docs/`, não neste arquivo. Este `CLAUDE.md` (e os filhos em
`app/` e `backend/`) apontam para eles — não os duplicam. Qualquer decisão
arquitetural nova deve ser registrada no doc correspondente **antes** de
ser implementada.

## Regras globais (valem para todo o monorepo)

* Toda comunicação entre client e servidor passa pela API REST versionada
  (`/api/v1`) — nenhum client acessa o banco diretamente.
* Todos os timestamps são armazenados e trafegados em UTC. Conversão de
  fuso é responsabilidade do client.
* LGPD é premissa de design desde o V1: consentimento explícito, revogação
  simples, trilha de auditoria — não é algo a adicionar depois.
* O backend nunca conhece detalhes de apresentação; ele é desacoplado de
  qualquer client específico.

## Convenção de trabalho com IA

* Implementar uma funcionalidade por vez, de ponta a ponta, antes de
  seguir para a próxima.
* Em caso de dúvida arquitetural, propor a mudança no doc relevante antes
  de implementar — não decidir silenciosamente em código.
* Ao introduzir um padrão novo, comentar brevemente o porquê, não só o como
  (este projeto também é laboratório de aprendizado).