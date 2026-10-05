---
title: Escolher a linha, ou duas
version: 1
---

O limiar de 0.5 da seção anterior era um padrão que ninguém escolheu. **Movê-lo troca um tipo de erro
pelo outro**, e a troca é mais fácil de ver em spam, onde os scores do substituto são espalhados:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category spam --sweep
category spam: 10 of 60 messages labelled spam by a person
threshold  flagged  precision  recall
     0.1       13       0.69    0.90
     0.2       13       0.69    0.90
     0.3       12       0.75    0.90
     0.4       12       0.75    0.90
     0.5       10       0.80    0.80
     0.6        8       0.88    0.70
     0.7        6       1.00    0.60
     0.8        5       1.00    0.50
     0.9        2       1.00    0.20
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Precisão e recall do substituto para spam com limiares de 0.1 a 0.9. A precisão sobe de 0.69 para 1.00 e o recall cai de 0.90 para 0.20; em 0.5 os dois são 0.80.\"><text x=\"20\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">spam, 60 mensagens: precisão e recall conforme o limiar sobe</text><line x1=\"80\" y1=\"250.0\" x2=\"560\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"none\"></line><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><line x1=\"80\" y1=\"145.0\" x2=\"560\" y2=\"145.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"72\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><line x1=\"80\" y1=\"40.0\" x2=\"560\" y2=\"40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"80.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"140.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><text x=\"200.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"260.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><text x=\"320.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"380.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><text x=\"440.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.7</text><text x=\"500.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><text x=\"560.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.9</text><text x=\"320.0\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">limiar</text><polyline points=\"80.0,105.1 140.0,105.1 200.0,92.5 260.0,92.5 320.0,82.0 380.0,65.2 440.0,40.0 500.0,40.0 560.0,40.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><circle cx=\"80.0\" cy=\"105.1\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"140.0\" cy=\"105.1\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"200.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"260.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"320.0\" cy=\"82.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"380.0\" cy=\"65.2\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"440.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"500.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"560.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"574\" y=\"40.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">precisão</text><polyline points=\"80.0,61.0 140.0,61.0 200.0,61.0 260.0,61.0 320.0,82.0 380.0,103.0 440.0,124.0 500.0,145.0 560.0,208.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><circle cx=\"80.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"140.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"200.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"260.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"320.0\" cy=\"82.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"380.0\" cy=\"103.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"440.0\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"500.0\" cy=\"145.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"560.0\" cy=\"208.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"574\" y=\"208.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recall</text><line x1=\"320.0\" y1=\"40\" x2=\"320.0\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"320.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5, o limiar medido primeiro</text></svg>", "caption": "Subir o limiar compra precisão com recall. As duas linhas se cruzam em 0.5, e cada ponto é uma linha do `guard modeval --sweep` acima.", "same": ["recall"]}
```

Em 0.1 o filtro pega 9 das 10 mensagens de spam, e 4 das 13 que ele marca são legítimas. Em 0.7 nada
legítimo é marcado e 4 mensagens de spam passam. Nenhuma linha é a certa em geral. **A linha certa é
aquela cujos erros a Tarefa prefere aguentar**, e isso depende do custo de cada erro:

- uma mensagem legítima bloqueada custa a quem escreveu: um freelancer cujo link de portfólio nunca
  aparece, o `m38`, perde trabalho e talvez nunca saiba por quê;
- spam publicado custa a quem lê: um golpe que chega a cem freelancers são cem chances de alguém
  perder dinheiro.

Para spam num marketplace, muitas equipes pendem para o recall e aceitam alguns bloqueios, desde que
quem escreveu seja avisado e possa recorrer. Para uma categoria em que uma mensagem perdida pode ferir
alguém, como ameaças, a inclinação para o recall é ainda maior. A inclinação é uma decisão, e, como a
métrica de justiça da aula 9, vai por escrito com os números que a justificaram.

## Um score que não se espalha

A mesma varredura em assédio fica diferente:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --sweep
category harassment: 15 of 60 messages labelled harassment by a person
threshold  flagged  precision  recall
     0.1       15       0.73    0.73
     0.2       15       0.73    0.73
     0.3       15       0.73    0.73
     0.4       15       0.73    0.73
     0.5       15       0.73    0.73
     0.6       15       0.73    0.73
     0.7       11       0.82    0.60
     0.8        9       0.78    0.47
     0.9        4       0.75    0.20
```

De 0.1 a 0.6 nada muda, porque o menor score que uma mensagem de assédio recebe do substituto é 0.6, e
toda mensagem sem palavra da lista marca 0. Uma lista de palavras produz um punhado de valores
distintos, então a maioria dos limiares é o mesmo limiar. Classificadores reais produzem scores mais
espalhados, mas **um score não é automaticamente uma probabilidade**: um 0.8 de um fornecedor não
significa que 80% dessas mensagens são assédio. A varredura sobre o seu próprio conjunto rotulado é o
que diz o que um score significa na sua plataforma.

## Duas linhas e três faixas

Uma linha só força toda mensagem a ser *bloqueada* ou *publicada*. A maioria das plataformas traça
duas, e a faixa entre elas vai para uma pessoa:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --review 0.5 --block 0.85 --show
category harassment: 15 of 60 messages labelled harassment by a person
  publish m08 0.00  u r an id1ot
  publish m10 0.00  Seu idiota, ninguém te contrata
  publish m11 0.00  Vai catar coquinho, incompetente
  publish m15 0.00  Such a brilliant idea, genius. Really.
  block   m32 0.90  He called me an idiot in the chat, can a moderator look?
lane     score        labelled yes  labelled no
block    >= 0.85              4            1
review   0.50-0.85            7            3
publish  <  0.50              4           41
```

Acima de 0.85, a mensagem é bloqueada na hora: 4 mensagens de assédio e 1 que não é. Entre 0.5 e
0.85, dez mensagens esperam por um moderador, e 7 delas são assédio. Abaixo de 0.5, as 41 mensagens
limpas são publicadas junto com 4 que não deviam, o que nenhum limiar conserta, porque todas marcam 0.

Leia a única mensagem da faixa de bloqueio que não devia estar lá. É o `m32`, a pessoa relatando que
foi chamada de idiota, **bloqueada automaticamente** porque um relato repete o insulto palavra por
palavra. Uma faixa de bloqueio precisa de salvaguardas próprias exatamente por isso: quem escreveu é
avisado do motivo, há como recorrer, e as mensagens bloqueadas automaticamente são amostradas e lidas
por uma pessoa toda semana, porque a faixa de bloqueio é onde ninguém olha.

Mais três coisas mantêm o arranjo honesto:

- **Meça as faixas por categoria.** O 0.85 que serve para assédio não diz nada sobre ameaças ou spam.
- **Devolva as decisões dos moderadores como rótulos.** Cada mensagem revisada na faixa do meio é um
  exemplo rotulado novo, então o conjunto em que os limiares foram escolhidos não para de crescer.
- **Rode o conjunto de novo quando o endpoint mudar.** Um fornecedor atualiza o classificador sem
  perguntar, e o mesmo texto pode ter outro score no mês que vem. Fixe uma versão quando o fornecedor
  oferecer, e rode o conjunto rotulado periodicamente quando não oferecer.
