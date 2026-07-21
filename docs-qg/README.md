# QG (Quartel General) — documentação central

> Você está em **`QG\QG-DOCS\`**, a documentação de produto e negócio do QG.
> A pasta-mãe **`QG\`** reúne tudo: código em `QG\QG-IAI\`, operação por tenant em
> `QG\QG-Grupo-Malory\` e `QG\QG-WowLog\`, revenda SaaS em `QG\QG-SAAS\`.
> Índice mestre da pasta-mãe: [`..\README.md`](../README.md).

**QG = Quartel General** (nome em português) / **Quantum Governance** (nome em inglês).
Produto da **IAI** (a agência de implementação de IA do Grupo Malory). Plataforma
white-label, no ar em **`qg.grupomalory.com`**.

Regra de nome (dura): o produto é o **QG**, fabricado pela **IAI**. Não se usa nenhum
outro nome (nem o da base open-source que roda sob o capô), com cliente ou internamente.
Para todos os efeitos, é sempre **QG**.

---

## O que é o QG, em uma frase

A sala de comando de uma empresa que trabalha com agentes de IA: um só lugar para
contratar, organizar, dar metas, controlar custo e auditar tudo que os agentes de IA
fazem, em tempo real. Detalhe em [QG-O-QUE-E.md](QG-O-QUE-E.md).

## Hierarquia de marca (3 camadas) — o coração do white-label

| Camada | O quê | Varia por cliente? |
|---|---|---|
| **Produto** | "Quartel General" / "QG" | Não (fixo) |
| **Fabricante** | IAI (logo + `iaiqg.com`) | Não (fixo) |
| **Cliente** | logo + nome + cor + formato da logo | **Sim** (um arquivo por cliente) |

A IAI **fabrica** o QG e o **revende** com a marca de cada cliente. O Grupo Malory, apesar
de dono da IAI, aqui é **um cliente** usando a ferramenta. Detalhe em
[QG-MARCA-E-WHITELABEL.md](QG-MARCA-E-WHITELABEL.md).

## Status atual (2026-07-18)

- **No ar:** `qg.grupomalory.com` (tenant do Grupo Malory), servido da VPS2.
- **Marca Malory:** cor `#2436A8`, logo redonda, idioma pt-BR, tema `comando`.
- **Login cinematográfico**, **pt-BR em tempo real**, **mobile dark**.
- **Reset de senha por email funcionando** (`noreply@iaiqg.com`, domínio verificado).
- **Modelo white-label pronto** para montar o próximo cliente sem tocar em código.

---

## Mapa: onde cada coisa mora (tudo dentro de `QG\`)

| Camada | Onde | Papel |
|---|---|---|
| **Documentação de produto (aqui)** | `QG\QG-DOCS\` | Navegação, o-que-é, marca, registro de produto |
| **Código-fonte** | `QG\QG-IAI\` | O app: `server/`, `ui/`, `cli/`, `deploy/`, `WHITELABEL.md`, `CLAUDE.md` |
| **Cliente Grupo Malory** | [`..\QG-Grupo-Malory\`](../QG-Grupo-Malory/) | Tudo do tenant que está no ar |
| **Cliente WowLog** | [`..\QG-WowLog\`](../QG-WowLog/) | Tenant WowLog (switch no mesmo login) |
| **Revenda SaaS (modelo base)** | [`..\QG-SAAS\`](../QG-SAAS/) | O produto vendável, fluxo de novo cliente, `clientes\` |
| **Registro do produto (comercial + técnico)** | [`QG-PRODUTO.md`](QG-PRODUTO.md) | O que a equipe vende, prospecta, vira landing page |
| **Memória / decisões** | Cérebro, pasta `10-Agencia-IAI/` | Notas QG (marca, temas, reset, domínios) |
| **Material comercial da agência** | `...\Agência Inteligente\Agência IAI\produtos\QG\` | Mesma cópia do registro de produto, para o time comercial |
| **Servidor de produção** | VPS2 (`89.117.76.183`), `/root/paperclip-fork` | Onde roda o app; deploy em `..\deploy\QG-DEPLOY.md` |

> **Nota sobre nomes legados:** a pasta do projeto se chama `QG-IAI`. O que permanece com
> nome antigo é só o **encanamento interno** que não dá para trocar sem quebrar o
> build/deploy: os nomes de pacote (`@paperclipai/*`), o repo no GitHub
> (`MaloryGabrielOxePay/paperclip-whitelabel.git`) e o clone da VPS2 (`/root/paperclip-fork`).
> **Nada disso aparece para o cliente nem entra no discurso de produto.** Para todos os
> efeitos de comunicação, o produto é o QG.

---

## Navegação rápida

- **"O que é isso?"** -> [QG-O-QUE-E.md](QG-O-QUE-E.md)
- **"Como funciona o white-label / a marca?"** -> [QG-MARCA-E-WHITELABEL.md](QG-MARCA-E-WHITELABEL.md)
- **"O que a gente vende? Como faço uma LP?"** -> [QG-PRODUTO.md](QG-PRODUTO.md)
- **"Como o app fica em português? Cadê o nome antigo?"** -> [QG-I18N-PT-BR.md](QG-I18N-PT-BR.md)
- **"E aquele copiloto dentro do app?"** -> [QG-COPILOTO-IN-APP.md](QG-COPILOTO-IN-APP.md)
- **"Onde está o site público (iaiqg.com)?"** -> [../QG-SITE/README.md](../QG-SITE/README.md)
- **"O que está no ar para o Grupo Malory?"** -> [../QG-Grupo-Malory/README.md](../QG-Grupo-Malory/README.md)
- **"E o tenant WowLog?"** -> [../QG-WowLog/README.md](../QG-WowLog/README.md)
- **"Como monto um cliente novo?"** -> [../QG-SAAS/README.md](../QG-SAAS/README.md)
- **Deploy, rollback, código** -> `..\QG-IAI\deploy\QG-DEPLOY.md` e `..\QG-IAI\WHITELABEL.md`

---

## Fontes de verdade (para não duplicar)

Esta pasta `QG-DOCS/` é a camada de **leitura e navegação**. As fontes vivas continuam:

- **Código, deploy, build:** o repo `QG\QG-IAI\` (`WHITELABEL.md`, `CLAUDE.md`,
  `deploy/QG-DEPLOY.md`, `docs/`).
- **Histórico de decisões e sessões:** cérebro, `10-Agencia-IAI/`.

Se algo aqui divergir do código ou do cérebro, **o código manda no técnico e o cérebro
manda na decisão**. Este índice aponta; não substitui.
