---
title: Allure, um relatório montado a partir de resultados
version: 1
---

Um arquivo de resultados não é um relatório. O XML da seção 02 guarda tudo sobre uma execução e
ainda assim não é algo que alguém abre para saber como a versão está indo. **Uma ferramenta de
relatório lê arquivos de resultado como aquele e monta páginas que as pessoas navegam: totais,
falhas com suas evidências, e como cada caso se saiu nas últimas execuções.** O Allure Report é a
de código aberto mais encontrada em times que automatizam, e é um bom exemplo do tipo. Este curso
não o rodou, e nada nesta seção pede que você o instale.

## Como ele é alimentado

O Allure não roda testes. Os testes rodam no framework que o time usa, e um **adaptador** para esse
framework escreve cada resultado numa pasta conforme os testes rodam: o desfecho, os passos que o
teste percorreu, quanto tempo cada um levou, e qualquer anexo, como uma captura de tela da página
no momento da falha ou o texto da resposta. Existem adaptadores para os frameworks comuns em várias
linguagens, e a ferramenta de linha de comando do Allure também lê JUnit XML, o formato da seção 02.

A ferramenta de linha de comando então transforma essa pasta num **site estático**: arquivos HTML
simples que podem ser abertos do disco, publicados pelo servidor de integração contínua depois de
cada execução, ou anexados a uma versão.

## O que as páginas acrescentam ao XML

**Uma visão geral.** A primeira página responde "como foi a execução" com totais por status e um
gráfico, os mesmos dezessete resultados do arquivo da seção 02 numa forma que se lê em dois
segundos.

**A falha, com a evidência.** Clicar num teste que falhou mostra os passos, o passo que falhou, a
mensagem e os anexos. Numa aplicação web a captura de tela muitas vezes é toda a evidência do relato
de defeito, já capturada, que é o assunto da aula 15 alcançado pelo outro lado.

**Histórico e tendências.** Quando os resultados das execuções anteriores são guardados e entregues
ao próximo relatório, cada teste mostra seus desfechos recentes, e a visão geral desenha uma
tendência ao longo das execuções. É o histórico de resultados da aula 18 reconstruído a partir de
execuções automatizadas. Sem os resultados anteriores, o relatório só conhece o dia de hoje.

**Agrupamento por comportamento.** Os testes podem ser rotulados com a funcionalidade ou a história
que conferem, e o relatório os agrupa assim além de por suíte. Rotulados por requisito, os
resultados do boxoffice mostrariam o R5 com três testes e uma falha, que é de novo a visão de
rastreabilidade da aula 18.

**Categorias e testes instáveis.** As falhas podem ser separadas em categorias pelas mensagens, de
modo que vinte falhas com a mesma causa se leiam como um problema só, e um teste que passou numa
nova tentativa depois de falhar é marcado como **instável** (*flaky*): um teste cujo resultado não
merece confiança numa execução só.

## Para quem ele é

O leitor do Allure é o time: o desenvolvedor que precisa do passo que falhou e da captura de tela,
e o líder de teste que precisa ver que os mesmos três testes falham há uma semana. Ele responde bem
às perguntas deles. **Ele não responde às da liderança**, pelo motivo que a seção 01 desta aula deu
sobre a taxa de aprovação: uma página de fatias verdes e vermelhas diz quantos testes falharam, e
não se o teatro pode abrir as vendas na sexta. Uma gerente que recebe o link de um relatório assim
ou aprende a lê-lo, o que é o trabalho do testador empurrado para cima, ou olha a cor do gráfico e
decide por ela.

## Os outros lugares onde resultados aparecem

O Allure é uma escolha entre várias. A maioria dos servidores de integração contínua desenha
sozinha uma página de resultados a partir de JUnit XML, o que basta para um time que só precisa ver
o que falhou no último build. As ferramentas de casos da aula 18 guardam resultados automatizados
ao lado dos manuais, para que uma execução tenha uma resposta só, seja qual for o jeito de rodar
cada caso. E um time sem ferramenta nenhuma tem um arquivo como o `results-1.1.xml` e uma pessoa
que o lê.

A escolha entre eles segue a mesma regra da escolha de uma ferramenta de casos: comece por quem lê
e pelo que essa pessoa precisa decidir.
