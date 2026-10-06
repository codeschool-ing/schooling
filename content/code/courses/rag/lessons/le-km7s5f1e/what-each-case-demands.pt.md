---
title: O que cada caso exige
version: 1
---

Os quatro usos compartilham um pipeline e diferem em quase todo o resto. Postas lado a lado, as
diferenças dizem que partes do pipeline cada um precisa acertar, e portanto onde uma equipe deveria
gastar seu tempo primeiro.

| | documentação | atendimento ao cliente | jurídico | conhecimento interno |
| --- | --- | --- | --- | --- |
| quem lê a resposta | um engenheiro, que vai rodá-la | um cliente, que vai agir com base nela | um advogado, que vai citá-la | um funcionário, que talvez não tenha acesso |
| o que custa uma resposta errada | minutos, descobertos depressa | uma promessa, um reembolso, um print | uma responsabilidade | um vazamento |
| o vocabulário | identificadores exatos | as palavras do próprio cliente | as palavras do próprio documento | o jargão da empresa |
| a busca que combina | lexical e vetorial juntas | vetorial, em todas as línguas dos clientes | vetorial, restrita a um conjunto de documentos | vetorial, filtrada por quem pergunta |
| a citação | a página, para o leitor conferir | raramente mostrada | o documento, a versão e a cláusula | o documento e o dono |
| atualidade | a cada versão | a cada mudança de preço ou política | toda versão, guardada com suas datas | constante, e trabalho de ninguém |
| "não sei" | aceitável | melhor que um chute | o único padrão seguro | aceitável |

## Três coisas que a tabela diz

**A busca tem de combinar com o vocabulário.** Perguntas de documentação são sobre strings exatas e
perguntas de atendimento são sobre paráfrase. Uma única estratégia de recuperação atende mal as duas, e
é por isso que a aula 6 combina busca lexical e vetorial e deixa o peso de cada uma variar por uso.

**O custo de uma resposta errada decide quanto vale recusar.** Onde errar é barato, um assistente pode
responder a partir de uma correspondência fraca e deixar o leitor conferir. Onde é caro, ele deveria
recusar abaixo de um limiar e dizer isso. O limiar é uma decisão de produto, não técnica, e a aula 7
mostra como defini-lo por medições e não por gosto.

**Dois dos quatro usos falham revelando, não errando.** No jurídico e no conhecimento interno o pior
resultado é uma resposta correta dada à pessoa errada, ou uma versão antiga citada como a atual.
Nenhum dos dois aparece num teste que confere se as respostas estão certas. Os dois precisam de
metadados guardados com cada pedaço desde o primeiro dia, porque acrescentá-los depois significa
reindexar tudo, e o momento mais barato de guardar o público, o dono, a versão e o status de um
documento é quando ele é cortado em pedaços pela primeira vez. A aula 5 guarda os quatro.

## Escolhendo por onde começar

Uma equipe que começa do zero faz bem em começar pelo atendimento ao cliente sobre a central de ajuda
pública: artigos curtos, texto público, uma medida clara de sucesso em chamados respondidos, e uma falha
conhecida numa resposta errada que uma pessoa pode corrigir. A documentação vem em segundo, e precisa
de busca lexical cedo. O jurídico e o conhecimento interno vêm por último, não por valerem menos, mas
porque precisam do maquinário de permissões e versões das aulas 5 e 14 antes de o primeiro usuário
vê-los.
