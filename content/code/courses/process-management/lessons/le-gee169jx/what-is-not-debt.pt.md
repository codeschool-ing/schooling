---
title: O que não é dívida técnica
version: 1
---

Uma metáfora que cobre tudo não explica nada. Times que chamam toda reclamação sobre o código de "dívida técnica" acabam com uma lista de dívidas tão longa que ninguém a leva a sério, e os itens que de fato cobram juros se perdem no meio dos outros. Traçar a fronteira faz parte de gerenciá-la.

## Não é defeito

Um **defeito** é o sistema fazendo algo que não deveria: um agendamento salvo no dia errado, um lembrete enviado duas vezes. É uma falha contra os requisitos, entra no backlog como bug, e é corrigido porque está errado. Dívida técnica é código que **funciona** mas é caro de mudar. Os dois se sobrepõem — dívida torna defeitos mais prováveis —, mas uma lista de bugs não é um registro de dívida.

## Não é funcionalidade que falta

Uma funcionalidade que ninguém construiu ainda é **escopo**, não dívida. "Não temos módulo de relatórios" é uma decisão de produto sobre o que construir a seguir, e pertence à priorização da aula 12 como funcionalidade.

## Não é preferência

"Eu teria usado outro framework" é uma opinião sobre um projeto que funciona e não está custando tempo extra. Um projeto que um desenvolvedor mais novo acha estranho não é dívida, a menos que a estranheza tenha um custo recorrente — mudanças mais lentas, mais erros — que dê para apontar. **Se você não consegue nomear os juros, ainda não é dívida**; pode ser uma escolha razoável que outra pessoa não teria feito.

## Não é tudo o que é velho

Código velho não é dívida por ser velho. Um módulo estável que não precisou de mudança em três anos, escrito num estilo que o time não usa mais, não custa nada enquanto é deixado em paz. Ele vira dívida no dia em que uma mudança precisa ser feita nele e a mudança leva o triplo do que deveria.

## O que é

Dívida técnica é **uma propriedade do código ou do sistema que torna as mudanças futuras mais caras do que precisariam ser**, com um custo recorrente que pode ser descrito. Exemplos típicos, todos presentes de alguma forma no registro do time Agenda:

- uma suíte de testes que falha ao acaso e precisa ser rodada de novo, desperdiçando tempo a cada mudança;
- um deploy que exige três horas de passos manuais;
- um módulo que só uma pessoa entende, então toda mudança nele espera por ela;
- uma versão de banco de dados saindo de suporte, depois do que falhas de segurança não serão corrigidas;
- uma regra de negócio duplicada, então toda mudança de regra precisa ser feita em dois lugares e às vezes é feita em um.
