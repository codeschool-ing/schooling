---
title: Um produto, três sistemas e o caminho até a produção
version: 1
---

Joana passou a segunda semana na Serra Alta com o time de SAP de Edson Prado, e chegou com a imagem
que a maioria dos engenheiros vindos de empresa de produto tem. O SAP, pensava ela, era uma aplicação
grande: instalada uma vez, atualizada de tempos em tempos e acessada por algum tipo de API. **Na
Serra Alta, o SAP é um produto dividido em módulos que compartilham um banco de dados. Ele roda como
três sistemas separados, só muda quando uma mudança registrada passa de um sistema para o próximo, e
é mais configurado do que programado.** Cada uma dessas partes limita o que um arquiteto pode fazer em
volta dele, e esta seção trata de uma por vez.

Como os outros quatro produtos das aulas 2 a 6, o SAP é ensinado aqui a partir da documentação
publicada e de como uma empresa o usa. Você não vai entrar num sistema SAP neste curso. A SAP vende o
software para empresas, em contratos negociados por um time de vendas, e não para pessoas físicas.
Ela publica sistemas de avaliação para desenvolvedores, mas eles pedem muito mais memória do que um
notebook tem, e nada aqui depende de um deles. O que um arquiteto precisa é saber onde ficam as
bordas, e elas estão documentadas.

## Cinquenta anos de um produto

A SAP foi fundada em 1972 por cinco ex-funcionários da IBM na Alemanha, e a ideia desde o começo era
o software padrão: um programa, vendido a muitas empresas, que cada uma configura em vez de escrever
o seu. A linha tem quatro nomes que vale conhecer, e a Serra Alta roda o terceiro.

| geração | quando | onde rodava |
|---|---|---|
| R/2 | 1979 | mainframes |
| R/3 | 1992 | cliente-servidor, em três camadas |
| ECC 6.0 | a última versão da linha clássica | as mesmas três camadas, sobre vários bancos de dados possíveis |
| S/4HANA | 2015 | as mesmas três camadas, só sobre o banco HANA, da própria SAP |

**O R/3 definiu a forma que todas as versões seguintes mantiveram.** Ele dividiu o sistema em três
camadas: a de *apresentação*, que é o SAP GUI na mesa de cada usuário; a de *aplicação*, um conjunto
de servidores de aplicação rodando os programas da SAP; e um *banco de dados*. Acrescente servidores
de aplicação e o sistema atende mais usuários. O banco continua único, e é isso que a aula 1 quis
dizer com um banco só: quando um almoxarife em Lavras lança uma entrada de mercadoria, o estoque que
um vendedor em Juiz de Fora vê muda na mesma transação.

O ECC 6.0, a versão que a Serra Alta instalou em 2011, é o fim da linha clássica. A SAP não lançou um
ECC 7. As melhorias vieram depois como *enhancement packages* aplicados sobre o 6.0, então duas
empresas que dizem "ECC 6.0" podem estar a vários anos de distância no que de fato rodam. O S/4HANA
é a geração seguinte e não é um ECC mais novo, como a próxima seção explica.

## Módulos não são fronteiras

A aula 1 listou os sete módulos que a Serra Alta licencia, FI, CO, SD, MM, PP, QM e WM, e o que cada
um registra ali. Um time de SAP fala nesses códigos o dia inteiro, e num segundo vocabulário também:
o *código de transação* que abre cada tela. `VA01` cria uma ordem de venda, `ME21N` um pedido de
compra, `MIGO` lança um movimento de mercadoria. Joana guardou uma lista deles num cartão durante o
primeiro mês, porque o pessoal de Edson dizia "dá erro na `VA01`" do jeito que o time antigo dela
dizia "dá erro no checkout".

**Um módulo é mais uma fronteira de licença e de organização do que uma fronteira técnica.** Os sete
compartilham um banco e um fluxo de documentos, então uma ordem de venda no SD reserva estoque no MM,
o faturamento dela lança no FI e a margem cai no CO, sem que nenhum chame os outros por uma
interface. É por isso que "só integramos com o SD" raramente é verdade: cada uma das 1.400 ordens
por dia que entram no SD passa por quatro módulos antes de o dia acabar. Os códigos de módulo dizem a
quem perguntar no time de Edson; não dizem onde param os efeitos de uma integração.

