---
title: Registros, temporalidade e o dever de descartar
version: 1
---

O instinto com documentos é guardar tudo, porque armazenamento é barato e excluir parece o ato
arriscado. **Para um registro, guardá-lo além do prazo é uma falha do mesmo tipo que perdê-lo antes
da hora**: as duas quebram uma regra que a própria empresa definiu, e a primeira ainda pode violar a
lei de dados pessoais. Esta seção trata das regras que decidem o que se guarda, por quanto tempo, e o
que acontece no fim.

## Um registro é um documento guardado como prova

A ISO 15489, a norma internacional de gestão de registros (publicada em 2001 e revisada em 2016),
trata um registro como informação criada, recebida e mantida como prova do que uma organização fez.
**O teste é o propósito, não o formato.** O rascunho 1.2 do procedimento de pasteurização é um
documento. A versão 1.0, a que a linha 2 seguiu em março de 2026, é um registro, porque é a prova do
que a planta mandou os operadores fazerem.

Virar registro muda o que pode acontecer com um documento:

- ele fica fixo: ninguém o edita, nem o próprio autor, e uma correção é um documento novo que se
  refere a ele;
- ele tem um prazo de guarda tirado de uma tabela, não do julgamento de alguém no dia;
- ele pode ficar sob retenção legal, que impede o descarte;
- no fim do prazo ele é descartado, e o descarte também fica registrado.

Muitos sistemas tornam essa mudança explícita. Uma pessoa ou uma regra *declara* o documento como
registro, e daí em diante o sistema recusa edições e exclusões, mesmo vindas de um administrador. Na
Serra Alta todo certificado de análise é declarado registro no instante em que é arquivado, pela
rotina que o arquiva.

## A tabela de temporalidade

Uma tabela de temporalidade diz, para cada classe de registro, por quanto tempo ela é guardada, a
partir de que evento o tempo é contado, e por quê. O departamento jurídico da Serra Alta escreveu a
sua em 2019 e a revisa a cada dois anos. Um trecho:

| classe de registro | guardado por | contado a partir de | por que é guardado |
|---|---|---|---|
| certificado de análise de um lote | 5 anos | o fim do ano em que o lote foi produzido | segurança de alimentos e contratos com clientes |
| registros de inspeção do SIF | 10 anos | o fim do ano da inspeção | inspeção federal |
| procedimentos substituídos | 10 anos | a data em que foram substituídos | auditorias, e reclamações sobre lotes antigos |
| certificados de fornecedores | 5 anos | o fim da relação com o fornecedor | auditorias de fornecedores |
| NF-e e livros fiscais | 6 anos | o fim do exercício fiscal | fisco |
| dossiê de cadastro de uma fazenda (contrato, documento de identidade, dados bancários) | 5 anos | o último pagamento à fazenda | disputas de contrato e de pagamento |

Esses prazos são da própria Serra Alta, escolhidos pelos advogados dela a partir das leis que se
aplicam a cada classe, com uma margem. **Os mínimos legais são um advogado quem diz, e a tabela é
onde a empresa escreve a sua resposta.** Um arquiteto não escolhe os números. O que um arquiteto
decide é se os sistemas conseguem cumpri-los.

Olhe a terceira coluna. O prazo começa num **evento**, e o evento muitas vezes não é a data em que o
documento foi feito. "Cinco anos depois do fim da relação com o fornecedor" não dá para calcular
quando o certificado é arquivado, porque ninguém sabe ainda quando a relação vai acabar. Esse fato
mora no SAP, no cadastro do fornecedor. **Uma regra de guarda que conta a partir de um evento de
negócio precisa de uma integração**, porque o DMS tem de ser avisado quando o evento acontece, e
alguém precisa construir isso.

