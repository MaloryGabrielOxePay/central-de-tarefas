# Central de Tarefas (HUB · Grupo Malory) — Documento de Transferência Técnica

> **Handoff para desenvolvedor humano ou LLM (Claude Code, Cursor, etc.).**
> Estado **verificado ao vivo em 02/jun/2026** contra o Supabase (`pyoabyuqbjivqgidrtpi`) e o GitHub (`main`). Onde a documentação antiga do projeto diverge da realidade, este documento segue a **realidade verificada**.

---

## 0. Leia isto primeiro (resumo de 60 segundos)

- **O que é:** dashboard pessoal de gestão de tarefas multi-empresa do Gabriel Brito Artaud (Malory). Single-page app.
- **Fonte única da verdade = o repositório GitHub.** Não confie em cópias locais nem nos arquivos anexados a projetos do Claude.ai — eles ficam defasados. Antes de qualquer edição de código, **puxe do GitHub**.
- **Arquitetura:** um único arquivo `index.html` com React via CDN (sem build step) + Supabase como backend.
- **Deploy:** `git push` no branch `main` → Netlify republica sozinho em ~30s.
- **3 gotchas que vão te morder se você não ler a seção 5 e 10:**
  1. A escala de **prioridade é invertida** (1 = mais urgente, 10 = menos). O dono pensa ao contrário.
  2. Existe um **token do GitHub hardcoded** dentro de uma Edge Function (risco de segurança — seção 11).
  3. O projeto Supabase é **free tier** e **pausa sozinho** após inatividade — quando isso acontece, o dashboard fica em branco e as escritas falham.

---

## 1. Identidade do projeto

| Campo | Valor |
|---|---|
| Nome | Central de Tarefas / HUB · Grupo Malory |
| Dono | Gabriel Brito Artaud ("Malory") — empresário, João Pessoa-PB, Franco-Brasileiro |
| URL produção | https://darling-arithmetic-ecee8e.netlify.app/ |
| Repositório | `github.com/MaloryGabrielOxePay/central-de-tarefas` |
| Branch de deploy | `main` |
| Arquivo principal | `index.html` (o app inteiro vive aqui) |
| Idioma da UI | Português (BR) |
| Fuso do dono | UTC−3 (Brasília) |

---

## 2. Stack técnica completa

Tudo carregado por CDN no `<head>`. **Não há `package.json`, não há `node_modules`, não há build.** Você edita o HTML e isso é o app.

| Camada | Tecnologia | Versão / fonte |
|---|---|---|
| UI / runtime | **React 18** | `unpkg.com/react@18/umd/react.production.min.js` |
| | **ReactDOM 18** | `unpkg.com/react-dom@18/umd/react-dom.production.min.js` |
| Transpilação JSX | **Babel Standalone** (in-browser) | `unpkg.com/@babel/standalone/babel.min.js` |
| Backend client | **Supabase JS v2** | `cdn.jsdelivr.net/npm/@supabase/supabase-js@2` |
| Tipografia (produção) | **Inter** (corpo) + **Space Grotesk** (títulos) | Google Fonts |
| Estilo | **CSS puro** com custom properties (`:root` / `body.light` / `body.dark`) | inline no `<style>` |
| Persistência | **Supabase Postgres** (primário) + **localStorage** (cache/fallback) | — |
| Realtime | **Supabase Realtime** (`postgres_changes`) | — |
| Hospedagem | **Netlify** (deploy automático via GitHub) | — |
| Backend serverless | **Supabase Edge Functions** (Deno/TypeScript) | seção 4.2 |

Linguagens que um dev vai tocar: **HTML5, CSS3, JavaScript (ES6+) com JSX** no front; **TypeScript/Deno** nas Edge Functions; **SQL (PostgreSQL)** no banco.

> ⚠️ **Nota sobre o JSX in-browser:** como o Babel transpila no navegador, erros de sintaxe JSX **quebram a tela inteira** (página branca) e só aparecem no console (F12). Não existe erro de build em tempo de commit — o "build" é o navegador do usuário. Teste sempre abrindo a página de verdade.

---

