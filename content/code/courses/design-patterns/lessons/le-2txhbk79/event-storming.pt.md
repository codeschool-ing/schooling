---
title: "Event storming: achar o modelo numa sala"
version: 1
---

**Event storming é uma oficina em que as pessoas que conhecem o negócio e as que vão construir o
software cobrem uma parede comprida com post-its, um para cada coisa que acontece, e os põem em
ordem.** Alberto Brandolini a criou por volta de 2013 como um jeito rápido de fazer o trabalho
estratégico desta lição: achar a linguagem, achar onde ela muda e achar o que ninguém entende ainda.

O jeito errado de começar, e o usual, é um documento de requisitos escrito por um lado e lido pelo
outro. Ele chega no vocabulário dos desenvolvedores ou no do negócio, nunca nos dois, e as lacunas
dele são invisíveis porque um documento parece completo. Uma parede de post-its em ordem de tempo faz
uma lacuna parecer lacuna: dois post-its sem nada entre eles, e alguém perguntando "e depois?".

## Os post-its

Cada cor é um tipo diferente de coisa, e vale manter a convenção porque ela deixa uma sala ler a
parede num relance:

| cor | o que é | da biblioteca |
|---|---|---|
| laranja | um evento de domínio: algo que aconteceu, no passado | *Copy returned*, *Hold lapsed* |
| azul | um comando: o que alguém pediu | *Place hold*, *Renew loan* |
| amarelo pequeno | o ator que deu o comando | sócio, bibliotecária |
| lilás | uma política: "sempre que isto acontecer, faça aquilo" | sempre que um exemplar volta com reservas para o título, ponha-o na estante de reservas |
| rosa | um ponto quente: uma pergunta, uma discordância, uma dor | "e se o primeiro da fila dever mais de 1000 centavos?" |

Os laranjas vêm primeiro e são os que mais importam. **O tempo passado é a regra que faz o
trabalho**: *Hold lapsed*, reserva caducada, é um fato que alguém pode confirmar ou negar, enquanto
*caducando* ou *o processo de caducidade* já é um projeto. A lição 9 guardou exatamente esses fatos
como eventos, e a lição 12 os levanta de dentro do modelo.

## Um trecho da parede da biblioteca

Uma tarde com três bibliotecárias e dois desenvolvedores produziu, entre algumas centenas de
post-its, este trecho, em ordem de tempo:

| | o post-it laranja | dito por |
|---|---|---|
| 1 | *Copy ordered* | quem trata com fornecedores |
| 2 | *Copy received* | quem trata com fornecedores |
| 3 | *Title catalogued* | a catalogadora |
| 4 | *Hold placed* | o balcão de empréstimo |
| 5 | *Copy returned* | o balcão de empréstimo |
| 6 | *Copy shelved for hold* | o balcão de empréstimo |
| 7 | *Hold collected* | o balcão de empréstimo |
| 8 | *Loan started* | o balcão de empréstimo |
| 9 | *Loan overdue* | o balcão de empréstimo |
| 10 | *Fine charged* | o balcão de empréstimo |
| 11 | *Hold lapsed* | o balcão de empréstimo |
| 12 | *Fine paid* | o balcão de empréstimo |

Repare onde o vocabulário muda. *Copy ordered* e *Copy received* são ditos por quem trata com
fornecedores, sobre dinheiro e quantidades. *Title catalogued* é da catalogadora, sobre descrições.
De *Hold placed* em diante, todo post-it é do balcão de empréstimo, sobre sócios e datas. **Essas
mudanças são fronteiras candidatas**: os três contextos delimitados das seções anteriores saíram
desta parede, com a palavra *livro* querendo dizer uma coisa diferente de cada lado.

Os post-its rosa foram a outra colheita. Um ficou entre *Copy returned* e *Copy shelved for hold*: o
que acontece quando o primeiro da fila deve mais que o limite de 1000 centavos? Uma bibliotecária
disse que o exemplar espera por ela; outra disse que vai para o próximo sócio. Ninguém tinha escrito
isso, porque cada uma vinha fazendo do seu jeito havia anos. Um documento de requisitos teria
afirmado uma resposta e escondido a discordância. A parede a transformou numa pergunta para a
biblioteca decidir, antes de alguém escrever o código.

## Como ela corre

O formato tem variações, e uma sequência comum para uma primeira sessão é assim:

1. todo mundo escreve post-its laranja ao mesmo tempo, sem ordem e sem debate;
2. a sala os arruma numa só linha do tempo e tira as duplicatas;
3. post-its rosa marcam toda discordância e toda pergunta;
4. comandos azuis, atores e políticas lilás entram onde explicam um evento;
5. o grupo traça linhas onde a linguagem muda, e dá nome às partes.

Duas horas e um rolo comprido de papel bastam para uma primeira passada num domínio do tamanho do da
biblioteca. O que sai é o vocabulário, um primeiro mapa de contextos e uma lista de perguntas. Isso
fica aquém de um projeto, e é tudo o que as cinco primeiras seções desta lição pediram.
