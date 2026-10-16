---
title: Quanto custa um acionamento falso
version: 1
---

A linha do tempo de 30 de setembro, da aula 14, começa às 17:20, com o release. O pager já tinha falado meia hora antes. Às 16:52, o alerta chamado **card provider p99 over 2 s** acionou o Rafa, que estava de plantão: pelo menos uma cobrança em cada cem estava levando mais de dois segundos. O Rafa olhou, viu o alerta que já tinha visto muitas vezes e o reconheceu. No postmortem ele disse com todas as letras: **"eu vi o alerta e achei que era o ruído de sempre."**

Ele acertou que era o alerta de sempre, e acertou que a maioria dos acionamentos dele não pedia nada. Errou sobre aquela tarde, porque a lentidão do provedor era exatamente a condição que fez o novo retry disparar vinte e oito minutos depois. Ninguém no postmortem achou que o Rafa deveria ter sabido; a aula 15 é clara sobre isso. A pergunta que ela deixou para esta aula é outra: **por que o time tinha ensinado a quem estava de plantão que esse alerta podia ser ignorado?**

## Fadiga de alertas

**Fadiga de alertas** é o que acontece com quem é acionado com frequência por coisas que não pedem nada. Cada acionamento falso ensina um pouco mais que acionamentos podem esperar, e essa lição é aprendida queira alguém ou não. Os sintomas são conhecidos de qualquer pessoa que já carregou um pager movimentado:

- **reconhecer sem ler**, para parar o ruído, com a intenção de olhar depois;
- **silenciar** um alerta por uma hora, depois por um dia, e depois esquecer que está silenciado;
- **uma resposta mais lenta a todo acionamento**, inclusive ao raro que importa, porque o valor esperado de olhar caiu;
- **gente saindo da escala**, que a aula 17 mostrou ser o último sintoma, não o primeiro.

Os hospitais conhecem a mesma coisa como **fadiga de alarmes**: monitores à beira do leito que tocam tantas vezes por nada que a equipe deixa de ouvi-los. Em 2013 a Joint Commission, que acredita os hospitais americanos, emitiu um alerta formal sobre isso, depois de uma série de mortes em que alarmes tinham sido silenciados, abaixados ou não ouvidos. O mecanismo é o mesmo numa enfermaria e num pager, e não é uma fraqueza das pessoas envolvidas. **Uma pessoa exposta a um sinal que costuma estar errado aprende a descontá-lo, e acerta quase todas as vezes.**

## O custo é pago duas vezes

Um acionamento falso custa o óbvio: o sono de alguém, ou uma hora da tarde dessa pessoa. Esse custo é visível, e às vezes os times o aceitam como o preço da segurança.

O segundo custo é o que importa, e ninguém o registra. Todo acionamento falso diminui a credibilidade de todos os outros, inclusive dos verdadeiros. Um time com vinte alertas, dezesseis deles ruidosos, não tem quatro alertas bons e dezesseis irritantes. Tem vinte alertas em que ninguém acredita por inteiro. **O ruído não fica ao lado do sinal; ele gasta a credibilidade do sinal.**

Por isso a correção não é "tome mais cuidado ao reconhecer". Pedir que as pessoas fiquem atentas a um sinal que costuma estar errado é pedir que lutem contra o que a experiência lhes ensina. A correção é fazer o sinal voltar a merecer crédito, e o resto desta aula mostra como.
