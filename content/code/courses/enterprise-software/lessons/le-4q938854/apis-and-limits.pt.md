---
title: As APIs e a cota diária
version: 1
---

O Salesforce tem mais portas de entrada e saída do que a maioria dos produtos que um arquiteto
encontra, e elas não são intercambiáveis. **Cada API foi feita para um formato de tráfego, e uma
integração construída na errada funciona perfeitamente até o dia em que o volume muda.** A Serra Alta
aprendeu isso num fechamento de mês, e a história vale mais do que o catálogo, então o catálogo vem
primeiro e rápido.

## As portas de entrada e saída

| API | para que serve | formato |
|---|---|---|
| REST API | ler e gravar registros um de cada vez, ou poucos de cada vez | síncrona, JSON sobre HTTPS |
| SOAP API | as mesmas operações, descritas por um WSDL | síncrona, XML; integrações mais antigas a usam, e a aula 8 trata de SOAP |
| Bulk API 2.0 | carregar ou extrair grandes volumes: dezenas de milhares de registros para cima | assíncrona: você envia um job com um arquivo CSV e busca os resultados depois |
| Change Data Capture | uma mensagem toda vez que um registro de um objeto escolhido é criado, alterado, excluído ou restaurado | eventos saindo do Salesforce, para assinantes |
| Platform Events | mensagens que a própria org define, como *cliente solicitado*, com nomes de API terminando em `__e` | eventos nos dois sentidos |

A REST API também tem **recursos compostos**, que levam várias operações numa requisição só. Dois
merecem ser conhecidos pelo nome. O *Composite* manda até 25 sub-requisições numa chamada, e as
posteriores podem usar os resultados das anteriores. O *sObject Collections* cria, atualiza ou faz
upsert de até 200 registros de um objeto numa chamada.

As duas APIs de eventos são o que torna o Salesforce algo que outros sistemas podem escutar, em vez
de algo a que precisam perguntar. Um assinante se conecta, normalmente pela Pub/Sub API, e recebe os
eventos à medida que acontecem. Cada evento carrega um replay id, e a plataforma guarda os eventos
recentes por alguns dias, então um assinante que ficou fora do ar pode pedir tudo o que veio depois
do último id que processou. A aula 10 trata do que isso exige do lado do assinante.

## A cota

Toda org tem uma **cota diária de requisições de API**: um número total de chamadas que todas as suas
integrações juntas podem fazer em quaisquer 24 horas corridas. O tamanho depende da edição e de
quantas licenças de usuário a org tem, e a org o mostra nas telas de configuração e pelo recurso
`limits` da REST API. **A cota da Serra Alta é de 100.000 requisições por 24 horas.** Num dia comum,
as integrações que não são as de faturas (preços e estoque vindos do SAP, pedidos voltando para ele,
a telefonia da central de atendimento) usam cerca de 45.000 delas.

O que acontece depois da linha importa mais do que a linha. Quando uma org passa da cota, o
Salesforce pode bloquear novas chamadas de API daquela org até que o uso nas 24 horas anteriores
volte a ficar abaixo do total. **O bloqueio não é por integração. É de todas as integrações da org ao
mesmo tempo**, inclusive as que não fizeram nada de errado.

## A noite do fechamento

Desde 2018 um fluxo de mensagens do IIB no time de Rui copia faturas do SAP para o `Invoice__c` do
Salesforce toda noite, para que um representante que visita uma rede veja o que ela deve. Ele foi
escrito do jeito óbvio. Para cada fatura que o SAP informa como nova ou alterada, o fluxo faz duas
chamadas: uma consulta para achar o Id no Salesforce da Account com aquele número de cliente do SAP,
e depois uma chamada para criar ou atualizar a fatura.

Numa noite comum, cerca de 2.800 faturas mudaram: umas 1.400 novas e outras tantas pagas. São 5.600
chamadas, e com as outras 45.000 o dia termina bem abaixo da cota. **Ninguém tinha medido um
fechamento de mês.** Na semana do fechamento, o financeiro lança os ajustes do mês, os descontos
combinados com as redes, as devoluções e as baixas, e roda de novo o cálculo de vencidos. Toda fatura
que eles tocam conta como alterada, e numa noite do fechamento o fluxo encontrou cerca de 34.000
delas.

A conta, que ninguém tinha feito em 2018:

| | requisições |
|---|---|
| faturas alteradas naquela noite | 34.000 |
| chamadas por fatura | × 2 |
| sincronização de faturas | 68.000 |
| todo o resto, nas mesmas 24 horas | 45.000 |
| total | 113.000 |
| cota da Serra Alta | 100.000 |
| excesso | 13.000 |

O fluxo passou da linha pouco depois das quatro da manhã. Dali em diante toda chamada da org foi
recusada, e a que importava não era a sincronização de faturas. **Os pedidos dos 140 representantes,
que vão do Salesforce para o SAP pela cota da mesma org, pararam de chegar ao SAP**, e os pedidos de
supermercado tirados naquela manhã ficaram parados no Salesforce até a janela andar. O chamado do
incidente o descreveu como uma queda da integração de pedidos. A integração de pedidos não tinha
defeito nenhum.

## A primeira ideia estava errada

A primeira sugestão de Joana, na revisão uma semana depois, foi rodar a sincronização com mais
threads em paralelo, para que terminasse antes de os representantes começarem a trabalhar. Rui
apontou para a tabela. **A cota conta requisições, não tempo.** Um fluxo mais rápido faz as mesmas
68.000 chamadas e chega à linha mais cedo na noite. A correção tinha de mudar o número de
requisições, e havia três jeitos de fazer isso.

