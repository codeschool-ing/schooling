---
title: Ligar um documento à coisa de que ele trata
version: 1
---

Um documento sozinho não responde a nenhuma pergunta de negócio. **Um certificado de análise importa
porque pertence a um lote, e um certificado de fornecedor porque pertence a um fornecedor**, então
quase toda busca útil num DMS começa por algo que o ERP conhece. Como os dois são amarrados é uma
decisão de arquitetura, e as respostas mais comuns são as que quebram.

## A pergunta que testa o vínculo

Numa terça-feira de outubro de 2026, a equipe de qualidade de uma rede de supermercados abre um caso
no Service Cloud: quer o certificado de análise do lote L2610-0457, leite UHT integral produzido em
Juiz de Fora. O atendente trabalha no Salesforce, o certificado está no Documentum e o lote está no
SAP. Hoje o atendente manda um e-mail para o laboratório da planta, e o laboratório encontra o PDF
buscando no Documentum o número do lote no nome do arquivo. Isso leva cerca de um dia, e duas vezes
em 2025 o laboratório mandou o certificado do lote errado.

Qualquer forma de ligar documentos pode ser julgada por esse caso. Ela encontra o documento a partir
do lote, encontra a versão certa, e vai continuar funcionando daqui a cinco anos, depois que o
servidor de arquivos, o DMS e o ERP tiverem sido trocados?

## Três jeitos de quebrar um vínculo

**Pelo caminho do arquivo.** Até 2019, os registros de lote da Serra Alta no SAP traziam o caminho do
PDF do certificado num campo de texto livre: `\\jf-fs02\qualidade\certificados\2018\...`. Quando esse
servidor de arquivos foi trocado, em 2019, cada um desses caminhos passou a apontar para o nada, e
nada acusou falha. Um caminho é uma string, e o SAP não fazia ideia de que ela significava alguma
coisa. **Um caminho é o endereço de uma cópia, e cópias mudam de lugar.**

**Pelo nome do arquivo.** Nomes são escolhidos por pessoas, e pessoas os repetem. Até 2022 os
laboratórios de Juiz de Fora e de Lavras davam aos certificados um número sequencial como nome, então
um arquivo chamado `CA-0457.pdf` existia nas duas plantas. Um nome também é editado quando alguém
corrige um erro de digitação, e o vínculo fica com a grafia antiga.

**Pelo título ou pela posição.** "O terceiro anexo do lote" ou "o documento intitulado Certificado
de análise L2610-0457" se soltam no dia em que alguém acrescenta um anexo ou muda o título do
documento. Palavras e lugares numa lista são coisas que as pessoas mudam, e por isso nenhum dos dois
segura um vínculo.

## Ligar por um id estável

Todo objeto num DMS tem um id que o sistema atribui e nunca reaproveita. No Documentum é o
`r_object_id`, dezesseis caracteres hexadecimais; no CMIS é a propriedade `cmis:objectId`. **Um
vínculo é um par de ids: a chave do objeto de negócio de um lado e o id do documento do outro.**
Nenhum dos dois descreve coisa alguma, e é exatamente por isso que os dois sobrevivem a um arquivo
renomeado, a uma pasta movida e a um servidor novo.

Há uma sutileza que importa mais do que parece. Um documento com versões tem dois ids que vale a pena
guardar, e eles respondem a perguntas diferentes:

| o id de | ele nomeia | guarde-o quando o vínculo for para |
|---|---|---|
| uma versão | aquela versão exata, para sempre | prova: o certificado enviado a um cliente, a versão do procedimento em vigor quando um lote foi produzido |
| a série de versões | o documento como um todo, qualquer que seja a versão em vigor | uma instrução: "siga o procedimento de pasteurização" |

No CMIS são `cmis:objectId` e `cmis:versionSeriesId`. No Documentum cada versão tem o seu próprio
`r_object_id`, e todas as versões de um documento compartilham um `i_chronicle_id`. Uma ordem de
serviço ligada ao POP-JF-PAS-004 pela série abre a versão 2.0 no dia em que a 2.0 entra em vigor. Um
registro de lote ligado à versão exata que a linha 2 seguiu em março de 2026 continua abrindo a 1.0
depois que a 2.0 é aprovada, e isso está certo: **a prova aponta para o que era verdade então, a
instrução para o que é verdade agora.**

## Que lado guarda o vínculo

Qualquer um dos dois sistemas pode guardar o par, e os dois padrões são usados.

**O ERP guarda o id do documento.** A interface do próprio SAP para isso, o ArchiveLink, mantém uma
tabela de vínculos que liga um objeto de negócio, pelo tipo e pela chave, a um documento num
repositório de conteúdo externo, e assim a tela do lote no SAP consegue listar os documentos do lote.
O custo é que cada documento precisa ser registrado no SAP, e o DMS sozinho não consegue dizer a que
lote um documento pertence.

