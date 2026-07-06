# CLAUDE.md — Central de Tarefas · HUB Grupo Malory

> Contexto operacional lido automaticamente pelo Claude Code.
> **Para o handoff técnico completo** (arquitetura detalhada, dívida técnica, segurança, governança) ver **`HANDOFF-central-de-tarefas.md`** na raiz.
> **Estado verificado ao vivo em 02/jun/2026** contra Supabase e GitHub. Onde algo aqui divergir do código, o código (`main`) é a verdade — corrija este arquivo.

---

## ⚠️ Regras de ouro (antes de tocar em qualquer coisa)

1. **Fonte única da verdade = este repo no GitHub.** Antes de editar: **`git pull`**. Nunca edite a partir de cópia local defasada nem de arquivo anexado a projeto Claude.ai (eles ficam atrás dos commits automáticos do pipeline remoto).
2. **Prioridade é INVERTIDA:** `1` = mais urgente, `10` = menos urgente. O dono fala "8/10 = importante" — é o oposto do app. Ver seção Prioridade.
3. **App single-file, sem build.** Erro de JSX **quebra a tela inteira** (página branca) e só aparece no console (F12). Teste sempre abrindo a página de verdade.
4. **Soft-delete sempre** (`status='excluido'`). `DELETE` real só em ação explícita de "excluir permanente".
5. **Divisão de trabalho:** dados (tarefas/setores) → mexer via Supabase; código → aqui no Claude Code, sempre com `pull` antes.

---

## Projeto

| Campo | Valor |
|---|---|
| Nome | Central de Tarefas / HUB · Grupo Malory |
| Dono | Gabriel Brito Artaud (Malory) — João Pessoa-PB, fuso UTC−3 |
| URL produção | https://darling-arithmetic-ecee8e.netlify.app/ |
| Repo | `github.com/MaloryGabrielOxePay/central-de-tarefas` (branch `main`, arquivo `index.html`) |
| **Pasta local (canônica)** | `C:\Users\artau\.claude\projects\HUB Dashboard Malory` — clone git único, **trabalhar SEMPRE aqui**. `C:\MaloryHub` descontinuado (consolidado nesta pasta em 06/jul/2026). |
| Deploy (atual) | Push no `main` → Netlify republica em ~30s |
| **Host preferido (alvo)** | **Coolify ou Vercel** (preferência do dono, 06/jul/2026). Netlify segue live até migrar. Migração de host = tarefa **gated** (DNS/produção) — não flipar sem confirmar. |
| **Vercel (paralelo, live)** | `https://hub-central-tarefas.vercel.app` — deploy paralelo do `index.html` (06/jul/2026), Netlify **intacto**. Projeto `malorygabrieloxepays-projects/hub-central-tarefas`, `ssoProtection` desligado (público, paridade c/ Netlify). Deploy manual do scratchpad hoje; **cutover** (ligar Git→Vercel = push vira deploy) pendente. Descartar: `vercel remove hub-central-tarefas --yes --token $VERCEL_TOKEN --scope malorygabrieloxepays-projects`. |
| Título da página | `HUB · Grupo Malory` |

---

## Arquitetura

App **single-file** (`index.html`), sem build step. Tudo via CDN:

- **React 18** (unpkg) + **ReactDOM 18** (unpkg)
- **Babel Standalone** (unpkg) — transpila o JSX **no navegador**
- **Supabase JS v2** (jsdelivr) — backend + realtime
- **Fontes:** **Inter** (corpo) + **Space Grotesk** (títulos) — Google Fonts
- **CSS puro** com custom properties (`:root` / `body.light` / `body.dark`)
- **Light + Dark mode** (toggle; default light)
- **localStorage** como cache/fallback

Editar o HTML = editar o app. Não há `package.json` nem `node_modules`.

---

## Supabase

| Config | Valor |
|---|---|
| Project ID | `pyoabyuqbjivqgidrtpi` |
| URL | `https://pyoabyuqbjivqgidrtpi.supabase.co` |
| Status | `ACTIVE_HEALTHY` |
| Plano | Free tier — **pausa após inatividade** (causa dashboard em branco; reativar é não-destrutivo) |
| **Conta dona** ⚠️ | Supabase **logado via GitHub** (MaloryGabrielOxePay / oxepaybr@gmail.com). O projeto aparece como **"Claude"** na **MaloryGabrielOxePay's Org** (free). **NÃO** está nas contas Google `artaudgabriel@gmail.com` nem `gabriel@grupomalory.com` (essas = orgs MaloryV2 / Solution Pay). Pra dashboard/management (editar Edge Functions, secrets, PAT): no Supabase, **Continue with GitHub**. Descoberto 06/jul/2026. |

