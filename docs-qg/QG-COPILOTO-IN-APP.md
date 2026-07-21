# QG — copiloto embutido no app (registro de decisão)

> **Status: PARQUEADO no desenho.** Direção escolhida, mapa do código levantado, nenhuma linha
> de código escrita. Próximo passo é fechar o desenho antes de implementar.
> Levantado em 2026-07-19.

## O que o Gabriel pediu

Um chat no canto inferior direito do frontend do QG, com o conhecimento de toda a documentação,
para ajudar quem está começando a configurar. Além do passo a passo: aberto a perguntas, capaz
de **ajudar a configurar o próprio QG**, apontar erros, e **enxergar o que o usuário está
fazendo** para ter sincronia. Objetivo declarado: derrubar a curva de aprendizado.

Ele descartou a opção mais simples (onboarding dinâmico só com fases e passo a passo) em favor
da completa.

## Decisões travadas

| Pergunta | Decisão |
|---|---|
| **O que ele pode fazer** | **Configura com confirmação.** Propõe a ação (criar empresa, criar agente, definir orçamento, ligar heartbeat), mostra o que vai fazer, o usuário aprova, aí executa. Não age sozinho. |
| **O que ele enxerga** | **Estado do app via API** (página atual, empresas, agentes, tarefas, custos, aprovações, o que falta configurar). Ver a tela de verdade (DOM/screenshot) fica para uma fase 2. |
| **Para quem** | **Feature de plataforma:** vai para o modelo base white-label, todo tenant ganha o copiloto com a marca dele. |
| Conhecimento | A documentação do QG. Nunca citar o nome da base open-source. |

Isso casa com a filosofia do produto: o copiloto **não fura a governança, ele usa** a mesma
mecânica de aprovação que o QG já prega.

## Mapa do código (levantado, vale ouro para quem for implementar)

| Peça | Onde | Situação |
|---|---|---|
| **Molde já existente** | `QG-IAI\ui\src\pages\BoardChat.tsx` + `server\src\routes\board-chat.ts` | "Board Concierge Chat": já faz *gerenciar a empresa conversando*, com skill como system prompt, streaming SSE e sinais `%%ACTIONS%%` para a UI agir. **Mas** exige `deploymentMode === "local_trusted"` + flag experimental, então fica **inerte no QG hospedado**. É molde, não produto. |
| **Runtime de chat** | `@assistant-ui/react` (já instalado) via `ui\src\hooks\usePaperclipIssueRuntime.ts` + `IssueChatThread.tsx` | Pronto para reusar na UI do widget |
| **Onde montar o widget** | `ui\src\components\Layout.tsx` (bloco de overlays, junto de paleta de comandos e toasts) | Shell autenticada, dentro de todos os providers (empresa, tema, query) |
| **Ler estado** | `ui\src\api\*` (companies, agents, issues, costs, approvals, budgets, dashboard, heartbeats, activity, goals, adapters) | Tudo escopado por `companyId`, cookie de sessão automático |
| **Contexto atual** | `ui\src\context\CompanyContext.tsx` (`selectedCompany`) + rota | É assim que o copiloto sabe "onde o usuário está" |
| **Executar ação** | `companies.create`, `agents.create`/`hire`, `budgets.createPolicy`, config de adapter, `instance/settings` | Mesmas rotas que a UI já usa |
| **Auth** | better-auth por cookie; no servidor `getActorInfo` / `assertCompanyAccess` (`server\src\routes\authz.ts`) | Rota nova deve reusar isso antes de ler ou escrever |
| **LLM hoje** | Não existe chamada direta do app para a API da Anthropic. Só (a) adapters do runtime de agente e (b) o relay do board-chat, que dá `spawn("claude")` e está travado em `local_trusted` | Define as opções abaixo |

## Abordagens avaliadas

**1. Rota nova no servidor + API da Anthropic direta + widget assistant-ui**
Endpoint SSE espelhando o board-chat, mas chamando a API direto (chave no servidor, sem
depender do CLI, sem a trava `local_trusted`). Leitura de estado no servidor; ações o modelo só
**propõe**, a UI mostra card de confirmação e o **browser executa pela API existente com a sessão
do usuário** (zero escalonamento de privilégio). *Era a recomendação técnica: funciona no modo
hospedado, baixa latência, reusa tudo.*

**2. Reusar o runtime de agente/heartbeat (chat = comentários de issue)  ← ESCOLHIDA**
O copiloto vira um agente do próprio QG; a conversa acontece como comentários numa issue e o
agente responde no heartbeat (é o padrão que o `OnboardingChat` já usa hoje). Dogfood puro: as
ações dele já passam pela aprovação nativa do produto.

**3. Loop no browser + proxy burro**
Menos código de servidor, porém frágil e com conhecimento e loop expostos no cliente. Descartada.

## Riscos da escolhida (a resolver no desenho)

Registrado com honestidade para a próxima sessão não tropeçar:

1. **Galinha e ovo.** O copiloto existe para ajudar quem chega do zero, mas a abordagem 2 exige
   um agente já configurado para funcionar. Mitigação a desenhar: semear um agente-copiloto
   junto com a criação da empresa (ou no bootstrap do tenant), já com adapter e chave do próprio
   ambiente, sem depender do usuário configurar nada.
2. **Latência de heartbeat.** Não tem sensação de chat ao vivo. Mitigação: acordar sob demanda
   (`wake on demand` já existe na política de execução) em vez de esperar o timer, e mostrar
   estado de progresso na UI como o `OnboardingChat` faz.
3. **Custo.** Cada turno de conversa é uma execução de agente, contabilizada em custos. Definir
   faixa de modelo econômica para o copiloto.

## Próximo passo

Fechar o desenho (arquitetura, contrato de ações e confirmação, semeadura do agente, UI do
widget), escrever a spec e só então implementar. Como é **feature de plataforma**, entra no
modelo base e afeta todos os tenants: seguir a regra de propagação de `QG-IAI\CLAUDE.md`.
