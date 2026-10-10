---
title: Duplicados e rejeições
version: 1
---

Dois dos três relatos novos da triagem da seção 03 nunca chegaram a um desenvolvedor. Isso não é
desperdício: **um duplicado pego na triagem custa um minuto, e um duplicado que escapa custa duas
pessoas corrigindo um defeito**, ou uma pessoa corrigindo e o outro relato parado por meses porque
ninguém lembra que já foi resolvido. Uma rejeição pega na triagem poupa um desenvolvedor de mudar
código que estava certo. As duas saídas pedem a mesma habilidade, que é separar um sintoma de uma
causa.

## Um duplicado é a mesma causa, não as mesmas palavras

O relato desta semana diz que pagar um pedido já pago responde *"cannot be payed"*. O relato da aula
11 tem *"cannot be useed"* no título. Palavras diferentes, botões diferentes. Antes de decidir, a Ana
reproduz os dois numa 1.1 recém-iniciada:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1002 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is paid cannot be payed.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">An order that is used cannot be useed.</p>
```

(O pedido é o 1002 porque o reteste da seção 02 desta aula criou o 1001 na mesma rodada.)

As duas mensagens são montadas do mesmo jeito: o nome da ação com *ed* colado no fim. *Pay* e
*use* viram *payed* e *useed*. Uma única frase do programa monta toda recusa, então **uma correção
conserta as duas, e um reteste confere as duas**. Esse é o teste de um duplicado: corrigir o
primeiro relato corrigiria o segundo? Aqui corrigiria, então o relato novo é fechado como duplicado
e ligado ao da aula 11. A sessão da aula 11 já tinha encontrado *payed* também, então os passos do
original cobrem as duas formas, e não há nada a copiar.

O caso oposto parece mais semelhante e não é. *Um pedido usado pode ser reembolsado* e *um
reembolso é aceito depois que o espetáculo começou* tratam de reembolso, estão na mesma página e
ambos respondem *"Order is now refunded."* Mas o R6 traz duas condições separadas, pago e antes do
espetáculo, e o boxoffice não confere nenhuma. Uma correção do primeiro, recusando pedidos usados,
deixa o segundo escancarado: um pedido pago ainda pode ser reembolsado depois que o espetáculo
começou, que é o que a aula 11 encontrou. **Duas causas, dois relatos**, mesmo que um desenvolvedor
provavelmente corrija os dois na mesma tarde.

A maioria dos duplicados é evitada, não pega. **Busque antes de registrar**, com as palavras que um
leitor usaria: a página, a mensagem, o campo. As regras de título da aula 15 existem em parte para
essa busca, porque um título como "erro na página de pedido" não combina com nada útil e combina com
todo o resto.

## Rejeitado: o programa está certo

O segundo relato novo diz que um membro que reserva cinco ingressos leva 15% de desconto e deveria
levar 25%. A Ana o reproduz:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=5' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'
<p>The Little Prince, 5 ticket(s), 15% off:
<strong>R$ 127,50</strong></p>
```

O comportamento é exatamente o que o relato diz, e está correto. O R5 dá ao membro 10% e a um
pedido de cinco ou mais 15%, e diz que **os descontos não se somam: vale o maior**. Cinco ingressos
a R$ 30,00 dão R$ 150,00, e com 15% de desconto, R$ 127,50. Quem relatou somou os dois descontos,
que é o que a 1.0 fazia e o que a aula 5 relatou como defeito. O relato é rejeitado, *funciona como
projetado*, e o motivo cita o R5.

**Uma rejeição é uma frase, nunca um estado seco.** "Rejeitado" sozinho diz a quem relatou que
errou e não diz por quê, e a pessoa vai registrar de novo no mês que vem com outras palavras.
"Rejeitado: R5, vale o maior desconto; a 1.0 somava, e o relato da aula 5 sobre isso foi corrigido
na 1.1" diz, e diz também à próxima pessoa que buscar.

**E às vezes quem relatou tem razão de que algo está errado, só que não é o programa.** Se duas
pessoas cuidadosas leem o R5 de dois jeitos, o requisito é ambíguo, e isso também é um defeito, num
documento em vez de no código. A aula 6 chamou de verificação o trabalho de encontrá-lo. A resposta
é mudar o texto do R5, combinado com o gerente, para que o próximo leitor não o leia errado.

O terceiro relato, de que a caixa de saída mostra o e-mail de todos os clientes, é rejeitado por
outro motivo. A caixa de saída só existe no build de teste, como a aula 1 disse ao apresentá-la; em
produção os e-mails saem para caixas de entrada de verdade e essa página não existe. A rejeição diz
isso, e aponta a linha do plano de teste que confere o e-mail real uma vez, em produção.

## Não reproduzível

A saída que pede mais cuidado é aquela em que ninguém na triagem consegue ver o defeito. **"Não
reproduzível" é um pedido de informação, não um veredito.** Quer dizer que o relato e o ambiente do
leitor diferem em algum ponto: uma versão, um navegador, uma conta num estado específico, os dados
que já estavam na máquina. O relato volta para quem o escreveu com o que foi tentado, e essa pessoa
roda de novo com a primeira pergunta da aula 15 na cabeça: que versão, a partir de que estado? Só
quando nem quem escreveu consegue reproduzir é que ele fecha, e mesmo assim fecha com as tentativas
listadas, para que no dia em que acontecer de novo alguém possa comparar.
