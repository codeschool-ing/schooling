---
title: O que quer dizer não funcional
version: 1
---

Todo teste deste curso até aqui perguntou se o boxoffice faz o que deveria: se seis ingressos são
aceitos, se o estudante paga meia, se um pedido já usado pode ser reembolsado. Essas são perguntas
**funcionais**, sobre o que o sistema faz. Uma pergunta **não funcional** é sobre quão bem ele faz:
quão rápido, para quantas pessoas ao mesmo tempo, com que segurança, e para quem. Uma bilheteria
que cobra o preço certo e leva vinte segundos para mostrar uma página não tem defeito funcional
nenhum, e perde os clientes do mesmo jeito.

O nome sugere algo opcional, uma camada de acabamento depois do trabalho de verdade. Na prática é o
contrário. **Uma falha não funcional muitas vezes é a que vira notícia**: o site que cai quando os
ingressos de um espetáculo concorrido começam a ser vendidos, a página de erro que mostra a um
estranho o interior do programa, o formulário que um cliente cego não consegue preencher. Nenhuma
delas quebra um requisito sobre o que o sistema faz.

## As famílias

A norma de onde a maioria dos times tira o vocabulário é a ISO/IEC 25010, que lista as qualidades
de um produto. Você não precisa da lista de cor; precisa reconhecer as famílias de teste que
cresceram em volta dela, porque cada uma tem as suas ferramentas, os seus especialistas e os seus
cursos.

O **teste de desempenho** mede quão rápido o sistema responde com um uso comum. A medida de costume
é o **tempo de resposta**: do momento em que uma requisição sai até o momento em que a resposta
chegou inteira.

O **teste de carga** faz a mesma pergunta sob a carga que se espera que o sistema aguente no seu
momento mais cheio. Para o teatro, é a manhã em que um espetáculo concorrido abre as vendas, e a
pergunta é se as páginas ainda respondem a tempo quando centenas de pessoas reservam ao mesmo
tempo.

O **teste de estresse** passa desse pico de propósito, até algo ceder, para descobrir onde fica o
limite e como o sistema falha quando chega nele. Um sistema que fica lento e se recupera está numa
posição diferente de um que perde pedidos. Dois vizinhos aparecem com frequência suficiente para
valer reconhecer: o **teste de pico** (*spike*), um salto repentino de carga, e o **teste de
resistência** (*soak* ou *endurance*), carga comum mantida por horas para achar o que só aparece com
o tempo, como memória que nunca é devolvida.

O **teste de segurança** procura os jeitos de o sistema expor dados, aceitar o que deveria recusar
ou ser mal usado. A seção 04 desta aula fica do lado de quem defende.

O **teste de acessibilidade** confere que pessoas com deficiência conseguem usar o sistema: só com o
teclado, com um leitor de tela, com o texto ampliado. A seção 05 faz isso no boxoffice.

O **teste de compatibilidade**, navegadores, sistemas e telas, também é não funcional, e a aula 7 já
o fez. Usabilidade, confiabilidade e o resto da lista da norma também são testados, por pessoas
especializadas neles.

## Um requisito precisa de um número

Olhe de novo os requisitos do boxoffice na aula 1. Dois deles são não funcionais: o R8 nomeia
navegadores e uma largura de tela, e o R9 nomeia a WCAG 2.2 nível AA. Os dois podem ser testados
porque os dois nomeiam algo mensurável. **Não há nada sobre velocidade ou carga.**

Essa lacuna já é um achado, e levantá-la faz parte do trabalho. "O site tem de ser rápido" não pode
ser testado, porque ninguém consegue dizer quando ele falhou. Uma pergunta do testador o transforma
em algo que pode: rápido quanto, para quantas pessoas, medido onde? Uma versão testável para o
teatro poderia dizer: *com 200 pessoas reservando ao mesmo tempo, 95% das páginas respondem em até
um segundo, e nenhuma falha*. Cada número dessa frase saiu da decisão de alguém, como os riscos da
aula 1, e cada um pode ser contestado antes de qualquer medição.

## Onde fica o testador manual

A maior parte desta aula é um panorama, e a profundidade fica em outro lugar. Testes de carga são
escritos em ferramentas feitas para isso, teste de segurança é uma especialidade com ética e leis
próprias, e auditorias de acessibilidade são feitas por pessoas treinadas em tecnologia assistiva.
O curso desta trilha que vai fundo nos três é o `non-functional-testing`, e o
`security-fundamentals` leva a segurança adiante.

O que sobra para um testador manual é mais do que parece. **Você é a primeira pessoa a usar cada
build**, e é você quem percebe a página que levou quatro segundos, o erro que mostrou um caminho de
arquivo, o campo que não se alcançava com Tab. Um número, uma captura de tela e uma frase num
relatório de defeito são como a maioria dos defeitos não funcionais é achada pela primeira vez,
muito antes de alguém rodar uma ferramenta. As três próximas seções mostram como isso fica no
boxoffice.
