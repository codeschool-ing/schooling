---
title: Modos degradados: trabalhar enquanto uma dependência está fora
version: 1
---

Todo sistema da Serra Alta depende de outro, e cada um desses vai ficar fora do ar em algum momento,
de propósito ou não. A pergunta que um arquiteto deve a cada dependência não é se ela vai falhar, mas
**o que este sistema faz enquanto ela está falhando**. "Mostra um erro" é uma resposta, e para uma
padaria fazendo o pedido de amanhã às 05:30 é a pior disponível.

Um **modo degradado** é um jeito de trabalhar com menos: menos funcionalidades, dados mais velhos,
confirmação mais lenta, mais trabalho manual, mas trabalhando. Ele é projetado com antecedência,
ligado de propósito e tem um caminho de volta. A crença comum que ele substitui é que resiliência
significa manter tudo no ar. Manter tudo no ar é a aritmética de disponibilidade da primeira seção,
e essa aritmética diz que toda cadeia falha alguns dias por ano. Um modo degradado é o que o negócio
faz nesses dias.

## Cinco formatos

A maioria dos modos degradados tem um entre poucos formatos. A Serra Alta tem todos eles, alguns de
propósito e alguns por costume.

*Guardar e encaminhar.* O trabalho é aceito e guardado até o outro lado poder recebê-lo. O arquivo
noturno do Coleta esperando no diretório durante a janela de domingo do SAP é o exemplo mais antigo.
Uma fila na frente de um sistema é a mesma ideia com ferramentas melhores, e a aula 10 trata de
torná-la confiável. O que ela precisa é de espaço para guardar, da garantia de que nada guardado se
perde e de um consumidor que consiga alcançar o atraso.

*Servir dados velhos, com a idade deles.* Quando a fonte não consegue responder, dê a última
resposta que ela deu e diga quando foi. Desde a aula 1 o portal faz exatamente isso nas noites de
domingo: a padaria vê o número de estoque de antes da janela, com o horário ao lado. **A idade é o que
torna honesto o dado velho.** O mesmo número sem o horário é uma mentira que por acaso está quase
certa.

*Aceitar agora, confirmar depois.* O pedido é recebido sem o sistema que o confirmaria, e é
confirmado ou recusado quando esse sistema volta. Isso tira uma falha do momento em que o cliente
está esperando e a leva para um momento em que alguém consegue tratar dela. Também cria um caso novo
de que o negócio tem de ser dono: o pedido aceito no domingo à noite que o SAP não consegue atender
na segunda de manhã. A regra do portal é que a padaria é avisada antes de os caminhões de entrega
serem carregados, por mensagem, com o item que não pôde ser fornecido.

*Fazer à mão.* Um formulário de papel numa gaveta é um modo degradado, e muitas vezes o mais
confiável. Quando a máquina do Coleta está inacessível, a recepção de cada fábrica anota os
caminhões que chegam numa folha impressa, e alguém digita as folhas quando ela volta. É lento, e
precisa de pessoas que saibam onde fica a gaveta, o que significa que precisa ser treinado.

*Trabalhar desconectado na borda.* O coletor de mão em cada caminhão de leite registra os litros de
cada fazenda, a temperatura do tanque e a etiqueta do frasco de amostra. Boa parte da rota passa por
vales sem sinal de celular, então o coletor nunca precisou da rede para funcionar. Ele guarda as
coletas, imprime um comprovante para o produtor e envia tudo quando volta a ter sinal. Ele mantém os
últimos sete dias, então um envio que falhou se conserta mandando de novo. **Um projeto que supõe que
a rede não existe não pode ser quebrado pela ausência dela**, e para os caminhões era o único projeto
que tinha alguma chance.

## Um modo degradado previsto em lei: a contingência da NF-e

