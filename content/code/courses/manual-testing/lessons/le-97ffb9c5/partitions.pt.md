---
title: Partições de equivalência
version: 1
---

**O primeiro impulso diante de um campo é experimentar muitos valores nele**, e se sentir mais
cuidadoso a cada um. O R4 deixa alguém reservar de 1 a 6 ingressos; quem reserva 1, depois 2,
depois 3, depois 4 e depois 5 rodou cinco casos e fez a mesma pergunta cinco vezes. Se o boxoffice
reserva três ingressos corretamente, há muito pouco motivo para achar que ele reserva quatro de
outro jeito: o requisito trata os dois igual, e o código, quase com certeza, também.

Essa observação é a técnica inteira. **Uma partição de equivalência é um conjunto de entradas que
o requisito manda tratar do mesmo jeito**, e um valor tirado dela representa todos os outros.
Testar um segundo valor da mesma partição custa um caso e compra quase nada; testar um valor de uma
partição que ninguém tentou ainda é uma pergunta nova. O objetivo é cobrir cada partição pelo menos
uma vez, com o menor número de casos que isso exigir.

## O requisito traça as linhas

As partições saem do que o requisito diz, não do que o programa por acaso faz. É isso que torna esta
uma técnica de caixa-preta, no sentido que `qa-fundamentals` deu à palavra: dá para traçá-las antes
de existir uma linha de código, e você as traça do mesmo jeito sabendo ou não ler o código.

Pegue os dois tamanhos do R2. "Um nome de 1 a 40 caracteres" divide todos os nomes possíveis em
três:

- **vazio**, nenhum caractere, que o requisito recusa;
- **de 1 a 40 caracteres**, que ele aceita;
- **41 caracteres ou mais**, que ele recusa.

"Uma senha de 8 a 64 caracteres" faz o mesmo, com outros números: de 0 a 7 recusada, de 8 a 64
aceita, 65 ou mais recusada. A partição do meio de cada uma é **válida**, a entrada que o programa
deve aceitar e processar; as duas das pontas são **inválidas**, a entrada que ele deve devolver com
uma frase dizendo o que está errado (R7). Os dois tipos são partições, e os dois precisam de um
caso. Quem só alimenta um formulário com o que ele pede testou metade dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-partitions\" aria-label=\"Três barras, uma por campo, cada uma dividida em três partições. Tamanho do nome: vazio, recusado; 1 a 40, aceito; 41 ou mais, recusado. Tamanho da senha: 0 a 7, recusado; 8 a 64, aceito; 65 ou mais, recusado. Ingressos por pedido: 0 ou menos, recusado; 1 a 6, aceito; 7 ou mais, recusado; e ao lado dessa barra uma quarta partição tracejada, não é número inteiro, recusada com uma frase.\"><text x=\"20.0\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tamanho do nome</text><text x=\"20.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R2</text><rect x=\"160.0\" y=\"22.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vazio</text><text x=\"210.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><rect x=\"264.0\" y=\"22.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 a 40</text><text x=\"357.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">aceito</text><rect x=\"454.0\" y=\"22.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"38.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">41 ou mais</text><text x=\"504.0\" y=\"53.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><text x=\"20.0\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tamanho da senha</text><text x=\"20.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R2</text><rect x=\"160.0\" y=\"92.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0 a 7</text><text x=\"210.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><rect x=\"264.0\" y=\"92.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8 a 64</text><text x=\"357.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">aceito</text><rect x=\"454.0\" y=\"92.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"108.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">65 ou mais</text><text x=\"504.0\" y=\"123.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><text x=\"20.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ingressos por pedido</text><text x=\"20.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R4</text><rect x=\"160.0\" y=\"162.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0 ou menos</text><text x=\"210.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><rect x=\"264.0\" y=\"162.0\" width=\"186.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 a 6</text><text x=\"357.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">aceito</text><rect x=\"454.0\" y=\"162.0\" width=\"100.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7 ou mais</text><text x=\"504.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado</text><rect x=\"570.0\" y=\"162.0\" width=\"150.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"645.0\" y=\"178.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">não é número inteiro</text><text x=\"645.0\" y=\"193.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado, com uma frase</text></svg>", "caption": "As partições do R2 e do R4, como os requisitos as desenham. Cada barra tem uma partição válida entre duas inválidas, e a quantidade tem uma quarta que nem está na reta dos números. As larguras não estão em escala."}
```

Nem toda partição é uma faixa de números. O endereço de e-mail do R2 tem de ser um que "nenhuma
outra conta usa", e isso divide os endereços em dois: um endereço que ninguém tem, e um que uma
conta já tem. Nenhum dos dois é um tamanho. A conta semeada, `member@example.org`, é um membro
pronto da segunda partição, e cadastrar com ela é o caso que a testa.

## Um valor de cada

Para cada partição, escolha um **valor representativo**, e escolha-o do meio, não da borda: as
bordas ganham casos próprios na seção 03 desta aula, e o trabalho do representante é dizer como a
partição se comporta como um todo. Para o R2:

| campo | partição | tipo | representante |
|---|---|---|---|
| nome | vazio | inválida | nome nenhum |
| nome | de 1 a 40 caracteres | válida | `Ana Lima`, 8 caracteres |
| nome | 41 ou mais | inválida | um nome de 60 caracteres |
| senha | de 0 a 7 caracteres | inválida | `abc`, 3 caracteres |
| senha | de 8 a 64 caracteres | válida | uma senha de 20 caracteres |
| senha | 65 ou mais | inválida | uma senha de 100 caracteres |
| e-mail | não usado por nenhuma conta | válida | `new@example.org` |
| e-mail | usado por uma conta | inválida | `member@example.org` |

Oito partições, mas não oito casos. **Partições válidas podem dividir um caso**: um cadastro com
`Ana Lima`, uma senha de 20 caracteres e `new@example.org` põe um valor nas três partições válidas
de uma vez, e se ele cria a conta, as três se comportaram. Partições inválidas não podem dividir, e
a seção 05 desta aula mostra por quê, com uma captura. Então o R2 precisa de um caso válido e cinco
inválidos, seis ao todo, onde experimentar nomes um atrás do outro não tem fim natural.

## Onde o particionamento erra

**Partições são uma afirmação sobre o programa, e a afirmação pode ser falsa.** A técnica supõe que
todo valor de uma partição é tratado igual, e acerta sempre que o código segue o requisito. Se o
código divide uma partição que o requisito não dividiu, por exemplo tratando nomes acima de 30
caracteres de outro jeito porque essa é a largura de uma coluna em algum banco de dados, um
representante do meio não percebe. A defesa é a próxima técnica, que vai aos lugares onde as linhas
são traçadas, e o hábito de perguntar ao desenvolvedor se existe algum limite que o requisito não
menciona.

O outro jeito de errar é esquecer uma partição inteira, e a esquecida costuma ser a entrada que o
formulário não espera. Um campo de nome é desenhado como uma caixa para letras; nada impede alguém de
digitar números nele, ou colar 3.000 caracteres, ou nada. A seção 05 desta aula é sobre essa
partição, no campo em que o boxoffice erra.
