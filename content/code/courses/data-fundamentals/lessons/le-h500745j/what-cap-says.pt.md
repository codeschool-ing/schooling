---
title: O que o teorema diz, e a imagem a abandonar
version: 1
---

**O CAP é uma afirmação sobre uma situação só: a rede entre as máquinas de um sistema caiu, e cada
máquina que continua rodando precisa escolher entre responder e estar certa.** Não há como garantir
as duas coisas. Esse é o teorema inteiro, e o resto desta aula é o que decorre dele para quem guarda
dados em mais de uma máquina.

## A imagem a abandonar primeiro

A versão que a maioria das pessoas encontra é um triângulo de três vértices — Consistência,
Disponibilidade (*Availability*), tolerância a Partição — e um slogan: *escolha dois quaisquer*. Ele
sugere um cardápio, em que um projetista cuidadoso pediria C e A e deixaria o P de fora.

**O P não está no cardápio.** Uma partição não é um recurso que o sistema tem; é algo que a rede faz
com ele. A aula 9 listou o que uma máquina sozinha nunca precisou enfrentar: mensagens que se
perdem, relógios que discordam, um par que está lento ou morto e parece igual nos dois casos. No
momento em que o dado mora em duas máquinas com uma rede entre elas, um enlace cortado vai
acontecer, e a única pergunta que sobra é o que cada máquina faz enquanto ele dura. Eric Brewer, que
propôs a conjectura em 2000, escreveu doze anos depois que o "dois de três" sempre tinha sido
enganoso: um sistema só precisa abrir mão de algo enquanto dura uma partição.

Então leia o teorema como uma bifurcação, e não como um cardápio: **quando acontece uma partição,
escolha C ou A.** Quando não há partição, o CAP não diz nada — e é nesse silêncio que a próxima
ideia, o PACELC, entra, na seção 06.

## As três palavras, como a prova as usa

Seth Gilbert e Nancy Lynch provaram a conjectura de Brewer em 2002, e a prova precisou que cada
palavra quisesse dizer uma coisa precisa. As três dizem menos do que dizem numa conversa.

| palavra | o que significa no teorema | o que não significa |
|---|---|---|
| **consistência** | toda leitura devolve a escrita concluída mais recente, como se houvesse uma cópia só; o nome disso é *linearizabilidade* | o C do ACID, que trata de uma transação deixar intactas as regras do banco — esse é assunto de `sql-databases` |
| **disponibilidade** | toda requisição que chega a uma máquina que continua rodando recebe uma resposta que não é erro | "o serviço ficou no ar 99,9% do mês", que é uma medida ao longo do tempo |
| **tolerância a partição** | o sistema continua funcionando quando quaisquer mensagens entre as suas máquinas se perdem | uma promessa de que partições não vão acontecer |

A tabela carrega uma armadilha que vale nomear. Disponibilidade no CAP é sobre **toda** máquina que
está rodando responder. Um sistema em que as máquinas de um lado do corte continuam funcionando e a
máquina do outro lado devolve erros *não* é disponível no sentido do CAP, mesmo que a maioria dos
seus usuários nem tenha percebido nada. Esse sistema pode ser perfeitamente bom; ele escolheu a
consistência.

## Na Roda Livre

Davi guarda o número de bicicletas presas em cada estação em três máquinas, para que o aplicativo
continue funcionando quando uma delas é reiniciada. Chame-as de `n1`, `n2` e `n3`. Num dia normal,
uma mudança chega às três, e o aplicativo pode ler de qualquer uma.

Então o enlace até o `n3` é cortado. Uma cliente devolve uma bicicleta na Rua XV, e o celular dela
alcança o `n3`. O `n3` não tem como avisar os outros. Ele pode recusar — a cliente vê um erro, e
toda resposta que alguém lê continua verdadeira. Ou pode aceitar — a cliente fica satisfeita, e por
um tempo o `n3` e os outros dois discordam sobre quantas bicicletas há na Rua XV. **Não existe
terceira opção que mantenha as duas coisas**, e a próxima seção faz as duas acontecerem na sua
máquina.
