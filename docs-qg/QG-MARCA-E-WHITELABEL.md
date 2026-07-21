# QG — Marca e modelo white-label

Como o QG é fabricado uma vez pela IAI e revendido com a cara de cada cliente. Este é o
resumo de navegação; a fonte técnica viva é `QG-IAI\WHITELABEL.md` (no repo).

## Hierarquia de marca (3 camadas)

Entender isto é o coração do produto.

| Camada | O quê | Varia por cliente? | Onde vive (técnico) |
|---|---|---|---|
| **Produto** | "Quartel General" / "QG" | **Não** (fixo) | default de `ui/src/brand.ts` |
| **Fabricante (IAI)** | logo `iai.png` + `iaiqg.com` | **Não** (fixo) | constantes `vendor*` do `brand.ts` |
| **Cliente** | logo + nome + cor + formato da logo | **Sim** | `ui/.env.<slug>` + `ui/public/brands/<slug>/` |

- A **IAI fabrica** a plataforma. O produto é o **QG**.
- O **Grupo Malory**, apesar de dono da IAI, aqui é **um cliente** usando a ferramenta.
- Onde aparece o **produto** (QG), aparece o **fabricante** (logo da IAI ao lado).
- Onde aparece a **instância** (o painel grande de login), aparece o **cliente** (logo + nome).

### Onde cada peça aparece na tela de login

```
   [ LOGO DO CLIENTE, grande, sobre fundo animado ]   cliente (redonda ou quadrada)
                 QUARTEL GENERAL                       produto (fixo; em inglês: Quantum Governance)
                  <nome do cliente>                    cliente (dinâmico)
   rodapé:   [logo iAi]  iaiqg.com                     fabricante (a marca da IAI vive só aqui)
```

## Nome do produto por idioma

- Português: **Quartel General**
- Inglês: **Quantum Governance**
- A troca é automática pelo idioma da interface. Sigla sempre **QG**.

## Filosofia técnica

**Um código-base + um arquivo de configuração e um conjunto de assets por cliente.
Nunca copiar o app inteiro por cliente.** Um cliente = um `ui/.env.<slug>` + uma pasta
`ui/public/brands/<slug>/`. A base sem cliente já renderiza como **QG puro**.

## Domínios

- **App / login:** servido sob `grupomalory.com`. Ativo hoje: `qg.grupomalory.com` (Malory).
  Possíveis: `iai.grupomalory.com`, `iaiqg.grupomalory.com`.
- **Marca do fabricante (rodapé):** `iaiqg.com` (domínio próprio da IAI, já registrado e
  verificado; também usado para enviar o email de reset de senha, `noreply@iaiqg.com`).
- **Favicon universal:** o "iAi" vermelho da IAI, igual em todo cliente, em todas as páginas
  e subdomínios. Não muda por cliente.

## Fluxo "novo cliente X" (revenda IAI)

1. Copiar a pasta base de assets e trocar pelos assets do cliente
   (`cp -r ui/public/brands/_base ui/public/brands/<slug>`).
2. Copiar o modelo de configuração e preencher nome, cor, logo, idioma e formato
   (`cp ui/.env.template ui/.env.<slug>`).
3. Dicionário de idioma só se for outro idioma além de pt-BR.
4. Build com a marca do cliente (`--mode <slug>`).
5. Deploy na **VPS do cliente** (o cliente contrata a infraestrutura e o motor de LLM; a
   IAI implanta).

**Sem tocar em código-fonte.** Detalhe passo a passo em `WHITELABEL.md` e
`ui/public/brands/_base/README.md` (no repo).

## Regra de propagação (cliente x modelo base) — obrigatória

Toda mudança pedida no contexto de **um cliente** (ex: Grupo Malory) precisa ser
classificada antes de fechar a tarefa:

1. **Cliente-específica** (identidade visual, regra de negócio só dele) -> fica só no cliente.
2. **De plataforma** (reset de senha, idioma, login, mobile, qualquer melhoria que todo
   cliente deveria ter) -> entra no **modelo base** e vale para todos.

**Na dúvida:** aplicar primeiro no cliente pedido e depois **perguntar** se replica no
modelo base e nos clientes em andamento. Nunca replicar no base em silêncio, nem deixar uma
melhoria de plataforma presa a um cliente.

## O que fica com nome legado (só encanamento interno)

Nomes internos de pacote e de runtime (`@paperclipai/*` e afins), endpoints e adaptadores
mantêm o naming da base open-source: **não aparecem para o usuário** e renomear quebraria o
build. A remoção do nome antigo é da **camada visível** (título, textos, marca), feita por um
mecanismo que troca o wordmark em tempo de execução. Para o cliente e para o discurso de
produto, é sempre **QG**.
