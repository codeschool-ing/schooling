---
title: Os dois formulários, e o que "coletar" quer dizer neles
version: 1
---

**As duas lojas obrigam todo app a responder, num formulário, que dados ele coleta e o que faz com
eles, e as duas mostram as respostas à pessoa na página do app antes de ela instalar.** O Google Play
chama isso de seção *Data safety*, Segurança dos dados, preenchida na página Conteúdo do app do Play
Console. A Apple chama de *privacy details* do app, preenchidos pelo App Store Connect, e no próprio
site descreve o resultado como *Privacy Nutrition Labels*: um painel curto na página do produto, como o
rótulo de uma embalagem de comida. Nenhum dos dois formulários é opcional. A página da Apple sobre
privacy details diz que a informação "é obrigatória para enviar apps novos e atualizações à App Store".

O que segue foi lido na documentação de cada empresa em 30 de outubro de 2026: o guia do Android para
desenvolvedores sobre o formulário Data safety, e a página da Apple sobre privacy details. As duas
dizem que mudam, e os dois formulários já mudaram desde que foram criados, então leia as páginas atuais
antes de preencher qualquer um. As definições detalhadas do Play ficam na Central de Ajuda do Play
Console, que não pôde ser acessada da máquina em que este curso foi gravado; o resumo abaixo vem do guia
do Android para desenvolvedores.

## As perguntas são as mesmas perguntas

**Tirando o vocabulário, os dois formulários perguntam três coisas sobre cada tipo de dado.** O dado
sai do aparelho? Ele vai para alguém além de você? Para que ele é usado? A Apple acrescenta uma quarta:
se o dado está ligado à identidade da pessoa, por uma conta, pelo aparelho ou por qualquer outra coisa.

| pergunta | palavras da Apple | palavras do Google Play |
|---|---|---|
| sai do aparelho? | *collect*: enviado para fora do aparelho e guardado por mais tempo que o pedido exige | *collect*, coletar |
| alguém mais o recebe? | *third-party partners*, e *tracking* | *share*, compartilhar |
| para quê? | uma finalidade de uma lista fechada | uma finalidade de uma lista fechada |

**"Coletar" quer dizer que o dado sai do celular, e essa é a palavra que mais gente entende errado.** A
Apple a define com exatidão: transmitir dados para fora do aparelho "de um jeito que permita a você e/ou
aos seus parceiros terceiros acessá-los por um período maior do que o necessário para atender ao pedido
transmitido em tempo real". Então um plano que fica no celular não é coletado, por maior que seja, e um
único endereço de e-mail enviado ao seu servidor e guardado lá é. A crença comum vai no sentido
contrário, de que "coletado" é tudo o que o app toca, e leva a rótulos que assustam as pessoas sem
motivo.

**As finalidades são uma lista curta, e "o app precisa disso para funcionar" é uma delas.** A lista da
Apple é App Functionality, Analytics, Product Personalization, Developer's Advertising or Marketing,
Third-Party Advertising e Other Purposes, cada uma com uma definição. A página acrescenta que dados
coletados só para o próprio funcionamento do app "ainda precisam ser declarados": uma finalidade não
desculpa uma coleta, ela a descreve.

## O código que você não escreveu conta

**Dados coletados por uma biblioteca dentro do seu app são coleta sua, nos dois formulários.** O guia
do Android diz que, se um SDK ou biblioteca de terceiros no seu app coleta ou compartilha dados de
usuário, "você precisa refletir essa coleta e esse compartilhamento no formulário Data safety". A Apple
pede as práticas "dos parceiros terceiros cujo código você integra ao seu app", e define esses parceiros
como "ferramentas de analytics, redes de publicidade, SDKs de terceiros ou outros fornecedores
externos". Um relatório de crashes, um kit de analytics ou uma biblioteca de anúncios que você
acrescenta numa tarde muda o que o seu formulário precisa dizer, tenha você lido a documentação dela ou
não.

**E o formulário é uma promessa que alguém confere.** O guia do Android diz que só quem desenvolve
responde por declarações completas e corretas, e que, quando o Google percebe uma diferença entre o
comportamento de um app e a declaração dele, "pode tomar a ação apropriada, inclusive de fiscalização".
Um formulário preenchido uma vez, de memória, e nunca atualizado conforme bibliotecas entram é o jeito
comum de um app honesto acabar declarando algo falso.

## Rastrear tem um sentido mais estreito do que parece

**O *tracking* da Apple é um termo definido: ligar dados do seu app a dados de apps ou sites de outras
empresas para publicidade, ou passá-los a um corretor de dados.** A página lista isso, e só isso.
Analytics sobre como as pessoas usam o seu próprio app não é tracking nesse sentido, embora continue
sendo coleta e continue sendo declarado. Quando um app rastreia, o iOS exige que ele pergunte antes,
pelo framework App Tracking Transparency, que a próxima seção mostra. O planner não rastreia, e nada
neste curso pede que você rastreie.
