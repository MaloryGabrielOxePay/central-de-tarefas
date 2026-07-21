# QG x WhatsApp (Evolution API) — por que travou e como pedir certo

_Diagnóstico gerado em 2026-07-19, direto do banco do Paperclip na VPS2 e da doc oficial._

## Veredito em uma linha

O agente não falhou. **Ele bloqueou corretamente porque o insumo não existe:** a Evolution API
nunca foi instalada em lugar nenhum. Em cima disso, cinco erros de configuração e de uso da
plataforma impediram que a mensagem chegasse até você.

---

## 1. A causa raiz: não havia o que conectar

Verificado na VPS2 (`89.117.76.183`) em 2026-07-19:

| Checagem | Resultado |
|---|---|
| `which docker` | **ausente** |
| pastas `/root/evolution*`, `/opt/evolution*` | **não existem** |
| portas 8080/8081 | **nada escutando** |
| serviços rodando | caddy, cerebro-mcp, hermes-dashboard, hermes-gateway, paperclip, postgres, tailscale. **Nenhum Evolution** |

O próprio agente escreveu isso em `/root/.paperclip/her-5-evolution-api-spike-report.md`:

> Status: bloqueado por insumo operacional ausente.
> Não foi feita conexão real com WhatsApp/Evolution API porque não há credenciais nem número
> descartável/QR disponíveis no ambiente desta execução.

E nomeou as variáveis que faltavam: `EVOLUTION_API_BASE_URL`, `EVOLUTION_API_TOKEN`,
`EVOLUTION_INSTANCE_ID`, `EVOLUTION_WEBHOOK_TOKEN`, `WHATSAPP_ALLOWED_ADMIN_PHONES`,
`WHATSAPP_ALLOWED_OPERATOR_PHONES`.

**Pedir para um agente "conectar o WhatsApp" quando não existe instância, token nem número é
como pedir para o motorista sair com o caminhão antes de comprar o caminhão.**

---

## 2. O Paperclip não tem WhatsApp nativo

Varredura das 169 URLs do sitemap oficial (`docs.paperclip.ing`): **zero menções a WhatsApp.**

O que existe oficialmente:

| Canal | Suporte | Como |
|---|---|---|
| Slack / Discord | Sim, **só saída** | routine agendada, agente notificador, HTTPS POST no webhook ([guia](https://docs.paperclip.ing/how-to/wire-slack-discord-notifications/)) |
| Entrada externa genérica | Sim | routine com trigger `webhook` (URL assinada) ou trigger `api` público |
| WhatsApp | **Não existe** | teria que ser construído: plugin SDK (`@paperclipai/plugin-sdk`, em alpha) ou routine + webhook |

A doc é explícita: o Paperclip **não tem push nativo**. Canal externo é composição, não configuração.

> **Consequência prática:** WhatsApp no QG é obra de engenharia, não item de menu. Nenhum
> agente resolve isso "configurando", porque não há o que configurar.

---

## 3. Os cinco erros de uso da plataforma

### 3.1 Work mode `planning` versus o grito no comentário

As issues estavam em **work mode `planning`**, cujo contrato literal é
*"Update the plan only. Do not write code or perform implementation work."*

Você comentou `IMPLEMENTE O PLANO E EXECUTE!`. O agente respondeu, corretamente:

> o issue está em work mode: planning com diretiva explícita (...). Então NÃO posso implementar
> neste heartbeat sem violar a regra de maior prioridade do Paperclip.

**Comentário não sobrepõe work mode.** Quem manda é o campo, não o texto. Para implementar,
a issue precisa estar em **standard**.

### 3.2 `maxTurnsPerRun` estava em 6

Todo heartbeat morria com `⚠️ Reached maximum iterations (6). Requesting summary...`
antes de terminar qualquer coisa. Ele gastava os 6 turnos só descobrindo o estado e sumarizando.

**Hoje já está em 30** (alguém corrigiu). O default do adapter Claude Code na doc é **300**.

### 3.3 Execution policy pedindo que o agente aprove a si mesmo

A issue HER-3 tem `execution_policy` com duas stages, `review` e `approval`, e em **ambas** o
participante é o próprio Hermes Engineer, com `commentRequired: true`.

Resultado: aquele `Paperclip needs a disposition before this issue can continue.` que apareceu
duas vezes. A issue fica esperando uma decisão que ninguém toma.

### 3.4 Sete issues paradas no Blocked Inbox, sem ninguém responder

Estado atual das issues da cadeia:

| ID | Título | Status |
|---|---|---|
| HER-3 | COMUNICACAO NO WHATS | **blocked** |
| HER-4 | Plano | **blocked** |
| HER-5 | Fase 1: Spike seguro Evolution API | **blocked** |
| HER-6 | Fase 2: Webhook receptor + bridge | **blocked** |
| HER-7 | Fase 3: Política de risco | **blocked** |
| HER-8 | Fase 4: Runbook e healthcheck | **blocked** |
| HER-9 | Integração final: teste ponta-a-ponta | **blocked** |

`blocked` no Paperclip **não é erro, é pedido de decisão**. Existe uma tela para isso
(`/inbox/blocked`) e ela nunca foi trabalhada. Enquanto ninguém dá a disposition, o agente
não tem o que fazer, e é por isso que o último heartbeat foi às **06:09 de hoje**, e desde
então, silêncio.

### 3.5 Credenciais quebradas em dois dos três agentes

68 heartbeats no total, **24 falharam**. Agrupados por erro:

| Erro | Vezes | Tradução |
|---|---|---|
| `acpx_turn_failed: Authentication required` | 9 | credencial de modelo não autenticada |
| `hermes_gateway_api_base_url_invalid: Invalid Hermes gateway apiBaseUrl: malory@grupomalory.com` | 6 | **o email foi colado no campo de URL do adapter** |
| `adapter_failed` | 5 | genérico, decorrente dos acima |
| `configuration_incomplete: no Codex credentials available for managed home .../companies/513e8945...` | 4 | empresa nova, home isolado, sem credencial |

Sobre o último: o Paperclip cria **um home isolado por empresa**. Verificado na VPS, nenhuma
das três empresas tem `auth.json`. O Hermes Engineer funciona porque `hermes_local` lê de
`/root/.hermes/auth.json`, que está fora do home gerenciado. Os agentes `codex_local` (Rafa e
Mike) não têm de onde ler, então: `Rafa = error`, `Mike = idle`.

---

## 4. Outros erros encontrados (não relacionados ao WhatsApp)

1. **Três empresas onde deveria haver uma linha clara.** `Grupo Malory` (`e7b2ebf1`, a original,
   dona de tudo que funciona), `Grupo Malory v2` (`513e8945`) e `WowLog` (`9b85339a`). As duas
   novas nasceram sem credencial e com agentes quebrados. Decidir: consolidar ou provisionar
   credencial em cada uma.
2. **`Rafa` em estado `error`** desde a criação (04:57 de hoje). Nunca rodou.
3. **Zero plugins instalados, zero webhook deliveries.** A superfície de integração está intacta.
4. **Zero MCP registrado nos agentes.** `toolsets` = `terminal,file,web`, sem `mcp`. O agente
   não enxerga o cérebro nem nenhuma ferramenta externa. Segundo a doc, MCP se pluga no
   **runtime** (`~/.hermes/config.yaml`), não no Paperclip, e o adapter precisa de `mcp` no toolsets.
5. **Zero políticas de orçamento** (`budget_monthly_cents = 0` nos três agentes, `budget_policies`
   vazia). Nenhum teto de gasto ativo.
6. **O site promete o que a plataforma não faz.** `QG-SITE\onboarding.html` vende
   *"Atender e fechar pedido no WhatsApp 24/7"* e *"Perde venda no WhatsApp fora de hora"*
   para o segmento Loja/Varejo. Hoje isso não existe no produto. Risco comercial direto.

---

## 5. Como pedir certo (o método)

### Ordem correta, sempre

```
1. INSUMO   → a coisa existe? (servidor, token, número, credencial)
2. AGENTE   → tem credencial válida, toolsets certos, turnos suficientes?
3. ISSUE    → work mode standard, critério de aceite verificável, sem policy circular
4. TRIGGER  → atribuir (acorda sozinho) ou `paperclipai agent wake`
5. INBOX    → responder o blocked no mesmo dia, senão tudo congela
```

O erro do pedido original foi começar no passo 3 com o passo 1 vazio.

### Anatomia de um pedido que funciona

| Campo | Errado | Certo |
|---|---|---|
| Título | `COMUNICACAO NO WHATS` | `Instalar Evolution API na VPS2 e expor healthcheck em loopback` |
| Work mode | `planning` | `standard` |
| Descrição | 4 bullets de intenção | pré-requisitos já resolvidos + passos + critério de aceite binário |
| Execution policy | review + approval no próprio agente | nenhuma, ou aprovador **humano** |
| Escopo | "conecte o WhatsApp" (5 sistemas) | uma entrega verificável por issue |
| Pré-requisito | implícito | **explícito e já satisfeito antes de atribuir** |

### Frase-modelo

> Objetivo: `<uma coisa só>`.
> Pré-requisitos já resolvidos: `<lista, com caminhos e nomes reais>`.
> Faça: `<passos>`.
> Critério de aceite: `<comando que eu rodo e vejo passar>`.
> Não faça: `<limites duros>`.
> Se faltar insumo: pare, marque blocked e nomeie exatamente o que falta.

O agente já cumpre a última linha sozinho. O que faltou foi alguém **ler** o blocked.

---

## 6. Gate aberto (decisão do Gabriel)

Para destravar a cadeia HER-3 é preciso, nesta ordem:

1. **Onde roda a Evolution API.** VPS2 (junto do QG) ou VPS1 (isolada). A VPS2 não tem Docker;
   instalar Docker nela é mudança de infra em produção.
2. **Qual número.** Chip descartável, e o QR precisa ser escaneado **por você**, no celular.
   Nenhum agente faz isso.
3. **Quem fala com quem.** Só você manda comando, ou operadores também? Vira a allowlist.

Enquanto os três não forem respondidos, qualquer issue nova trava exatamente no mesmo ponto,
e o agente vai escrever o mesmo blocker de novo, com razão.

---

## Fontes

- Banco do Paperclip na VPS2 (leitura direta): `companies`, `agents`, `issues`, `issue_comments`,
  `issue_work_products`, `heartbeat_runs`, `agent_runtime_state`, `approvals`, `plugins`.
- `/root/.paperclip/her-5-evolution-api-spike-report.md` e `her-3-whatsapp-hermes-operational-spec.md`.
- Doc oficial `docs.paperclip.ing`: work modes, blocked inbox, approvals, execution policy,
  adapters, routines, plugin SDK, guia de MCP.