Um registro, do começo ao fim: o lote L2603-0112 de leite integral foi produzido em 14 de março de
2026. O certificado dele é guardado por cinco anos a partir do fim de 2026, então pode ser descartado
a partir de 1º de janeiro de 2032, cinco anos e cerca de nove meses e meio depois da produção do
lote. Contar a partir do fim de um ano é comum justamente por isso: a Serra Alta roda o descarte uma
vez por ano, em janeiro, e uma rodada dá conta de um ano inteiro de lotes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-retention\" aria-label=\"Uma linha do tempo de 2026 a 2034 para o certificado do lote L2603-0112. O lote é produzido em 14 de março de 2026. O prazo de guarda começa no fim de 2026 e corre cinco anos, até 1º de janeiro de 2032, quando o certificado pode ser descartado. Uma retenção legal aplicada em 2031 cobre essa data, então a rodada de descarte de janeiro de 2032 o pula. A retenção é suspensa em 2033 e o certificado é destruído na rodada de janeiro de 2034, que deixa um registro do descarte.\"><path d=\"M50.0 150.0 L656.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 145.0 L60.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2026</text><path d=\"M132.0 145.0 L132.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"132.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2027</text><path d=\"M204.0 145.0 L204.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"204.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2028</text><path d=\"M276.0 145.0 L276.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"276.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2029</text><path d=\"M348.0 145.0 L348.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"348.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2030</text><path d=\"M420.0 145.0 L420.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2031</text><path d=\"M492.0 145.0 L492.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"492.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2032</text><path d=\"M564.0 145.0 L564.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"564.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2033</text><path d=\"M636.0 145.0 L636.0 155.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2034</text><circle cx=\"74.4\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"74.4\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lote produzido</text><text x=\"74.4\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14 mar 2026</text><path d=\"M74.4 124.0 L74.4 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"132.0\" y=\"60.0\" width=\"360.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 anos a partir do fim de 2026</text><path d=\"M132.0 82.0 L132.0 143.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M492.0 82.0 L492.0 143.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"492.0\" y=\"29.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pode ser descartado</text><text x=\"492.0\" y=\"42.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1º jan 2032</text><rect x=\"448.8\" y=\"190.0\" width=\"151.2\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"524.4\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">retenção legal</text><text x=\"492.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rodada de jan 2032: pulado</text><path d=\"M492.0 176.0 L492.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"636.0\" cy=\"150.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"632.0\" y=\"251.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">destruído em jan 2034,</text><text x=\"632.0\" y=\"264.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">descarte registrado</text><path d=\"M636.0 176.0 L636.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "O prazo começa num evento, não na data do lote, e a retenção legal vence o prazo. O certificado sobrevive dois anos além do período por causa de um processo."}
```

## Retenção legal

Uma **retenção legal** (*legal hold*) suspende o descarte dos registros ligados a uma disputa, uma
investigação ou uma fiscalização, por mais antigos que sejam. Suponha que em 2031 um consumidor
processe a empresa por uma caixa de leite do lote L2603-0112, e o certificado seja prova. O jurídico
aplica uma retenção sobre ele e sobre tudo o mais ligado àquele lote: o certificado, os registros de
produção da linha, a versão do procedimento em vigor naquele dia. Quando chega a rodada de janeiro de
2032, ela os pula. O processo termina em 2033, a retenção é suspensa, e os registros entram na
rodada seguinte, em janeiro de 2034.

Três propriedades fazem uma retenção funcionar. Ela se sobrepõe a qualquer prazo de guarda. Ela é
aplicada e suspensa por quem responde pelo caso, não pela TI. E ela cobre tudo o que está ligado ao
assunto, onde quer que esteja guardado, que é a parte difícil quando um lote tem registros no
Documentum, no SAP e no Coleta. **Uma retenção que o DMS obedece e o arquivo do ERP ignora é meia
retenção.**

## Descartar é um dever

O descarte é a etapa que todo mundo adia, e é a etapa para a qual a tabela existe. Há três motivos
para não guardar tudo.

**A lei de dados pessoais.** A LGPD, a Lei Geral de Proteção de Dados (Lei 13.709/2018), diz que os
dados pessoais devem ser eliminados quando termina o tratamento para o qual foram coletados. O artigo
16 lista as finalidades para as quais eles podem ser conservados mesmo assim, e a primeira é o
cumprimento de obrigação legal ou regulatória. Isso faz da tabela o lugar onde as duas forças puxam
em sentidos opostos e são conciliadas: cada classe diz por que é guardada, e esse motivo é o que
justifica guardá-la. Passada a data, o motivo acabou.

O dossiê de cadastro de uma fazenda é o caso mais nítido. A maioria dos 1.900 fornecedores de leite
da Serra Alta são produtores pessoa física, então o dossiê guarda o documento de identidade, o CPF e a
conta bancária de uma pessoa. Um produtor que parou de fornecer em 2019 e recebeu o último pagamento
em dezembro de 2019 tinha um dossiê com descarte previsto para dezembro de 2024. Quando Joana
pergunta, a equipe de Cláudia encontra 340 dossiês nessa situação ainda no repositório, o mais antigo
de 2010. Ninguém nunca tinha rodado um descarte para essa classe.

**Custo e ruído.** Tudo o que se guarda entra no backup, é migrado na próxima atualização e aparece
nas buscas. Uma busca por um procedimento que devolve primeiro as suas dez versões substituídas é uma
busca em que as pessoas aprendem a não confiar.

**Exibição em juízo.** Num processo, o que existe pode ser requisitado. Uma empresa que ainda guarda
documentos que a própria tabela mandava destruir não pode dizer que eles não existem, e ainda mostrou
que não segue a própria política.

Um descarte deixa um registro próprio: o que foi destruído, sob qual regra da tabela, aprovado por
quem, em que data. **O registro do descarte é guardado mesmo que o registro em si não seja**, porque
uma pergunta posterior, "vocês tinham este certificado?", precisa de resposta, e "destruímos em
janeiro de 2034 pela regra CQ-05" é uma.

## Onde entra o arquiteto

A gestão de registros falha nas emendas entre sistemas, então ela é um problema de integração tanto
quanto de qualidade. Quatro perguntas a fazer a qualquer projeto que toque em documentos:

1. Que sistema guarda o registro? Um PDF de certificado mandado por e-mail a um cliente é uma cópia;
   o registro é o que está no DMS.
2. Onde mora o evento que dispara o prazo, e como o DMS fica sabendo dele?
3. Uma retenção legal alcança todos os sistemas que guardam parte do assunto?
4. Quando um registro é descartado, o que acontece com os vínculos que apontam para ele a partir do
   SAP ou do Salesforce? A última seção desta aula volta a isso.

A aula 14, sobre migração de dados, encontra a mesma tabela pelo outro lado. Registros levados para
um sistema novo precisam manter as datas, as declarações e as retenções, ou o sistema novo acaba
cheio de documentos que deixaram de ser prova sem que ninguém percebesse.
