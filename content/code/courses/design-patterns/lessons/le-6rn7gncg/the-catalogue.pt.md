---
title: "O catálogo: vinte e três padrões em três famílias"
version: 1
---

**Um padrão de projeto é uma solução com nome para um problema que sempre volta num certo
contexto, registrada junto com os seus custos.** O nome é metade do valor. "Põe um adapter na frente"
é um projeto inteiro dito em quatro palavras para quem conhece o vocabulário, e o vocabulário que
esta lição ensina é o mais antigo e mais compartilhado que a profissão tem.

A leitura errada mais comum é achar que padrões são código para copiar, ou uma lista de coisas que
um bom programa precisa ter. Nenhuma das duas vale para o livro de onde eles vêm. Um padrão é a
descrição de um problema e da forma de uma solução; o código que o implementa muda em cada programa
e em cada linguagem. E um programa sem padrão nenhum não é um programa pior, só um que nunca
encontrou esses problemas.

## O livro

Em 1994, Erich Gamma, Richard Helm, Ralph Johnson e John Vlissides publicaram *Design Patterns:
Elements of Reusable Object-Oriented Software*. Os quatro autores viraram a Gangue dos Quatro, o
livro virou "GoF", e os seus vinte e três padrões viraram o vocabulário comum. Os exemplos eram em
C++ e Smalltalk, as linguagens da época, e alguns padrões mostram isso: a última seção de leitura
desta lição trata dos que uma linguagem moderna engoliu.

Todo padrão do livro tem as mesmas partes. Um **nome**, o **problema** que ele resolve e quando se
aplica, a **solução** como um conjunto de classes que colaboram, e as **consequências**: o que o
padrão custa e o que ele dificulta. A última parte é a que mais pula quem aprendeu padrões num post
de blog, e é nela que mora o julgamento. Todo padrão acrescenta uma indireção; a seção de
consequências diz quando essa indireção compensa.

A introdução do livro também afirma dois princípios que correm por baixo de quase todos os padrões:

- programe para uma interface, não para uma implementação;
- prefira composição de objetos a herança de classes.

Você já conhece os dois. A lição 4 defendeu o primeiro como inversão de dependência, e a lição 2
defendeu o segundo longamente. **A maior parte dos padrões GoF são esses dois princípios aplicados a
um problema específico**, e por isso quem acompanhou o curso até aqui vai achar muitos deles
familiares antes mesmo de ler os nomes.

## Três famílias

O livro organiza os padrões pelo assunto de cada um.

| família | do que trata | quantos |
|---|---|---|
| criacionais | como os objetos são feitos, para o código que os usa não decidir que classe recebe | 5 |
| estruturais | como os objetos são montados em estruturas maiores | 7 |
| comportamentais | como os objetos dividem o trabalho e conversam entre si | 11 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-catalogue\" aria-label=\"Os vinte e três padrões do livro de 1994 em três colunas. Criacionais, cinco: Abstract Factory, Builder, Factory Method, Prototype, Singleton. Estruturais, sete: Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy. Comportamentais, onze: Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor. Treze têm borda contínua porque esta lição trata deles: Builder, Factory Method, Singleton, Adapter, Decorator, Facade, Proxy, Command, Iterator, Observer, State, Strategy e Template Method. Os outros dez têm borda tracejada.\"><text x=\"105.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">criacionais · 5</text><rect x=\"30.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Abstract Factory</text><rect x=\"30.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Builder</text><rect x=\"30.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Factory Method</text><rect x=\"30.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"105.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Prototype</text><rect x=\"30.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Singleton</text><text x=\"295.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estruturais · 7</text><rect x=\"220.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Adapter</text><rect x=\"220.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Bridge</text><rect x=\"220.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Composite</text><rect x=\"220.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Decorator</text><rect x=\"220.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Facade</text><rect x=\"220.0\" y=\"195.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"295.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Flyweight</text><rect x=\"220.0\" y=\"226.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Proxy</text><text x=\"560.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">comportamentais · 11</text><rect x=\"405.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Chain of Responsibility</text><rect x=\"405.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Command</text><rect x=\"405.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Interpreter</text><rect x=\"405.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Iterator</text><rect x=\"405.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mediator</text><rect x=\"405.0\" y=\"195.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Memento</text><rect x=\"565.0\" y=\"40.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Observer</text><rect x=\"565.0\" y=\"71.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">State</text><rect x=\"565.0\" y=\"102.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Strategy</text><rect x=\"565.0\" y=\"133.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Template Method</text><rect x=\"565.0\" y=\"164.0\" width=\"150.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"640.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Visitor</text><path d=\"M200.0 10.0 L200.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M390.0 10.0 L390.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"170.0\" y=\"258.0\" width=\"34.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nesta lição (13)</text><rect x=\"410.0\" y=\"258.0\" width=\"34.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"452.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só citados (10)</text></svg>", "caption": "O catálogo por família. As caixas contínuas são os treze que esta lição constrói; as tracejadas ganham uma linha na tabela.", "same": ["Abstract Factory", "Adapter", "Bridge", "Builder", "Chain of Responsibility", "Command", "Composite", "Decorator", "Facade", "Factory Method", "Flyweight", "Interpreter", "Iterator", "Mediator", "Memento", "Observer", "Prototype", "Proxy", "Singleton", "State", "Strategy", "Template Method", "Visitor"]}
```

Esta lição percorre treze deles, em pares fáceis de confundir ou que resolvem problemas vizinhos:
factory e builder, adapter e facade, decorator e proxy, strategy e observer, command e state,
template method e iterator. O singleton ganha uma seção só para ele, quase toda sobre por que
desconfiar dele. Os outros dez são mais raros em código de aplicação, e cada um tem uma descrição de
uma linha abaixo para você reconhecer o nome quando alguém usar.

| padrão | numa linha |
|---|---|
| Abstract Factory | um objeto que cria uma família inteira de objetos relacionados, como todos os widgets de um visual |
| Prototype | objetos novos feitos copiando um existente em vez de chamar uma classe |
| Bridge | separar uma abstração da sua implementação para os dois variarem, como formas e renderizadores |
| Composite | uma árvore em que um grupo e um item isolado respondem à mesma interface, como pastas e arquivos |
| Flyweight | compartilhar a parte imutável de muitos objetos pequenos, como um objeto de glifo por letra |
| Chain of Responsibility | um pedido passado ao longo de uma fila de tratadores até um deles assumir |
| Interpreter | uma classe por regra de gramática, para avaliar frases de uma linguagem pequena |
| Mediator | um objeto que coordena muitos, para eles pararem de se referir uns aos outros |
| Memento | uma foto do estado de um objeto tirada sem quebrar o encapsulamento, para desfazer |
| Visitor | uma operação acrescentada a uma hierarquia de classes sem editar as classes |

Vale conhecer chain of responsibility pelo nome, porque é a forma do middleware de todo framework
web: cada camada trata o pedido ou o passa adiante. A lição 19 trata da pergunta mais difícil que
esse vocabulário deixa em aberto, que é quando usar qualquer um deles.
