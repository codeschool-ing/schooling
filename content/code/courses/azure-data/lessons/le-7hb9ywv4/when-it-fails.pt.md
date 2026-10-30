---
title: A noite em que falha
version: 1
---

**Um pipeline é julgado pela pior noite dele, e o papel do Data Factory nessa noite é falhar de forma
visível.** Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.

## Como é uma falha

**Toda execução de um pipeline, e toda atividade dentro dele, é registrada com status, entradas,
saídas e erro**, e a visão de monitoramento do portal as mostra. A Microsoft documenta que a factory
guarda esse histórico por 45 dias; um time que precisa de mais, ou quer consultá-lo, o manda para um
workspace do Log Analytics pelas configurações de diagnóstico da factory, que é território de
`azure-operations`. Na cópia da Quitanda, o erro de uma execução falha diz que lado falhou, origem ou
destino, e por quê: o arquivo não estava lá, a identidade foi recusada, o CSV tinha uma linha com
onze campos onde o dataset esperava dez.

**Uma falha que ninguém ouve é o mesmo que nenhuma carga.** O Data Factory pode disparar um alerta
pelo Azure Monitor quando uma execução de pipeline falha, e o alerta chega a um telefone por um
action group. Uma factory sem alerta tem uma visão de monitoramento que mostra a linha vermelha a quem
a abrir, e a primeira pessoa a abri-la costuma ser a analista que percebeu que ontem sumiu de um
dashboard.

## As três saídas

**Retry, na política da atividade**, para o que passa sozinho: uma falha de rede momentânea, um banco
que estava ocupado. O pipeline da quarta seção tenta a cópia de novo duas vezes, com cinco minutos
entre elas.

**Reexecutar, à mão ou pelo gatilho**, depois que a causa é corrigida. O Data Factory consegue
reexecutar um pipeline a partir da atividade que falhou, mantendo o que deu certo antes dela, e uma
tumbling window consegue reexecutar uma janela. De um jeito ou de outro, o pipeline roda uma segunda
vez para o mesmo dia.

**Desviar, no pipeline**: as setas de uma atividade podem dizer "em caso de falha", para que o
pipeline mande a própria mensagem ou escreva a própria linha numa tabela de log quando um passo
falha, com o erro dentro.

## Seguro de rodar duas vezes

**Uma reexecução só é segura se rodar o pipeline duas vezes para o mesmo dia der o mesmo resultado
que rodar uma vez.** A cópia desta lição escreve o Parquet do dia em `orders/dt=<dia>/`; se ela
substitui o que está lá, uma reexecução depois de uma noite que parou no meio deixa uma cópia do dia,
e se ela acrescenta arquivos ao lado do que está lá, uma reexecução deixa o dia duas vezes. O Data
Factory não escolhe por você. Numa tabela Delta, os commits da lição 18 deixam a escolha explícita: a
substituição da partição de um dia é um commit que remove os arquivos antigos e adiciona os novos, e
os leitores veem o dia antigo ou o novo.

Todo gatilho da seção anterior reexecuta janelas, toda atividade tenta de novo, e pessoas reexecutam
noites; um pipeline que não é seguro de rodar duas vezes transforma cada uma dessas coisas num
duplicado no lago. A lição 24 dá nome a essa propriedade e mostra as consequências dela em streams.
