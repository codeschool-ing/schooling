---
title: Geração: o dado nasce num sistema feito para outra coisa
version: 1
---

**Quase nenhum dado é gerado para as pessoas que o analisam.** Ele é um subproduto de um sistema
fazendo o próprio trabalho, e carrega o formato desse trabalho. O aplicativo da Roda Livre grava uma
linha para cada viagem porque precisa cobrar a viagem. A linha guarda o que a cobrança precisa: qual
bicicleta, de onde, quando, por quanto tempo, e o preço. Não guarda nada que só um relatório
quisesse, e ninguém nunca pediu que guardasse.

Essa é a primeira coisa a entender sobre uma origem: **o dono a construiu para um propósito, e a sua
pergunta não é esse propósito.** Na Roda Livre, quatro sistemas geram quase tudo o que o time de
dados vai tocar.

| sistema | o que ele grava | para que foi feito | de quem é |
|---|---|---|---|
| o banco do aplicativo | viagens, clientes, as estações | cobrar clientes e destravar bicicletas | do time do aplicativo |
| os sensores das docas | uma leitura por minuto por doca: tem bicicleta ou não | o mapa do aplicativo | de um fornecedor de hardware |
| o provedor de pagamentos | cobranças, estornos, cartões recusados | movimentar dinheiro | de uma empresa fora da Roda Livre |
| o próprio aplicativo | toques e telas: abriu o mapa, buscou uma estação | os experimentos do time de produto | do time do aplicativo |

A aula 4 trata de cada tipo de origem por vez — um banco, uma API, um arquivo, um log, eventos,
sensores — e do que cada uma custa para ler. Esta seção é sobre o que elas têm em comum.

## O que quem gera decide por você

Quem grava o dado decide coisas com as quais todas as etapas seguintes têm de conviver:

- **O relógio.** O aplicativo da Roda Livre grava `started_at` como `2025-09-15 06:01`, uma hora local
  sem fuso escrito ao lado. Todo leitor tem de saber que é o relógio de Curitiba. A quarta-feira de
  27 horas de leituras da aula 1 é o que acontece quando dois geradores discordam sobre isso.
- **As unidades.** O preço está em `price_cents`, um número inteiro de centavos. Um sensor pode mandar
  o nível de bateria de 0 a 100 num ano e de 0 a 1 no seguinte.
- **A identidade.** Uma viagem é `R000174` porque o aplicativo as numera. Se o aplicativo reusasse um
  número, nenhuma etapa seguinte conseguiria separar duas viagens.
- **O que conta como uma linha.** O aplicativo grava a viagem quando a bicicleta é devolvida. Uma
  viagem ainda em andamento à meia-noite não está nos dados daquele dia.

Nenhuma dessas é escolha do engenheiro de dados, e **todas podem mudar sem aviso** quando o time dono
lança uma versão nova. A aula 1 mostrou o que uma coluna renomeada faz com um programa que confiava
nela.

## Uma origem guarda o presente, não o passado

**Um sistema operacional guarda o estado atual das coisas, e o atualiza no lugar.** Se uma viagem é
estornada, o aplicativo pode zerar o preço dela. Se um cliente troca de e-mail, o antigo é
sobrescrito. Se uma estação muda de nome, toda viagem antiga passa a apontar para o nome novo. O
sistema está certo em funcionar assim: o trabalho dele é saber a verdade agora.

**A primeira cópia que o time de dados tira muitas
vezes é a única história que existe.** Os sensores das docas guardam dois dias de leituras; uma cópia
que perde uma noite perdeu aquela noite para sempre. É por isso que a próxima etapa, a ingestão,
copia o dado para fora num horário fixo e não muda nada nele, e por isso a etapa seguinte guarda a
cópia.
