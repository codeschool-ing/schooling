---
title: Reescrevendo um caso até ele andar sozinho
version: 1
---

Reescrever um caso vago dá vontade de fazer por remendo: um número aqui, um nome ali, até as
perguntas pararem. Isso deixa a forma do caso como estava, e a forma era parte do problema. **Uma
reescrita começa decidindo a única coisa que o caso confere**, e o resto do caso é montado para
conferir isso e mais nada. Esta seção reescreve assim o rascunho da Ana da seção 02, e depois
executa o resultado exatamente como está escrito.

## Uma coisa, dita no título

*A reserva funciona* é um título que cobre toda reserva que o boxoffice vai fazer na vida, e um caso
não consegue conferir todas. Perguntada sobre o que queria dizer de fato, a Ana deu uma resposta
mais estreita: que um membro que reserva paga o preço de membro. Isso é uma coisa, e vira o título,
com o espetáculo e a quantidade dentro dele, para que quem lê a lista saiba que reserva é esta.

O rascunho também escondia um segundo caso. A caixa Student corta o preço pela metade, e um caso
sobre o desconto de membro precisa deixá-la desmarcada, então o preço de estudante vira um caso à
parte. **Dividir um caso vago em dois ou três casos claros é o resultado comum de uma reescrita**, e
custa menos do que parece: cada um dos casos novos é curto.

## A reescrita

As perguntas da seção 02 foram respondidas no caso, nunca numa mensagem para quem o executa. Eis o
resultado:

| campo | TC-BOOK-04 |
|---|---|
| título | Um membro confirmado que reserva três ingressos para The Little Prince paga 10% menos |
| requisito | R4, R5 |
| pré-condição | O boxoffice 1.0 acabou de ser iniciado: se estiver rodando, pare-o com Ctrl-C e inicie-o de novo com `python3 boxoffice.py`. Uma inicialização limpa tem a conta confirmada `member@example.org` e 200 lugares livres para The Little Prince. |
| dados de teste | e-mail `member@example.org`; espetáculo The Little Prince; 3 ingressos; Student desmarcado |
| passos | 1. No navegador, abra `http://127.0.0.1:8000/book`. 2. No campo E-mail, digite `member@example.org`. 3. Na lista Show, escolha The Little Prince. 4. No campo que mostra Tickets (1 to 6), digite `3`. 5. Deixe desmarcada a caixa Student (half price). 6. Clique em Book. 7. Siga o link Shows no rodapé da página. |
| resultado esperado | Depois do passo 6: uma página Order diz que o pedido está reservado, para The Little Prince, 3 ticket(s), 10% off, R$ 81,00, e State: reserved. Depois do passo 7: a linha de The Little Prince mostra 197 em Seats left. |

O total foi deduzido dos requisitos antes da execução, como pede a seção 02 da aula 2. O R5 cobra
um ingresso pelo preço do espetáculo, R$ 30,00 para The Little Prince, então três são R$ 90,00. Um
membro confirmado tem 10% de desconto, o que deixa R$ 81,00. Três ingressos de 200 deixam 197.

Três ingressos é uma escolha deliberada de dados. Está dentro da faixa de 1 a 6 do R4, então a
reserva é permitida, e abaixo dos cinco ingressos a partir dos quais começa o desconto de grupo do
R5, então o único desconto que pode valer é o de membro. Um caso cujos dados pudessem disparar duas
regras ao mesmo tempo não diria qual delas conferiu.

## Conferindo contra as perguntas

Toda pergunta da seção 02 agora tem uma linha que a responde:

| pergunta | respondida por |
|---|---|
| 1 logar onde? | passo 2: não há login, o formulário de reserva pede um e-mail |
| 2 que membro? | os dados de teste: `member@example.org` |
| 3 que espetáculo? | os dados de teste e o passo 3: The Little Prince |
| 4 quantos são alguns? | os dados de teste e o passo 4: 3 |
| 5 Student está marcado? | passo 5: desmarcado |
| 6 que total é o correto? | o resultado esperado: R$ 81,00 |
| 7 o que é sucesso? | o resultado esperado: State: reserved, e 197 lugares |
| 8 a partir de que estado? | a pré-condição, e como chegar a ela |

## Executando como está escrito

Um caso reescrito é executado uma vez por quem o escreveu, seguindo só as palavras, antes de mais
alguém vê-lo. A Ana reiniciou o boxoffice e fez os passos um de cada vez, lendo cada um no caso e
não na memória. O navegador mostrou uma página Order e depois a página Shows; as mesmas requisições,
enviadas com curl, são a evidência:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=3' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>The Little Prince, 3 ticket(s), 10% off:
<strong>R$ 81,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>80</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>197</td>
```

Toda parte do resultado esperado está lá: reservado, três ingressos, 10% de desconto, R$ 81,00 e
197 lugares livres. O TC-BOOK-04 passa.

A execução também é a primeira verificação do próprio caso. Ler cada passo na página, e não na
memória, é o mais perto que um autor chega de ser um estranho. Isso pega um passo faltando ou um
controle com o nome errado, e não pega uma palavra que o autor entende sem perceber. A seção 06 trata
da verificação que pega.

## Quanto custou

O rascunho tinha quatro linhas curtas, e a reescrita é uma tabela de seis linhas com sete passos.
Essa é a proporção comum, e vale pagá-la uma vez. **Um caso é escrito uma vez e executado muitas**,
por pessoas que não estavam lá quando ele foi escrito: a cada versão, depois de cada correção, por
cada testador novo. Cada uma dessas execuções ou custa uma pergunta ou arrisca um chute, e as linhas
a mais se pagam a partir da segunda execução.