## 3. Arquitetura

```
┌──────────────┐      ┌───────────────────────────┐      ┌──────────────┐
│  Navegador   │◀────▶│  Supabase (pyoabyuqb...)   │      │   Netlify    │
│  index.html  │      │  • Postgres (tasks, etc.)  │      │  (hospeda    │
│  React+Babel │      │  • Realtime                │      │   index.html)│
│  (sem build) │      │  • Edge Functions (Deno)   │      └──────▲───────┘
└──────────────┘      └─────────────┬──────────────┘             │
       ▲                            │ pg_net (HTTP async)        │ auto-deploy
       │ localStorage cache         ▼                            │ no push
       │              ┌──────────────────────────┐      ┌────────┴───────┐
       └──────────────│  Edge Fn push-to-github   │─────▶│  GitHub (main) │
                      └──────────────────────────┘      └────────────────┘
```

**Fluxo de dados normal (uso diário):**
1. App abre → `sb.from('tasks').select('*')` lê tarefas com a anon key.
2. App assina `sb.channel('tasks-changes').on('postgres_changes', ...)` → atualiza em tempo real.
3. CRUD direto via Supabase JS (`insert`/`update`/`delete`). Soft-delete = `update status='excluido'`.
4. `localStorage` guarda um cache como fallback se o Supabase cair.

**Fluxo de deploy de código:** ver seção 7.

---

## 4. Backend Supabase — estado real verificado (02/jun/2026)

| Config | Valor |
|---|---|
| Project ID | `pyoabyuqbjivqgidrtpi` |
| URL | `https://pyoabyuqbjivqgidrtpi.supabase.co` |
| Status atual | `ACTIVE_HEALTHY` |
| Plano | Free tier (**pausa após inatividade** — ver seção 10) |

### 4.1 Tabelas (schema `public`)

> RLS está **habilitada** em todas, mas com policy permissiva: a **anon key lê e escreve** (é assim que o app funciona sem login). Na prática, qualquer um com a URL+anon key tem acesso total aos dados. Ver seção 11.

#### `public.tasks` — tabela principal (14 linhas no momento da verificação)

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| `id` | uuid | `gen_random_uuid()` | PK |
| `sector` | text | `'wowlog'` | categoria de negócio (ver 5.1) |
| `title` | text | — | obrigatório |
| `description` | text | `''` | nullable |
| `status` | text | `'pendente'` | **CHECK:** `pendente`/`aguardando`/`concluido`/`excluido` |
| `priority` | integer | `2` | **CHECK:** 1–10. **Escala invertida** (ver 5.3) |
| `comments` | jsonb | `'[]'` | array de `{text, date}` |
| `created_at` | timestamptz | `now()` | |
| `updated_at` | timestamptz | `now()` | |
| `due_date` | timestamptz | null | prazo |
| `manual_order` | integer | `0` | **ordem manual do drag & drop** (ver 5.4) — *ausente da doc antiga* |

#### `public.custom_sectors` — setores customizados (1 linha)

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| `id` | uuid | `gen_random_uuid()` | PK |
| `key` | text | — | **unique**; é a chave usada em `tasks.sector` |
| `label` | text | — | nome exibido |
| `emoji` | text | `'🏢'` | ícone |
| `color` | text | `'#7c6af7'` | cor do dot/barra |
| `created_at` | timestamptz | `now()` | |

A única linha hoje é o setor **"Suplente"** (criado pela própria interface). Setores customizados aparecem **depois** dos fixos na sidebar.

#### `public.deployments` — histórico de deploys (**0 linhas — VAZIA**)

| Coluna | Tipo | Default |
|---|---|---|
| `id` | bigint identity | auto |
| `html_content` | text | — |
| `commit_message` | text | `'chore: update dashboard via Claude'` |
| `status` | text | `'pending'` |
| `commit_sha` | text | — |
| `created_at` | timestamptz | `now()` |

> ⚠️ A tabela **existe mas está vazia**. O fluxo de "puxar o HTML atual via SQL" (que a `fetch-source` deveria popular) **não está gravando snapshots**. Trate como **não confiável** até consertar — para obter o código atual, puxe direto do GitHub raw (ver seção 8).

