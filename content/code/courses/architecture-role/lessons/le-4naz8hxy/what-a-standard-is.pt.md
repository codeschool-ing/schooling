---
title: Princípios, padrões e diretrizes
version: 1
---

É fácil imaginar um documento de padrões como uma lista comprida que deixa o código de todo mundo
igual. **Um padrão é uma decisão tomada uma vez para que ninguém precise tomá-la de novo**, e ele vale
exatamente o que evita. Uma lista com sessenta deles não evita nada, porque ninguém guarda sessenta
regras na cabeça enquanto escreve código numa quinta à tarde.

Renata encontrou a lista da Carreto no segundo mês como arquiteta. Uma página da wiki chamada
*Engineering standards*, editada pela última vez em 2020, trazia **61 regras**. Ela pediu aos sete tech
leads que escrevessem, de memória, os padrões que seus times seguiam. Ninguém lembrou mais de cinco, e
nenhuma lista bateu com outra. Algumas das 61 descreviam um servidor Jenkins desligado dois anos antes.
Uma dizia que todo serviço novo era escrito em Flask, enquanto três dos mais novos eram FastAPI e
ninguém tinha avisado aos times que eles estavam quebrando uma regra. A página não era um padrão. Era o
registro do que alguém um dia tinha desejado.

## Três palavras, três forças

A página misturava três tipos de afirmação que fazem trabalhos diferentes, e separá-los foi a primeira
coisa que Renata fez.

| | o que é | que força tem | exemplo da Carreto |
|---|---|---|---|
| **princípio** | uma direção para raciocinar quando nenhuma regra cobre o caso | não se verifica sozinho | Dinheiro passa por Payments e por nenhum outro lugar. |
| **padrão** | uma regra com resposta sim ou não | **deve** | O pacote de um time importa o pacote de outro só pelo módulo `api` dele. |
| **diretriz** | um conselho que deixa espaço para julgamento | **deveria** | Prefira PostgreSQL para armazenamento novo. |

*Deve* e *deveria* têm aqui o peso que MUST e SHOULD têm na RFC 2119, o documento de 1997 que fixou
como os padrões da internet usam MUST, SHOULD e MAY. Um **deve** não tem "a não ser que": quebrá-lo
pede uma exceção que alguém concede, e esse é o assunto da última seção desta aula. Um **deveria**
espera que o leitor o siga e aceita outra escolha com um motivo escrito ao lado, num pull request ou
num ADR (aula 5).

**Um princípio é de onde os padrões vêm, e ele mesmo não é um padrão.** "Dinheiro passa por Payments"
não se confere linha a linha, mas produz regras que se conferem: Shipper não escreve na tabela de
repasses, e nada fora de Payments chama o banco parceiro. Quando aparece um caso que nenhum padrão
cobre, é a partir do princípio que as pessoas discutem.

O teste que separa um do outro é uma pergunta só: **uma máquina, ou qualquer revisor, consegue responder
sim ou não?** "O código deve ser limpo" não passa, então é no máximo uma diretriz, e fraca. "Nenhum CPF
aparece numa linha de log" passa, então pode ser um padrão. Uma regra que não passa no teste mas está
escrita com *deve* gera discussão na revisão, porque dois revisores a leem de dois jeitos.

## Poucos, cada um com um motivo e um dono

Renata dividiu a página em três pilhas. 38 regras foram apagadas: descreviam ferramentas que não
existiam mais, repetiam algo que a linguagem ou o framework já garantia, ou ninguém sabia dizer por que
estavam ali. 14 viraram diretrizes. **9 continuaram padrões.** Nove é um número que um tech lead
consegue recitar.

Cada um dos nove traz os mesmos quatro fatos: a regra, o motivo, o dono e como é verificado.

