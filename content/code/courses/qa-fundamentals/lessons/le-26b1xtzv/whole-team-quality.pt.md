---
title: Qualidade como trabalho do time todo, e o que quem testa faz nela
version: 1
---

**"Qualidade é responsabilidade de todos" é um slogan que, dito sozinho, faz da qualidade responsabilidade
de ninguém.** Ele só fica verdadeiro quando o time combina o que cada pessoa faz a respeito, e quando o
trabalho de alguém é tornar isso mais fácil. Lisa Crispin e Janet Gregory, cujo livro *Agile Testing*
(2009) deu nome a isso, o chamam de **abordagem do time todo**: o time, não um departamento, é dono da
qualidade, e quem testa traz uma habilidade particular a essa posse em vez de carregá-la sozinho.

## O que muda para todo mundo

Na abordagem do time todo os trabalhos se sobrepõem de propósito:

- **quem desenvolve** testa o próprio trabalho antes de qualquer outra pessoa vê-lo, e escreve as
  verificações automatizadas que o mantêm funcionando. A aula 15 trata da forma mais disciplinada disso,
  escrever o teste primeiro;
- **a dona do produto** escreve requisitos verificáveis, com exemplos, e responde rápido às perguntas
  sobre eles. As quatro perguntas da aula 2 e os testes de aceitação da aula 17 são as ferramentas;
- **quem testa** traz as perguntas que ninguém mais está fazendo, explora o que ninguém roteirizou, e
  torna os riscos visíveis cedo o bastante para se agir.

Nenhum papel desaparece. A diferença é que um defeito é preocupação de todos desde a primeira conversa, e
quem testa é alguém a quem os outros recorrem para ajuda, não uma porta pela qual precisam passar.

## Uma semana no Cine Aurora

O que a Lia de fato fez na terceira semana mostra o formato do trabalho melhor que uma descrição:

| dia | o que a Lia fez | a quem ajudou |
|---|---|---|
| segunda | sentou com a Joana enquanto ela escrevia as regras da próxima sprint, e perguntou o que "menos de 12" quer dizer para uma criança que faz doze anos no dia | a Joana, antes de qualquer coisa ser construída |
| terça | pareou com o Rafael por uma hora na funcionalidade de cupom, sugerindo entradas enquanto ele escrevia testes | o Rafael, enquanto o código era escrito |
| quarta | explorou o mapa de assentos por noventa minutos sem roteiro, anotando; achou que atualizar a página perdia os assentos escolhidos | o time todo, com um achado que ninguém tinha planejado procurar |
| quinta | escreveu a informação para a decisão de entrega, incluindo o que não foi testado | a Joana, que decidiu |
| sexta | mostrou à Célia como relatar um problema com o número do pedido e o horário, para o próximo relato do balcão já começar com evidência | a Célia, e toda investigação futura |

Conte as horas gastas conferindo trabalho pronto. O relato de quinta se apoia nelas, e são minoria na
semana. A maior parte do valor veio antes de o código existir, ou enquanto ele era escrito, ou de ensinar
alguém a ver problemas. **É isso que faz de quem testa um multiplicador, e não um portão**: cada hora gasta
melhorando como os outros trabalham é paga de volta toda vez que eles trabalham.

## Quem testa como treinador

A palavra que mais aparece para esse papel em times modernos é **coach**, treinador, e é fácil de entender
mal como "alguém que não testa mais". Quer dizer alguém cujo conhecimento de teste está espalhado pelo
time: desenvolvedores que perguntam "e com sessenta exatos?" sem ninguém lembrar, uma dona do produto que
escreve "a partir de 60" da primeira vez, uma gerente de bilheteria cujos relatos chegam com horários e
números de pedido.

O objetivo não é tornar quem testa desnecessário. É apontar a atenção dessa pessoa para os problemas que só
alguém com esse hábito particular de dúvida acharia, porque os fáceis estão sendo pegos por todo mundo.

## O que não muda

Algumas coisas continuam sendo de quem testa, seja qual for o nome da abordagem do time. Alguém precisa
manter a visão de conjunto do que foi testado e do que não foi; alguém precisa trazer um olhar de fora a um
trabalho que não fez; alguém precisa ser a pessoa que diz, numa reunião de planejamento, *nunca testamos o
que acontece quando duas pessoas compram o último assento no mesmo instante*. Na abordagem do time todo
essas coisas continuam sendo de quem testa, e valem mais por não estarem enterradas sob as verificações que
todo mundo consegue fazer.
