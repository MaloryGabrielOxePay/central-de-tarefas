# QG — tradução pt-BR e eliminação do nome legado

> Como o app fica em português, por que o nome da base open-source ainda aparecia em alguns
> lugares, o que foi corrigido, e como continuar traduzindo sem quebrar nada.
> Fonte viva do código: `QG\QG-IAI\ui\src\brand-i18n.ts` e `brand-dict.pt-BR.ts`.

## Como o motor funciona (importante antes de mexer)

O upstream tem encanamento de i18n mas com catálogos praticamente vazios: as strings visíveis
são **inglês hardcoded** nos componentes. Em vez de editar centenas de componentes (e viver em
inferno de rebase), o fork traduz o **DOM renderizado**:

- `ui/src/brand-i18n.ts` roda um `MutationObserver` e troca **apenas nós de texto cujo valor
  exato** bate com uma chave do dicionário. Conteúdo do usuário (título de tarefa, nome de
  agente) nunca casa, então nunca é alterado.
- Também passa pelos atributos `placeholder`, `title` e `aria-label`.
- Pula o que está dentro de `script, style, code, pre, [contenteditable], [data-no-translate]`.
- Idioma: cookie `qg_locale` + `localStorage brand.locale`. Trocar recarrega a página.
  O cookie chega ao servidor, então o email de reset sai no idioma certo.

**Ordem da tradução (a pegadinha central):**

```
1. dicionário (match exato)  -> se bater, retorna e PARA
2. substituições de nome do produto -> \bPaperclip\b vira brand.appName
```

Ou seja: **uma entrada de dicionário vence o scrub de nome**. Se o dicionário mapear uma frase
para um valor que ainda contenha o nome antigo, o nome antigo aparece na tela mesmo com o scrub
ligado. Foi exatamente esse o bug corrigido abaixo.

`brand.appName` = `Quartel General` (default), `appNameShort` = `QG`, `appNameEn` por env.

## O que estava vazando (corrigido, commit `41f4c204`)

Três pontos, todos **visíveis ao usuário**:

| Onde | Era | Virou | Por que vazava |
|---|---|---|---|
| `brand-dict.pt-BR.ts` | `"Paperclip host": "Host Paperclip"` | `"Host QG"` | dicionário casa antes do scrub |
| `brand-dict.pt-BR.ts` | `"Paperclip": "Paperclip"` | `"QG"` | idem (rótulo de fonte de skill) |
| `ui/src/context/BreadcrumbContext.tsx` | `buildDocumentTitle` com `"Paperclip"` fixo | `brand.appName` | escreve em `document.title`, que fica **fora do `body`**, então o observer nunca alcança |

## O que continua com o nome antigo (interno, invisível)

Não é vazamento de marca e **não deve ser renomeado** (quebra build/deploy):

- Pacotes npm `@paperclipai/*`, repo GitHub `MaloryGabrielOxePay/paperclip-whitelabel`,
  clone de deploy `/root/paperclip-fork`.
- Comentários HTML do build (`<!-- PAPERCLIP_RUNTIME_BRANDING_START -->`, `..._FAVICON_...`).
- Chave de `localStorage` `paperclip.theme`.
- Identificadores de CSS: `::highlight(paperclip-doc-annotation-*)` e as variáveis
  `--paperclip-doc-annotation-*` (geram 4 warnings cosméticos no build, não são erro).

Nada disso aparece como texto para o usuário. Se um dia quiser limpar por completo, o CSS e a
chave de tema são renomeáveis com pouco risco; pacotes e repo, não.

## Leva grande de tradução (commit `3080420c`)

Dicionário passou de **379 para 1662 chaves** (+1283).

**Método (repetível):** 4 subagentes varreram o app por área, colhendo strings de UI em inglês
que ainda não estavam no dicionário, com tradução pt-BR já pronta. Depois um script fez o merge:
decodifica entidades HTML nas chaves, pula as que já existiam, reserializa com `JSON.stringify`
(literal JS sempre válido) e **valida que o dicionário inteiro parseia antes de gravar**.

| Área varrida | Cobertura |
|---|---|
| Shell e home | Sidebar, Layout, paleta de comandos, diálogos de criação, Painel, Caixa de entrada, Atividade, Busca, Linha do tempo |
| Agentes e adapters | Agentes, detalhe, novo agente, organograma, gerenciador de adapters, formulário de config, campos de todos os adapters |
| Trabalho | Workspaces de execução e de projeto, skills da empresa |
| Admin, custos e onboarding | Ambientes, configurações da instância, perfis, segredos, plugins, auth do CLI, convites, bootstrap, assistente de onboarding |

**O que continua em inglês (limitação do motor):** strings interpoladas ou com contador
(`{n} tarefas`, `Duration: ...`), porque o match é exato e o texto varia em runtime. Para
traduzir essas seria preciso mexer no componente (fora do padrão atual do fork).

## Como adicionar tradução nova (checklist)

1. Pegue a string **exatamente como renderiza** (pontuação, reticências `…` vs `...`, apóstrofo
   curvo `’` vs reto `'`). Se não bater 100%, o motor simplesmente ignora, em silêncio.
2. Se a fonte tiver entidade HTML (`&amp;`, `&gt;`), a chave precisa do caractere **decodificado**
   (`&`, `>`), porque o nó do DOM já vem decodificado.
3. **Não traduzir palavras funcionais soltas** (`For`, `in`, `to`): elas casam em qualquer lugar
   do app e traduzem coisa errada globalmente.
4. Valor sempre com **QG**, nunca o nome antigo. **Sem travessão.**
5. Aspas duplas dentro da string precisam de escape (`\"`).
6. Antes de commitar, garanta que o arquivo parseia (um erro de sintaxe derruba o i18n inteiro
   e o app volta todo para inglês).

## Estado e deploy

- Commits na branch `malory/whitelabel-base`: `41f4c204` (nome legado) e `3080420c` (tradução).
- **Deployados em produção em 2026-07-19** (`qg.grupomalory.com`), via o loop de
  `QG-IAI\deploy\QG-DEPLOY.md`. Depois do deploy é preciso **hard-refresh** (Ctrl+Shift+R):
  o service worker gruda o shell antigo.

## Pendente

- Segunda passada: detalhe de tarefa, rotinas e aprovações a fundo, mais os arquivos de
  workspace que ficaram fora do escopo da varredura (`LocalWorkspaceRuntimeFields`,
  `runtime-json-fields`, `PathInstructionsModal`).
- Decidir se vale traduzir as strings interpoladas (exige tocar componente).
