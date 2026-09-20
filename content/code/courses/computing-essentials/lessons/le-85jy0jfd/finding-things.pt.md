---
title: Achar as coisas, e por que a busca às vezes não acha nada
version: 1
---

Há dois jeitos de um computador procurar um arquivo, e eles se comportam de modo tão diferente
que saber qual você está usando explica quase toda surpresa.

- **Uma varredura** percorre a árvore e lê cada nome. Ela sempre acha o que está lá, e demora o
  tanto que a árvore for grande.
- **Um índice** é uma lista montada de antemão — nomes, e muitas vezes o conteúdo dos documentos —
  que é consultada em vez do disco. Ele responde na hora e responde sobre **a árvore como ela era
  quando o índice foi atualizado pela última vez.**

Toda caixa de busca de sistema usa o índice. Então *a busca não achou nada* quase sempre
significa que **o índice ainda não chegou àquele arquivo**, ou que a pasta não é coberta pelo
índice, ou que o índice está danificado. O arquivo está lá; a lista não.

## O que fazer quando ela não acha nada

1. **Esperar.** Um arquivo criado há um minuto numa máquina ocupada pode ainda não estar
   indexado.
2. **Conferir o que é indexado.** O Windows indexa a pasta pessoal e não o disco inteiro por
   padrão; um disco externo normalmente não é indexado.
3. **Reconstruir o índice** se ele estiver consistentemente errado. Leva horas e conserta a
   classe inteira do problema.
4. **Usar uma ferramenta que varre**, para os casos que o índice não cobre — o `Everything` no
   Windows, o `find` na linha de comando, o `mdfind` no macOS.

## Os operadores que valem conhecer

Caixas de busca aceitam mais que palavras, e quatro tipos de filtro cobrem quase tudo:

| | o que faz |
|---|---|
| `"frase exata"` | as palavras juntas e nessa ordem |
| `type:pdf` ou `kind:document` | restringe pelo que é em vez de pelo que diz |
| `date:esta semana`, `modified:>2026-01-01` | o filtro que as pessoas buscam por último e deveriam buscar primeiro |
| `size:>100MB` | o que encontra o que está enchendo um disco |

**Data e tamanho são os dois que acham um arquivo cujo nome você não lembra**, e são os dois que
ninguém usa. *Modificado nesta semana, maior que um megabyte, tipo pdf* costuma ser uma lista de
quatro coisas, uma das quais é a que você queria.

## A parte que é serviço seu

Um índice busca nomes e, em documentos, o texto de dentro. Ele não consegue buscar o que não está
escrito.

O que significa que a qualidade da sua busca é decidida muito antes de você buscar — pelo nome
dos arquivos. **`documento(3).pdf` é inachável por qualquer ferramenta já feita.** Não porque a
busca seja fraca, mas porque não há nada naquele nome contra o que casar.

É esse o argumento inteiro da próxima seção, e é o único lugar desta aula em que o serviço é seu
e não da máquina.

## Uma nota sobre a nuvem

Arquivos sincronizados de um serviço de nuvem muitas vezes são **substitutos** — um nome e um
ícone no seu disco, com o conteúdo ainda no servidor até você abrir. Isso se chama *arquivos sob
demanda*, e poupa uma quantidade enorme de espaço.

Também significa que uma busca pelo *conteúdo* dos arquivos pode não alcançá-los, que uma
ferramenta de backup pode copiar os substitutos em vez dos arquivos, e que uma pasta que mostra
40 GB pode estar usando 40 MB. Vale saber antes de depender de qualquer um dos dois.
