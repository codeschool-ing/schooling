---
title: Cotas, e os trinta dias depois da exclusão
version: 1
---

Nada nesta seção foi rodado. As cotas são contadas pelo Google e o ciclo de vida de um projeto é do
Resource Manager, e o laboratório não responde por nenhum dos dois; o que segue vem da documentação do
Google, com os comandos nomeados para você reconhecê-los numa conta real.

## Cotas

**Uma cota é um teto que o Google põe por projeto**, e ela existe para proteger os dois lados: o Google
de um cliente descontrolado, e o cliente de uma fatura descontrolada. Há dois tipos:

- **cotas de alocação** contam o que existe: quantas CPUs virtuais em `southamerica-east1`, quantos
  endereços externos, quantas redes. Criar um a mais do que a cota permite é recusado.
- **cotas de taxa** contam pedidos no tempo: quantas chamadas a uma API por minuto. Passar do limite é
  recusado com `429` e `RESOURCE_EXHAUSTED` até o minuto virar.

As cotas são por projeto e, para a maioria dos recursos, por região, então um projeto pode ter espaço
para 24 CPUs em São Paulo e 8 em Santiago. As cotas de um projeto novo são pequenas de propósito, e
aumentar uma é um pedido, feito na página *Cotas* do console ou com
`gcloud beta quotas preferences create`; a maioria é concedida em minutos, e as grandes passam por
revisão. **Pedir aumento na semana do lançamento é o erro clássico**: o pedido é barato e a revisão
não é instantânea.

Uma cota é também o único teto que o cliente pode **baixar**. A cota de taxa de uma API pode ser posta
abaixo do padrão, o que a transforma num limite: a lição 12 usa isso para limitar quanto uma API pode
custar.

## O ciclo de vida

Um projeto é criado **`ACTIVE`**. Apagá-lo não o apaga: o projeto passa a **`DELETE_REQUESTED`**, tudo
dentro dele para de servir, e a cobrança dos recursos dele para. Por **trinta dias** ele pode ser
restaurado com `gcloud projects undelete planner-reports`, por alguém que tenha o papel para isso.
Depois dos trinta dias o Google o apaga de vez, com tudo que há dentro, e o id fica ocupado para sempre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l03-life-cycle\" aria-label=\"O ciclo de vida de um projeto, da esquerda para a direita. Criado, o projeto está ACTIVE. Um pedido de exclusão o leva a DELETE_REQUESTED: os recursos param de servir e de ser cobrados. Por trinta dias um undelete o traz de volta a ACTIVE, desenhado como uma seta que volta. Depois de trinta dias o Google o apaga de vez, e o id fica ocupado para sempre. Acima da primeira seta, duas proteções que recusam o pedido de exclusão: um lien no projeto, e o deletion_policy PREVENT no Terraform.\"><defs><marker id=\"l03-life-cycle-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l03-life-cycle-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l03-life-cycle-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"110.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ACTIVE</text><text x=\"110.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">servindo e cobrado</text><rect x=\"280.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DELETE_REQUESTED</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parado, sem cobrança</text><rect x=\"540.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></rect><text x=\"620.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">apagado</text><text x=\"620.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o id continua ocupado</text><path d=\"M192.0 128.0 L276.0 128.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-paper)\"></path><text x=\"234.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">excluir</text><path d=\"M276.0 156.0 L192.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-phosphor)\"></path><text x=\"234.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">undelete</text><path d=\"M442.0 140.0 L536.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-life-cycle-af-ah-paper-dim)\"></path><text x=\"489.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">após 30 dias</text><rect x=\"120.0\" y=\"22.0\" width=\"230.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"235.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusam a exclusão:</text><text x=\"235.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um lien no projeto</text><text x=\"235.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">deletion_policy = &quot;PREVENT&quot;</text><path d=\"M235.0 78.0 L235.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por trinta dias a exclusão pode ser desfeita; depois, nada a desfaz</text></svg>", "caption": "Apagar um projeto liga um relógio de trinta dias, e duas proteções impedem o relógio de ligar."}
```

Duas proteções impedem uma exclusão que não deveria acontecer:

- **Um lien** é uma marca no projeto que recusa a exclusão enquanto estiver lá. O Google põe alguns ele
  mesmo: um projeto que hospeda uma rede compartilhada, lição 18, leva um, porque apagá-lo cortaria todo
  projeto que usa a rede. Pessoas podem pôr o seu num projeto que nunca pode ser apagado por acidente.
- **O `deletion_policy` do Terraform.** Desde a versão 6 do provider, um `google_project` leva
  `deletion_policy = "PREVENT"` a não ser que o arquivo diga outra coisa, e é por isso que ele apareceu
  no plano da lição 2 sem ser escrito. Um `terraform destroy` que chegue a um projeto assim falha antes
  de mandar qualquer coisa. Pô-lo como `"DELETE"` é uma decisão que alguém toma num diff que outra
  pessoa lê.

**Apagar um projeto é o jeito mais seguro de parar de pagar pelo que há nele**, porque nada dentro de um
projeto sobrevive a isso. É também o jeito mais seguro de perder o que há nele, e é por isso que os
trinta dias e as duas proteções existem.