#### `public.dashboard_data` — **tabela legada/morta (0 linhas)**

Colunas: `id` (int, default 1), `tasks` (jsonb), `updated_at`. Resquício de uma arquitetura antiga que guardava tudo num único blob JSON. **O app atual não usa.** Pode ser dropada após confirmação.

### 4.2 Edge Functions (Deno/TypeScript) — todas `ACTIVE`, `verify_jwt: false`

| Slug | Versão | Papel |
|---|---|---|
| `push-to-github` | v2 | Recebe `{content, message}`, pega o SHA atual do `index.html`, faz commit no `main` → dispara Netlify. **Contém token GitHub hardcoded como fallback (risco).** |
| `fetch-source` | v1 | Deveria puxar o `index.html` do GitHub e gravar snapshot em `deployments`. **Atualmente não grava (tabela vazia).** |
| `bidding-pricer` | v1 | Precificação de bidding (operação uShip/WowLog — em andamento). |
| `bidding-agent` | v1 | Agente de bidding uShip (em andamento — é o "item 11" do roadmap). |

> `verify_jwt: false` em todas significa que **qualquer pessoa com a URL pode invocá-las sem autenticação**. Justificável para `push-to-github` se ela validar internamente, mas é um vetor de abuso. Ver seção 11.

### 4.3 Chaves de API

| Chave | Tipo | Valor | Uso |
|---|---|---|---|
| `anon` | legacy JWT | `eyJhbGci...YeuiV4` (válida até ~2036, `disabled:false`) | É a que está hardcoded no `index.html`. Projetada para ser pública (client-side). |
| `default` | publishable moderna | `sb_publishable_vTM3Ipu4HLM7xxmlwV7yPw_65IxvzqP` | Recomendada para apps novos (rotação independente, melhor segurança). |
| `service_role` | secreta | **NÃO incluída neste doc** | Necessária para Edge Functions que escrevem no banco (bypassa RLS). Vive nos secrets da função, nunca no client. |

> **Regra:** nunca hardcode a anon key sem confirmar que ainda é válida (`Supabase:get_publishable_keys`). Ela pode ser rotacionada. Considere migrar para a publishable moderna.

---

## 5. Modelo de domínio

### 5.1 Setores (categorias de negócio) — **estado real em produção**

Os setores são definidos em **dois lugares**:
- **Fixos:** hardcoded na constante `DEFAULT_SECTORS` dentro do `index.html`.
- **Customizados:** linhas na tabela `custom_sectors`, mergeadas em runtime.

Ordem **real** em produção (commit `de2a7aa` promoveu Malory Connect para o topo):

| Ordem | key | Label | Emoji | Cor | Origem |
|---|---|---|---|---|---|
| 1 | `maloryconnect` | Malory Connect | 🔗 | `#14b8a6` | fixo |
| 2 | `wowlog` | Wowlog | 📦 | `#38bdf8` | fixo |
| 3 | `iai` | Agência IAI | 💡 | `#eab308` | fixo |
| 4 | `entretenimento` | Malory Entretenimento | 🎪 | `#ec4899` | fixo |
| 5 | `oxepay` | Oxepay | 💳 | `#34d399` | fixo |
| 6 | `pessoal` | Pessoal / Malory | 👤 | `#a78bfa` | fixo |
| 7 | `escritorio` | Escritório Geral | 🏢 | `#fb923c` | fixo |
| — | `suplente` | Suplente | 💼 | (azul) | **custom** (`custom_sectors`) |

> **Dica para o dev:** existe uma linha redundante de `maloryconnect` em `custom_sectors` (de quando ele era custom, antes de virar fixo). É inofensiva mas pode ser limpa. Para adicionar um setor **fixo**, edite `DEFAULT_SECTORS` no HTML + deploy. Para um setor **temporário**, basta inserir em `custom_sectors` (a UI já faz isso).

### 5.2 Status (máquina de estados da tarefa)

`pendente` → `aguardando` → `concluido`, com `excluido` como soft-delete fora do fluxo.

