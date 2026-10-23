---
title: Contratos de interface e como eles mudam
version: 1
---

**Um contrato de interface é tudo aquilo de que o consumidor de uma integração depende, escrito
onde os dois lados podem ler.** A crença comum é que o contrato é o schema: um WSDL, um arquivo
OpenAPI, um leiaute de registro. O schema é uma linha dele. A maioria das integrações que quebraram
na Serra Alta nos últimos cinco anos quebrou com o schema intacto. Um arquivo chegou duas horas mais tarde que o normal. Um campo
mudou de significado. Um lado relatou um erro e o outro lado o ignorou.

## O que um contrato declara

O modelo de Joana tem sete partes. Aqui estão elas para a integração mais antiga da empresa, o arquivo noturno do Coleta para o SAP. Ele não tinha nenhuma delas por escrito até ela pedir a
Sebastião e Edson que se sentassem na mesma sala:

| parte | a pergunta que responde | o arquivo do Coleta para o SAP |
|---|---|---|
| schema | como os dados são | o leiaute de largura fixa com cabeçalho e trailer (a aula 9 o mostra) |
| semântica | o que cada campo significa | litros medidos no tanque da fazenda; gordura e proteína em gramas por 100 g; a data é o dia da coleta, não o da carga |
| volumes | quanto, no normal e no pior caso | cerca de 1.900 linhas por noite, até cerca de 2.100 no pico das chuvas |
| horário | quando chega e quando é necessário | no diretório até 01:30; carregado até 02:30, ou até 06:30 aos domingos |
| comportamento de erro | o que acontece com dados ruins | uma linha que falha na validação vai para um arquivo de rejeição devolvido ao Coleta; o resto do arquivo carrega |
| responsáveis | quem responde por cada lado | Sebastião pelo Coleta, Edson pela carga no SAP |
| versão | que acordo é este | versão 1, a primeira que alguém escreveu |

**A semântica e o horário são onde os contratos quebram em silêncio.** Uma mudança de schema faz quem
recebe falhar ruidosamente, que é o caso bom. Uma mudança de significado passa por todas as
verificações. Se o Coleta começasse a mandar a data da carga em vez da data da coleta, todas as
linhas continuariam sendo lidas, e o leite de sábado de cada fazenda seria pago como se fosse de
domingo.

## Mudanças compatíveis e mudanças que quebram

Uma mudança numa interface é **compatível** se todos os consumidores existentes continuam
funcionando sem mudar nada, e **quebra** se pelo menos um precisa mudar. Se uma mudança quebra
depende menos da mudança do que de como os consumidores leem, e essa é a parte que surpreende.

| mudança | compatível? |
|---|---|
| um novo campo opcional numa mensagem JSON | sim, para consumidores que ignoram o que não conhecem |
| um novo campo no fim de uma linha de largura fixa | não, para qualquer carga que confira o tamanho de cada linha, como a do SAP confere |
| um campo renomeado | não |
| uma unidade trocada sob o mesmo nome, de litros para quilos | não, e nada falha: o pior tipo |
| um campo numérico alargado de 9 para 11 dígitos num registro de largura fixa | não: todos os campos depois dele se deslocam |
| um novo valor numa lista de códigos, uma nova classe de qualidade | não, para qualquer consumidor que mapeia cada código que conhece e rejeita o resto |
| o arquivo chegando duas horas mais tarde | não, para uma carga que roda às 02:00 |

As duas primeiras linhas são a mesma mudança em formatos diferentes. Consumidores de JSON podem ser
escritos para ignorar campos que não reconhecem, e o nome que Martin Fowler deu a um consumidor
escrito assim é *tolerant reader*, o leitor tolerante (2011): leia só o que você precisa e deixe o
resto passar. **Um leitor tolerante transforma muitas mudanças que quebrariam em mudanças
compatíveis**, e é a coisa mais barata que um consumidor pode fazer pelo próprio futuro. Uma carga de
largura fixa não consegue ser tolerante do mesmo jeito, porque a posição é o significado: ela não tem
como distinguir um campo a mais de um campo deslocado.

## Versões e descontinuação

