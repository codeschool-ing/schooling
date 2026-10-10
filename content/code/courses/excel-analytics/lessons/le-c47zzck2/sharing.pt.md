---
title: Atualizando e entregando
version: 1
---

**Um painel mostra os dados como estavam na última atualização, e viaja com todos eles.** Nenhum
dos dois fatos aparece na tela. A dona vê quatro cartões e três gráficos que parecem atuais, sejam
os dados de ontem ou de março, e nada na planilha diz que o arquivo também guarda 108 vendas e o
nome de cada cliente.

## Atualizando

As tabelas dinâmicas leem o modelo de dados, e o modelo é alimentado pelas tabelas e consultas que
a aula 15 carregou nele. **Dados › Atualizar Tudo** roda tudo, em ordem: as consultas recarregam as
fontes, o modelo recebe as linhas novas, e as tabelas dinâmicas e os gráficos acompanham. É o botão
a apertar porque é o que alcança toda consulta, o modelo e toda tabela dinâmica de uma vez.

Uma pasta de trabalho também pode se atualizar sozinha ao ser aberta. Em **Dados › Consultas e
Conexões**, clique com o botão direito numa consulta, abra as **Propriedades** e marque **Atualizar
dados ao abrir o arquivo**. Custa ao leitor alguns segundos a cada abertura, e garante que os
números nunca são mais velhos que as fontes que as consultas leem.

A data **dados até** do título é o que diz ao leitor o quão nova é a tela. Depois de uma
atualização, ela deve ser a data da última venda que existe. Se as fontes ganharam vendas em julho
e o título ainda diz 23 de junho de 2026, a atualização não chegou até elas, e todos os cartões
estão velhos junto.

## Salvando do jeito que deve abrir

Uma pasta de trabalho abre no estado em que foi salva, e isso inclui a segmentação. Salve com
`Wholesale` selecionado e a dona abre um painel de um canal só, sem nada nos cartões dizendo que os
outros dois estão faltando.

Antes de salvar a cópia que vai sair, ponha o painel no estado padrão:

1. **Dados › Atualizar Tudo**, e confira a data do título.
2. Limpe a segmentação, para que todos os canais fiquem selecionados.
3. Ponha a linha do tempo no período a que o painel se refere.
4. Vá para a `Dashboard`, selecione **A1** e salve. A pasta abre na planilha e na célula em que foi
   salva.

## Quem deveria ter o arquivo

**Tudo o que o painel resume está dentro dele**, nas planilhas de dados, na planilha oculta `Calc`
e no modelo. Um painel mandado por e-mail a alguém que só deveria ver totais entrega também cada
venda e cada cliente. Os clientes da Café Serra são empresas, mas uma loja cujos clientes são
pessoas estaria mandando uma lista delas, e no Brasil isso é dado pessoal sob a LGPD, abra alguém
essa planilha ou não.

Dois caminhos, conforme o que o leitor precisa:

| o leitor precisa | mande |
|---|---|
| ver os números | um PDF do painel, por **Arquivo › Exportar › Criar PDF/XPS**: os números e gráficos como estavam, sem segmentação e sem dados |
| filtrar e explorar | acesso à cópia única, guardada no OneDrive ou no SharePoint e compartilhada com quem deve tê-la, em vez de uma cópia na caixa de entrada |

O PDF é uma fotografia: não filtra e nunca se atualiza, o que é exatamente o certo para quem só
deveria vê-lo. A aula 18 volta à cópia compartilhada, porque muita gente trabalhando numa mesma
pasta de trabalho é onde o Excel começa a sofrer.

## Qual Excel abre o arquivo

Uma pasta de trabalho com modelo de dados precisa do Excel para Windows para atualizar ou mudar o
modelo, como diz a tabela da seção 03 da aula 1. O que um leitor num Mac ou no navegador consegue
fazer com ela, em visualizar e filtrar, mudou de uma versão para outra, então **abra o arquivo no
Excel do leitor antes de mandar**, e não depois que ele responder dizendo que os cartões estão
vazios.