- A UI progride o status com botões "← anterior / próximo →".
- **Soft-delete:** excluir = `update status='excluido'` (vai pra Lixeira). **Nunca** `DELETE` real, exceto "excluir permanente" na Lixeira/Concluídas.
- `concluido` só aparece na view "Concluídos", nunca nas listas principais.

### 5.3 ⚠️ Prioridade — escala INVERTIDA (a maior fonte de confusão do projeto)

No **código**, prioridade vai de **1 a 10**, onde:

| Faixa | Label | Cor | Ordenação |
|---|---|---|---|
| 1–2 | **Urgente** | vermelho | aparece **primeiro** |
| 3–4 | Alta | amarelo | |
| 5–7 | Média | azul | |
| 8–10 | **Baixa** | verde | aparece **por último** |

**O problema:** o dono (Malory) pensa "8/10 = muito importante" (escala mental: maior = mais urgente). Isso é o **oposto** do app. Se você inserir as prioridades "como o Malory fala", os itens importantes dele aparecem como **"Baixa" (verde) no fim da lista**, e a aba "Urgente" (que só mostra ≤2) fica **vazia** — dando a falsa impressão de que "o dashboard não tem nada".

> **Isto já causou um falso bug de "dashboard em branco".** A causa raiz era: nenhuma tarefa tinha prioridade ≤2, então a aba inicial "Urgente" não listava nada óbvio. Antes de assumir que algo quebrou, cheque a aba/ordenação.
>
> **Decisão atual do dono:** manter a escala **literal** (sem inverter na inserção). Se for mexer nisso, **alinhe com ele primeiro** — não inverta por conta própria.

### 5.4 `manual_order` (drag & drop)

Coluna `integer` que guarda a ordem manual definida pelo usuário arrastando cards (aba **Programação**). Lógica de ordenação:
- Se ambas as tarefas têm `manual_order` → ordena por ele.
- Se nenhuma tem → fallback para `priority`.
- Ao reordenar, o app oferece um **diálogo de sugestão de prioridade** (`getSuggestedPriority`) para alinhar a prioridade à nova posição.

---

## 6. Features (versão de produção)

Componentes React presentes no `index.html` atual: `App`, `GeralView`, `SectorView`, `ConcluView`, `TrashView`, `CalendarWidget`, `TaskCard`, `DraggableTaskCard`, `ProgrTab`, `TaskModal`.

**Navegação / views (sidebar):**
- **Programação** (`ProgrTab`) — lista com **drag & drop** (mouse + touch/mobile) para reordenar via `manual_order`, com diálogo de sugestão de prioridade.
- **Visão Geral** (`GeralView`) — com sub-abas **🔥 Urgente** / **📅 Calendário** / **📋 Todas**, stat cards clicáveis (Urgentes/Pendentes/Aguardando/Concluídas) que filtram, busca e filtro por setor.
- **Por setor** (`SectorView`) — uma entrada por setor; mostra só as tarefas daquele setor (ignora a confusão de prioridade — bom para conferência rápida).
- **Concluídos** (`ConcluView`) — tarefas concluídas, com restaurar / editar / excluir permanente.
- **Lixeira** (`TrashView`) — soft-deleted, com restaurar / excluir permanente.

**Recursos transversais:**
- **Calendário interativo** (`CalendarWidget`) — grade mensal com dots coloridos por prioridade nos dias com `due_date`, tooltip com títulos, navegação de mês/ano, e ações inline.
- **Realtime sync** via Supabase subscription (INSERT/UPDATE/DELETE).
- **localStorage cache** como fallback offline.
- **Light/Dark mode** com toggle (default: light). *(A doc antiga dizia "sem dark mode" — incorreto.)*
- **Mobile responsive** — sidebar vira hambúrguer abaixo de 768px.
- **Inline controls** no card: badge de prioridade clicável (picker 1–10), date picker, progressão de status, comentários, editar, soft-delete.
- **Modal de criar/editar tarefa** (`TaskModal`).

---

## 7. Pipeline de deploy

