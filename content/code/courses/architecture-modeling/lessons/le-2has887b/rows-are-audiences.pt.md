---
title: Linhas são públicos, não níveis de detalhe
version: 1
---

**A leitura errada mais comum da grade de Zachman é achar que cada linha é a de cima com mais
detalhe.** Não é. Cada linha é uma descrição diferente, para uma pessoa diferente, e descer uma
linha muda o que está sendo descrito, não só a finura.

## A analogia do prédio

Zachman montou o framework a partir de como outras indústrias descrevem coisas complexas. Para um
prédio:

- o **dono** precisa de um esboço do que o prédio é para fazer e, por alto, do que ele contém;
- o **arquiteto** precisa de plantas e fachadas, na linguagem de cômodos e espaços;
- o **construtor** precisa de desenhos de obra, na linguagem de vigas e canos;
- o **subempreiteiro** precisa de desenhos de fabricação de uma parte, na linguagem de peças e
  encaixes.

O desenho do construtor não é uma versão mais detalhada do esboço do dono. Ele responde a perguntas
que o dono nunca fez, com palavras que o dono não usa. Cada um é **completo para quem lê** no seu
próprio nível, e cada um sai do de cima por uma troca de linguagem, não por um zoom.

## Dar zoom e trocar de linha são movimentos diferentes

É aqui que Zachman e o modelo C4 da aula 3 se encontram e se separam:

- **Os níveis do C4 dão zoom.** Um diagrama de containers e um diagrama de componentes são o mesmo
  tipo de descrição, para leitores técnicos, em dois aumentos.
- **As linhas de Zachman traduzem.** O *como* da linha 2 é um processo de negócio em palavras de
  negócio; o *como* da linha 3 é o processo lógico do sistema; o *como* da linha 4 é o desenho
  físico, com tecnologias. Cada um é um modelo diferente.

Então o C4 inteiro fica mais ou menos nas linhas 3 e 4, e dá zoom dentro delas. O modelo de
processo do gestor de negócio, na linha 2, é outro tipo de coisa, e é por isso que existem o BPMN
da aula 4 e a análise de negócio da aula 7.

## Por que isso importa na prática

Confundir as linhas com detalhe produz uma falha conhecida: um gestor de negócio recebe o diagrama
de um engenheiro *porque ele é mais completo*. Para esse leitor ele não é mais completo; está na
linguagem errada. A aula 14 transforma isso na regra para apresentar arquitetura: quando o público
muda, **troque de linha, não de zoom**.