⚠️ **Anon key:** a chave anon legacy está embutida no `index.html` (válida até ~2036). **Antes de gerar HTML, confirme a key atual** via `Supabase:get_publishable_keys`. Existe também uma publishable moderna (`sb_publishable_...`) recomendada para o futuro. Nunca hardcode sem confirmar.

### ⚙️ MCP dedicado do HUB — `supabase-hub` (isolado do wowlog)

O conector Supabase global (`~/.mcp.json`, server `supabase`) está **pinado no projeto wowlog** (`pyvcjpngdyirnykzfnzw`) e é OAuth/claude.ai — **não usar pro HUB** (risco de mexer no wowlog + o ref wowlog estava dando 504 em 06/jul). Em vez disso, o HUB tem um MCP **próprio, local (stdio), isolado**, versionado em **`.mcp.json` na raiz deste repo**:

```json
{ "mcpServers": { "supabase-hub": {
  "command": "npx",
  "args": ["-y","@supabase/mcp-server-supabase@latest","--project-ref=pyoabyuqbjivqgidrtpi"],
  "env": { "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN_HUB}" } } } }
```

- **Sem OAuth** — autentica por **Personal Access Token** (`sbp_...`) do Supabase, lido da env var Windows **`SUPABASE_ACCESS_TOKEN_HUB`** (nunca no git; o `.mcp.json` só referencia).
- **Escopado ao ref do HUB** (`--project-ref=pyoabyuqbjivqgidrtpi`) → blast radius = só o HUB. Não toca o server `supabase`/wowlog.
- **Setup (1×):** gerar PAT em supabase.com/dashboard/account/tokens → `setx SUPABASE_ACCESS_TOKEN_HUB "sbp_..."` (reabrir o terminal/Claude Code) → o server `supabase-hub` aparece nas tools ao rodar o Claude Code **nesta pasta**.
- **Fallback Windows:** se `npx` não subir direto, trocar `command` por `cmd` e prefixar `["/c","npx",...]`.
- **Sem MCP:** operações de **dados** (backup/leitura de `tasks`/`custom_sectors`) funcionam via REST + anon key direto (RLS aberta) — foi como o backup de 06/jul foi feito. Só operações de **management** (edge functions, migrations) exigem o `supabase-hub` autenticado.

### Tabela `public.tasks` (principal)

| Coluna | Tipo | Default | Notas |
|---|---|---|---|
| id | uuid | gen_random_uuid() | PK |
| sector | text | 'wowlog' | categoria de negócio |
| title | text | — | obrigatório |
| description | text | '' | nullable |
| status | text | 'pendente' | CHECK: pendente/aguardando/concluido/excluido |
| priority | integer | 2 | CHECK 1–10 — **escala invertida** |
| comments | jsonb | '[]' | array de `{text, date}` |
| due_date | timestamptz | null | prazo |
| created_at | timestamptz | now() | |
| updated_at | timestamptz | now() | sempre `new Date().toISOString()` |
| **manual_order** | integer | 0 | **ordem do drag & drop** (toggle "Reordenar" na Visão Geral) |
| **subtasks** | jsonb | '[]' | checklist de sub-itens `{id,text,done}` + barra de progresso (HUB v2, 06/jul/2026) |

### Tabela `public.custom_sectors`

