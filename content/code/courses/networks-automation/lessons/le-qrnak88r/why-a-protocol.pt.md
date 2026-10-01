---
title: O que o CLI não pode prometer
version: 1
---

A aula 1 enviou configuração como linhas de texto, uma depois da outra, e a aula 2 a enviou como
JSON para uma API que aplicava cada requisição por conta própria. As duas têm uma fraqueza que
aparece no dia em que uma mudança tem mais de uma parte. **Se a terceira linha de cinco é
recusada, as duas primeiras já estão em vigor**, e o equipamento fica num estado que ninguém
projetou: nem a configuração antiga nem a nova.

O NETCONF, RFC 6241, foi escrito por gente que passou por isso. É um protocolo para configuração
e nada mais, e ele faz quatro promessas que o CLI não faz:

- **Estrutura.** A configuração é uma árvore de dados definida por um **modelo YANG**, não texto a
  ser interpretado. Todo elemento tem um nome, um tipo e um lugar. A aula 5 é sobre os modelos.
- **Datastores separados.** Uma mudança é escrita numa configuração **candidate**, verificada, e
  só então vira **running**. Há um terceiro, **startup**, para aquilo com que o equipamento liga.
- **Transações.** Um commit aplica o candidate inteiro ou nada dele.
- **Um caminho de volta.** Um **confirmed commit** se desfaz sozinho a menos que seja confirmado a
  tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os três datastores do nc1. O edit-config de um script escreve no candidate. O validate confere o candidate contra o modelo YANG. O commit copia o candidate inteiro para o running, a configuração em vigor, ou nada se alguma parte for inválida. O discard-changes volta o candidate ao running. O copy-config escreve o running no startup, aquilo com que o equipamento liga.\"><defs><marker id=\"ds-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um script</text><text x=\"85.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ncclient</text><rect x=\"220\" y=\"110\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">candidate</text><text x=\"295.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma cópia de trabalho</text><rect x=\"450\" y=\"110\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">running</text><text x=\"525.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em vigor</text><rect x=\"450\" y=\"230\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">startup</text><text x=\"525.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lido ao ligar</text><path d=\"M152 140 L216 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ds-ah)\"></path><text x=\"184\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">edit-config</text><path d=\"M372 132 L446 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ds-ah)\"></path><text x=\"409\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">commit</text><path d=\"M446 152 L374 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ds-ah)\"></path><text x=\"409\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">discard-changes</text><path d=\"M525 172 L525 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ds-ah)\"></path><text x=\"535\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">copy-config</text><path d=\"M295 108 L295 70 L250 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"90\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"170.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">validate</text><text x=\"295\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conferido contra o YANG</text><text x=\"525\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tudo, ou nada</text></svg>", "caption": "Uma edição nunca toca o running diretamente. Ela passa a valer no commit, inteira, ou não passa.", "same": ["candidate", "running", "startup", "validate", "ncclient"]}
```

O **RESTCONF**, RFC 8040, põe os mesmos dados e os mesmos modelos atrás de HTTPS. É o REST da aula
2 com os recursos definidos pelo YANG em vez de por quem escreveu a API. A seção 09 usa ele.

O equipamento desta aula é o **`nc1`**. O plano de gerência dele é o Clixon, software livre sobre
o qual produtos reais são construídos: ele guarda uma configuração no formato dos modelos padrão
`ietf-interfaces` e `ietf-ip`, verifica toda mudança contra eles, e serve NETCONF na porta 830 e
RESTCONF na porta 443. **O `nc1` não encaminha tráfego nenhum.** As interfaces dele só existem na
configuração, que é tudo de que esta aula precisa, porque o que ela ensina é como a configuração é
alterada.
