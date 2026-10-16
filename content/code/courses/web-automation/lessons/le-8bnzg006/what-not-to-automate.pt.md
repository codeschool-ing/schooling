---
title: O que deixar para uma pessoa, ou para outra camada
version: 1
---

**O erro comum é tratar os testes manuais como a fila de espera dos automatizados**, como se
cada caso que uma pessoa executa estivesse esperando a vez de virar código, e a suíte estivesse
pronta quando a lista esvaziasse. Alguns casos nunca devem mudar de lugar. Uns custariam mais
que qualquer defeito que pudessem achar, e outros um robô simplesmente não faz, porque a
resposta pede julgamento, ou a página é de outra pessoa, ou a página existe para barrar robôs.
Para cada um, a pergunta útil é o que fazer no lugar, e sempre há resposta.

| o caso | por que não um teste de navegador | o que fazer no lugar |
|---|---|---|
| uma verificação que você vai fazer uma vez | escrever custa mais que uma execução à mão | faça à mão e anote o que viu |
| uma funcionalidade que ninguém viu ainda | você não sabe a resposta certa, então o teste congelaria um palpite | explore primeiro (`manual-testing` aula 11); automatize o que se mostrar importante |
| como a página fica, como o texto soa | uma diferença de pixels não é um julgamento | uma pessoa olha; um teste verifica os fatos por baixo, como a ausência de rolagem lateral |
| uma funcionalidade prestes a mudar | todo teste escrito agora vai ser mantido, ou apagado, no mês que vem | teste à mão até o desenho assentar |
| uma regra que uma camada de baixo verifica | o navegador é o lugar mais lento para conferir uma soma | o teste de unidade ou de API que a aula 21 põe abaixo do navegador |
| uma página que é de outra empresa | muda sem avisar, e uma execução vermelha não é sua para corrigir | simule a fronteira, como o `cy.intercept` da aula 9, e teste o seu lado dela |
| um CAPTCHA | existe para distinguir um robô de uma pessoa, então passar por ele é um defeito do CAPTCHA | desligue-o no ambiente de teste, ou use as chaves de teste documentadas pelo provedor |
| um provedor de pagamento | cartões de verdade, dinheiro de verdade, uma página que não é sua | o sandbox do provedor e seus cartões de teste, dentro do que o modo de teste dele suporta |

## Três deles com mais detalhe

**Uma funcionalidade nova passa primeiro por uma pessoa.** O teste exploratório, com um roteiro
de missão e anotações, é como o testador aprende o que a funcionalidade faz e o que pode dar
errado nela, que é justamente o conhecimento de que um bom teste automatizado precisa. Um teste
escrito antes disso codifica o que o autor supôs. A página de busca da aula 3 é um bom exemplo:
nada na especificação dizia *vence a última resposta a chegar*, e uma pessoa digitando rápido é
como você teria encontrado o defeito primeiro. O teste veio depois, e foi preciso por isso.

**Aparência se julga; fatos se verificam.** O experimento da seção anterior pôs os dois na mesma
tabela. Se uma borda é o verde certo é uma decisão que alguém tomou, e um robô que compara
pixels só consegue dizer que ela mudou. Se a página rola para o lado em 360 pixels, se um preço
está na página, se um alvo tem 24 pixels: isso tem resposta, e a aula 7 verificou. Divida uma
questão visual assim, e o robô fica com a metade que tem resposta.

**A página de outra empresa é uma fronteira, não um objeto de teste.** Uma página de pagamento,
um mapa, um login operado por outra empresa: cada um muda no próprio ritmo, e um teste que o
dirige falha no dia da versão deles, não no da sua. A aula 9 esbarrou nos limites do Cypress com
uma segunda origem; o Playwright dirigiria uma, e a questão não é essa. A questão é o que uma
execução vermelha diria, e a resposta é *algo sobre uma empresa que não lê os seus relatórios*.
Teste que a sua loja manda o pedido certo e trata cada resposta possível, inclusive uma recusa e
um tempo esgotado, com o outro lado simulado. O modo de teste do provedor serve para a única
execução de ponta a ponta que confere se vocês dois ainda concordam, e a documentação dele diz
que cartões e respostas esse modo suporta.

## Um CAPTCHA não é um problema de teste

Um CAPTCHA existe para que um programa não passe por ele. Um teste que resolve um, por qualquer
meio, mostrou que o CAPTCHA não funciona, e isso é um defeito a relatar, não uma técnica a
guardar. O lado do testador são duas perguntas. No ambiente de teste, o CAPTCHA está desligado,
ou respondendo às chaves de teste documentadas pelo provedor, para que o resto do formulário
possa ser testado? E em produção, está ligado? A segunda é um pedido só, feito por uma pessoa ou
por uma verificação que apenas lê a página.

## Quando automatizar um caso está certo, afinal

Vire a tabela ao contrário e os casos que merecem um teste de navegador também têm um formato:
**rodam com frequência, têm desenho estável, uma resposta que uma máquina compara, e custam caro
quando quebram**. O total da cesta, a busca que tem de assentar no que foi digitado, a página que
não pode rolar para o lado num celular. Os testes do curso, na maior parte, são assim, e as duas
seções seguintes tratam de mantê-los assim.
