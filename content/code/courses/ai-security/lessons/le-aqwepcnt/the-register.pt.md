---
title: O que o registro deixou de fora, e como mantê-lo verdadeiro
version: 1
---

As entradas abertas são ameaças em que alguém pensou e ainda não respondeu. **A lacuna mais perigosa é
a ameaça em que ninguém pensou**, e uma lista não consegue relatar o que não está nela. Por isso o
`threats.py` confere o registro contra o diagrama, e não contra ele mesmo: todo fluxo que o
`guard flows` marca precisa ser nomeado por pelo menos uma entrada.

Pela regra das zonas o registro está completo, como disse a última linha da seção anterior. Pela regra
do texto, não está:

```
ana@lab:~/guard$ guard threats --open --text; echo "exit status $?"
id   flow kind risk  control           threat
T11  f12  T       9  OPEN              an upload carries text written to steer the model
T10  f11  R       4  OPEN              a reply cannot be traced to the prompt that made it
T12  f5   T       2  OPEN              a help page is edited to say something false
UNREVIEWED f4 app -> assistant (message and session)
UNREVIEWED f6 files -> assistant (attachment text)
12 threats, 3 open, 2 marked flows with no entry
exit status 1
```

O `f4` e o `f6` são marcados pelo `--text` e não são nomeados por nenhuma entrada, e o programa sai com
status 1 por causa deles. Os dois levam palavras de um cliente para o assistente, e os dois ficam
dentro da zona da Tarefa. Quem escreveu o registro pôs o `T2` no `f1`, onde a mensagem chega, e o
`T11` no `f12`, onde o arquivo chega, e parou na fronteira.

## Onde uma entrada deve ficar

O que decide é **onde o controle está**, não de onde os dados vieram. O primeiro controle do `T2` é o
`check-in`, e ele lê a mensagem a caminho do `app` para o assistente, que é o `f4`. Então a ameaça
mora no `f4` tanto quanto no `f1`. Escrevê-la também no `f4` custa uma linha e põe o registro de
acordo com o diagrama.

O `f6` é outro caso. **Nenhum controle está nele**: o anexo vai do armazenamento de arquivos ao
assistente sem que nada o leia. A entrada certa é uma ameaça nova, adulteração, impacto 3,
probabilidade 3, controle `null`, e ela vai para o topo da lista ao lado do `T11`. A aula 15 é o
trabalho que fecha as duas.

## Um registro que continua verdadeiro

Um modelo de ameaças escrito uma vez e arquivado está correto no dia em que foi escrito. Três hábitos
impedem que ele vire a descrição de uma aplicação que já não existe:

- **ele mora no repositório**, ao lado do código, como o inventário da aula 1. O `flows.json` e o
  `threats.json` são arquivos que um pull request pode mudar;
- **uma funcionalidade que acrescenta um fluxo acrescenta suas entradas no mesmo pull request.** Uma
  ferramenta nova, uma fonte de dados nova ou um fornecedor novo é uma linha nova no `flows.json`, e o
  `threats.py` passa a apontá-la como não revisada até alguém escrever o que pode dar errado ali;
- **a verificação roda onde os testes rodam.** O `threats.py` já sai com 1 enquanto um fluxo marcado
  não tem entrada, e a aula 26 o roda no build, para que um fluxo não revisado reprove um pull request
  como um teste que falha.

## O que ele não faz

O registro anota julgamento; ele não julga. Uma probabilidade 1 que deveria ser 3 põe uma ameaça real
no fim da lista, e nenhum programa percebe. Duas pessoas avaliando separadamente e comparando pegam a
maioria desses casos, e o momento mais barato para essa conversa é antes de a funcionalidade ir ao ar.
E um modelo de ameaças cobre a aplicação como foi desenhada. **Um componente que ninguém desenhou não
tem fluxos para revisar**, e esse é o argumento para desenhar a partir do código e da infraestrutura,
e não de memória.
