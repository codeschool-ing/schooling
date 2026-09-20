---
title: Três programas, e o erro que custa mais caro
version: 1
---

A suíte são três programas que se parecem e não são parecidos. Cada um é construído em torno de
uma ideia diferente, e o desperdício de tarde mais comum é fazer um serviço naquele que não foi
desenhado para ele.

| | serve para | a unidade dele |
|---|---|---|
| **Word** | texto que é lido em ordem | um parágrafo |
| **Excel** | valores que são calculados a partir de outros valores | uma célula |
| **PowerPoint** | coisas ditas em voz alta, com algo numa tela | um slide |

## O erro do programa errado, nos dois sentidos

**Uma tabela de números montada no Word** parece boa e não dá para ordenar, filtrar, somar nem
conferir. Todo total dentro dela é um número que alguém digitou, o que significa que todo total
dentro dela está errado no instante em que uma linha muda.

**Um documento escrito no Excel** — e isso é mais comum do que parece, porque a grade fica
arrumadinha — não tem página, não tem refluxo, não tem estilos, e imprime em quatro folhas numa
ordem que ninguém previu.

O teste é uma pergunta: **alguma coisa aqui vai ser calculada?** Se sim, Excel, e cole o resultado
no Word depois. Se não, Word.

## Os formatos, e o que o x significa

O `.docx`, o `.xlsx` e o `.pptx` substituíram o `.doc`, o `.xls` e o `.ppt` por volta de 2007. O
`x` é de XML: os novos são **arquivos zip cheios de arquivos de texto**, e é por isso que são
menores, que se recuperam melhor de um dano, e que um `.docx` pode ser aberto por programas que a
Microsoft não escreveu.

Duas consequências práticas:

- **Qualquer coisa que ainda diga `.doc` é de antes de 2007** ou foi salva de propósito por
  compatibilidade. Salve como `.docx` a menos que alguém tenha pedido outra coisa.
- **O `.docm` e o `.xlsm` guardam macros**, que são programas. Um `.xlsm` inesperado num anexo é a
  versão em planilha do `.exe` da aula sete.

## Desktop, web e celular são três produtos diferentes

Eles dividem um nome e um formato de arquivo e não dividem uma lista de recursos. As versões web
são genuinamente capazes e têm faltas: mala direta, a maior parte das funções estatísticas
avançadas, refinamentos de tabela dinâmica, macros.

**Trabalhe na versão de desktop para qualquer coisa complicada e use a web para qualquer coisa
colaborativa**, e saiba que um documento que dá a volta pela versão web pode perder um recurso
que ela não suportava — em silêncio, e normalmente um campo ou uma macro.

## Quanto custa, e a alternativa que é de graça

O Microsoft 365 é assinatura; ainda existe uma licença avulsa *Home and Student* que dá uma versão
fixa sem atualizações além das de segurança. A assinatura inclui o armazenamento na nuvem e as
versões web.

**O LibreOffice é gratuito, abre e salva todos esses formatos, e é uma suíte genuinamente
completa.** A fraqueza dele é exatamente a mesma da versão web: um `.docx` complexo que dá a volta
por ele pode voltar com o layout levemente deslocado. Para os seus próprios documentos isso não é
nada; para um contrato que outra pessoa vai abrir no Word, confira antes de enviar.
