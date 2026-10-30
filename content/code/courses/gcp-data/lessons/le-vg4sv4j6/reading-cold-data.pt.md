---
title: Lendo de volta um objeto em Archive
version: 1
---

**Um objeto em Archive é lido como qualquer outro, na hora.** Não há pedido de restauração, nem cópia
em espera, nem nível de velocidade para escolher. Quem já usou um arquivo em fita, ou a classe de
arquivo de outra nuvem, espera o contrário: um objeto que aparece na listagem e não pode ser aberto até
que alguém o peça com horas de antecedência. No Cloud Storage o preço do Archive é pago em dinheiro e
numa estadia mínima de 365 dias, não em tempo.

O bucket da seção anterior ainda tem a cópia em Archive. Leia-a:

```
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-archive-prod/orders/2026-09/archive.csv | head -3
order_id,customer_id,total_cents
ord-09-1,c-1,997
ord-09-2,c-2,1004
ana@laptop:~/gcp$ gcloud storage cp gs://quitanda-archive-prod/orders/2026-09/archive.csv back.csv && wc -c back.csv
Copying gs://quitanda-archive-prod/orders/2026-09/archive.csv to file://back.csv
  

10295 back.csv
ana@laptop:~/gcp$ gcloud storage restore --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p' | head -8
DESCRIPTION
    The restore command restores soft-deleted resources:

        $ gcloud storage restore url...

EXAMPLES
ana@laptop:~/gcp$ python3 -c 'print(1024 * 0.01, 1024 * 0.02, 1024 * 0.05)'
10.24 20.48 51.2
```

**O emulador serviu a cópia em Archive na hora, todos os 10.295 bytes**, e aqui ele se comporta como o
Cloud Storage. O `restore` que a linha de comando tem é outra coisa: a ajuda diz que ele restaura
recursos excluídos de forma reversível, objetos apagados de um bucket que os guarda por um tempo, que é
o assunto da aula 3. Nada no `gcloud storage` restaura um objeto arquivado, porque nada precisa.

O que o emulador não consegue mostrar é a conta dessa leitura. O último comando acima é o que ler de
volta um tebibyte inteiro custaria só em taxas de recuperação: 10,24 USD do Nearline, 20,48 do Coldline
e 51,20 do Archive. Por cima disso vem uma operação Class B por objeto lido, ao preço da classe dele, e
a rede, quando os dados saem da rede do Google ou da região, que a aula 5 calcula.

Três detalhes da taxa, da página de preços, decidem como ela cai:

- **ela é cobrada sobre os bytes servidos, não sobre o tamanho do objeto.** Um programa que lê os
  primeiros 8 MB de um objeto de 100 MB em Nearline paga a taxa sobre 8 MB, e um download que quebra
  depois de 8 MB também;
- **copiar, mover e reescrever também são leituras.** A página diz que a taxa se aplica quando você
  "read, copy, move, or rewrite" um objeto guardado nas três classes mais frias. A mudança de
  classe da seção anterior, feita a partir de Coldline ou Archive, paga uma taxa de recuperação além da
  reescrita;
- **ela não se aplica num bucket com Autoclass ligado**, que é o assunto da próxima seção.

## O que os milissegundos significam para um desenho

**Uma classe que lê na hora muda a fronteira entre "arquivar" e "deixar à mão".** As exportações de
auditoria da Quitanda vão para o Archive, e também algo que um arquivo de horas nunca poderia guardar:
as fotos que o entregador tira em cada entrega, lidas só quando um cliente contesta uma, meses depois,
e necessárias enquanto o cliente está no telefone. A pergunta a fazer sobre um conjunto de arquivos não
é mais com que pressa eles são necessários. É com que frequência são lidos e por quanto tempo são
guardados, porque são as duas coisas de que a conta depende.

## As fotos de entrega, com preço

Digamos que as fotos tenham 300 KB cada e que a Quitanda tire dois milhões delas por ano. O comando
abaixo dá o tamanho delas em GiB e depois, para Standard e para Archive, o que esse volume custa para
guardar por doze meses e o que os dois milhões de uploads custam em operações Class A:

```
ana@laptop:~/gcp$ python3 -c 'gib = 2_000_000 * 300_000 / 2**30; print(round(gib, 1)); [print(c, round(gib * p * 12, 2), round(2_000_000 / 1000 * a, 2)) for c, p, a in (("Standard", 0.035, 0.005), ("Archive", 0.003, 0.05))]'
558.8
Standard 234.69 10.0
Archive 20.12 100.0
```

**O Archive guarda os 558,8 GiB do ano por 20,12 USD contra 234,69 do Standard, e custa dez vezes mais
para escrever**: 100 USD de uploads contra 10. No primeiro ano, o Archive ainda ganha, 120,12 contra 244,69, e
continua ganhando todo ano depois, porque as fotos são escritas uma vez e guardadas. Uma contestação lê
cinco fotos, cinco operações Class B a 0,05 por mil e 1,5 MB de recuperação a 0,05 por GiB, e nenhuma
das duas chega a um centavo. A conta de uma classe fria é decidida por quantos objetos são escritos e
quantos bytes são lidos, e aqui os dois são pequenos.

A mesma conta vira para o outro lado para dados escritos em pedaços minúsculos e lidos em massa, que é
um fluxo de cliques. É por isso que a classe é decidida por tipo de dado, e por isso que um bucket pode
guardar vários.
