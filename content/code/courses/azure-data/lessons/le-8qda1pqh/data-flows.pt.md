---
title: "Mapping data flows: Spark desenhado como caixas"
version: 1
---

**Um mapping data flow é uma transformação desenhada no editor do Data Factory e rodada como job
Spark num cluster que o Data Factory inicia para ele.** Ninguém escreve código Spark: as caixas e as
configurações delas viram Spark pelas mãos do serviço. É a metade de transformação do pipeline da
lição 19, para times que querem a noite inteira numa ferramenta visual. Esta seção é ensinada a
partir da documentação da Microsoft e não foi executada; não há emulador para data flows, e eles
precisam de um cluster para rodar.

## Do que ele é feito

**Um data flow é um grafo de transformações, de uma ou mais origens a um ou mais destinos.** O editor
oferece as operações de que um job de limpeza precisa, cada uma como uma caixa com as próprias
configurações:

- **source** e **sink**, que leem e gravam datasets, os mesmos datasets e linked services da
  atividade de cópia da lição 19;
- **filter**, **select** e **derived column**, que descartam linhas, mantêm ou renomeiam colunas e
  calculam colunas novas com uma linguagem de expressões do próprio Data Factory;
- **aggregate**, **join**, **lookup**, **union** e **conditional split**, que fazem o que os nomes
  dizem, entre fluxos de linhas;
- **window**, **rank** e **pivot**, para as perguntas que precisam deles;
- **alter row**, que marca linhas para serem inseridas, atualizadas, mescladas ou apagadas num destino
  de banco.

A noite da Quitanda, desenhada assim, é uma source sobre o CSV cru, uma derived column que tira os
espaços e as maiúsculas da forma de pagamento e transforma `42,87` em centavos, um aggregate que
mantém uma linha por pedido, e um sink na pasta curada: quatro caixas para o que a seção depois da
próxima escreve como uma consulta.

**Por trás das caixas há um script**, que o editor mostra e que o Data Factory guarda na definição do
data flow. É o que o `azurerm_data_factory_data_flow` do Terraform recebe, e o que uma revisão no Git
vê: um texto, mas escrito pelo editor e não por uma pessoa, e raramente lido por uma.

## Onde ele roda

**Todo data flow roda num cluster Spark que o integration runtime do Azure inicia**, dimensionado em
núcleos, e a seção sobre o relógio põe preço nele. O cluster pertence à execução: o Data Factory o
inicia, roda o job e o para, a menos que um time to live o guarde para o próximo. **Não há cluster
para cuidar**, nem versão para atualizar nem biblioteca para instalar, e é por isso, quase sempre,
que times escolhem data flows. O mesmo vale para tudo o que você não pode mudar: a versão do Spark, a
configuração, o que pode ser instalado.

**Para construir um, o editor oferece uma sessão de debug**: um cluster mantido ligado enquanto você
trabalha, com uma prévia das linhas depois de cada caixa. Ela é cobrada enquanto roda, e é como se faz
quase todo trabalho com data flow, olhando linhas em vez de escrever testes, assunto ao qual a seção
de testes volta.

## Os dataflows do Fabric são outra coisa

**O Fabric tem o "Dataflow Gen2", que não é um mapping data flow.** É o Power Query, a ferramenta de
transformação do Excel e do Power BI, rodando no Fabric e pago com a capacidade da lição 17. Ele
desenha caixas parecidas para passos parecidos, e o motor por baixo, a linguagem e os limites são
outros. Um time que muda do Data Factory para o Fabric leva os pipelines com mais facilidade que os
data flows, o que vale saber antes de desenhar muitos.