**O DMS guarda a chave do ERP como metadado.** O certificado leva propriedades tipadas, lote,
material e planta, preenchidas quando ele é arquivado, e uma busca por lote funciona no DMS sem
perguntar nada ao SAP. O custo é que a chave precisa estar certa na hora do arquivamento e continuar
certa: um lote corrigido no SAP depois do arquivamento deixa um certificado que ninguém encontra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l05-links\" aria-label=\"À esquerda, o lote no SAP: material 100231, lote L2610-0457, planta JF, e o id do documento do certificado. À direita, o certificado no DMS: o id do objeto e as propriedades lote, material e planta. Uma seta do DMS para o SAP é o id do documento gravado de volta no lote; uma seta do SAP para o DMS é a chave do lote guardada como propriedades, que é a fonte da verdade. Abaixo do DMS, um caso do Service Cloud pede o certificado pelo lote e recebe um link. Abaixo do SAP, em âmbar, os vínculos que quebram: um caminho num servidor de arquivos e um nome de arquivo usado por duas plantas.\"><defs><marker id=\"l05-links-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-links-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"40.0\" width=\"230.0\" height=\"128.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP: o lote</text><text x=\"44.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">material  100231</text><text x=\"44.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch     L2610-0457</text><text x=\"44.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plant     JF</text><text x=\"44.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">doc id    0901e24080003a7f</text><rect x=\"460.0\" y=\"40.0\" width=\"230.0\" height=\"128.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">DMS: o certificado</text><text x=\"474.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">object id 0901e24080003a7f</text><text x=\"474.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch     L2610-0457</text><text x=\"474.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">material  100231</text><text x=\"474.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plant     JF</text><path d=\"M270.0 88.0 L450.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l05-links-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave guardada como propriedades</text><text x=\"360.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(fonte da verdade)</text><path d=\"M450.0 144.0 L270.0 144.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-links-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">id do documento gravado de volta</text><rect x=\"460.0\" y=\"243.0\" width=\"230.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"261.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">caso no Service Cloud</text><text x=\"575.0\" y=\"274.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pede pelo lote, recebe um link</text><path d=\"M560.0 242.0 L560.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-links-es-ah-phosphor)\"></path><path d=\"M590.0 172.0 L590.0 242.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-links-es-ah-paper-dim)\"></path><text x=\"552.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">consulta</text><text x=\"598.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">link</text><rect x=\"30.0\" y=\"214.0\" width=\"280.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">vínculos que quebram</text><text x=\"44.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\\\\jf-fs02\\qualidade\\...</text><text x=\"44.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor é trocado</text><text x=\"44.0\" y=\"294.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CA-0457.pdf</text><text x=\"44.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">duas plantas, um nome</text></svg>", "caption": "Um vínculo é um par de ids. O certificado leva a chave do lote sob a qual foi arquivado, o SAP guarda o id do documento, e nada depende de onde o arquivo está ou de como se chama.", "same": ["link"]}
```

A Serra Alta hoje faz metade do segundo padrão: o número do lote vai digitado no nome do arquivo. O
projeto de Joana faz os dois padrões e torna um deles a fonte da verdade do vínculo. A rotina que
gera o certificado a partir dos resultados do SAP QM o arquiva com lote, material e planta como
propriedades tipadas, e depois grava o id do documento novo de volta no lote, no SAP. O DMS responde
"que certificados pertencem a este lote?" e o SAP mostra o certificado na tela do lote. **Se os dois
algum dia discordarem, valem as propriedades do DMS**, porque foram preenchidas a partir da origem
no momento do arquivamento e o id no SAP foi copiado delas.

Com isso no lugar, o caso do supermercado vira uma consulta pelo lote L2610-0457 em busca do
certificado aprovado, e o Service Cloud mostra ao atendente um link que o abre. Um link, não uma
cópia: o DMS confere o acesso do atendente quando o link é seguido, e continua existindo um único
certificado.

## Use a chave inteira, e a chave de negócio

Que chave vai para o DMS? O SAP identifica um lote pelo material e pelo número do lote juntos, e o
mesmo número de lote pode existir para dois materiais. **Use toda a chave que o ERP usa**, ou uma
busca só pelo número do lote vai um dia devolver dois certificados e alguém vai mandar o errado.

E prefira chaves de negócio, o código do material, o número do lote, o número do fornecedor, a um
número técnico interno do ERP. O SAP da Serra Alta vai ser substituído nos próximos anos, como a
aula 2 explica, e o sistema seguinte vai ter os números de lote impressos nas caixas, mas não os ids
internos de linha do antigo. As fazendas são o mesmo caso, já que cada uma é um cadastro de
fornecedor no SAP. Um certificado de fornecedor ou um dossiê de cadastro arquivado sob o número do
fornecedor sobrevive ao ERP que o emitiu, desde que a migração da aula 14 preserve os números.

## Quando o documento vai embora

A seção sobre temporalidade deixou uma pergunta em aberto: o que acontece com um vínculo quando o
documento é descartado? Se o registro do lote no SAP guarda o id de um certificado destruído em
janeiro de 2034, a tela do lote mostra um link para o nada. Então a rodada de descarte informa os
ids que destruiu, e os sistemas que guardam vínculos os marcam como descartados, mantendo a data e a
regra. **Um vínculo para um registro destruído deve dizer que ele foi destruído**, e não falhar em
silêncio, pelo mesmo motivo pelo qual o registro do descarte é guardado.

## Mande o id, não o documento

A mesma ideia vale quando documentos viajam entre sistemas. Hoje o fluxo do ESB que manda
confirmações de pedido a duas das redes de supermercados anexa o PDF do certificado a cada mensagem,
cerca de 300 KB por vez. As filas carregam megabytes de cópias, e cada cópia é um registro que
ninguém gerencia. A alternativa é mandar o id do documento, ou um link que o resolva, e deixar o
destinatário buscar o documento no DMS quando precisar dele. A mensagem fica pequena, o acesso é
conferido quando o documento é buscado, e existe uma cópia só. A aula 11 dá nome a esse padrão, o
*claim check*, e o coloca entre os outros padrões de mensagem.

A regra que cobre a seção inteira é uma a que este curso sempre volta: **ligue por um id estável,
nunca por um nome, um caminho ou uma posição.** Um sistema de documentos que faz tudo o que as três
seções antes desta descrevem, e que está ligado ao ERP pelo nome do arquivo, continua perdendo o
certificado.