### Caminho A — Claude Code / Git local (recomendado para mudanças grandes)
```bash
git clone https://github.com/MaloryGabrielOxePay/central-de-tarefas.git
cd central-de-tarefas
# editar index.html
git add index.html
git commit -m "feat: descrição"
git push origin main          # Netlify deploya em ~30s
```
> O dono usa **git via GUI** (evita terminal). O efeito é o mesmo.

### Caminho B — deploy remoto via Supabase (sem PC / mobile)
A função SQL `deploy_dashboard(p_html text, p_message text)` grava em `deployments` e chama `push-to-github` via `pg_net`:
```sql
SELECT deploy_dashboard('<html>...completo...</html>', 'feat: descrição');
```
> `pg_net` é **assíncrono**: a função retorna na hora, o push roda em background. Confirme consultando `deployments` (ou o commit no GitHub) após alguns segundos. **Hoje a tabela `deployments` está vazia — valide esse caminho antes de depender dele.**

### Caminho C — commit direto via GitHub API
Como `api.github.com` costuma estar liberado em ambientes de agente, dá para editar e dar `PUT` no arquivo direto (pegando o SHA atual antes), sem inflar tokens jogando o HTML inteiro numa chamada SQL. Foi assim que o commit `de2a7aa` (Malory Connect no topo) foi feito.

**Em todos os caminhos: o gatilho final é o push no `main`, e a Netlify deploya sozinha.**

---

## 8. Como configurar / rodar (para um dev novo)

**Para desenvolver localmente:**
1. Clone o repo. Não há `npm install` — abra o `index.html` direto no navegador (ou sirva com qualquer static server, ex. `python -m http.server`).
2. O app já aponta para o Supabase de produção via anon key embutida. Edições refletem nos **dados reais** — cuidado.
3. Edite o HTML, recarregue o navegador, abra o **console (F12)** para ver erros de JSX/runtime.
4. Para publicar: commit + push no `main`.

**Para obter SEMPRE a versão atual do código (não confie em cópias):**
```bash
curl -s https://raw.githubusercontent.com/MaloryGabrielOxePay/central-de-tarefas/main/index.html -o index.html
```

**Se o dashboard abrir em branco / dados não carregam, cheque nesta ordem:**
1. Projeto Supabase pausou? (free tier) → reativar (não-destrutivo, ~1–2 min).
2. Você está na aba "Urgente" sem tarefas ≤2? → troque de aba / veja "Por setor".
3. Cache velho? → `Ctrl+Shift+R` (hard refresh).
4. Erro de JSX quebrando o render? → F12 → Console.

---

## 9. Convenções de código (do projeto)

1. **Tudo em um único arquivo** `index.html` — nunca separar CSS/JS.
2. **React funcional** com hooks (`useState`, `useEffect`, `useCallback`, `useMemo`, `useRef`).
3. **Realtime:** `sb.channel('tasks-changes').on('postgres_changes', {event:'*', schema:'public', table:'tasks'}, ...)`.
4. **CSS:** custom properties no `:root`/`body.light`/`body.dark`; responsivo via media queries (`max-width:768px`).
5. **Sem libs extras** além de React, Babel e Supabase.
6. **Nomenclatura:** kebab-case para CSS, camelCase para JS.
7. **Seções marcadas** com comentários `// ===== NOME =====` (ou `// ─── NOME ───`).
8. **Timestamps:** sempre `new Date().toISOString()`.
9. **Migrations de coluna:** `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` (obrigatório).
10. **Deletes:** soft-delete por padrão; `DELETE` real só em ação explícita de "excluir permanente".

---

## 10. Dívida técnica e problemas conhecidos (a seção que economiza tempo)

