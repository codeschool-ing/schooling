---
title: Os controles, mapeados na cadeia
version: 1
---

Sete incidentes podem deixar a impressão de que cada elo falha de um jeito único e precisa de uma
ferramenta única. O contrário está mais perto da verdade. **A maioria dos controles que os teriam pegado é uma ideia só, aplicada em elos diferentes.** Comparar o que chegou com um registro independente do que se pretendia. Um hash é esse registro para um arquivo, um hash de commit para uma action, a
proveniência para um build, o diff de um lockfile para uma árvore de dependências, uma assinatura para
quem publica.

### Cada incidente, a sua letra e o seu controle

| incidente | onde na cadeia | o controle que o teria pegado | neste curso |
|---|---|---|---|
| SolarWinds | E, o processo de build | builds isolados e de vida curta; proveniência; um segundo build comparado | aula 14 (proveniência), aula 16 (o build) |
| Codecov | F, a publicação de um script | conferir o hash antes de rodar; poucos segredos no CI | esta aula (hashes), aula 17 (segredos) |
| tj-actions | uma dependência do build | fixar actions por commit; tokens de menor privilégio | aula 16 |
| event-stream | a cadeia da própria dependência | ler o diff do lockfile; proveniência até o código | aulas 13 e 15 |
| ua-parser-js | F, publicação por uma conta roubada | versões travadas; um período de espera | aulas 15 e 18 |
| torchtriton | H, a escolha do pacote | um índice só; hashes; nomes registrados | esta aula, aula 15 |
| xz-utils | B e D, um mantenedor e um tarball | build a partir do código; comparar tarball e repositório; saúde do projeto | aula 15 |

Duas letras quase não aparecem na tabela, e isso é honestidade e não omissão. **A, o produtor, e I, o
uso, ficam fora do que um pipeline consegue checar.** Nenhum controle num build diz que a pessoa que
escreveu o software tinha más intenções, e nenhum diz que o serviço implantado foi depois configurado
com uma senha padrão. A primeira é uma questão de em quem você confia; a segunda é território das aulas
9 e 10, e das políticas de admissão de lá.

### O que um time pode fazer nesta semana

A tabela parece um programa de trabalho, e em boa parte é. Ordenado pelo quanto cada passo custa contra
quantas linhas ele cobre:

1. **Um índice só, e `--index-url` para ele.** Elimina a dependency confusion como classe, e é uma
   mudança de configuração.
2. **Um lock com hashes para toda dependência.** Transforma qualquer arquivo alterado, em qualquer
   índice, numa instalação recusada. A aula 15 faz isso no linkbox com um comando.
3. **Actions e imagens base fixadas por commit e por digest**, o que transforma uma tag movida em nada.
4. **Um período de espera** para releases novas, para que uma release publicada há uma hora por uma
   conta roubada não seja instalada antes de alguém olhar para ela.
5. **Um registro do que cada artefato contém**, para que na manhã em que uma dependência for apontada
   como comprometida, a pergunta "temos isso, e onde?" leve minutos. Esse registro é o SBOM, e é a
   aula 13.
6. **Artefatos assinados e proveniência**, verificados antes da implantação, que a aula 14 acrescenta.

### O que o registro precisa responder

Os incidentes têm mais uma coisa em comum, que é sobre o dia seguinte e não sobre o dia anterior. Cada
vítima passou dias ou semanas descobrindo se tinha sido afetada: quais builds usaram o Bash Uploader,
quais imagens tinham o xz 5.6.1, quais máquinas instalaram o nightly entre duas datas. **As organizações
que responderam mais rápido foram as que já tinham uma lista do que havia em cada artefato, feita
quando ele foi construído.** Sem essa lista, a resposta é uma busca em toda imagem e todo servidor,
feita às pressas, enquanto o aviso está no noticiário.

Para o linkbox, a lista já teria respondido uma pergunta que ninguém fez ainda: a imagem contém um
pacote, `packaging`, que o `requirements.txt` nunca menciona. A aula 13 faz a lista, o encontra e explica
por que ele está lá.