Alguns modos degradados estão escritos na lei, e a nota fiscal eletrônica brasileira é um deles. Uma
carga de iogurte não pode sair da fábrica até a NF-e dela ser autorizada pela secretaria da fazenda
do estado, e o serviço da secretaria é uma dependência como qualquer outra: às vezes lento, às vezes
inacessível. Como mercadoria que não pode ser faturada não pode ser expedida, uma queda na
secretaria pararia os caminhões.

Por isso as regras da NF-e definem modos de contingência para emitir quando a autorização normal
está indisponível. Entre eles estão a autorização por uma secretaria virtual de contingência operada
fora da do estado emissor (SVC, a SEFAZ Virtual de Contingência) e o registro prévio de um resumo da
nota (EPEC), que deixa a mercadoria sair enquanto a nota completa é autorizada depois. O documento
impresso que acompanha a mercadoria diz que foi emitido em contingência, e o emissor tem de
regularizar cada nota depois.

Para a arquitetura, os detalhes importam menos do que três fatos sobre eles. **Ligar o modo degradado
cabe ao emissor**, então alguém na Serra Alta tem de decidir, e tem de saber que pode. O software que
emite as notas precisa já suportá-lo, configurado e testado antes do dia em que for preciso. E sair
dele dá trabalho: cada nota emitida em contingência tem de ser acompanhada até ficar regular. O
registro de Joana dá ao fluxo da NF-e um responsável nomeado pela chave e um roteiro para as duas
direções.

## O roteiro

Um modo degradado que só existe na cabeça de um arquiteto vai ser improvisado por outra pessoa, de
noite, de outro jeito. O roteiro de cada um tem os mesmos passos na mesma ordem:

1. detectar que a dependência caiu, por um alarme sobre um objetivo e não por um telefonema de
   cliente;
2. declarar o modo degradado: uma pessoa nomeada decide, e a decisão é registrada com o horário;
3. trocar: ligar a alternativa, seja o número guardado do portal, a fila ou o formulário de papel;
4. avisar as pessoas afetadas: as padarias, as fábricas, o atendimento, quem atende o telefone;
5. escoar o que se acumulou, quando a dependência voltar;
6. conciliar: conferir que tudo o que foi feito em modo degradado chegou ao destino exatamente uma
   vez, e encerrar o modo.

O quinto passo é o que se esquece quando o modo é projetado. **Sair de um modo degradado leva tempo,
e o tempo pode ser calculado.** Suponha que o SAP fique indisponível por 4 horas numa noite de dia
útil, enquanto as padarias fazem cerca de 120 pedidos por hora pelo portal. O portal os aceita para
confirmação posterior, então 4 × 120 = 480 pedidos estão esperando quando o SAP volta. O job que os
cria no SAP processa cerca de 360 pedidos por hora, e novos pedidos continuam chegando a 120. O
acúmulo diminui 360 − 120 = 240 por hora, então leva 480 ÷ 240 = 2 horas para zerar. A queda durou
quatro horas; o modo degradado durou seis. Se o escoamento fosse de só 120 por hora, o acúmulo nunca
diminuiria, e esse é um defeito de projeto que vale encontrar no papel e não às 03:00.

O sexto passo é território da aula 10: uma mensagem entregue duas vezes durante a recuperação não
pode criar dois pedidos, e é para isso que existe um consumidor idempotente.

## Um modo degradado é testado, ou é um palpite

A primeira vez que um modo degradado é usado não deveria ser a primeira vez que ele roda. Com Rui e a
equipe do portal, Joana desligou o serviço de estoque de propósito por vinte minutos numa tarde calma
de terça-feira, com aviso prévio, e observou o que as padarias viam. O portal serviu o número
guardado, como projetado. O horário ao lado dele estava três horas errado, porque era mostrado em UTC
e não no horário de Brasília. Ninguém tinha visto isso antes, porque nas noites de domingo ninguém
tinha olhado.

Esse único teste achou um defeito que nenhuma revisão tinha achado, e custou vinte minutos. **Uma
alternativa que nunca foi ligada é uma hipótese sobre como o sistema se comporta**, e é mais barato
testar a hipótese numa terça-feira do que na noite em que ela for necessária.
