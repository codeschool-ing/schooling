---
title: O que a pessoa fica sabendo, e quando
version: 1
---

**Uma tela offline-first mostra uma mudança como feita no momento em que ela é gravada localmente,
e deve à pessoa um aviso claro mais tarde se o servidor disser não.** Esse padrão se chama
atualização **otimista**: o app age como se o servidor fosse concordar, porque ele quase sempre
concorda. A parte difícil é o caso em que ele não concorda, porque a essa altura a pessoa já seguiu
em frente.

## Os dois erros

**Fingir.** A tela mostra toda linha do mesmo jeito, `pending` ou não, e uma sessão que nunca
chegou ao servidor parece idêntica a uma que chegou. A pessoa troca de celular um mês depois e
encontra uma semana faltando. Nada em tela nenhuma a avisou.

**Gritar.** A tela põe um aviso em cada linha pendente, ou um indicador girando ao lado dela. Num
trem, cada sessão que a pessoa adiciona dispara um alarme sobre algo normal. Ela aprende a ignorar o
aviso, e depois ignora aquele que importava.

O caminho do meio do planner é o que a seção anterior imprimiu: um `waiting to send` discreto ao
lado de uma linha pendente, `saved` quando ela é aceita, e uma frase com o motivo do servidor quando
ela falha.

## Um erro que chega depois do fato

A sessão de 300 minutos falhou quando a sincronização rodou, e nada ligava esse momento ao momento
em que ela foi digitada. Esse é o formato comum de uma falha offline, então a mensagem precisa se
sustentar sozinha:

- **dizer qual item**, pelo que a pessoa vê, a data e o curso, e não por um id;
- **dizer por quê**, nas palavras do servidor se forem palavras com que uma pessoa consiga agir;
- **dizer o que fazer**: mudar a duração, ou apagar a sessão;
- **manter a linha** até a pessoa decidir. Apagá-la por ela joga fora a única coisa que ela
  digitou.

Num celular, a mensagem vai para onde a pessoa vai olhar em seguida: uma marca na linha, um número
na aba e, se o app roda em segundo plano, uma notificação. O que uma plataforma permite quando o app
não está aberto é a aula 16.

## Quando não ser otimista

Uma atualização otimista é uma promessa de que o servidor vai concordar. **Faça-a só onde uma
recusa é rara e barata de corrigir.** Uma sessão de estudo cumpre as duas coisas. Comprar um curso,
não: o pagamento é do servidor aceitar, uma recusa é comum (um cartão negado), e mostrar "comprado"
primeiro seria uma mentira que custa dinheiro. Essas operações esperam o servidor e dizem isso, com
um indicador girando que está dizendo a verdade. A aula 10 é o pagamento enviado duas vezes, que é o
que acontece quando uma operação dessas é repetida sem cuidado.