Uma mudança que quebra sai como uma **nova versão ao lado da antiga**, nunca como uma edição da
antiga. Os consumidores migram quando podem, e a versão antiga é desligada quando o último migrou.

Essa última frase é onde a política faz falta, porque sem ela a versão antiga vive para sempre. A
regra de Joana:

- uma nova versão é anunciada no registro com a data e as diferenças;
- a versão antiga fica por seis meses depois que a nova está disponível, e o registro mostra quais
  consumidores ainda estão nela;
- os consumidores que ainda estão nela são avisados no dia do lançamento, aos três meses e a um mês;
- a versão antiga é desligada quando o tráfego dela, medido e não suposto, ficou em zero por um mês,
  ou aos seis meses com os responsáveis por qualquer consumidor restante concordando com a data.

Os números de versão seguem o costume do versionamento semântico: o número maior muda numa mudança
que quebra, o menor numa compatível. Num serviço web a versão maior vai no endereço (`/v2/`), para
que as duas possam rodar ao mesmo tempo. Num arquivo ela vai no cabeçalho, para que quem lê possa
recusar uma versão que não entende em vez de lê-la errado.

## Contratos guiados pelo consumidor

Um produtor não tem como saber quais dos seus campos importam. Ele sabe o que publica; não sabe que o
portal lê `available` e ignora `reserved`, enquanto o Rota lê os dois. O artigo de Ian Robinson
*Consumer-Driven Contracts* (2006) inverteu isso: **cada consumidor declara aquilo de que depende, na
forma de testes, e o produtor roda os testes de todos os consumidores antes de lançar.** Uma mudança
que quebra um consumidor falha no build do produtor em vez de na manhã do consumidor.

O Pact é a ferramenta mais conhecida para isso. O teste do consumidor registra as requisições que
ele faz e as partes de cada resposta de que ele depende; o registro é publicado; o build do produtor
o reproduz contra o serviço real. Os sistemas próprios da Serra Alta, o Portal B2B e o Rota, podem
trabalhar assim, porque os dois lados são equipes da mesma empresa com builds que elas controlam.

Isso não chega ao SAP nem ao Salesforce. Nenhum dos dois fornecedores vai rodar os testes da Serra
Alta antes de lançar uma versão. Para eles, a mesma ideia funciona ao contrário: a Serra Alta mantém
testes daquilo de que depende nas interfaces deles e os roda contra o sandbox do fornecedor antes que
cada atualização chegue à produção. Não é um contrato que o fornecedor assinou, mas encontra a
mudança que quebra num ambiente de testes, que é onde ela deve ser encontrada.

## O registro

A aula 9 deixou Joana com um mapa de cerca de 110 integrações. Ela o transformou num registro, uma entrada por integração no formato da tabela acima, e isso mostrou quão pouco estava escrito: 39 tinham
alguma especificação, a maioria os WSDLs dos fluxos do barramento, e 14 tinham um responsável
nomeado dos dois lados.

Ela não tentou preencher as 110 de uma vez. As primeiras entradas foram as 23 integrações que movem
dinheiro, documentos fiscais ou os caminhões. Toda integração nova ganha uma entrada antes de ir para
produção, e toda mudança numa integração existente preenche a entrada dela se ainda não houver. Uma
entrada é curta e fica num repositório, para que uma mudança num contrato seja uma mudança que alguém
revisa:

```yaml
id: int-coleta-sap-receipts
producer: Coleta
consumer: SAP ECC (goods receipts of milk)
style: file
version: 1
owners:
  producer: Sebastião Lima
  consumer: Edson Prado
schema: lesson 9 layout, header and trailer with record count and total litres
semantics: litres measured at the farm tank; date is the day of collection
volume: about 1900 lines a night, peak about 2100
timing: file by 01:30; loaded by 02:30, Sundays by 06:30
window: SAP down Sundays 01:00-05:00
errors: rejected lines returned to Coleta in a reject file; the rest loads
objective: loaded by 06:30 on 99% of days in a rolling 90 days
```

A última linha liga esta seção à segunda. **Um contrato sem objetivo diz o que atravessa e não quão
bem**, e um objetivo sem contrato mede algo com que ninguém concordou. O registro é onde os dois se
encontram, com o calendário ao lado.
