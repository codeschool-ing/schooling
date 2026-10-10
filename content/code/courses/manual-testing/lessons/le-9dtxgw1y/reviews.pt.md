---
title: Revisões, ou o teste que não roda nada
version: 1
---

Uma imagem comum do teste é que ele começa quando existe algo para rodar. Parte do teste mais barato
que existe não roda nada. **O teste estático examina um artefato de trabalho sem executá-lo**: um
requisito, um projeto, um caso de teste, um trecho de código. Sua forma mais comum é a revisão,
uma pessoa lendo um documento com uma pergunta em mente, e o documento que mais compensa revisar é
aquele a partir do qual todo o resto é construído, os requisitos.

Uma revisão de R1 a R9 é verificação no sentido da seção 02 desta aula. Ela confere os requisitos
contra eles mesmos e uns contra os outros, antes que o produto seja conferido contra eles.

## O que uma revisão procura

Um requisito testável tem quatro propriedades, e a revisão lê cada frase atrás delas:

- *uma leitura só*: duas pessoas cuidadosas que o leem saem com a mesma regra;
- *completo*: diz o que acontece em todos os casos que cobre, inclusive os incômodos;
- *consistente*: concorda com os outros requisitos e usa as palavras deles do mesmo jeito;
- *testável*: alguém conseguiria decidir passou ou falhou a partir dele, sem perguntar ao autor.

A última é a pergunta do próprio testador, e as outras costumam aparecer na tentativa de
respondê-la. Ler o R5 para escrever um caso para ele é onde a maioria dos testadores percebe que não
sabe o que o caso deveria esperar.

## Ana revisa R1 a R9

Ana lê cada requisito como se tivesse de escrever os casos dele naquela tarde, e anota cada lugar
em que teria de adivinhar. Quatro dos achados dela:

| | as palavras | a pergunta |
|---|---|---|
| R5 | "Estudantes pagam meia." | Como alguém mostra que é estudante, e para quem: uma caixa marcada na reserva, uma carteirinha mostrada na porta? |
| R5 | "Estudantes pagam meia." | Metade de quê, do ingresso ou do pedido? Um membro que reserva para si e para dois filhos estudantes poderia pagar de um jeito ou de outro. |
| R4 | "A reserva de um espetáculo fecha uma hora antes do início." | O R1 diz que os horários são de São Paulo; o R4 não diz em que horário a hora é contada. O corte é às 19:00 de São Paulo também para quem reserva de Lisboa? |
| R8 | "nas versões atuais do Chrome, Firefox, Safari e Edge" | Quais versões são as atuais: a mais nova de cada um, ou as duas últimas? A aula 7 precisa saber. |

Nenhum deles é um defeito do boxoffice. Cada um é um lugar em que o requisito deixa duas pessoas
construírem ou testarem duas coisas diferentes, e **o resultado da revisão é uma lista de perguntas
para quem é dono dos requisitos**, a gerente do teatro, cada uma com o identificador, as palavras e
as leituras possíveis. "O R5 está confuso" não dá à gerente nada para responder. "R5, por ingresso
ou por pedido, e aqui está quanto cada um cobraria" se responde numa linha.

## O que o programa fez com a pergunta

Uma ambiguidade deixada num requisito não fica em aberto. Quem escreve o código precisa escolher uma
leitura, geralmente sozinho e sem avisar. Reinicie o boxoffice e reserve três ingressos de Hamlet
como o membro, primeiro com a caixa Student marcada e depois sem ela:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3&student=on' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 3 ticket(s), 50% off:
<strong>R$ 120,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1002 reserved.</p>
<p>Hamlet, 3 ticket(s), 10% off:
<strong>R$ 216,00</strong></p>
```

A página Book tem uma caixa Student para o pedido inteiro, então Rui respondeu à segunda pergunta
do R5: a meia vale para o pedido. Com a caixa marcada, o ingresso da própria Bia também sai pela
metade, R$ 120,00 pelos três. Sem ela, os dois filhos pagam o preço de membro, R$ 216,00. Se a meia
valia por ingresso, a família deveria pagar R$ 72,00 pelo de Bia e R$ 40,00 por cada filho,
R$ 152,00, e a página não tem como pedir isso. E a primeira pergunta do R5 também ficou respondida:
quem marca a caixa é estudante.

Qual dos três totais está certo é decisão do teatro, não de Rui nem de Ana. O sentido da revisão é
que **a pergunta chegue a quem pode decidi-la antes que alguém a escreva no código adivinhando**.
Encontrada numa revisão, ela custa um e-mail para a gerente. Encontrada depois da versão, custa uma
discussão na porta com uma família segurando três ingressos de meia. A aula 3 de
`qa-fundamentals` põe números em como esse custo cresce.

## Tipos de revisão

Revisões vão de um colega lendo uma página até uma reunião com moderador e lista de verificação. As
normas nomeiam quatro, do menos ao mais formal. Na *revisão informal*, uma pessoa lê e manda
comentários. No *walkthrough*, o autor conduz os outros pelo documento. Na *revisão técnica*, colegas
julgam o documento diante do seu propósito, e a *inspeção* tem papéis definidos, lista de verificação
e números guardados sobre o que foi encontrado. Os nove requisitos de um teatro precisam do primeiro
tipo e de uma hora. As regras de pagamento de um banco justificam o último.

A mesma leitura serve para coisas além de requisitos. O teste da aula 3, se um estranho conseguiria
rodar um caso sem fazer nenhuma pergunta, é uma revisão de caso de teste. Desenvolvedores revisam o
código uns dos outros, e ferramentas de análise estática leem o código atrás de padrões que
costumam ser erros, sem rodá-lo. O testador participa dos dois primeiros e quase sempre só ouve
falar do terceiro.
