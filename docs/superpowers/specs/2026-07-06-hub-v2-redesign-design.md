# HUB v2 — Redesign completo (spec)

**Data:** 2026-07-06 · **Projeto:** Central de Tarefas (HUB · Grupo Malory) · **Arquivo alvo:** `index.html` (single-file)

## Objetivo
Atualização completa "senior dev": corrigir bug de clique, mesclar Programação na Visão Geral, elevar o visual (impeccable, polindo a identidade atual), adicionar 4 funções, e garantir responsividade mobile. Entregar no ar (Vercel gated), sem tela branca.

## Restrições (invariantes — não quebrar)
- **Single-file** `index.html`: React 18 + Babel standalone (JSX no browser) + Supabase JS, **sem build**. Erro de JSX = tela branca.
- **Prioridade INVERTIDA:** 1–2 Urgente, 3–4 Alta, 5–7 Média, 8–10 Baixa. Não inverter.
- **Light + dark mode** ambos funcionando (custom properties em `:root`/`body.light`/`body.dark`).
- Realtime Supabase (`sb.channel('tasks-changes')`), soft-delete (`status='excluido'`), **publishable key** (`sb_publishable_...`). Não mexer em RLS/keys.
- 7 setores fixos (maloryconnect 1º) + custom_sectors. `manual_order` para drag-reorder.
- Fontes Inter (corpo) + Space Grotesk (títulos). Manter o roxo (--accent) como identidade.

## Bug: card não abre
**Causa (verificada ao vivo):** só o `<span class="task-title">` tem `onClick={()=>onEdit(task)}`. O resto do card não abre → no celular/toque impreciso parece "não abre".
**Fix:** a área principal do card (`task-body`, exceto os controles interativos) abre o modal de edição ao clicar/tocar. Badges (status/prioridade/data), botões (💬 ✏️ 🗑), checkbox de seleção e o handle de drag chamam `e.stopPropagation()` para NÃO abrir o modal. Alvo de toque ≥ 44px no mobile.
Varredura adicional durante implementação: pickers (fecham no outside-click?), dark mode, overflow horizontal mobile, empty states.

## Merge: Programação → Visão Geral
Hoje Programação existe como item de sidebar (`currentView`) E/OU sub-modo (`geralTab==='programacao'`). Alvo:
- Remover o item **"🗓️ Programação"** da sidebar.
- Dentro da Visão Geral, um toggle **"Reordenar"** (ícone ↕) entra no modo drag-and-drop inline sobre a lista atual: arrastar persiste `manual_order` (função `reorder_tasks`/`onSaveOrder`), mantendo o diálogo de sugestão de prioridade. Fora do modo Reordenar, a lista é a normal.
- Uma só view, zero função perdida. Reaproveitar `ProgrTab`/`DraggableTaskCard` como o modo Reordenar embutido.

## Funções novas
1. **Quick-add:** input no topo da Visão Geral — digitar + Enter cria a task (status `pendente`, setor = filtro atual ou default) sem abrir modal. Parse leve opcional: `#setor` seta setor, `!N` seta prioridade (ex.: "ligar cliente #wowlog !2"). Sem match → task simples.
2. **Agrupar por** (segmented control): **Nenhum** (padrão) · **Setor** · **Prazo** (Atrasado / Hoje / Esta semana / Depois / Sem data) · **Prioridade** (Urgente/Alta/Média/Baixa). Cabeçalhos de grupo com contagem. Ordena dentro do grupo por prioridade ASC (respeitando manual_order quando aplicável).
3. **Seleção múltipla + ações em massa:** checkbox por card (aparece no hover/long-press). Barra de ações flutuante quando ≥1 selecionada: mudar status, mudar prioridade, mudar setor, excluir (soft-delete). Um único round de updates no Supabase.
4. **Subtarefas/checklist:** nova coluna `subtasks jsonb DEFAULT '[]'` em `public.tasks` (array de `{id, text, done}`). No modal e no card: lista de sub-itens marcáveis + barra de progresso (% done). Adicionar/remover/marcar sub-item persiste em `subtasks`.

## Visual (impeccable — polir identidade)
- Refinar hierarquia, espaçamento e ritmo (Things 3 / Linear como âncora de calma/premium). Cards mais limpos e respirados; badges consistentes; densidade confortável.
- Micro-interações **em CSS** (hover, abrir/fechar picker, check de subtarefa, seleção) — sem lib de animação externa (single-file/CDN → jank).
- Manter roxo como accent; light + dark impecáveis.
- **Mobile:** alvos de toque maiores, cards adaptados, sidebar hambúrguer revisada, sem overflow horizontal. Validar a 375px.

## Data model
- Migration única, aditiva: `ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS subtasks jsonb NOT NULL DEFAULT '[]'::jsonb;` (projeto HUB `pyoabyuqbjivqgidrtpi`, via Management API). Baixo risco, reversível (`DROP COLUMN` se preciso). Nenhuma outra mudança de schema.

## Componentes (alvo)
`App` (estado global, quick-add, seleção, agrupar) · `Sidebar` (sem Programação) · `GeralView` (unificada: quick-add + agrupar + toggle Reordenar + seleção) · `TaskCard` (card clicável, checkbox, subtarefas inline) · `TaskModal` (com editor de subtarefas) · `ReorderList` (ex-ProgrTab/DraggableTaskCard) · `SectorView`/`ConcluView`/`TrashView`/`CalendarWidget` (herdam melhorias). Manter o arquivo em seções `// ─── NOME ───`.

## Testes / verificação
- Testar **local (file://)** no browser ANTES do push (deploy é direto pra prod).
- Verificar no browser (via `?k=9877`) **desktop E mobile 375px**, de forma humana: renderiza (sem tela branca), abrir/editar task pelo card, mudar status, reordenar, quick-add, agrupar, seleção em massa, subtarefas, light+dark.
- 0 erro fatal no console (favicon 404 é benigno).

## Deploy / rollback
- Push no `main` → Vercel auto-deploy (gated 9877) + Netlify redireciona. Confirmar no ar (browser).
- Rollback: `git revert <commit>` → push (dados têm backup separado; migration `subtasks` é aditiva).

## Fora de escopo (YAGNI)
Login/auth (Opção 2 da RLS — adiado), RLS Fase B (adiado), animação por lib externa, multi-usuário, notificações push.
