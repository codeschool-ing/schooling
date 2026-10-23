---
title: Quatro tipos de documento, que envelhecem de jeitos diferentes
version: 1
---

**Um conjunto de documentação falha com os leitores quando uma página tenta ensinar, instruir,
listar e explicar ao mesmo tempo.** O **Diátaxis**, de Daniele Procida, separa a documentação
técnica em quatro tipos conforme o que o leitor está fazendo, e essa separação acaba importando
tanto para manter as páginas vivas quanto para lê-las.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l11-diataxis\" aria-label=\"Os quatro tipos de documento numa grade de dois por dois. Na horizontal: passos práticos à esquerda, conhecimento teórico à direita. Na vertical: aprender ou estudar no alto, trabalhar embaixo. Tutorial: aprender, prático. Explicação: estudar, teórico. Guia prático: trabalhar, prático. Referência: trabalhar, teórico. Cada célula tem um exemplo da Carcará.\"><rect x=\"160.0\" y=\"40.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"84.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Tutorial</text><text x=\"295.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">siga uma compra</text><text x=\"295.0\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">na primeira semana</text><rect x=\"440.0\" y=\"40.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"84.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Explicação</text><text x=\"575.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">por que o embarque</text><text x=\"575.0\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">funciona sem rede</text><rect x=\"160.0\" y=\"170.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Guia prático</text><text x=\"295.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">adicionar um meio</text><text x=\"295.0\" y=\"245.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de pagamento</text><rect x=\"440.0\" y=\"170.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Referência</text><text x=\"575.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o catálogo de</text><text x=\"575.0\" y=\"245.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">containers</text><text x=\"295.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">passos práticos</text><text x=\"575.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">conhecimento teórico</text><text x=\"150.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">aprender, estudar</text><text x=\"150.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">trabalhar</text><text x=\"435.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a referência apodrece em silêncio: gere ou confira</text></svg>", "caption": "Uma página que tenta ser os quatro tipos ao mesmo tempo é a primeira a morrer, porque nenhum tipo de manutenção serve para ela.", "same": ["Tutorial"]}
```

| tipo | o leitor está… | um exemplo de arquitetura na Carcará | como envelhece |
| --- | --- | --- | --- |
| **tutorial** | aprendendo, num exercício guiado | *sua primeira semana: siga uma compra de passagem pelo sistema* | quando um passo para de funcionar; o recém-chegado descobre no primeiro dia |
| **guia prático** | trabalhando, e precisa chegar a um objetivo | *como adicionar um meio de pagamento* | quando o procedimento muda; quem o segue descobre |
| **referência** | trabalhando, e precisa consultar algo | o catálogo de containers; os formatos de evento | em silêncio: ninguém lê do começo ao fim, então os itens errados sobrevivem |
| **explicação** | estudando, e quer entender o porquê | *por que o embarque funciona sem rede*; os registros de decisão | devagar: os motivos continuam verdadeiros por mais tempo que qualquer outra coisa |

## Por que o tipo decide a manutenção

A coluna da direita é o que a Carcará usou. **Cada tipo recebe a manutenção que o seu envelhecimento
pede**:

- **Tutoriais e guias práticos falham alto**, porque alguém os segue passo a passo. Precisam de um
  dono que responda quando um recém-chegado diz *o passo quatro não funciona*, e de pouco mais.
- **A referência falha em silêncio**, e por isso é o tipo que mais vale **gerar** a partir da fonte
  da verdade, ou **conferir** contra ela automaticamente. O catálogo de containers da Carcará é
  gerado a partir da configuração de implantação; os formatos de evento, a partir dos schemas no
  código.
- **A explicação é a que envelhece melhor**, mas cada peça leva uma data, porque um motivo é
  verdadeiro *a partir* do momento em que foi escrito. Registros de decisão são explicação, e é por
  isso que a aula 5 os congelou.

## Dividir uma página misturada

A página mais lida da Carcará se chamava *Embarque*. Começava com uma visão geral de por que o
embarque funciona sem rede (explicação), depois dava os passos para preparar um celular de teste
(guia prático), depois listava os endpoints de sincronização (referência), depois conduzia um
engenheiro novo por uma leitura de bilhete (tutorial). Tinha 14 telas, e a parte de referência
estava dois endpoints desatualizada. Dividida em quatro, cada parte achou o seu dono e a sua
manutenção, e a lista de endpoints passou a ser gerada. **Nada de novo foi escrito; a página só foi
cortada nas linhas do que os leitores estavam fazendo.**
