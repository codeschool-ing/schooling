---
title: Lixo de gráfico
version: 1
---

O nome que Tufte deu à decoração que não carrega informação é **chartjunk**, lixo de gráfico. Quase
todo ele chega por padrão, de um modelo ou de um tema, e não da decisão de alguém. Os tipos comuns:

- **Molduras e fundos.** Uma caixa em volta da área do gráfico e um preenchimento colorido dentro
  dela. Os eixos já marcam onde o gráfico está.
- **Linhas de grade pesadas.** Linhas escuras em cada marca, que disputam o olho com o dado.
- **Sombras, degradês e preenchimentos brilhantes.** Uma sombra atrás de uma barra é uma segunda
  barra, mais fraca, que o leitor tem de descontar. Um degradê faz uma ponta da barra parecer mais
  longa que a outra.
- **Uma legenda para uma série só.** Se há uma cor só, a legenda não dá nome a nada. O título ou o
  eixo podem dizer o que as barras são.
- **Rótulos redundantes.** O mesmo valor como comprimento da barra, como número na barra e como linha
  de grade embaixo dela. Escolha os de que o leitor precisa.
- **Imagens atrás do dado.** A foto de legumes atrás de um gráfico de receita cria um clima e esconde
  as linhas de grade.
- **A terceira dimensão**, da aula 16, que é lixo de gráfico que ainda por cima distorce.

O teste para cada um é a mesma pergunta: **se eu apagar isto, o leitor perde alguma coisa?** Se não,
apague. Se perde um pouco, deixe mais leve em vez de tirar.

## Padrões também são decisões

As ferramentas diferem em quanto lixo trazem de início. O matplotlib começa com fundo branco, mas com
uma moldura preta completa nos quatro lados; muitos modelos de planilha acrescentam degradês e bordas.
Seja qual for a ferramenta, os padrões foram escolhidos por alguém que nunca viu o seu dado. Trate-os
como um primeiro rascunho.
