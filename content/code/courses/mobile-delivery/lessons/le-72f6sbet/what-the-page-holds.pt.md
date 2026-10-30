---
title: O que a página da loja guarda
version: 1
---

**Uma ficha na loja é um formulário com caixas fixas, e toda caixa tem um limite que a loja impõe
quando você salva.** Escrever a ficha se parece menos com escrever uma página web e mais com
preencher uma declaração de alfândega: o que vai onde já está decidido, e a criatividade está no
que você põe dentro. *Lido nas páginas de referência do App Store Connect, outubro de 2026, e na
Central de Ajuda do Play Console como publicada em 2025, que a máquina de gravação não conseguiu
abrir; não rodado.*

| o que a pessoa vê | App Store | Google Play |
|---|---|---|
| o nome | **name**, de 2 a 30 caracteres | **title**, até 30 caracteres |
| a linha embaixo dele | **subtitle**, até 30 caracteres | **short description**, até 80 caracteres |
| o texto longo | **description**, até 4000 caracteres, texto puro | **full description**, até 4000 caracteres |
| palavras escondidas para a busca | **keywords**, até 100 **bytes** | nenhuma: o Google lê o próprio texto |
| texto trocado sem release | **promotional text**, até 170 caracteres | nenhum |
| o que mudou nesta versão | **What's New**, até 4000 caracteres | **notas da versão**, por release |

Duas linhas merecem uma segunda olhada. **As palavras-chave da Apple são contadas em bytes, não em
caracteres**, e em UTF-8 uma letra acentuada ocupa dois bytes, então uma lista de palavras-chave em
português chega ao limite antes de uma em inglês do mesmo tamanho. E **o promotional text é o único
texto da página da Apple que você muda sem enviar uma versão nova**, o que faz dele o lugar para
"novidade deste semestre", e não a descrição.

## O que pertence ao app e o que pertence à versão

Na App Store, o nome e o subtítulo pertencem ao **app** e mudam com uma versão nova; a descrição,
as palavras-chave, as capturas de tela e o What's New pertencem à **versão** enviada. No Google
Play, a ficha é editada à parte, e as mudanças nela passam por revisão como um release. Nas duas,
**uma mudança na ficha é revisada**, então um erro de digitação corrigido na sexta à noite pode ir
ao ar na segunda.

## Localizada, campo por campo

Cada uma dessas caixas existe **por idioma**. Uma ficha em `en-US` e `pt-BR` são dois conjuntos
completos de texto, dois conjuntos de capturas, duas listas de palavras-chave. Um idioma que você
acrescenta e deixa pela metade cai no idioma principal nas caixas que faltam, e é assim que um
visitante brasileiro acaba lendo um nome em português acima de uma descrição em inglês. A lição 18
mede o que isso custa em instalações.

## A mesma página para as três plataformas

Um app em Kotlin tem uma página, no Google Play; um app em Swift tem uma, na App Store. **Um app
React Native tem duas**, uma por loja, com limites diferentes e tamanhos de imagem diferentes, e é
o mesmo trabalho duas vezes. As próximas seções mantêm as duas lojas lado a lado por isso.
