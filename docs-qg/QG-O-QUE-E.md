# O que é o QG (Quartel General)

**QG é a sala de comando (o control plane) de uma empresa que opera com agentes de IA.**
É a espinha dorsal que faz uma força de trabalho de inteligência artificial funcionar com
estrutura, governança e responsabilidade, em vez de virar um monte de robôs soltos sem
ninguém no controle.

Uma única instalação do QG pode rodar **várias empresas ao mesmo tempo**. Cada empresa tem
funcionários (os agentes de IA), organograma, metas, orçamentos e gestão de tarefas: tudo
que uma empresa de verdade precisa, só que o "sistema operacional" é software real.

## O problema

Gestor de tarefas comum não dá conta. Quando a sua força de trabalho inteira é de agentes
de IA, você precisa de mais do que uma lista de afazeres: precisa de uma **sala de comando
para a empresa inteira**. Quem está fazendo o quê, quanto está custando, e se está dando
certo.

## O que o QG faz

O QG é o lugar único onde você:

- **Gerencia agentes como funcionários** — contrata, organiza e acompanha quem faz o quê.
- **Define o organograma** — a estrutura dentro da qual os próprios agentes operam.
- **Acompanha o trabalho em tempo real** — a qualquer momento você vê no que cada agente
  está trabalhando agora.
- **Controla custo** — orçamento de tokens por agente (o "salário"), gasto acumulado, ritmo
  de queima.
- **Alinha às metas** — cada agente enxerga como o trabalho dele serve o objetivo maior.
- **Governa a autonomia** — portões de aprovação, trilha de auditoria de tudo que foi feito,
  e limite de orçamento que trava sozinho.

## As duas camadas

### 1. A sala de comando (o QG em si)

O sistema nervoso central. Cuida do cadastro de agentes e do organograma, da atribuição e
do status das tarefas, do controle de orçamento e gasto de tokens, da hierarquia de metas e
do monitoramento de sinal de vida (heartbeat) de cada agente.

### 2. Os serviços de execução (os adaptadores)

Os agentes rodam por fora e reportam para a sala de comando. Os adaptadores conectam
ambientes de execução diferentes: Claude Code, OpenAI Codex, processos de terminal, webhooks
HTTP, ou qualquer runtime capaz de chamar uma API.

A sala de comando **não executa** os agentes. Ela **orquestra** os agentes. Cada agente roda
onde tiver que rodar e "liga para casa" reportando o que fez.

## O princípio central

Você tem que conseguir olhar para o QG e **entender a sua empresa inteira num relance**:
quem está fazendo o quê, quanto está custando, e se está funcionando.

---

## Por que isso importa para a IAI e para os clientes

A IAI (agência de implementação de IA do Grupo Malory) atende empresas de médio e grande
porte que estão trocando software ultrapassado por automação com IA. O QG é a peça que
faltava: depois de colocar agentes de IA para trabalhar dentro de uma empresa, o cliente
precisa de um painel único para comandar, medir e confiar nesse time. O QG é esse painel,
entregue com a marca do próprio cliente (white-label). Ver
[QG-MARCA-E-WHITELABEL.md](QG-MARCA-E-WHITELABEL.md).