| # | Problema | Severidade | Ação sugerida |
|---|---|---|---|
| 1 | **Token GitHub hardcoded** como fallback em `push-to-github` | 🔴 Alta (segurança) | Rotacionar token; deixar só no secret/env da função. Ver seção 11. |
| 2 | **`verify_jwt: false`** em todas as Edge Functions | 🟠 Média (segurança) | Validar internamente ou ativar JWT onde fizer sentido. |
| 3 | **RLS aberta** — anon lê/escreve tudo | 🟠 Média | Aceitável p/ app pessoal, mas qualquer um com a URL acessa os dados. Avaliar policies. |
| 4 | **Prioridade invertida** vs modelo mental do dono | 🟠 Média (UX) | Não inverter sem alinhar. Documentado em 5.3. |
| 5 | **Free tier pausa sozinho** → dashboard em branco | 🟡 Recorrente | Considerar upgrade ou um "keep-alive" (cron pingando o projeto). |
| 6 | **`deployments` vazia** — `fetch-source` não grava snapshot | 🟡 Média | Caminho B/snapshot não confiável. Consertar a função ou abandonar o padrão e usar GitHub raw. |
| 7 | **`dashboard_data` legada/morta** | 🟢 Baixa | Dropar após confirmação. |
| 8 | **Doc antiga (`CLAUDE.md`) desatualizada** (fontes, dark mode, setores, `manual_order`) | 🟠 Média | Atualizar o `CLAUDE.md` no repo (ver tabela de divergências abaixo). |
| 9 | **JSX in-browser** quebra a tela toda em erro de sintaxe | 🟡 | Testar sempre no navegador real; sem build não há erro em tempo de commit. |
| 10 | **Múltiplas frentes de edição** (Claude Code local + Claude.ai remoto) sem trava | 🟠 Processo | Disciplina de sync — ver seção 12. |

### Tabela de divergências — documentação antiga vs realidade verificada

| Item | `CLAUDE.md` antigo afirma | Realidade em produção (02/jun/2026) |
|---|---|---|
| Fontes | Plus Jakarta Sans + DM Sans | **Inter + Space Grotesk** |
| Dark mode | "light mode permanente, sem dark" | **Tem dark mode** (default light) |
| Setores | sem Malory Connect | **Malory Connect é o 1º setor fixo** |
| `manual_order` / drag & drop | não menciona | **Existe e está em uso** (aba Programação) |
| Aba "Programação" | não menciona | **Existe** |
| Título da página | "Central de Tarefas · Malory" | **"HUB · Grupo Malory"** |
| `deployments` | "guarda histórico de deploys" | **Existe mas está vazia** (não grava) |

---

## 11. Segurança

- 🔴 **Token GitHub hardcoded** na função `push-to-github` (como fallback no corpo do código). Quem ler o código da função tem **acesso de escrita ao repo**. **Rotacionar o token e movê-lo para um secret/env var**, removendo do corpo. Prioridade alta.
- 🟠 **Edge Functions com `verify_jwt: false`** — invocáveis sem auth por qualquer um com a URL. Para `push-to-github`, isso significa que um terceiro poderia disparar commits. Mitigar com validação interna (segredo compartilhado no header) ou ativar JWT.
- 🟠 **RLS aberta + anon key pública** — a anon key está exposta no HTML público (por design, é client-side), e as policies permitem leitura/escrita anônima. Para um dashboard pessoal sem dados sensíveis é tolerável, mas qualquer um com a URL do site pode ler/alterar as tarefas. Se algum dado sensível entrar, repensar policies.
- 🟢 **anon key vs publishable** — a anon legacy (até ~2036) ainda é válida; existe uma publishable moderna disponível (`sb_publishable_...`) com melhor postura de segurança. Migração opcional.
- A **`service_role` key** (secreta, bypassa RLS) é necessária para Edge Functions que escrevem no banco. Deve viver **apenas** nos secrets da função, nunca no client nem em docs.

---

## 12. Governança / fluxo de trabalho multi-ambiente

Este projeto é editado de **mais de um lugar**. Para evitar conflito e sobrescrita, siga este modelo:

| Tipo de mudança | Onde fazer | Por quê |
|---|---|---|
| **Dados** (criar/editar/remover tarefa ou setor) | Claude.ai (este canal) → Supabase direto | Não toca código, não gera conflito de merge. É o uso ideal aqui. |
| **Código pesado** (features, refactor, UI) | **Claude Code (VS Code)** | Tem as skills locais (Superpowers/GSD/Impeccable) que o Claude.ai não tem. |
| **Hotfix de emergência** (sem PC) | Claude.ai → GitHub API / `deploy_dashboard` | Aceitável, **desde que** puxe do GitHub antes e committe de volta. |
| **Planejamento / decisão** | Projeto de planejamento ("Meu Diário") | Discussão, não execução. **Não peça código aqui** — se pedir, o agente vai commitar e furar o sync. |

