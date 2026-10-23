---
title: Depois da entrada no ar: hypercare, o primeiro pagamento e o arquivo
version: 1
---

A noite do cutover termina às 10:00 de domingo, e é tentador chamar isso de fim da migração. É o fim
da parte que dava para ensaiar. **O que uma migração errou aparece quando o negócio usa os dados pela
primeira vez**, e alguns desses usos só acontecem uma vez por mês: o fechamento, o pagamento, o
extrato que uma fazenda lê. As semanas depois da entrada no ar são planejadas com o mesmo cuidado da
noite, porque é nelas que os erros que sobraram aparecem.

## Hypercare

**Hypercare é um período fixo de suporte reforçado depois da entrada no ar**, com as pessoas que
construíram e migraram o sistema perto das pessoas que o usam. Na Serra Alta ele foi marcado para
oito semanas, tempo suficiente para cobrir dois pagamentos, e tinha um formato escrito antes do
cutover:

- uma reunião toda manhã às 08:30 nas duas primeiras semanas, depois duas vezes por semana, com o
  time de migração, Sebastião, o time de integração de Rui, a equipe de qualidade de Cláudia e o
  financeiro;
- uma lista única de problemas, cada um com uma gravidade e um dono, para um problema relatado duas
  vezes ser um problema só e nada relatado se perder na caixa de entrada de alguém;
- os técnicos de campo que visitam as fazendas, avisados antes, porque o produtor que acha que os
  litros do extrato estão errados liga primeiro para o técnico;
- uma saída escrita antes: dois pagamentos sem nenhuma fazenda paga errado, e nenhum problema aberto
  acima da gravidade mais baixa.

Os critérios de saída importam pelo mesmo motivo que os critérios de go/no-go da seção anterior.
**Um hypercare que termina quando as pessoas se cansam dele termina com os problemas ainda abertos**,
e eles passam a pertencer a um time de suporte que nunca viu a migração.

## O sistema antigo, somente leitura

O Coleta não sumiu às 10:00. Ele continuou no ar, **somente leitura**, por doze meses: ninguém podia
mudar nada nele, e qualquer um podia consultar. Nas primeiras semanas isso foi usado todos os dias.
Uma fazenda que contesta o pagamento de julho está perguntando sobre um mês que o Coleta calculou, e a
resposta está nas telas do Coleta, com as regras do Coleta. Um técnico de campo que quer saber se o
tanque de uma fazenda era coletado todo dia ou dia sim, dia não também consulta lá.

Somente leitura é uma decisão com custo: a máquina IBM i, as licenças e o tempo de Sebastião por mais
um ano. Em troca, toda pergunta sobre o passado tem resposta sem que ninguém precise migrar o passado
inteiro. O `legacy_code` que o mapeamento guardou no novo sistema é o que permite usar os dois lado a
lado. Quando o ano acabar, o que ainda for necessário vai para o arquivo, e a aula 13 trata de
desligar a máquina.

## Relatórios em paralelo

Durante o hypercare, os números que o negócio já acompanhava foram acompanhados duas vezes: uma a
partir do novo sistema, e outra a partir de uma fonte que a migração não tocou.

**Litros coletados contra litros recebidos.** Todo dia, os litros que os caminhões coletaram nas
fazendas são comparados com os litros que as plantas mediram quando os caminhões descarregaram. Com o
Coleta, os dois diferiam por uma margem pequena e estável que todo mundo conhecia. Depois do cutover a
mesma comparação rodou sobre os números do novo sistema. **Um degrau no dia do cutover teria apontado
para a migração**, e não houve nenhum.

**SAP contra o novo sistema.** As entradas de mercadoria de leite no SAP agora são criadas a partir do
arquivo noturno do novo sistema. Um relatório diário de litros por planta tirado do SAP, ao lado do
mesmo relatório tirado do novo sistema, mostra se a integração e o sistema concordam. Na primeira
semana eles discordaram uma vez, na segunda-feira, pelos litros de onze fazendas: as leituras delas
tinham ficado guardadas nos coletores durante a janela e foram liberadas depois das 06:00, então
chegaram ao novo sistema no domingo e ao SAP na noite de segunda. Estava certo, e era bom saber.

## O primeiro fechamento e o primeiro pagamento

O primeiro teste de verdade é o primeiro fim de mês. O financeiro fecha agosto nos primeiros cinco
dias úteis de setembro, e o leite comprado em agosto é o maior custo nos livros da Serra Alta.
Catorze dias das coletas daquele mês foram migrados e dezessete foram recebidos pelo novo sistema,
então o fechamento é onde aparece qualquer buraco entre as duas metades. O financeiro comparou os
litros de agosto com os de julho e com os do mesmo mês do ano anterior, e fechou no prazo.

**O primeiro pagamento, no dia 10, é o teste que mais importa**, porque é a primeira vez que o novo
sistema decide quanto dinheiro 1.900 fazendas recebem, e o ponto sem volta da seção anterior vem logo
antes dele. Antes de a rodada ser lançada, o financeiro comparou o pagamento de agosto de cada fazenda
com o de julho e conferiu à mão toda fazenda cujo pagamento tinha mudado mais de 15%. Foram 38.
Trinta e cinco tinham um motivo nos dados: mais litros, menos litros, um resultado de laboratório
melhor ou pior. **Três não tinham motivo**: o resultado de gordura delas era exatamente 3,50%, e o
novo sistema o pôs na faixa de baixo da bonificação por qualidade, onde o Coleta o punha na de cima.
Os três meses de execução em paralelo da aula 13 nunca tiveram uma fazenda com exatamente 3,50%, então
nem a execução em paralelo nem reconciliação nenhuma poderiam ter visto isso. A regra foi corrigida e
assinada por Cláudia, os três valores foram recalculados, e o arquivo do banco saiu no dia 9.

É para esse tipo de falha que o hypercare existe. **Uma reconciliação prova que os dados chegaram; só
usá-los prova que o sistema faz a coisa certa com eles.**

## Arquivando os dados antigos

Os dados que não mudaram de sistema ainda precisam ser guardados pelo tempo que a lei e o negócio
exigirem. As ideias da aula 5 sobre registros valem aqui: um prazo de retenção, um dono dos registros
e uma data em que os registros são destruídos.

O arquivo da Serra Alta guarda três coisas. **O histórico fora do período da migração**: as 182
fazendas e cerca de 10,5 milhões de coletas, com os 1.312 órfãos marcados. **Uma cópia completa do
Coleta no momento do congelamento**, para que qualquer pergunta sobre o que o Coleta guardava possa
ser respondida pelo arquivo depois que a máquina se for. E **uma descrição de cada campo**, escrita por
Sebastião, porque a única descrição completa do que cada campo significa é o programa RPG que o usa,
e o autor dele se aposenta em 2028.

O formato é o que ainda vai abrir daqui a vinte anos: arquivos de texto simples, CSV com o layout
escrito, e não um backup que precisa de um IBM i para ser restaurado. O arquivo é reconciliado contra
o Coleta como qualquer outro destino, por contagens e totais por ano, antes de a máquina ser
desligada. O dono dos registros é o financeiro, e o prazo de retenção e a data de descarte ficam
escritos no próprio arquivo. Um arquivo sem data de fim fica guardado para sempre por padrão, e dado
guardado para sempre é custo e, pela LGPD, um risco quando guarda o CPF de pessoas.

**Uma migração termina quando os dados antigos têm uma casa, um dono e uma data de fim**, não quando o
novo sistema entra no ar. Tudo entre esses dois momentos faz parte do plano.
