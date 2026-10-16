---
title: O que a cor diz, e quem consegue ver
version: 1
---

**Uma célula colorida é uma frase sem as palavras, e quem lê completa.** Se quem lê completa com o
que você quis dizer, a regra comunica. Se não, ela enfeita, ou diz algo falso, como as 86 setas
vermelhas da última seção. Três perguntas decidem qual dos casos, e nenhuma delas é sobre o Excel.

## Quem lê sabe o que ela quer dizer?

Um preenchimento quer dizer "R$ 1.500 ou mais" só para quem criou a regra. Todo o resto vê âmbar e
chuta: atrasado, não pago, importante, errado. Então:

- **Um significado por cor, na pasta de trabalho inteira.** Se âmbar quer dizer "venda grande" em
  `Sales`, não quer dizer "abaixo da meta" em outra planilha.
- **Diga isso na planilha.** Um título como `Âmbar: vendas de R$ 1.500 ou mais` acima da tabela, ou
  ao lado da célula `Threshold`, custa uma linha e acaba com o chute.
- **Escolha o desenho pela pergunta.** Cada tipo de formatação responde a um tipo de pergunta, e
  emprestar um para outra pergunta foi como as setas vermelhas aconteceram:

| a pergunta | o desenho que responde |
|---|---|
| quais pedem atenção? | um preenchimento nessas células ou linhas, e nada no resto |
| qual o tamanho de cada um, comparado aos outros? | uma barra de dados |
| onde ficam os valores altos e baixos de uma grade? | uma escala de cor |
| subiu ou desceu desde a última vez? | setas, numa coluna que guarda uma variação |

## Todo leitor consegue ver?

**Por volta de um homem em cada doze, e uma mulher em cada duzentas, tem alguma deficiência na visão
de cores**, quase sempre dificuldade para distinguir vermelho de verde. Uma planilha em que verde quer
dizer bom e vermelho quer dizer ruim, sem mais nada que os diferencie, é uma planilha em que esses
leitores veem dois tons da mesma cor barrenta. Numa equipe de vinte e cinco homens, dois deles, em
média.

A saída é nunca deixar a cor carregar o significado sozinha:

- **acrescente um segundo sinal.** As três setas diferem na direção além da cor, e é por isso que um
  conjunto de ícones sobrevive onde um preenchimento vermelho e verde não sobrevive. Uma forma, um
  símbolo ou uma palavra na célula diz a mesma coisa para todo mundo;
- **varie a claridade, não só o matiz.** Um preenchimento claro e um escuro continuam distintos para
  qualquer leitor, e numa impressora só com tinta preta;
- **guarde a condição numa coluna.** Uma coluna de marcação, com o `SE` (`IF` no Excel em inglês) da
  aula 3, diz em palavras o que a cor diz em tinta:

```localised
=SE([@Revenue]>=Threshold; "Large"; "")
```

Uma coluna de marcação também faz o que uma cor não faz: `CONT.SE` (`COUNTIF` no Excel em inglês) a conta, um filtro a seleciona, e
ela continua lá quando a planilha é colada num e-mail como valores ou lida em voz alta por um leitor
de tela, que lê o que a célula guarda e não a aparência dela. A cor passa então a ser um segundo jeito
de dizer algo que a planilha já diz.

## Ela diz algo novo?

As linhas de atacado da seção 03 estão coloridas porque o `Channel` delas diz `Wholesale`, o que quem
lê já consegue ler na coluna G. Essa regra acrescenta ênfase, não informação, e só vale manter se o
atacado é o assunto desta planilha. Uma planilha em que cinco regras colorem metade das células não
diz nada, porque o olho não tem para onde ir. **Duas ou três regras por planilha, cada uma com um
significado escrito, é um teto sensato**, e a próxima seção trata de achar e tirar as outras.
