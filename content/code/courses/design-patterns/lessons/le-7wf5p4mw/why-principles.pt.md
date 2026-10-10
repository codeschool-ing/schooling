---
title: Para que serve um princípio de projeto
version: 1
---

**Um princípio de projeto é uma regra prática sobre onde a mudança vai doer, escrita por alguém que
se machucou com ela vezes suficientes.** Ele não diz o que construir. Ele diz qual arranjo do mesmo
código vai ser mais barato de mudar no mês que vem, e vale exatamente tanto quanto a mudança que
prevê.

A leitura errada mais comum é tratar princípios como leis: código que segue SOLID é bom, código que
o quebra é ruim, e um revisor pode ir marcando as letras. Essa leitura produz o código
superconstruído com que a lição 4 termina, em que toda classe tem uma interface e ninguém acha a
linha que faz o trabalho. Um princípio é uma pergunta a fazer quando algo está difícil de mudar, não
uma lista de verificação para rodar antes de qualquer coisa existir.

## De onde vieram as cinco letras

Robert C. Martin reuniu os princípios em artigos e num texto, *Design Principles and Design
Patterns*, por volta de 2000. Dois deles são mais velhos que a coleção: o princípio aberto/fechado é
de Bertrand Meyer, do livro *Object-Oriented Software Construction*, de 1988, e o princípio da
substituição é de Barbara Liskov, de uma palestra de 1987. Michael Feathers percebeu que as iniciais
podiam ser arrumadas numa palavra, e a palavra pegou.

| letra | princípio | a pergunta que ele faz | lição |
|---|---|---|---|
| S | responsabilidade única | quem vai pedir que este código mude? | 3 |
| O | aberto/fechado | dá para acrescentar um caso novo sem editar código que funciona? | 3 |
| L | substituição de Liskov | todo filho pode ser usado onde se espera o pai? | 3 |
| I | segregação de interfaces | cada cliente depende só do que usa? | 4 |
| D | inversão de dependência | a regra depende do detalhe, ou o contrário? | 4 |

Os cinco tratam de **dependências**: que pedaço de código precisa saber de qual outro e, portanto,
que pedaço quebra quando outro muda. A lição 2 também tratava disso. A classe base frágil é um filho
dependendo do funcionamento interno do pai; a explosão de classes é cada combinação dependendo de
cada eixo. SOLID dá nome a cinco formatos desse problema.

## O que cada um custa

Todo princípio desta lição, aplicado, acrescenta alguma coisa: uma classe dividida em duas, um
protocolo onde havia uma classe concreta, uma função que recebe uma parte em vez de construí-la.
Cada acréscimo é um lugar a mais para quem lê olhar. A troca vale a pena quando a mudança contra a
qual ela protege é provável, e é puro custo quando essa mudança nunca chega.

Então leia cada seção com duas perguntas na mão. Que mudança este princípio barateia? E, no código
em que você trabalha, com que frequência essa mudança de fato acontece? Os programas desta lição
foram escolhidos para a mudança acontecer na página, na sua frente, com a saída mostrando o que ela
quebrou ou deixou de quebrar.

## Princípios e padrões

Um padrão é uma solução com nome e formato conhecido: uma strategy, um adapter, um repository. Um
princípio é o motivo de o padrão ter esse formato. O catálogo de padrões da lição 6 fica muito mais
fácil de ler depois que estes cinco estão familiares, porque a maior parte dos padrões ali é um dos
princípios aplicado a um problema específico e recorrente. **O princípio é o argumento; o padrão é o
argumento já feito para um caso.**
