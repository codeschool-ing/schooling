---
title: Onde ele fica, e como se chega a ele
version: 1
---

Um runbook guardado no sistema que ele descreve se perde junto com ele. A página que explica como
recuperar o banco de dados não pode estar numa wiki cujo banco de dados é o que caiu, nem no disco do
primário, nem atrás de um single sign-on que faz parte da própria pane.

- **Dois lugares, no mínimo**: a documentação habitual do time, e uma cópia em algum lugar que não
  dependa de nenhum dos sistemas que ela descreve, como um repositório em outro provedor, ou impressa e
  arquivada ao lado do telefone de plantão. O repositório é melhor, porque tem histórico e diff: uma
  mudança no runbook é revisada como uma mudança no código, e o `runbook-check.sh` roda a cada mudança.
- **Segredos são referenciados, não escritos**: o runbook diz qual entrada do gerenciador de senhas
  guarda a senha de replicação, e como chegar ao gerenciador de senhas quando o caminho de sempre está
  fora do ar, o que às vezes se chama de procedimento de **break-glass** ("quebre o vidro", como num
  alarme de incêndio): uma conta lacrada para emergências, em que cada uso é notado e revisado.
- **O acesso é testado** como todo o resto: num ensaio, quem segue o runbook usa só o que consegue
  alcançar de onde está, e cada "eu só perguntaria para a Ana" é uma linha que falta na página.

## O curso, numa página só

O runbook é onde este curso vai dar, porque é onde tudo nele é usado. A restauração da lição 1, que
alguém viu dar certo, é a linha de "último teste" dele. As lições 2 a 10 são os backups para os quais
ele aponta, onde eles ficam e quem pode apagá-los. As lições 11 a 21 são a maquinaria que os cenários
dele descrevem. A lição 22 é como ele é usado na noite do incidente, e a lição 23 é como ele é mantido
honesto. O teste de tudo isso é o do topo desta lição: outra pessoa, só com a página, na pior hora
possível, trazendo o shop de volta.
