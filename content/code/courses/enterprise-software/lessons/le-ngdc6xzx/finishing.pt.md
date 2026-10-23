---
title: Terminar, e desligar
version: 1
---

O strangler tem um jeito característico de falhar, e não é no começo. O sistema novo entra em
produção, uma capacidade depois da outra muda de lado, os painéis ficam verdes, e então o progresso
desacelera até parar, com o sistema antigo ainda rodando "para umas poucas coisas". **O último
décimo de uma migração é a parte mais difícil, porque ele é feito de tudo o que ninguém sabia que o
sistema antigo fazia.** Uma migração que para ali carrega para sempre o custo dos dois sistemas:
dois conjuntos de licenças e de hardware, dois grupos de pessoas que os entendem, e um sistema antigo
que ninguém melhora e que ninguém tem permissão de desligar.

## As capacidades que você não listou

O inventário do Coleta que a Joana fez no primeiro mês do plano tem doze capacidades: cadastrar
fazendas, receber as coletas dos coletores portáteis, corrigir coletas, receber os resultados de
laboratório, suspender e liberar fazendas, calcular o pagamento, imprimir os extratos das fazendas,
o arquivo noturno para o SAP, os valores do pagamento mensal para o SAP, a consulta de fazenda, o
resumo da coleta e os relatórios que o setor de pagamento roda.

Ela não deixou a busca pelo resto para o fim. No segundo mês do plano o time foi procurar, e achou
três coisas que não estavam em inventário nenhum:

- uma planilha do financeiro que lê as tabelas do Coleta diretamente por uma conexão ODBC, e que é
  atualizada a cada fechamento do mês para estimar o custo do leite antes de o SAP ter os números
  finais;
- um arquivo que o Coleta manda no dia 5 de cada mês para uma cooperativa de crédito de produtores,
  com as parcelas de empréstimo a descontar do pagamento dos associados, criado em 2012 e rodado pelo
  agendador desde então;
- o informe anual que cada fazenda recebe em fevereiro, resumindo um ano de litros e pagamentos, que
  roda uma vez por ano e tinha rodado pela última vez antes de a Joana entrar na empresa.

Nenhuma delas estava escondida. Cada uma simplesmente não estava onde alguém olhava: uma planilha não
é um sistema, o arquivo da cooperativa sai por um job que ninguém acompanha, e um job de fevereiro é
invisível de março a janeiro. **O inventário passou de doze capacidades para quinze, e todo número de
progresso baseado em doze estaria errado.** Um relatório que conte nove capacidades migradas mostra
75% contra o primeiro inventário; contra o verdadeiro, são 60%. O denominador de uma migração cresce
conforme as pessoas procuram melhor, e um time que descobre esse crescimento nos últimos meses
o relata como atraso.

## Como achar os últimos usuários

Achá-los é uma atividade deliberada, e ela usa três fontes.

A primeira são as evidências do próprio sistema. O IBM i registra quais jobs rodam e quais conexões
se abrem, e os journals registram quais programas alteram quais tabelas. Uma lista de todos os jobs
que o agendador disparou no último ano e de todos os clientes que se conectaram ao banco no último
trimestre é uma lista dos usuários do Coleta, tenha alguém lembrado de mencioná-los ou não. Foi assim
que as três coisas acima foram achadas.

A segunda é a rede. O firewall na frente do IBM i conhece todo endereço que abriu uma conexão com
ele. Um endereço que não pertence a nenhum sistema conhecido é uma pergunta a fazer.

A terceira é desligar coisas de propósito e observar, e ela vem no fim. **Deixe o sistema antigo só
para leitura, mantenha-o rodando e registre cada tentativa de gravar nele, por pelo menos um ciclo
completo do negócio.** Para o Coleta esse ciclo é um mês que inclua o fechamento, e para os jobs
anuais é um ano, e por isso o informe anual precisou ser achado lendo o agendador, e não esperando.
A versão bruta, desligar alguma coisa para ver quem reclama, acha as mesmas coisas, só que as acha
na forma de incidentes.

## A ordem de desligar

Desligar um sistema é uma sequência, e cada passo é reversível até chegar àquele que não é.

1. Pare as entradas. Os caminhos de interceptação param de repassar qualquer coisa para o Coleta, e
   o lado de saída da camada anticorrupção para de gravar nele. Daqui em diante nada novo chega.
