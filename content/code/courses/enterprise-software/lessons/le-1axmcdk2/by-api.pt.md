---
title: Por API, uma resposta agora se todos estiverem no ar
version: 1
---

Uma chamada é a integração que todo desenvolvedor já conhece. Um sistema manda uma requisição, o
outro faz o trabalho e responde, e quem chamou segue em frente com a resposta na mão. A Joana passou
oito anos construindo serviços que se chamavam assim, e sua primeira correção na Serra Alta, na aula
1, foi uma dessas: em vez de um arquivo de estoque gravado a cada hora, o Portal B2B agora pergunta
ao SAP o estoque disponível quando uma padaria fecha o pedido. **Uma API dá a quem chama uma resposta
atual no momento em que precisa dela. O preço é que quem chama, e tudo o que fica entre ele e a
resposta, precisa estar no ar e rápido nesse momento.**

Hohpe e Woolf chamam o estilo de invocação remota de procedimento, que é o nome honesto: ele faz uma
chamada a outro sistema parecer a chamada de uma função do seu. REST e SOAP são esse estilo. O
envelope SOAP da aula 8 e uma requisição JSON sobre HTTP diferem em formato, em ferramentas e em
moda, e acoplam dois sistemas no tempo exatamente do mesmo jeito.

## Os dois no ar ao mesmo tempo

A consulta de estoque no checkout não vai do portal direto ao SAP. Vai do portal a um fluxo do ESB,
que chama o SAP, então três sistemas precisam estar funcionando para uma padaria ver um número. Nos
últimos doze meses, cada um dos três esteve disponível cerca de **99,5%** do tempo. Parecem três
números bons. A cadeia é o produto deles:

0,995 × 0,995 × 0,995 = 0,98507, ou seja, cerca de **98,5%**.

**Uma cadeia de chamadas é menos disponível do que o seu elo mais fraco**, porque falha sempre que
qualquer um deles falha. Num mês de 30 dias, com 720 horas, 99,5% permite 3,6 horas fora do ar para
cada sistema sozinho; o 1,49% da cadeia dá cerca de 10,7 horas em que o checkout de uma padaria não
consegue um número de estoque. A conta supõe que os três falham de forma independente, o que não é
bem verdade: o ESB e o portal dividem uma rede, e uma noite ruim para um costuma ser uma noite ruim
para os dois. A aula 12 desenvolve essas contas, e os jeitos de comprar disponibilidade de volta, com
calma.

As paradas planejadas vêm por cima. O SAP para todo domingo, da 01:00 às 05:00, para manutenção, e
essa janela não está nos 99,5%. O desenho da aula 1 já sabe disso: nas noites de domingo o portal
mostra o último número que tinha, com a hora em que foi obtido, e confirma o pedido depois. Guarde
esse desenho; ele acaba sendo a resposta para mais coisas do que o domingo.

## Quem espera

Toda chamada tem alguém esperando na ponta, e a pergunta útil sobre qualquer integração por API é
**quem espera, por quanto tempo, e o que acontece quando a espera acaba**. Na consulta de estoque,
quem espera é o dono de uma padaria numa página de checkout. Cada sistema no caminho tem um timeout,
o tempo máximo que espera antes de desistir, e a Joana os tinha configurado do jeito que quase todo
mundo faz: separadamente, cada um com um número que parecia razoável sozinho.

| salto | timeout | o que acontece quando ele acaba |
|---|---|---|
| navegador → portal | nenhum definido; a padaria espera | a padaria desiste e sai, ou aperta o botão de novo |
| portal → ESB | 10 segundos, depois duas novas tentativas automáticas | uma página de erro depois da terceira tentativa |
| ESB → SAP | 60 segundos, o padrão do ESB | um erro para o portal, que parou de escutar muito antes |

