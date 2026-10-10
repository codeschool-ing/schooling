---
title: Muitas mãos num arquivo só
version: 1
---

**Uma pasta de trabalho é feita para uma pessoa de cada vez, e quase todo o problema dela começa com
a segunda pessoa.** Tudo neste curso até aqui supôs um analista com um arquivo. Uma empresa
raramente é assim. A dona da Café Serra lança os pedidos de atacado, um funcionário no balcão
registra as vendas da loja, o contador quer a receita do mês, e cada um, com razão, quer o mesmo
arquivo.

## Cópias por e-mail

A resposta de costume é mandar o arquivo. Na segunda, a dona manda `cafe-serra.xlsx` por e-mail ao
funcionário. Na terça, ela acrescenta duas vendas de atacado na cópia dela. Na quarta, ele corrige o
preço da venda `S1105`, de 106 para 96, porque o cliente tinha desconto, na cópia dele. Na sexta,
há dois arquivos com o mesmo nome, cada um com algo que o outro não tem, e nenhum é a verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l18-copies\" aria-label=\"Duas cópias de uma pasta de trabalho ao longo de uma semana. Na segunda, a dona manda cafe-serra.xlsx por e-mail a um funcionário. Na terça, a cópia da dona ganha duas vendas de atacado. Na quarta, a cópia do funcionário muda o preço da venda S1105 de 106 para 96. Na sexta, há dois arquivos com o mesmo nome, cada um com uma mudança que falta no outro.\"><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">segunda</text><text x=\"290.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">terça</text><text x=\"470.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">quarta</text><text x=\"650.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">sexta</text><text x=\"36.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dona</text><text x=\"36.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">funcionário</text><rect x=\"40.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"48.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><path d=\"M110.0 112.0 L110.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M110.0 170.0 L114.0 162.0 L106.0 162.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"118.0\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e-mail</text><rect x=\"40.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"48.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><rect x=\"220.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"228.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><text x=\"228.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 vendas de atacado</text><rect x=\"220.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"228.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><rect x=\"400.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"408.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"408.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><text x=\"408.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 vendas de atacado</text><rect x=\"400.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"408.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"408.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">108 vendas</text><text x=\"408.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">S1105: preço 106 → 96</text><rect x=\"580.0\" y=\"52.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"588.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">+ 2 vendas de atacado</text><text x=\"588.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">S1105 ainda 106</text><rect x=\"580.0\" y=\"172.0\" width=\"140.0\" height=\"58.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cafe-serra.xlsx</text><text x=\"588.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">S1105: preço 106 → 96</text><text x=\"588.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem as vendas novas</text><path d=\"M182.0 81.0 L218.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M218.0 81.0 L210.0 77.0 L210.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M362.0 81.0 L398.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M398.0 81.0 L390.0 77.0 L390.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M362.0 201.0 L398.0 201.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M398.0 201.0 L390.0 197.0 L390.0 205.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M542.0 81.0 L578.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M578.0 81.0 L570.0 77.0 L570.0 85.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M542.0 201.0 L578.0 201.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M578.0 201.0 L570.0 197.0 L570.0 205.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"580.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">dois arquivos, um nome,</text><text x=\"580.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">nenhum é a verdade</text></svg>", "caption": "A semana de uma pasta de trabalho mandada por e-mail. Cada cópia ganha uma mudança correta que a outra nunca vê, e na sexta alguém precisa juntar as duas no olho.", "same": ["e-mail"]}
```

Alguém agora junta os dois no olho, linha a linha, e a cópia por onde começa decide quais mudanças
vai notar. Os nomes dos arquivos ganham sufixos, `cafe-serra-final.xlsx`,
`cafe-serra-final-v2.xlsx`, e a versão que acaba no relatório do mês seguinte é a que estava aberta
quando o relatório foi feito.

## Uma célula guarda o valor, não a história

**Nada numa planilha registra quem digitou um valor, quando, nem por quê.** A venda `S1105` mostra
96. Seja o preço que o cliente pagou, um desconto combinado por telefone ou um erro de digitação no
lugar de 106, a célula é a mesma. Se a receita de junho parecer errada daqui a três meses, não há
rastro que leve de volta à mudança que a estragou.

E nada impede a mudança errada. A validação da aula 8 confere o que se digita numa célula, e uma
colagem passa por fora dela, como aquela aula mostrou. As regras de que uma empresa precisa, como
*um preço é um número inteiro maior que zero* ou *toda venda cita um produto que existe*, moram na
pasta como conselho, não como parede.

## O que a coautoria resolve, e o que não resolve

O Microsoft 365 acaba com as cópias. Guarde a pasta no OneDrive ou no SharePoint e várias pessoas
podem abrir o mesmo arquivo ao mesmo tempo, cada uma vendo as edições das outras conforme chegam.
**Arquivo › Informações › Histórico de Versões** guarda versões anteriores do arquivo inteiro e
pode restaurar uma delas, e **Revisão › Mostrar Alterações** lista as edições recentes célula por
célula, com quem as fez.

Isso resolve o problema da sexta-feira: há um arquivo só. Não deixa os dados mais seguros. As
regras continuam sendo conselhos que uma colagem ignora. Nada registra por que um valor mudou. Uma
versão é a pasta inteira num momento, então desfazer uma edição ruim significa restaurar tudo em
volta também, ou copiar o valor antigo de volta à mão. E outro programa, o sistema de pedidos da
loja virtual, por exemplo, continua sem um jeito confiável de gravar uma venda no arquivo.

## O que um banco de dados faz no lugar

Um banco de dados é feito justamente para o caso que o Excel não é. **Ele recusa uma linha que
quebra uma regra, venha de quem vier**: um preço que não é número, uma venda que cita um produto
inexistente, uma segunda linha com a mesma chave. Muitas pessoas e programas podem gravar nele ao
mesmo tempo, e cada mudança acontece por inteiro ou não acontece. Quem mudou o quê pode ser
registrado pelo próprio banco, e não pela memória de cada um.

É um trabalho diferente do da pasta de trabalho, e a seção 06 desta aula diz qual curso da trilha o
ensina.
