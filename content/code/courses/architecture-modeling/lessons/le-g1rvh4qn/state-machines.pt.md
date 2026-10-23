---
title: "Máquinas de estados: cada estado e cada saída dele"
version: 1
---

**Um diagrama de máquina de estados mostra os estados em que uma coisa pode estar ao longo da vida, e
os eventos que a levam de um estado a outro.** Onde o diagrama de atividade segue um processo, a
máquina de estados segue um objeto: uma passagem, um ônibus, um pagamento. É o diagrama menos usado
deste curso e o que tem mais chance de achar um bug antes de ele ir para produção.

## A notação

- Um **estado** é uma caixa de cantos arredondados, nomeada com um adjetivo ou um particípio:
  *Reservada*, *Paga*, *Embarcada*. É uma condição em que o objeto fica por um tempo, não algo que
  ele faz.
- Uma **transição** é uma seta de um estado para outro, rotulada `evento [guarda] / ação`: o evento
  que a dispara, uma condição opcional que precisa ser verdadeira e uma ação opcional que roda quando
  ela acontece. `cancelada [3 h ou mais antes da partida] / estorno` se lê: *quando a passagem for
  cancelada, se faltarem três horas ou mais para a partida, estorne e mude de estado*.
- O **pseudoestado inicial**, um círculo preenchido, aponta para o estado em que o objeto nasce.
- Um **estado final**, um círculo em volta de um ponto, quer dizer que a vida do objeto nesta máquina
  acabou.
- Um estado pode ter **ações de entrada e de saída**, escritas dentro dele:
  `entrada / inicia timer de 10 min`.
- Estados podem se **aninhar**: um estado composto *Ativa* pode conter *Paga* e *Embarcada*, e uma
  transição saindo de *Ativa* vale para as duas.

## A vida de uma passagem da Carcará

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l04-state\" aria-label=\"Uma máquina de estados de uma passagem da Carcará. Do pseudoestado inicial, a passagem começa em Reservada, cuja ação de entrada inicia um timer de dez minutos. Pagamento recusado é uma transição de Reservada para ela mesma. Pagamento aprovado leva de Reservada a Paga. Passar dez minutos leva de Reservada a Expirada e libera o assento. De Paga: lida na porta leva a Embarcada; cancelada, três horas ou mais antes da partida, estorna e leva a Estornada; partiu sem ser lida leva a Não embarcou.\"><defs><marker id=\"l04-state-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"95.0\" y=\"103.0\" width=\"150.0\" height=\"54.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Reservada</text><text x=\"170.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">entrada / timer de 10 min</text><rect x=\"340.0\" y=\"110.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Paga</text><rect x=\"550.0\" y=\"30.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Embarcada</text><rect x=\"550.0\" y=\"130.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Estornada</text><rect x=\"550.0\" y=\"230.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Não embarcou</text><rect x=\"110.0\" y=\"260.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Expirada</text><circle cx=\"30.0\" cy=\"130.0\" r=\"7\" fill=\"var(--paper)\"></circle><path d=\"M37.0 130.0 L93.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><path d=\"M245.0 130.0 L338.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"292.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">pagamento aprovado</text><path d=\"M170.0 157.0 L170.0 258.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"178.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">passam 10 min</text><text x=\"178.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">/ libera assento</text><path d=\"M140 103 C140 60, 200 60, 200 103\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"170.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">pagamento recusado</text><path d=\"M460.0 120.0 L548.0 58.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"492.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">lida na porta</text><path d=\"M460.0 136.0 L548.0 148.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"500.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">cancelada [≥ 3 h]</text><text x=\"500.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">/ estorno</text><path d=\"M440.0 150.0 L550.0 240.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"470.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">partiu</text><text x=\"470.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">[não lida]</text></svg>", "caption": "Sete transições, cada uma com o rótulo evento [guarda] / ação. O caminho feliz é a linha de cima; quase todo o valor está nas outras setas."}
```

- A passagem nasce **Reservada**, quando o assento é reservado, e na entrada começa um timer de dez
  minutos.
- `pagamento aprovado` a leva para **Paga**. `passam 10 min` a leva para **Expirada**, e o assento é
  liberado.
- De Paga, `lida na porta` a leva para **Embarcada**. `cancelada [≥ 3 h] / estorno` a leva para
  **Estornada**. `partiu [não lida]` a leva para **Não embarcou**.
- Um `pagamento recusado` em Reservada é uma transição **para o próprio estado**: o passageiro pode
  tentar outro cartão, e o timer continua correndo.

Tudo o que vende, confere ou relata alguma coisa sobre uma passagem tem de concordar com este
desenho. A lista offline do app de embarque, por exemplo, contém só passagens em *Paga*: uma passagem
*Expirada* nessa lista deixaria alguém embarcar sem pagar.

## Estados são condições, não passos

O erro mais comum é desenhar um diagrama de atividade com caixas arredondadas: estados chamados
*Validando pagamento*, *Enviando e-mail*, *Salvando*. Isso são coisas que o sistema faz, e duram
milissegundos. Um teste que separa os dois: **você conseguiria consultar o banco amanhã de manhã e
achar uma passagem neste estado?** *Paga*, sim. *Enviando e-mail*, não.

O segundo mais comum é desenhar só o caminho feliz, *Reservada → Paga → Embarcada*, e deixar de fora
as transições que uma passagem de verdade faz todo dia: a expiração, o estorno, o não embarque. O
caminho feliz é a parte que todo mundo já conhece. **O valor de uma máquina de estados está nas setas
em que ninguém pensou**, e é isso que a próxima seção transforma em método.