## Três sistemas, não um

A segunda surpresa de Joana foi que a Serra Alta não tem um sistema SAP. Tem três.

**Toda mudança no SAP é feita num sistema de desenvolvimento, testada num sistema de qualidade e só
então copiada para a produção.** Cada um é uma instalação SAP completa, com banco de dados próprio,
servidores de aplicação próprios e um ID de sistema próprio, de três caracteres. Na Serra Alta eles
se chamam `DEV`, `QAS` e `PRD`, nomes comuns o bastante para você encontrá-los em outros lugares.
Ninguém altera a produção diretamente. O `PRD` está configurado para que os programas e a
configuração não possam ser editados de jeito nenhum, e essa configuração é conferida pelos
auditores que certificam o balanço.

O que se move entre eles é um *transporte*. Quando um dos desenvolvedores de Edson altera um programa
ou uma configuração no `DEV`, o SAP grava a mudança numa *requisição de transporte* com um ID como
`DEVK900123`: o sistema de origem, um `K` e um número. O desenvolvedor libera a requisição quando o
trabalho termina. O sistema de gerenciamento de transportes então a importa no `QAS`, onde os
usuários-chave testam, e depois importa a mesma requisição, sem alteração, no `PRD`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-transports\" aria-label=\"Três sistemas SAP lado a lado, cada um uma instalação completa com banco de dados próprio. DEV, desenvolvimento, tem o mandante 100; QAS, qualidade, tem o mandante 200 para testes e o 300 para treinamento; PRD, produção, tem o mandante 100 e não pode ser editado. Uma requisição de transporte, DEVK900123, é liberada no DEV e importada no QAS, onde os usuários-chave a testam; a mesma requisição, sem alteração, é depois importada no PRD, às terças ou quintas à noite e nunca nos cinco primeiros dias úteis do mês.\"><defs><marker id=\"l02-transports-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"25.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">DEV</text><text x=\"120.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenvolvimento</text><rect x=\"82.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandante 100</text><text x=\"120.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">banco próprio</text><rect x=\"265.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">QAS</text><text x=\"360.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualidade</text><rect x=\"280.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandante 200</text><rect x=\"364.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandante 300</text><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">banco próprio</text><rect x=\"505.0\" y=\"60.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">PRD</text><text x=\"600.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produção</text><rect x=\"562.0\" y=\"117.0\" width=\"76.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandante 100</text><text x=\"600.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">banco próprio</text><rect x=\"188.0\" y=\"32.0\" width=\"104.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DEVK900123</text><path d=\"M240.0 56.0 L240.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><rect x=\"428.0\" y=\"32.0\" width=\"104.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DEVK900123</text><path d=\"M480.0 56.0 L480.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M217.0 125.0 L261.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-transports-es-ah-phosphor)\"></path><text x=\"240.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">importa</text><path d=\"M457.0 125.0 L501.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-transports-es-ah-phosphor)\"></path><text x=\"480.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">importa</text><text x=\"360.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a mesma requisição segue adiante, sem alteração</text><text x=\"120.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a mudança é feita e</text><text x=\"120.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gravada numa requisição</text><text x=\"360.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os usuários-chave</text><text x=\"360.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">testam com dados realistas</text><text x=\"600.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">terça e quinta à noite;</text><text x=\"600.0\" y=\"224.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nunca na semana do fechamento</text><text x=\"600.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">ninguém edita o PRD diretamente</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo sistema que conversa com o SAP precisa de um par de teste apontado para o QAS, nunca para o PRD</text></svg>", "caption": "O caminho até a produção. Uma mudança é gravada uma vez no DEV e a mesma requisição segue adiante; a produção nunca é editada no lugar."}
```

**Os transportes são importados na ordem em que foram liberados**, e essa ordem importa. Uma
requisição que altera uma tabela e uma posterior que usa o campo novo só funcionam nessa sequência;
importar só a segunda na produção quebra algo que funcionava no `QAS`. A Serra Alta importa na
produção duas vezes por semana, às terças e quintas à noite, com aprovação de Edson em cada caso, e
nunca nos cinco primeiros dias úteis do mês, enquanto o financeiro fecha o balanço. Fora dessas
janelas a mudança espera, por mais urgente que pareça, a não ser que Edson assine um transporte de
emergência.

Para um arquiteto, isso tem duas consequências. **Uma mudança no SAP chega à produção na velocidade
do transporte, não na velocidade do deploy**: um campo acrescentado para uma integração nova leva
dias, no mínimo, porque passa pelo `QAS` e por um ciclo de testes como todo o resto. E todo sistema
que conversa com o SAP precisa de uma contraparte que converse com o `QAS`. Quando o time do Rota
testa uma versão, o ambiente de teste dele tem de apontar para o `QAS`, nunca para o `PRD`, e alguém
precisa manter os dados do `QAS` realistas o bastante para o teste significar alguma coisa.

## O mandante dentro de um sistema

Dentro de um sistema SAP existe mais uma divisão, sem equivalente na maior parte do software que
Joana conhecia. Um *mandante* (*Mandant*, no alemão da SAP; em inglês, *client*) é um número de três
dígitos que separa os dados de negócio dentro de uma instalação. Os dados de produção da Serra Alta
ficam no mandante `100` do `PRD`. O `QAS` tem dois mandantes: o `200` para testes e o `300` para
treinar usuários novos.

Quase toda tabela com dados de negócio carrega o mandante como primeira coluna da chave, e os
programas da SAP o acrescentam sozinhos a cada consulta. Já os programas e as definições de tabela
são compartilhados por todos os mandantes do sistema. Então uma mudança de programa chega a todos os
mandantes de uma vez, enquanto as ordens do mandante `200` são invisíveis do mandante `300`.

**Uma integração se conecta a um sistema e a um mandante, nunca só a um sistema.** Uma conexão
montada contra o `QAS` com o mandante errado vai entrar, rodar e lançar documentos nos dados de
treinamento. Os ambientes SAP costumam dar a cada par o nome de *sistema lógico*, como `PRDCLNT100`,
e a Serra Alta segue essa convenção.

## Customizing, e os 1.800 objetos que não são da SAP

O SAP é alterado de dois jeitos muito diferentes, e confundir os dois é o erro mais caro que um
arquiteto pode cometer na primeira conversa com um time de SAP.

O *customizing* é configuração feita pelo próprio *Implementation Guide* da SAP, aberto com a
transação `SPRO`. Um centro novo, uma condição de preço nova, um tipo de documento novo para
devolução: cada um é uma linha numa tabela de configuração que o código da SAP lê, e é o primeiro dos
três anéis da aula 1, a configuração. Quando a fábrica de Alagoa entrar no SAP algum dia, quase tudo
o que vai precisar acontecer é customizing. **Customizing é o código da SAP se comportando como você
o configurou**, e as atualizações da SAP são desenhadas para levá-lo adiante.

O *código próprio* são programas que a empresa escreve, em ABAP, a linguagem de programação da
própria SAP. A SAP reserva para os clientes os nomes que começam com `Z` ou `Y`, então os objetos
próprios são chamados de *objetos Z* e um time de SAP diz "tem um programa Z para isso". A Serra Alta
tem cerca de 1.800 deles: relatórios, tabelas, módulos de função, telas e código pendurado nas
transações da própria SAP, nos pontos que a SAP deixa abertos para isso. O programa ABAP que carrega
o arquivo do Coleta toda noite às 02:00 é um deles, e a tabela em que ele escreve também.

A primeira leitura de Joana desse número foi que os objetos Z eram plug-ins, separados do núcleo e
fáceis de pôr de lado. Edson mostrou que não. **Um objeto Z vive dentro do SAP: lê as tabelas da SAP,
roda nas transações da SAP e é movido pelos mesmos transportes**, e os 1.800 guardam quinze anos de
decisões sobre como a Serra Alta trabalha. Alguns são essenciais e não estão documentados em nenhum
outro lugar; outros não rodam desde que a pessoa que os pediu saiu da empresa. Ninguém na Serra Alta
sabe a proporção sem medir, e a próxima seção mostra por que essa resposta está para custar
dinheiro.

Esse número também é o tamanho honesto do sistema em volta do qual você está desenhando. A licença
compra o padrão da SAP; o que a Serra Alta de fato roda é esse padrão, o customizing dela e 1.800
objetos que só as seis pessoas de Edson e a consultoria entendem.