2. Deixe-o só para leitura. Todo usuário perde a autorização de alterar qualquer coisa; as telas
   continuam mostrando o histórico para os funcionários que consultam o registro de uma fazenda de
   2019. O plano marca isso para 3 de julho de 2028.
3. Arquive o que precisa ser guardado. Os registros de pagamento são documentos financeiros, e o
   Coleta guarda trinta anos deles. O que é guardado, em que formato e por quanto tempo é decidido
   pelas pessoas responsáveis por esses registros, o Marcos pelos financeiros e a Cláudia pelos de
   qualidade, seguindo as regras de retenção que a aula 5 descreve. Levar os dados em si é assunto
   da aula 14.
4. Desligue a máquina. O IBM i é desligado mas mantido intacto por um prazo escrito no plano, para
   o caso de aparecer algo que ninguém achou. É o último ponto em que voltar atrás é barato.
5. Encerre tudo o que está em volta: o contrato de manutenção do hardware e a assinatura de software
   da IBM, as licenças do emulador de terminal, os dois fluxos do barramento, as regras de firewall,
   as contas de usuário, a cópia no site de recuperação de desastres, o código da camada
   anticorrupção que lê os journals do Coleta e as rotas da fachada que ainda apontam para ele.

**O quinto passo é o que as migrações esquecem, e é onde está o dinheiro.** Uma máquina desligada cujo
contrato de manutenção se renova todo ano é um custo que sobrevive ao sistema por tanto tempo quanto
ninguém ler a fatura.

## A data, escrita no começo

**Um desligamento que não está escrito com data não acontece.** Ele escorrega, um mês de cada vez,
atrás do que o negócio precisa naquele mês. Por isso o desligamento é um registro de decisão como
qualquer outro (o `architecture-role` ensinou a forma deles), e a Joana o escreveu no começo da
migração, e não no fim. Ele diz que o Coleta será desligado em 30 de novembro de 2028, o que será
arquivado e onde, quais contratos terminam e quando, e quem responde por cada parte. A Regina assinou como CIO, o Marcos pelos registros financeiros e a Cláudia pelos de
qualidade. Um registro escrito no começo pode ser revisto, e revê-lo é um ato visível com um motivo;
uma data que só existe na cabeça das pessoas se move sem que ninguém decida movê-la.

As datas foram escolhidas pensando numa pessoa. O Sebastião sai no fim de junho de 2028, e o plano
muda o pagamento de lado em abril, para que quem mais conhece o Coleta ainda esteja lá nos primeiros
pagamentos que o Coleta não calcula. O Coleta fica só para leitura na segunda-feira depois do último
dia dele, e continua no ar até o fim de novembro, para que vários fechamentos de mês rodem com ele
antes de a máquina ser desligada. A última tarefa dele na Serra Alta não é escrever código. É
percorrer o histórico do Coleta com os funcionários, para confirmar que eles acham o registro de uma
fazenda sem ele, e ler mais uma vez os testes da camada anticorrupção.

## Meça o que foi desligado

A pergunta "em que ponto está a migração?" tem duas respostas honestas que contam histórias
diferentes. Uma conta o que foi construído: as capacidades que os sistemas novos atendem. A outra
conta o que foi removido: entradas paradas, telas desativadas, jobs apagados do agendador, usuários
sem autorização de alterar, contratos encerrados. Um mês em que os sistemas novos atendem nove
capacidades pode ter a segunda contagem ainda perto de zero, porque o Coleta continua fazendo as
outras seis e a máquina, os contratos e as pessoas continuam sendo pagos.

**O progresso de um strangler se mede pelo que foi desligado, porque essa é a única medida que não
dá para atingir enquanto o sistema antigo ainda é necessário.** A primeira contagem diz que os
sistemas novos são capazes. A segunda diz que a empresa deixou de depender do antigo, que é para o
que a migração existe. O relatório mensal da Joana para a Regina traz as duas, e a segunda vem
primeiro.

Esta aula planejou a substituição do Coleta: como o trabalho muda de lado, como os dois sistemas
convivem e como o antigo termina. Ficaram duas perguntas abertas. Como trinta anos de fazendas e
coletas são levados para o sistema novo e provados completos é a aula 14. Se o sistema novo de
pagamento será comprado, construído ou acrescentado ao SAP, e quanto essa escolha custa em três anos,
é a aula 15.
