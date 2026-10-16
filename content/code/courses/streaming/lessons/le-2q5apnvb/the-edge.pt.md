---
title: Onde o exatamente uma vez para
version: 1
---

**O exatamente uma vez do Kafka cobre o que o Kafka grava: registros em tópicos e offsets em
`__consumer_offsets`. Qualquer outra coisa que um programa faça no meio fica fora da transação, e
uma transação abortada não a desfaz.** Essa fronteira é estreita e precisa, e esperar "exatamente
uma vez" fora dela é de onde vem a decepção.

Suponha que o `eos_copy.py` da seção anterior tivesse mais uma linha: para cada venda grande, além
de copiá-la, mandar um e-mail ao gerente da loja. Suponha que ele caísse como antes, depois de 25
vendas. As cópias do lote inacabado são abortadas e gravadas de novo no reinício; os e-mails desse
lote já tinham sido enviados, e são enviados de novo. O gerente recebe dois e-mails para algumas
vendas e um para as outras, de um programa que é exatamente uma vez por toda medida que o Kafka
tem.

O mesmo acontece com todo efeito que não é uma gravação no Kafka:

| o que o programa faz | por que a transação não cobre |
|---|---|
| insere uma linha no PostgreSQL | o banco tem a própria transação, que confirma por conta própria |
| chama uma API de pagamento | o pagamento aconteceu, decida o Kafka o que decidir depois |
| grava um arquivo | o arquivo está em disco antes do commit e continua depois de um abort |
| manda um e-mail ou uma notificação | ninguém consegue desenviar |

Um commit em duas fases entre o Kafka e um banco fecharia o vão em teoria, e o Kafka não oferece
um: um coordenador que segura travas em dois sistemas enquanto espera os dois é lento, e quando
falha deixa os dois presos. O que sistemas em produção fazem em vez disso é tornar o segundo
sistema **tolerante a ver a mesma coisa duas vezes**, que é uma propriedade do lado que recebe e
custa muito menos que uma transação.

## O que o lado que recebe pode fazer

São três respostas, e a lição 8 constrói cada uma delas sobre o SQLite:

- escrever de um jeito que se repete sem estrago: definir um valor em vez de somar a ele, pela
  chave do evento, para a segunda gravação não mudar nada;
- lembrar o que já foi feito: guardar os ids dos eventos já aplicados, na mesma transação de banco
  do efeito deles, e pular um id que já está lá;
- guardar o offset junto com os dados: gravar a posição no stream na mesma transação do efeito, e
  começar dela, para o banco e o stream não discordarem.

As três transformam **entrega pelo menos uma vez em efeito exatamente uma vez**. Essa frase é a
versão honesta da promessa: as mensagens podem chegar mais de uma vez, e o resultado é como se cada
uma tivesse chegado uma vez. É o que "exatamente uma vez" quer dizer fora de um único sistema, e a
lição 8 usa a expressão nesse sentido.

Para o e-mail não existe essa propriedade, e a resposta usual é uma tabela de e-mails já enviados,
pela chave do evento que os causou, conferida antes de enviar. Ela estreita a janela ao momento
entre enviar e gravar a linha, e não a fecha. Alguns efeitos só podem ficar raros.
