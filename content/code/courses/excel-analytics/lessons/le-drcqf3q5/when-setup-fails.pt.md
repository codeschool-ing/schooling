---
title: Quando a instalação falha
version: 1
---

**A maioria das falhas de instalação aqui não é instalação quebrada.** É um Excel mais antigo que o
curso, um recurso desligado ou uma configuração regional que muda o jeito de digitar uma fórmula,
e cada uma mostra um sintoma reconhecível. Encontre o seu abaixo.

## O `PROCX` responde `#NOME?`

`#NOME?` quer dizer que o Excel não conhece um nome da fórmula. Se você digitou certo, o seu Excel é
mais antigo que a função: o Excel 2019 e os anteriores não a têm. A solução é o Microsoft 365, o
Excel 2021 ou posterior, ou um dos outros caminhos da seção anterior. Se ainda não der para trocar,
você consegue acompanhar a aula 4, que ensina `ÍNDICE` e `CORRESP` ao lado do `PROCX` justamente
porque cópias antigas do Excel estão em toda parte, e as aulas 1 a 3 e 5 a 12 não usam nada mais
novo.

## O Excel recusa uma fórmula impressa corretamente

A mensagem é *Há um problema com esta fórmula*. Confira o separador: num Excel em português os
argumentos são separados por **ponto e vírgula**, e esta versão do curso já imprime as fórmulas
assim. Se o seu Excel estiver em inglês, é o contrário: ele quer **vírgula** e nomes de função em
inglês, `SUMIFS` em vez de `SOMASES`. A seção 02 diz onde achar os dois nomes de cada função.

## Tudo colado na coluna A

As tabulações que separavam os valores não sobreviveram à cópia. Acontece quando o texto foi
selecionado e copiado à mão na página, em vez de com o botão de cópia do bloco, ou quando passou
por um programa que troca tabulações por espaços. Copie de novo com o botão. Se a coluna já estiver
cheia, selecione a coluna A e use **Dados › Texto para Colunas**, escolha **Delimitado**, marque só
**Tabulação** e conclua.

## As datas ficam à esquerda das células

Elas chegaram como texto, então `=CONT.NÚM(B:B)` na planilha `Sales` responde 0 em vez de 108. O
Excel lê um valor como `2025-01-02` na ordem ano-mês-dia em qualquer região, então isso é raro, e
costuma querer dizer que a colagem passou antes por outro programa. Selecione a coluna B, use
**Dados › Texto para Colunas**, clique em **Avançar** duas vezes, escolha **Data** com a ordem **AMD**
e conclua. A aula 6 explica o que aconteceu.

## Não existe a guia Power Pivot

No Excel para Windows, o Power Pivot é um suplemento que vem desligado. Vá em **Arquivo › Opções ›
Suplementos**, escolha **Suplementos de COM** na lista **Gerenciar**, embaixo, clique em **Ir**,
marque **Microsoft Power Pivot for Excel** e clique em **OK**. Se ele não estiver na lista, esta
edição do Excel não o inclui; no Mac ou no navegador ele nunca vem, e a seção anterior diz o que
fazer.

## O Excel abre arquivos só para leitura, ou diz *Produto Não Licenciado*

O Excel do Microsoft 365 confere a licença da conta com que está conectado. O aviso quer dizer que
ele está conectado com uma conta que não tem licença, muitas vezes uma conta pessoal num computador
cuja licença pertence a uma conta da empresa ou da escola. Vá em **Arquivo › Conta**, saia e entre
com a conta que tem a assinatura.

## A máquina virtual está lenta

O Windows numa máquina virtual quer pelo menos dois processadores e 4 GB de memória, ajustados nas
configurações da própria máquina virtual com ela desligada, e fica lentíssimo abaixo disso. Feche o
que não precisa no seu computador enquanto ela roda, e mantenha o disco da máquina virtual num SSD,
não num HD externo.

## Nenhuma das anteriores

Anote três coisas antes de pesquisar: o texto exato da mensagem, onde você estava quando ela
apareceu (que guia, que comando) e a versão em **Arquivo › Conta**. Uma busca pela mensagem exata
entre aspas, com a palavra Excel, acha a página da própria Microsoft para a maioria delas. Uma
pergunta feita com essas três coisas recebe resposta; "o Excel não funciona" não recebe.
