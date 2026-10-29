---
title: WebPageTest
version: 1
---

**O WebPageTest carrega a sua página de um navegador real em outro lugar do mundo**, numa conexão que
você escolhe, e descreve a carga com mais detalhe que qualquer outra ferramenta: uma cascata de cada
requisição, uma tira de filme do que a janela mostrou enquanto a página carregava, um vídeo, e as Core
Web Vitals daquela carga. Ele começou como um projeto de código aberto, é mantido hoje pela Catchpoint em
webpagetest.org, e o código continua público para quem quiser rodar o seu.

**Este curso não o rodou**, e a seção diz isso com todas as letras: o WebPageTest carrega a página das
máquinas dele, então só consegue testar uma página num endereço público, e tudo neste curso roda no seu
computador. O que vem a seguir é o que a documentação dele descreve. Use-o na primeira página que você
puser na internet; os termos do serviço público são da Catchpoint, que os define e os muda.

## O que ele acrescenta às outras duas

- **Um lugar e uma rede de verdade.** Um teste roda de uma cidade que você escolhe, num perfil de conexão
  como cabo ou 4G, então as idas e voltas são idas e voltas de verdade pela internet, e não 300
  milissegundos acrescentados num computador.
- **Várias rodadas, e a mediana.** Um teste costuma carregar a página mais de uma vez e mostrar a rodada
  mediana, pelo motivo que a seção "Simulado, ou desacelerado de verdade" deu.
- **First view e repeat view.** A segunda carga de um teste roda com o cache que a primeira encheu, que é
  a visita de quem volta, e a que a aula 9 deixa rápida.
- **A tira de filme.** Uma fileira de quadros, num intervalo que você escolhe, alinhada com a cascata. É
  o jeito mais claro de mostrar a outra pessoa como é uma carga lenta, e de ver que um LCP de três
  segundos foi uma tela em branco durante dois deles.

## Quando usar qual

**O Lighthouse para perceber, o painel para explicar, o WebPageTest para ver uma primeira visita real de
longe.** Um problema costuma passar por elas nessa ordem: uma nota cai no Lighthouse, o painel mostra a
tarefa longa ou a requisição tardia por trás, e o WebPageTest confirma o que um visitante em outro país,
numa rede de celular lenta, de fato espera. E as três são dados de laboratório: os dados de campo da aula
5 é que dizem se a correção importou para quem usa a página.
