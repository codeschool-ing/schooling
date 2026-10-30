---
title: Por que um catálogo, e o que é o Purview
version: 1
---

**Esta lição é ensinada a partir da documentação da Microsoft, a não ser por um programa do próprio
curso.** O Microsoft Purview não tem emulador e nada dele roda num laptop. A seção sobre
classificação executa um classificador pequeno escrito para este curso sobre a exportação da Quitanda
no Azurite, para mostrar o que um classificador faz; ele não é o Purview e diz isso onde roda.

**Uma plataforma de dados que cresce sem catálogo acaba guardando dados que ninguém consegue
achar.** As lições da Quitanda até aqui puseram o mesmo cliente em muitos lugares: o banco de pedidos
da lição 8, a exportação noturna no Blob Storage das lições 2 a 7, as tabelas Delta da lição 18, os
arquivos que o Capture gravou na lição 22. Cada um foi uma decisão sensata. Juntos, eles tornam
difícil responder a uma pergunta que parece simples: **onde está guardado o CPF deste cliente, e quem
o copiou para lá?**

Essa pergunta chega de forma real. Pela lei de proteção de dados do Brasil, a LGPD, uma pessoa pode
perguntar a uma empresa que dados ela tem a seu respeito e pedir que sejam corrigidos ou apagados; o
que a lei exige é o assunto de `data-governance`, lição 7, que este curso não pressupõe. Para o
engenheiro, o pedido vira uma busca em todos os armazenamentos, e a busca só é tão boa quanto a lista
dos armazenamentos e do que há em cada um. Um catálogo é essa lista, mantida em dia por uma máquina e
não pela memória.

## Três trabalhos

**Um catálogo faz três coisas, e as partes do Purview correspondem a elas**:

| trabalho | a pergunta que responde | no Purview |
|---|---|---|
| encontrar | que dados existem, onde, e o que há em cada coluna | o Data Map, preenchido por varreduras |
| reconhecer | quais colunas guardam dados pessoais ou sensíveis | as classificações, e os rótulos de confidencialidade |
| rastrear | de onde vieram os dados de uma tabela e para onde foram | a linhagem, informada pelas ferramentas que movem dados |

Por cima desses três fica a parte pela qual as pessoas buscam e governam, que a Microsoft chama de
**Unified Catalog**: termos de negócio, responsáveis, produtos de dados e as regras sobre quem pode
usar o quê. A última seção desta lição trata dele e da conta.

## Um nome que cobre duas famílias

**"Microsoft Purview" é o nome de duas famílias de produtos que cresceram juntas**, e a documentação
as mistura. Uma família governa plataformas de dados: o Data Map, as varreduras, a linhagem e o
catálogo, o assunto desta lição, sucessora do que se chamava Azure Purview e, antes disso, Azure Data
Catalog. A outra família protege documentos e mensagens no Microsoft 365: rótulos de confidencialidade
em arquivos e e-mails, prevenção contra perda de dados, retenção de caixas de correio. Elas dividem um
portal e alguns conceitos, os rótulos de confidencialidade acima de tudo, e uma busca por "Purview"
devolve as duas. Este curso é sobre a primeira, e encontra a segunda uma vez, na seção sobre rótulos.