**Regra de ouro (resolve o problema de "dois agentes ao mesmo tempo"):**
> **O GitHub é o juiz único.** Antes de **qualquer** edição de código, em qualquer janela: **puxe do GitHub** (`git pull` ou `curl` do raw). Depois committe de volta. A função `push-to-github` pega o SHA atual antes de commitar, então duas escritas **não simultâneas** não se sobrescrevem cegamente — o perigo real é (a) editar uma **cópia local defasada** e (b) editar o **mesmo arquivo simultaneamente** em dois lugares. Evite os dois.

**Por que cópias defasadas são o risco número 1:** os arquivos anexados a projetos do Claude.ai (e cópias locais não sincronizadas) **não acompanham os commits automáticos**. Quando o pipeline remoto commita (ex.: `de2a7aa`), a cópia local fica atrás. Editar a partir dela = sobrescrever features que já estão no ar. **Sempre parta do GitHub.**

---

## 13. Glossário / shorthand do dono

O dono usa abreviações e às vezes dita por áudio (sujeito a erros de transcrição). Convenções:
- `3v` = prioridade 3 · `wl` = wowlog · `urg` = urgente · `iai` = Agência IAI
- "Suplente" = contexto político/mandato (campanha, candidatos, prefeitura, SETUR, etc.)
- Erros comuns de transcrição de áudio a desconfiar: "hub"→"rubie", "Uly"→"Ulie", "order"→"ourdé", além de "schedule"/"shipment". Na dúvida, perguntar "quis dizer X em vez de Y?".

---

## 14. Roadmap / itens em andamento

- **Agente de bidding uShip** — Edge Functions `bidding-agent` e `bidding-pricer` já existem (v1), ligadas à operação WowLog/uShip. Trabalho em progresso.
- **Malory Connect** — empresa nova (modelo similar à WowLog); já é setor fixo no dashboard.
- Consertar/decidir o destino de `fetch-source` + `deployments` (snapshot).
- Limpeza: `dashboard_data` (morta) e linha redundante de `maloryconnect` em `custom_sectors`.
- Hardening de segurança (token, JWT, RLS) conforme seção 11.

---

## Apêndice — comandos SQL úteis

```sql
-- Criar tarefa
INSERT INTO public.tasks (title, sector, priority, status, due_date)
VALUES ('Título', 'wowlog', 5, 'pendente', '2026-06-10T12:00:00Z');

-- Listar tarefas ativas de um setor (lembre: priority ASC = mais urgente primeiro)
SELECT title, priority, status, due_date
FROM public.tasks
WHERE sector = 'maloryconnect' AND status <> 'excluido'
ORDER BY priority ASC;

-- Contagem por setor (exclui lixeira)
SELECT sector, count(*) FROM public.tasks
WHERE status <> 'excluido' GROUP BY sector;

-- Adicionar coluna com segurança
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS nova_coluna text DEFAULT '';

-- Criar setor customizado
INSERT INTO public.custom_sectors (key, label, emoji, color)
VALUES ('novo', 'Novo Setor', '✨', '#7c6af7');

-- Soft-delete (nunca DELETE direto, exceto limpeza explícita)
UPDATE public.tasks SET status = 'excluido' WHERE id = '<uuid>';

-- Deploy remoto (assíncrono — confirmar depois no GitHub)
SELECT deploy_dashboard('<html completo>', 'feat: descrição');
```

---

*Documento gerado a partir de inspeção ao vivo do Supabase `pyoabyuqbjivqgidrtpi` e do GitHub `MaloryGabrielOxePay/central-de-tarefas@main` em 02/jun/2026. Onde houver conflito entre este documento e o `CLAUDE.md` versionado no repo, atualize o `CLAUDE.md` — este reflete o estado real verificado.*
