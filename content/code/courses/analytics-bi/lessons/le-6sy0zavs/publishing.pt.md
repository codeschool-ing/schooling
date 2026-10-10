---
title: Publicar, compartilhar e manter atualizado
version: 1
---

Um relatório no computador de uma pessoa é um rascunho. Ele fica útil quando é **publicado** no
serviço do Power BI, onde outras pessoas o abrem num navegador, e é nesse passo que o Power BI deixa
de ser gratuito.

## Licenças, em palavras

Os detalhes e os preços mudam, e as páginas da própria Microsoft são a referência. O formato, no
momento em que isto foi escrito:

- **O Power BI Desktop é gratuito**, e montar relatórios nele também.
- **Publicar e compartilhar exigem uma licença paga por pessoa.** A padrão é a *Power BI Pro*; pessoas
  que compartilham um relatório entre si precisam cada uma de uma.
- **Uma capacidade** — um bloco de processamento que uma organização compra, hoje vendido como parte
  do Microsoft Fabric — muda a conta para os leitores: acima de certo tamanho, quem só lê relatórios
  não precisa de licença própria, e os autores continuam precisando.

Esse é o custo de que a aula 1 avisou, e o motivo de nenhuma aula deste curso depender dele.

## Workspaces e apps

Relatórios são publicados num **workspace**, uma pasta compartilhada com membros que podem editar,
contribuir ou só ler. Times costumam manter um workspace por assunto — vendas, financeiro — e publicar
uma seleção pronta, só de leitura, dos relatórios dele para quem precisa, como um **app**. Um relatório
publicado no workspace pessoal de alguém, o *Meu workspace*, só é visível para essa pessoa, e é o
primeiro lugar aonde bons relatórios vão para ser esquecidos.

## Atualização, e o gateway

Um modelo no modo Import é uma cópia, e uma cópia envelhece. O serviço pode **atualizá-lo** num
horário, rodando de novo os passos do Power Query contra a fonte. Isso só funciona se o serviço
alcançar a fonte. Um banco na internet ele alcança; um banco dentro da rede de uma empresa, ou dentro
da sua máquina virtual, não, e a ponte é o **gateway de dados local** (*on-premises data gateway*): um
programa instalado num computador dentro da rede, a que o serviço pede para rodar a atualização no
lugar dele. Sem um, um relatório publicado a partir de um banco privado mostra os dados como estavam
no dia em que foi publicado, por todo o tempo que alguém olhar para ele.

## Um modelo, muitos relatórios

O modelo semântico pode ser publicado uma vez e usado por muitos relatórios, inclusive relatórios
montados por outras pessoas no serviço. É a ideia da aula 3 nos termos do Power BI: **as medidas são
escritas uma vez, no modelo, e todo relatório sobre ele herda a mesma definição de receita
líquida.** Uma empresa em que todo analista publica um `.pbix` com a própria cópia do modelo tem
quarenta definições de receita de novo, numa ferramenta que faz todas parecerem idênticas.
