---
title: O que é o Power Query, e por que não simplesmente abrir o arquivo
version: 1
---

**O Power Query busca os dados, transforma-os e anota cada mudança como uma etapa, para que no mês
seguinte a lista inteira rode de novo sobre o arquivo novo com um clique.** Essa é a ideia toda, e
tudo nas aulas 13 e 14 é um detalhe dela.

## O hábito que ele substitui

A maioria das pessoas conhece um arquivo CSV com um clique duplo. O Excel o abre, e aí começa o
trabalho: os preços vieram como texto, as datas estão na ordem errada, há um pedido cancelado para
apagar e uma coluna de que ninguém precisa. Alguém conserta tudo à mão, copia as linhas para baixo
das do mês anterior e salva. No mês seguinte o arquivo chega de novo e a mesma tarde se repete, de
memória, com um erro diferente a cada vez.

O Power Query transforma essa tarde numa receita. Você abre o arquivo por ele uma vez, faz as mesmas
correções com os comandos dele, e cada correção fica registrada numa lista chamada **Etapas
Aplicadas** (Applied Steps). Quando o próximo arquivo chega, **Dados › Atualizar Tudo** o busca e
repete a lista. As correções deixam de ser a memória de alguém: estão escritas, em ordem, e rodam do
mesmo jeito todas as vezes.

## Onde ele fica

Tudo começa na guia **Dados**, no grupo **Obter e Transformar Dados**, em **Obter Dados**. Esse menu
lista os lugares que o Power Query sabe ler: arquivos, pastas, outras pastas de trabalho, bancos de
dados, páginas da web. Esta aula passa por eles nessa ordem.

Escolher uma fonte abre o **Editor do Power Query**, uma janela própria com quatro partes que vale
conhecer pelo nome:

| parte | o que mostra |
|---|---|
| a visualização | as primeiras linhas dos dados como estão depois da etapa selecionada |
| **Etapas Aplicadas** | à direita, em **Configurações de Consulta**: a lista de tudo o que foi feito até agora, a mais antiga no topo |
| a barra de fórmulas | a etapa selecionada escrita em **M**, a linguagem própria do Power Query |
| a faixa de opções | os comandos, cada um acrescentando uma etapa quando você o usa |

Clique em qualquer etapa da lista e a visualização volta àquele momento. Olhar não apaga nada: as
etapas seguintes continuam lá, e clicar na última leva você de volta ao fim.

## Três coisas que ele não é

**Não é uma fórmula.** Uma fórmula de célula recalcula sempre que uma célula que ela lê muda. Uma
consulta roda quando você manda, com **Atualizar**, e entre uma atualização e outra o resultado fica
parado. A seção 08 desta aula trata de quando e como ela atualiza.

**Não é uma macro.** Nenhum código roda na sua pasta de trabalho e nada é gravado como cliques na
tela. Cada etapa diz o que fazer com os dados, como "manter as linhas cujo status é paid", e o Excel
descobre como fazer.

**Não altera a origem.** O Power Query lê o arquivo e nunca escreve nele. O CSV na sua pasta depois
de cem atualizações é, byte a byte, o que você salvou, e o resultado mora em outro lugar: numa tabela
numa planilha, ou numa consulta que alimenta outra.

## Como os números desta aula foram feitos

**Nada nas aulas 13 e 14 foi executado no Excel.** O computador em que este curso foi escrito não tem
Excel, como diz a seção 02 da aula 1, e o Power Query não tem motor fora dele. Os arquivos que você vai
criar estão impressos na aula, e todo número que uma etapa produz aqui foi calculado por um script que
aplica as mesmas etapas aos mesmos arquivos. Os menus e as caixas de diálogo foram nomeados a partir da
documentação da Microsoft. Onde o código que o Excel escreve para você puder diferir do código impresso
aqui num detalhe, como o caminho de um arquivo ou a ordem de duas opções, a aula avisa.

Isso tem uma consequência para você: quando o seu número for diferente do da página, confira primeiro
o seu arquivo. Uma linha faltando ou um espaço a mais num arquivo digitado é o motivo mais comum, e os
arquivos são pequenos o bastante para comparar a olho.

## Windows e Mac

O Excel para Windows tem todos os conectores desta aula. O Excel para Mac ganhou o Power Query aos
poucos e lê arquivos de texto, arquivos CSV e pastas de trabalho, mas alguns dos outros não aparecem
no menu **Obter Dados** dele. Se um conector desta aula não estiver lá, o caminho do Windows da seção
02 da aula 1 é o jeito de acompanhar.