Na sexta-feira, 2 de outubro de 2026, na semana de fechamento, o SAP estava ocupado com os jobs de fim
de mês do financeiro, e a consulta de disponibilidade, que normalmente responde em menos de um
segundo, levou entre 20 e 40 segundos. O portal esperou 10 segundos e desistiu; o ESB, com 60
segundos para esperar, não desistiu, então o SAP continuou trabalhando numa requisição que ninguém
queria mais. Aí o portal tentou de novo, o que abriu uma segunda consulta no SAP ao lado da primeira,
e depois uma terceira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-timeouts\" aria-label=\"Uma linha do tempo de um checkout em 2 de outubro de 2026, de 0 a 60 segundos. O portal chama o ESB três vezes, e cada tentativa estoura o timeout em 10 segundos, aos 10, 20 e 30 segundos, e a padaria vê uma página de erro aos 30 segundos. O ESB, com timeout de 60 segundos, mantém abertas suas três chamadas ao SAP: a primeira de 0 a 35 segundos, a segunda de 10 a 42, a terceira de 20 a 55. Tudo o que vem depois de o portal desistir de cada tentativa está em âmbar, como trabalho que ninguém está esperando, e na maior parte do tempo o SAP está fazendo três consultas de disponibilidade para uma cesta só.\"><path d=\"M150.0 228.0 L630.0 228.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 228.0 L150.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M230.0 228.0 L230.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M310.0 228.0 L310.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"310.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><path d=\"M390.0 228.0 L390.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"390.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><path d=\"M470.0 228.0 L470.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40 s</text><path d=\"M550.0 228.0 L550.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 s</text><path d=\"M630.0 228.0 L630.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 s</text><text x=\"14.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">padaria</text><rect x=\"150.0\" y=\"51.0\" width=\"240.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esperando</text><text x=\"398.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">página de erro</text><text x=\"14.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portal → ESB</text><text x=\"14.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeout 10 s</text><rect x=\"151.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tentativa 1</text><rect x=\"231.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tentativa 2</text><rect x=\"311.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tentativa 3</text><text x=\"14.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ESB → SAP</text><text x=\"14.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeout 60 s</text><rect x=\"150.0\" y=\"140.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"140.0\" width=\"200.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"436.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP responde aos 35 s</text><rect x=\"230.0\" y=\"162.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"310.0\" y=\"162.0\" width=\"176.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"492.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP responde aos 42 s</text><rect x=\"310.0\" y=\"184.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"184.0\" width=\"200.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"596.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP responde aos 55 s</text><rect x=\"150.0\" y=\"266.0\" width=\"22.0\" height=\"12.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"180.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trabalho que ninguém espera: o portal já desistiu</text></svg>", "caption": "Um checkout na semana de fechamento. O portal desiste três vezes; o ESB nunca, então o SAP acaba conferindo a mesma cesta três vezes justamente quando está mais lento.", "same": ["0 s", "10 s", "20 s", "30 s", "40 s", "50 s", "60 s", "ESB → SAP", "portal → ESB", "timeout 10 s", "timeout 60 s"]}
```

Entre 09:00 e 11:00 daquela manhã, **212 checkouts falharam depois de 30 segundos de espera**, e o
SAP recebeu cerca de três vezes o número habitual de consultas de disponibilidade, no momento em que
estava menos capaz de respondê-las. As novas tentativas, pensadas para deixar a integração mais
confiável, multiplicaram a carga sobre o sistema que já estava lento. O cache curto que a Joana tinha
posto não ajudou, porque um cache só responde por um produto que alguém consultou no último minuto, e
a cesta de uma padaria é feita quase toda de produtos que ninguém mais tinha acabado de consultar.

## Timeouts e novas tentativas que trabalham juntos

Nada naquele incidente era um bug. Todo sistema fez exatamente o que estava configurado para fazer, e
a configuração estava errada como conjunto. As regras que corrigem isso são curtas.

**Quanto mais fundo o salto, menor o timeout.** Um timeout interno maior que o externo garante
trabalho que ninguém está esperando. A Serra Alta agora dá ao ESB 6 segundos para conseguir uma
resposta do SAP e ao portal 8 segundos para conseguir uma do ESB, de modo que o ESB desiste primeiro
e avisa enquanto o portal ainda está escutando.

**Só tente de novo o que é seguro, e não contra um sistema em dificuldade.** Perguntar o estoque de
novo é inofensivo; fazer o pedido de novo não é, a menos que quem recebe consiga reconhecer a segunda
tentativa como o mesmo pedido, que é o assunto da aula 10. E uma nova tentativa quando a causa é
sobrecarga acrescenta carga: se tentar de novo fizer sentido, espera mais entre uma tentativa e outra
e para depois de uma ou duas.

**Decida o que quem chama faz quando a resposta não vem.** Esse é o passo que as pessoas esquecem,
porque é uma decisão de negócio, não técnica. O portal já tinha uma resposta, feita para as noites de
domingo: mostrar o último número de estoque com a hora, aceitar o pedido, e confirmá-lo quando o SAP
responder. Desde outubro o portal usa isso sempre que o SAP passa do timeout, e na semana de
fechamento de novembro nenhum checkout falhou. **Uma integração síncrona precisa de um comportamento
planejado para quando o outro lado estiver lento, e lento é mais comum que fora do ar.**

## Quando a chamada é o estilo certo

Nada disso faz da chamada um estilo ruim. Ela é a certa quando três coisas valem juntas: quem chama
não consegue seguir sem a resposta, a resposta precisa ser atual, e alguém está esperando por ela. A
consulta de estoque cumpre as três, e foi por isso que a aula 1 a tirou de um arquivo e a passou para
uma chamada. Um certificado de qualidade que um supermercado pede pelo número do lote também cumpre as
três, e a última seção desta aula lhe dá uma API.

Onde falta uma das três, a chamada é um acoplamento que você paga sem precisar. Se ninguém está
esperando, como nas 1.900 linhas de produtores que o SAP só vai usar no fim do mês, a chamada
acrescenta uma dependência de tempo a uma integração que nunca precisou dela. E se quem chama não
precisa de resposta nenhuma, porque só quer contar a outros sistemas que algo aconteceu, então fazê-lo
chamar cada um deles por vez é o assunto da próxima seção.