| padrão | motivo | dono | verificado por |
|---|---|---|---|
| O pacote de um time importa o pacote de outro só pelo módulo `api` dele | a falha nos repasses de março de 2026 | Renata Okubo | um script no CI |
| Todo serviço expõe `/healthz` e `/metrics` | o plantão não enxerga um serviço que não tem nenhum dos dois | Paula Reis | o pipeline de deploy |
| Nenhum CPF, telefone ou dado bancário numa linha de log | LGPD; os logs ficam guardados 90 dias e muita gente os lê | Paula Reis | um scanner de logs em staging |
| Dinheiro é um número inteiro de centavos, nunca float | arredondamento tirou centavos dos repasses aos motoristas em 2021 | Bruno Farias | uma checagem de tipo nos campos de valor |
| Uma cotação é conferida contra o piso da ANTT só pelo serviço de Pricing | duas cópias da tabela do piso discordaram durante uma semana | o tech lead de Pricing | um teste de contrato |
| Todo serviço é implantado pelo pipeline compartilhado | é no pipeline que as outras verificações rodam | Paula Reis | só o pipeline tem credenciais de produção |
| Segredos ficam no cofre de segredos, nunca no repositório | um token foi commitado e achado por um estranho | Paula Reis | um scanner de segredos no CI |
| Uma mudança numa API pública é compatível com a anterior ou versionada | o app do motorista não se atualiza em todos os celulares ao mesmo tempo | Renata Okubo | uma comparação de schema no CI |
| Uma decisão que cruza fronteiras de time tem um ADR | aula 5 | Renata Okubo | o fórum de arquitetura |

**O motivo é a coluna que mantém um padrão honesto.** É ele que deixa um tech lead julgar se uma exceção
faz sentido, e é ele que diz a alguém em 2029 se a regra ainda é necessária. Uma regra cujo motivo
ninguém sabe dizer é uma regra que ninguém consegue defender numa revisão, e ela é ignorada na primeira
vez que atrapalha.

**O dono é uma pessoa, não "a arquitetura".** Renata é dona de três dos nove. Paula é dona de quatro
porque Platform cuida do pipeline e dos logs; Bruno é dono da regra do dinheiro porque é em Payments
que um centavo errado dói. O dono responde perguntas sobre o padrão, decide as exceções a ele e propõe
aposentá-lo. Uma arquiteta dona de todos os padrões virou o gargalo que a aula 17 chama de porteiro. O
trabalho dela é manter a lista curta e coerente, não segurar cada linha.

A primeira linha tem uma história. Em março de 2026 o time de Matching dividiu em dois um módulo
chamado `offers.py`. Nada no código do próprio Matching quebrou. Mas o job de repasses de Payments
importava uma função direto de `offers.py`, porque era o jeito mais rápido de saber qual motorista tinha
aceitado uma carga, e na sexta depois da mudança a rodada de repasses falhou. **312 motoristas
receberam na segunda em vez de na sexta.** Ninguém em Matching sabia que Payments dependia daquele
arquivo, e nada poderia ter avisado. A próxima seção constrói a verificação que teria avisado.

## De onde os padrões vêm

Um padrão escrito por gosto começa uma discussão. Um escrito a partir de evidência termina uma. Os
nove da Carreto vieram de três lugares, e vale procurar os mesmos três em qualquer empresa:

- um incidente cuja causa foi uma escolha estrutural, como a falha nos repasses;
- um comentário de revisão feito três vezes. Quando a mesma observação aparece em três pull requests
  de três times, ela é candidata a padrão, e escrevê-la poupa o esforço do quarto revisor;
- uma obrigação de fora: a LGPD para a regra dos logs, o piso da ANTT para a regra das cotações.

Como um padrão é adotado segue o processo de aconselhamento da aula 3. Renata escreve o rascunho com o
motivo e o jeito de verificar, consulta os tech leads que vão conviver com ele e a Paula, que vai rodar
a verificação, e registra a decisão e os conselhos recebidos num ADR. Um padrão sobre o qual ninguém foi
consultado é um padrão que todo mundo se sente livre para contornar.

## A estrada pavimentada

Um padrão que dá trabalho seguir é seguido por quem é cuidadoso e pulado por quem está com pressa, o que
numa semana ruim é todo mundo. **O jeito mais barato de fazer um padrão ser obedecido é tornar a
obediência o caminho padrão.**

O time da Paula mantém um template de serviço. Um serviço criado a partir dele já expõe `/healthz` e
`/metrics`, mascara CPF nos logs, lê os segredos do cofre de segredos e está ligado ao pipeline
compartilhado, com a comparação de schema da sua API pública já no CI. **Cinco dos nove padrões estão
cumpridos no primeiro dia, por alguém que não leu nenhum deles.** A Netflix chamou isso de estrada
pavimentada e o Spotify de caminho dourado; a aula 14 de `tech-strategy` trata de como um time de
plataforma constrói um e o mantém.

Sair da estrada é permitido. Um time que não começa pelo template assume o que o template teria dado, e
continua devendo os nove. Isso muda o que um padrão é na prática: menos uma regra que as pessoas
lembram, mais uma estrada que leva a algum lugar útil, e uma lista curta do que você ainda precisa fazer
se sair dela.
