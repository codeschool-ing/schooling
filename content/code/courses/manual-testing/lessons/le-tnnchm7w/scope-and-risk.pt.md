---
title: Escopo e risco
version: 1
---

**Escopo é uma lista do que vai ser testado e uma lista do que não vai**, e a segunda lista é a que
torna um plano honesto. Todo esforço de teste deixa coisas de fora; um plano que diz isso permite
que os donos do produto decidam se a omissão é aceitável, e um plano que não diz deixa que eles
descubram por um cliente.

## Escrevendo o escopo

Para o boxoffice, a versão em planejamento é a 1.0, e o escopo parte dos requisitos da seção 04
desta aula. No escopo:

- cadastro, confirmação e o e-mail de confirmação (R2, R3);
- reserva, preços e descontos (R4, R5);
- a vida de um pedido, de reservado a usado, cancelado ou reembolsado (R6);
- mensagens de erro (R7);
- as páginas no celular e no desktop, nos quatro navegadores citados (R8);
- uso por teclado e por leitor de tela (R9).

Fora do escopo, cada um com seu motivo:

- **pagamento.** O boxoffice registra que um pedido foi pago; o dinheiro em si é recebido pela
  maquininha de cartão da bilheteria, que é outro sistema com outro dono;
- **carga.** O teatro vende no máximo 400 lugares por semana. A aula 14 diz como se faz um teste de
  carga, e para esta versão o plano decide que não vale um;
- **o servidor de e-mail real.** Os e-mails param na caixa de saída na versão de teste (seção 04),
  então se eles chegam numa caixa de entrada real é conferido uma vez em produção, por uma pessoa,
  depois da entrega.

Um item fora do escopo não é um item esquecido. A diferença é que alguém o escreveu, deu um motivo,
e pode ser perguntado sobre ele.

## Risco: o que pode dar errado, e quanto importaria

Um **risco de produto** é algo que pode estar errado no produto e causaria dano se estivesse. Cada
um tem duas dimensões, e elas são julgadas separadamente porque vêm de pessoas diferentes:

- **probabilidade**: quão provável é que esta parte esteja errada. Quem mais sabe disso são os
  desenvolvedores: código novo, código complicado, código escrito às pressas e código que ninguém
  toca há anos têm mais chance de estar errados;
- **impacto**: quanto dano faria se estivesse. Quem mais sabe disso é o negócio: dinheiro perdido,
  clientes mandados embora, uma lei descumprida.

Colocadas numa grade, as duas juntas ordenam os riscos, e a ordem diz para onde o teste vai
primeiro e mais fundo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l01-risk-matrix\" aria-label=\"Uma grade de três por três com probabilidade subindo pela lateral e impacto ao longo da base, cada um baixo, médio e alto. A, preço, fica em probabilidade alta e impacto alto. B, venda além da lotação, e C, reembolsos, ficam em probabilidade média e impacto alto. D, e-mail de confirmação, fica em probabilidade baixa e impacto médio. E, layout no celular, fica em probabilidade média e impacto baixo. As células do canto superior direito estão marcadas testar primeiro, a faixa do meio testar em seguida, o canto inferior esquerdo testar por último.\"><rect x=\"120.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"20.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"102.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"284.0\" y=\"184.0\" width=\"76.0\" height=\"76.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baixa</text><text x=\"158.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baixo</text><text x=\"110.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">média</text><text x=\"240.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">médio</text><text x=\"110.0\" y=\"58.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alta</text><text x=\"322.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alto</text><text x=\"240.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">impacto</text><text x=\"20.0\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">probabilidade</text><circle cx=\"322.0\" cy=\"58.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"322.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><circle cx=\"306.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"306.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><circle cx=\"338.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"338.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><circle cx=\"240.0\" cy=\"222.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"240.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><circle cx=\"158.0\" cy=\"140.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"158.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"396.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><text x=\"414.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">preço</text><text x=\"396.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><text x=\"414.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">venda além da lotação</text><text x=\"396.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"414.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reembolsos</text><text x=\"396.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><text x=\"414.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e-mail de confirmação</text><text x=\"396.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"414.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">layout no celular</text><rect x=\"396.0\" y=\"178.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">testar primeiro, mais fundo</text><rect x=\"396.0\" y=\"204.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">testar em seguida</text><rect x=\"396.0\" y=\"230.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testar por último, mais leve</text></svg>", "caption": "Os cinco riscos do boxoffice numa grade de probabilidade e impacto. A posição de cada letra é um julgamento; a ordem em que a grade as coloca é o que o plano usa."}
```

Cinco riscos do boxoffice, colocados como um testador os colocaria depois de vinte minutos com a
gerente do teatro e o seu único desenvolvedor:

| | risco | probabilidade | impacto | por quê |
|---|---|---|---|---|
| A | um cliente paga o preço errado | alta | alto | três descontos com uma regra de combinação, escrita semana passada |
| B | um espetáculo vende além dos lugares | média | alto | uma plateia irritada na porta, numa noite lotada |
| C | um reembolso alcança um pedido que não deveria | média | alto | dinheiro devolvido por um lugar que foi usado |
| D | o e-mail de confirmação nunca chega | baixa | médio | o cliente ainda reserva, só que sem o desconto de membro |
| E | a tabela de espetáculos é difícil de ler no celular | média | baixo | incômodo, e ninguém paga nada a mais por isso |

**Uma ordenação é um argumento, não uma medição.** "Alto" e "médio" são julgamentos, e dois
testadores colocam o mesmo risco em células vizinhas. Isso é aceitável, porque o que a grade
precisa acertar é a ordem, não a posição: erro de preço antes de layout, reembolso antes de e-mail.
Onde a gerente do teatro discorda de uma ordem, o plano cumpriu seu papel ao tornar a divergência
visível antes de algo ser construído sobre ela.

## O que a ordenação decide

A ordenação vira esforço de dois jeitos. **Profundidade**: o risco A recebe as técnicas das aulas 4
e 5, em que toda combinação de descontos é listada e conferida; o risco E recebe uma olhada em dois
tamanhos de tela. **Ordem**: os riscos mais altos são testados primeiro, para que, se o tempo
acabar, o que ficou sem teste seja o que menos importa. Esse segundo ponto é todo o argumento a
favor de testar por risco. Um plano que fica sem tempo testando na ordem em que os requisitos por
acaso foram escritos deixa a regra de preço sem teste sempre que ela foi escrita por último.

Os riscos são revistos conforme o projeto anda. Todo defeito encontrado é evidência sobre a
probabilidade, então uma parte que vive falhando sobe, e uma parte estável há cinco versões pode
descer. A aula 10 usa a mesma ordenação para escolher o que rodar de novo depois de cada mudança.