`id` (uuid) · `key` (text, unique) · `label` (text) · `emoji` (text, def 🏢) · `color` (text, def #7c6af7) · `created_at`.
Setores customizados aparecem **depois** dos fixos na sidebar. Hoje contém só `suplente`.

### Tabela `public.deployments` — histórico (3 linhas em 06/jul/2026)

Schema: `id` (bigint identity), `html_content`, `commit_message`, `status`, `commit_sha`, `created_at`.
`deploy_dashboard()` grava aqui a cada deploy remoto. Mesmo assim, para **"puxar o HTML atual"** use o **GitHub raw** (`raw.githubusercontent.com/.../main/index.html`) — é a fonte da verdade; a tabela pode ficar atrás.

### Tabela `public.dashboard_data` — **legada/morta** (0 linhas)

Resquício de arquitetura antiga (blob jsonb). O app atual **não usa**. Candidata a `DROP`.

### Edge Functions (Deno/TS) — todas `ACTIVE`, `verify_jwt: false`

| Slug | Papel |
|---|---|
| `push-to-github` | Recebe `{content, message}`, commita **`index.html`** no `main`. ✅ **v4 (06/jul/2026)**: só `Deno.env.get("GITHUB_TOKEN")` + guard, fallback hardcoded removido. |
| `fetch-source` | Deveria snapshotar o HTML em `deployments` — **não grava hoje**. |
| `bidding-pricer` | Precificação bidding uShip (WIP). |
| `bidding-agent` | Agente bidding uShip (WIP). |

---

## Setores (categorias de negócio) — ordem real

Definidos em `DEFAULT_SECTORS` no `index.html` (fixos) + `custom_sectors` (custom).

| Ordem | key | Label | Emoji | Cor |
|---|---|---|---|---|
| 1 | `maloryconnect` | Malory Connect | 🔗 | #14b8a6 |
| 2 | `wowlog` | Wowlog | 📦 | #38bdf8 |
| 3 | `iai` | Agência IAI | 💡 | #eab308 |
| 4 | `entretenimento` | Malory Entretenimento | 🎪 | #ec4899 |
| 5 | `oxepay` | Oxepay | 💳 | #34d399 |
| 6 | `pessoal` | Pessoal / Malory | 👤 | #a78bfa |
| 7 | `escritorio` | Escritório Geral | 🏢 | #fb923c |
| — | `suplente` | Suplente (contexto político/mandato) | 💼 | azul (custom) |

> Setor **fixo** novo → editar `DEFAULT_SECTORS` + deploy. Setor **temporário** → inserir em `custom_sectors` (a UI já faz). Existe uma linha redundante de `maloryconnect` em `custom_sectors` (de quando era custom) — inofensiva, pode limpar.

---

## ⚠️ Prioridade — escala INVERTIDA (maior fonte de confusão)

No app, `1`–`10`:

| Faixa | Label | Cor | Ordenação |
|---|---|---|---|
| 1–2 | Urgente | vermelho | primeiro |
| 3–4 | Alta | amarelo | |
| 5–7 | Média | azul | |
| 8–10 | Baixa | verde | por último |

O dono pensa "maior = mais urgente" (oposto). Se inserir as prioridades "como ele fala", os itens importantes viram **"Baixa" (verde) no fim** e a aba "Urgente" (só ≤2) fica vazia → falso "dashboard em branco". **Decisão atual: manter literal.** Não inverter sem alinhar com o dono.

`manual_order` tem precedência sobre `priority` na ordenação (fallback para priority quando ambos `null`).

---

## Features atuais

Componentes: `App`, `GeralView`, `SectorView`, `ConcluView`, `TrashView`, `CalendarWidget`, `TaskCard`, `DraggableTaskCard`, `ProgrTab`, `TaskModal`.

- **Programação** — drag & drop (mouse + touch) reordenando via `manual_order`, com diálogo de sugestão de prioridade.
- **Visão Geral** — sub-abas 🔥 Urgente / 📅 Calendário / 📋 Todas; stat cards clicáveis que filtram; busca; filtro por setor.
- **Por setor** — uma view por setor (ignora a confusão de prioridade; boa pra conferência).
- **Concluídos** / **Lixeira** — restaurar, editar, excluir permanente.
- **Calendário interativo** — dots por prioridade nos dias com `due_date`, tooltip, ações inline.
- **Realtime** via `sb.channel('tasks-changes').on('postgres_changes', ...)`.
- **Mobile responsive** (sidebar vira hambúrguer < 768px).
- **Inline controls** no card: prioridade (picker 1–10), data, progressão de status, comentários.

---

## Regras de código

1. Tudo em um único `index.html` — nunca separar CSS/JS.
2. React funcional com hooks (`useState`, `useEffect`, `useCallback`, `useMemo`, `useRef`).
3. CSS via custom properties no `:root`/`body.light`/`body.dark`; responsivo com media queries (`max-width:768px`).
4. Sem libs extras além de React, Babel e Supabase.
5. Nomenclatura: kebab-case (CSS), camelCase (JS). Seções com `// ─── NOME ───`.
6. Timestamps sempre `new Date().toISOString()`.
7. Migrations de coluna: `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` (obrigatório).
8. Manter light **e** dark mode funcionando.
9. Soft-delete por padrão.

---

## Deploy

> **Host preferido = Coolify ou Vercel** (decisão do dono, 06/jul/2026). Hoje o gatilho ainda é Netlify (push no `main`). Migrar para Coolify/Vercel é tarefa separada e **gated** (mexe em DNS/produção) — confirmar antes. Enquanto não migrar, os fluxos abaixo valem para o Netlify atual.

**A — Git local / Claude Code (mudanças grandes):**
```bash
git pull origin main          # SEMPRE antes de editar
# editar index.html
git add index.html
git commit -m "feat: descrição"
git push origin main          # Netlify deploya em ~30s
```

**B — Remoto via Supabase (sem PC):**
```sql
SELECT deploy_dashboard('<html completo>', 'feat: descrição');
```
`pg_net` é assíncrono — confirmar no GitHub depois. (Tabela `deployments` vazia hoje; valide.)

**C — GitHub API direto** (pega SHA atual e dá PUT em `index.html`).

Gatilho final em todos: push no `main` → Netlify.

---

## SQL — operações comuns

```sql
-- Criar tarefa (priority literal: 1=urgente ... 10=baixa)
INSERT INTO public.tasks (title, sector, priority, status, due_date)
VALUES ('Título', 'maloryconnect', 5, 'pendente', '2026-06-10T12:00:00Z');

-- Listar ativas de um setor (priority ASC = mais urgente primeiro)
SELECT title, priority, status, due_date FROM public.tasks
WHERE sector = 'wowlog' AND status <> 'excluido' ORDER BY priority ASC;

-- Contagem por setor
SELECT sector, count(*) FROM public.tasks WHERE status <> 'excluido' GROUP BY sector;

-- Setor customizado
INSERT INTO public.custom_sectors (key, label, emoji, color)
VALUES ('novo', 'Novo Setor', '✨', '#7c6af7');

-- Soft-delete
UPDATE public.tasks SET status = 'excluido' WHERE id = '<uuid>';
```

---

## Segurança (pendências)

- ✅ **Token GitHub hardcoded — RESOLVIDO (06/jul/2026).** `push-to-github` **v4** usa só `Deno.env.get("GITHUB_TOKEN")` + guard (throw se ausente); fallback `ghp_` removido; secret `GITHUB_TOKEN` criado. Deploy feito via **Management API** (editor do dashboard estava fora por incidente). Pendente só: revogar o `ghp_` antigo (começa `ghp_tZTs`) no GitHub + rotacionar o github_pat interino (passou pelo chat).
- 🟠 Edge Functions com `verify_jwt: false` — invocáveis sem auth.
- 🟠 RLS aberta — anon lê/escreve tudo (ok p/ app pessoal, mas qualquer um com a URL acessa).

---

## Governança / fluxo multi-ambiente

| Mudança | Onde | Por quê |
|---|---|---|
| Dados (tarefa/setor) | Claude.ai → Supabase | não toca código, sem conflito |
| Código pesado | **Claude Code (aqui)** | tem as skills locais (Superpowers/GSD/Impeccable) |
| Hotfix sem PC | Claude.ai → GitHub API / `deploy_dashboard` | ok, com pull antes |
| Planejamento | projeto "Meu Diário" | discussão, **nunca código** |

**Regra de ouro:** GitHub é o juiz único. Antes de qualquer edição de código, `git pull`. `push-to-github` pega o SHA atual antes de commitar, então escritas não-simultâneas não se atropelam — o risco real é cópia defasada ou edição simultânea no mesmo arquivo.

---

*Atualizado em 02/jun/2026 a partir de inspeção ao vivo do Supabase `pyoabyuqbjivqgidrtpi` e do GitHub `main`. Substitui a versão anterior, que estava desatualizada (fontes, dark mode, setores, `manual_order`).*
