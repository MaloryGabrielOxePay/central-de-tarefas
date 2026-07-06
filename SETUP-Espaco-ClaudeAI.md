# Setup — (Re)criar o Espaço "Central de Tarefas" no Claude.ai

> Passo-a-passo para você voltar a operar o HUB pelo navegador/celular (criar tarefas, editar dados e publicar ajustes de layout remotamente).
> Serve para **criar um espaço novo** OU **atualizar o existente**. Tempo: ~10 min.

---

## Visão geral (o que o espaço vai poder fazer)

- ✅ Criar / editar / mover / consultar **tarefas, pendências e setores** (via conector Supabase).
- ✅ Publicar **ajustes pequenos/médios de layout** remotamente (via `deploy_dashboard`).
- ⚠️ Mudança **grande** de layout continua melhor no **Claude Code** (evita truncar o `index.html`).

---

## Passo 1 — Criar ou abrir o Projeto

1. No Claude.ai (web ou app), vá em **Projects** → **Create project** (ou abra o projeto existente "Central de Tarefas" / "Meu Diário").
2. Nome sugerido: **Central de Tarefas — HUB**.
3. Descrição: "Canal operacional e de emergência do dashboard HUB (dados + hotfix)".

## Passo 2 — ⚠️ Conectar o Supabase NA CONTA CERTA (o passo que mais dá erro)

O projeto Supabase do HUB (`pyoabyuqbjivqgidrtpi`, nome **"Claude"**) está na conta que você **entra pelo GitHub** (MaloryGabrielOxePay). **Não** está nas contas Google (artaudgabriel / gabriel@grupomalory).

1. Nas configurações de **conectores** do Claude.ai, adicione/abra o conector **Supabase**.
2. Ao autenticar, **entre com "Continue with GitHub"** (conta MaloryGabrielOxePay), não com Google.
3. Confirme que o conector enxerga o projeto **"Claude" / `pyoabyuqbjivqgidrtpi`**. (Teste no Passo 5.)
4. Se ele só mostrar projetos da org MaloryV2/Solution Pay → está na conta errada; desconecte e reconecte via GitHub.

## Passo 3 — Colar as Instruções do Projeto

1. Abra **Instruções do projeto** (Project instructions / Custom instructions).
2. Cole **todo** o conteúdo do arquivo **`Instrucoes-Projeto-ClaudeAI.md`** (está na raiz do repo).
3. Salvar.

## Passo 4 — Anexar os arquivos de referência

Anexe ao projeto (Project knowledge / files) os arquivos **atuais** do repo:
- **`index.html`** — o app em produção (fonte para gerar HTML novo). Pegue a versão mais recente em
  `https://raw.githubusercontent.com/MaloryGabrielOxePay/central-de-tarefas/main/index.html`
- **`CLAUDE.md`** — contexto técnico completo (schema, deploy, regras).

> Reanexe o `index.html` sempre que houver mudança grande no app, para o espaço não trabalhar em cima de cópia velha.

## Passo 5 — Teste de fumaça (prove que funciona)

**A) Dados (sem risco):**
- No chat do projeto, peça: *"cria uma task de teste: 'TESTE espaço' no setor pessoal, prioridade 9"*.
- Confirme que ele rodou o INSERT e que a task aparece no app (aba Pessoal / Todas).
- Depois: *"soft-delete a task TESTE espaço"* → confirme que sumiu (foi pra lixeira).

**B) Layout (opcional, mexe em produção — confirme):**
- Peça um micro-ajuste reversível, ex.: *"troca o subtítulo da sidebar de '4 Empresas' para '5 Empresas' e publica"*.
- Ele puxa o HTML do GitHub raw, edita, e roda `deploy_dashboard(...)`.
- Em ~30s confira em `https://darling-arithmetic-ecee8e.netlify.app/`.

## Passo 6 — Como reverter um deploy remoto

Se um deploy sair ruim:
- **Pelo espaço:** peça *"reverte o último deploy"* → ele pega a versão anterior do `index.html` no GitHub (histórico de commits) e republica via `deploy_dashboard`.
- **No PC (garantido):** no Claude Code, `git revert <commit>` → push → Netlify republica.

---

## Divisão de trabalho recomendada

| Tarefa | Onde |
|---|---|
| Criar/editar/consultar tarefas e setores | **Este espaço (Claude.ai + Supabase)** |
| Ajuste pequeno de layout / hotfix sem PC | **Este espaço** (`deploy_dashboard`) |
| Mudança grande de layout / arquitetura | **Claude Code** (pasta `…\projects\HUB Dashboard Malory`) |
| Backup dos dados (rotina separada do código) | Claude Code (dump para `backups/`) |
| Planejamento / discussão | Projeto "Meu Diário" (sem código) |

---

## Checklist rápido
- [ ] Projeto criado/aberto no Claude.ai
- [ ] Conector Supabase conectado **via GitHub** e enxergando o projeto "Claude"
- [ ] Instruções coladas (`Instrucoes-Projeto-ClaudeAI.md`)
- [ ] `index.html` (raw atual) + `CLAUDE.md` anexados
- [ ] Teste A (dados) passou
- [ ] (Opcional) Teste B (deploy) passou e revertido
