---
title: Trocando de edição sem reinstalar
version: 1
---

Os dois computadores chegaram com Home no fim das contas; a loja não tinha mais Pro. **Nada precisa
ser reinstalado.** Como as edições são um sistema só com mais coisas ligadas, subir é uma troca de
licença:

1. *Configurações > Sistema > Ativação*.
2. *Atualizar a edição do Windows*: ou digite uma *chave do produto Pro*, ou compre a atualização na
   Microsoft Store na mesma tela.
3. O Windows liga os recursos e reinicia. Arquivos, programas e configurações ficam.

A licença passa então a ser uma **licença digital** da Pro naquele hardware, como na aula 2, e uma
reinstalação limpa depois ativa a Pro sozinha.

## Descer não funciona assim

**De Pro para Home não é uma troca no lugar.** O Windows não tem um botão para desligar os recursos de
novo; o caminho para baixo é uma instalação limpa da Home, com tudo o que isso quer dizer. É mais um
motivo para escolher uma vez e escolher a Pro.

## Vendo o que uma instalação é e pode virar

```sh
DISM /Online /Get-CurrentEdition            # Professional, Core (Home), Enterprise…
DISM /Online /Get-TargetEditions            # what this installation can be upgraded to
slmgr /dli                                  # the licence: edition, channel, activation state
```

**Nenhum destes foi rodado para esta aula.** O `DISM` chama a Home de *Core* e a Pro de
*Professional*, que são os nomes internos; você vai encontrá-los em logs e no `EditionID` do
registro. O `slmgr` também mostra o **canal da licença**:

| canal | como a licença veio |
|---|---|
| **OEM** | com o PC, do fabricante; presa àquela máquina |
| **Retail** | comprada à parte; pode passar para outro PC, um de cada vez |
| **Volume** | um contrato da organização, ativado pela organização |

Uma licença OEM **não passa** para um PC novo. Um escritório que descarta um computador velho descarta
a licença do Windows junto, o que é normal e é o motivo de PCs novos serem comprados já com a edição.