**Mandar registros em conjuntos.** O sObject Collections faz upsert de até 200 faturas por
requisição. E como `SAP_Customer_Number__c` é um external id na Account, como a seção 03 mostrou, cada
fatura pode apontar a sua Account diretamente por esse número, e a consulta que achava o Id do
Salesforce desaparece:

```json
{
  "allOrNone": false,
  "records": [
    {
      "attributes": { "type": "Invoice__c" },
      "SAP_Invoice_Number__c": "0090412337",
      "Status__c": "Paid",
      "Account__r": { "SAP_Customer_Number__c": "0000104233" }
    }
  ]
}
```

A requisição vai para o recurso de coleção de `Invoice__c`, com upsert por `SAP_Invoice_Number__c`,
outro external id. `Account__r` é o nome do relacionamento de uma fatura com a sua Account, e a
plataforma encontra a Account cujo número SAP bate. **34.000 faturas a 200 por requisição são 170
requisições, contra 68.000.**

**Mandar um job.** O Bulk API 2.0 recebe os mesmos registros como um arquivo CSV, com uma coluna
chamada `Account__r.SAP_Customer_Number__c`, e o processa de forma assíncrona. Criar o job, enviar o
arquivo, fechá-lo, perguntar se terminou e buscar os resultados deu onze requisições quando o time de
Rui testou no sandbox Full. O Bulk API tem limites próprios, contados em registros e em jobs, e eles
ficam muito acima dessa carga.

**Questionar a cópia.** Um representante precisa mesmo de todas as faturas no Salesforce? O Salesforce
Connect consegue mostrar registros que moram em outro sistema como *external objects*, lidos ao vivo
por um serviço OData. Isso significaria nenhuma cópia noturna, e também um serviço OData no SAP que
precisa responder sempre que um representante abre uma conta, inclusive durante a janela de domingo,
além da questão do acesso indireto da aula 1, agora para 140 pessoas. Joana registrou como opção e não
a escolheu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-calls\" aria-label=\"Três barras horizontais na mesma escala, as requisições de API usadas em 24 horas na noite de fechamento do mês. Cada barra começa com as 45.000 requisições das outras integrações. A primeira soma 68.000 de duas chamadas REST por fatura e chega a 113.000, passando de uma linha âmbar na cota da Serra Alta, 100.000. A segunda soma 170 requisições de sObject Collections com 200 faturas cada. A terceira soma 11 requisições de um job do Bulk API 2.0. As duas últimas somas são pequenas demais para aparecer nesta escala.\"><text x=\"208.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">duas chamadas REST por fatura</text><rect x=\"220.0\" y=\"67.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"67.0\" width=\"206.7\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"571.5\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">113.000</text><text x=\"208.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sObject Collections, 200 por chamada</text><rect x=\"220.0\" y=\"129.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"129.0\" width=\"1.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"365.3\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45.170</text><text x=\"208.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um job do Bulk API 2.0</text><rect x=\"220.0\" y=\"191.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"191.0\" width=\"1.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"364.8\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45.011</text><path d=\"M524.0 46.0 L524.0 63.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M524.0 97.0 L524.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"524.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cota: 100.000 por 24 h</text><path d=\"M220.0 236.0 L600.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M220.0 236.0 L220.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M372.0 236.0 L372.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"372.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50.000</text><path d=\"M524.0 236.0 L524.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"524.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100.000</text><rect x=\"220.0\" y=\"268.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outras integrações, 45.000</text><rect x=\"450.0\" y=\"268.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sincronização de faturas</text></svg>", "caption": "A noite de fechamento de três jeitos, na mesma escala. Só o primeiro passa da cota; os outros dois mudam o número de requisições, não a velocidade."}
```

## O que o sandbox encontrou

O time de Rui construiu primeiro a versão com coleções, porque era a que menos mudava, e passou por
ela, no sandbox Full, o equivalente às faturas de um fechamento. A primeira coleção de 200 falhou com
`Too many SOQL queries: 101`.

A causa era um trigger de 2018 em `Invoice__c`. Para cada fatura salva, ele consultava a Account para
atualizar um campo que dizia se o cliente tinha algo vencido, uma consulta por fatura dentro de um
laço. **Um trigger recebe os registros de um salvamento em blocos de até 200.** Enquanto o fluxo
mandava uma fatura por chamada, cada transação tinha uma fatura e fazia uma consulta. Mandadas de 200
em 200, o mesmo trigger tentou 200 consultas numa transação e passou do limite da seção 02 na 101ª, e
a plataforma desfez o bloco inteiro.

A correção foi a de sempre: juntar os Ids das Accounts de todas as faturas do bloco, rodar uma
consulta só para todas elas e atualizar as Accounts num único comando. O parceiro levou um dia.
**Encontrar o problema exigiu um teste com o volume da produção**, que é para isso que o sandbox Full
existe, e é por isso que a mudança não chegou à produção numa sexta-feira, como estava planejado.

## O que a Serra Alta roda agora

| | antes | depois |
|---|---|---|
| faturas da noite | 2 chamadas REST por fatura | um job do Bulk API 2.0 |
| faturas alteradas durante o dia | nenhuma; esperavam a noite | sObject Collections, até 200 por chamada |
| o trigger em `Invoice__c` | uma consulta por fatura | uma consulta por bloco |
| acompanhamento da cota | ninguém | o recurso `limits` lido a cada 15 minutos; o time de Rui é alertado em 70% |

**A decisão que Joana registrou não foi "usar o Bulk API".** Foi que toda integração com o Salesforce
declara quantas requisições faz num dia comum e no pior dia do mês, e que a soma é conferida contra a
cota antes de uma nova entrar no ar. A cota é um orçamento que a org inteira divide, e até aquela
noite ninguém cuidava dele.
