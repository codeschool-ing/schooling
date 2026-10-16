---
title: O que este servidor ainda não é
version: 1
---

O `app.py` responde certo, confere o que recebe, diz qual modelo é e guarda um registro de toda resposta.
Ainda assim é um servidor para uma máquina e uma pessoa, e vale saber o que fica entre ele e um serviço em
que a equipe de retenção possa confiar. Nada disto é aprendizado de máquina, e tudo isto decide se o
aprendizado de máquina vai ser usado.

- **Ele responde a qualquer um que o alcance.** Ele escuta em `127.0.0.1`, só esta máquina, e é isso que
  o mantém seguro agora. Numa rede ele precisa saber quem está perguntando e recusar todos os outros: as
  chances são dados pessoais sobre assinantes com nome.
- **Ele roda como um processo numa máquina.** O Uvicorn consegue rodar vários workers, e um serviço
  costuma rodar várias cópias, em mais de uma máquina, atrás de algo que reparte os pedidos.
- **Ele para quando o terminal fecha.** Um serviço de verdade é iniciado pelo sistema, reiniciado quando
  falha e empacotado com as suas versões, para que a máquina em que roda bata com a ficha. Contêineres são
  o caminho comum, e o `stored.load` se recusando a subir com as versões erradas é a mesma ideia numa
  linha.
- **Trocar o modelo quer dizer pará-lo.** `churn-2025-12` está escrito no código. Um serviço nomeia o
  modelo que deve carregar na sua configuração, para que um modelo novo possa ser posto no lugar, e o
  antigo de volta, sem mudar uma linha.
- **O `scores.jsonl` cresce para sempre, num disco só.** É o arquivo mais importante que o servidor
  grava, e a próxima aula é sobre o porquê: é o registro do que o modelo disse, e em um mês ele é posto
  ao lado do que aconteceu.

Cada um desses tem ferramentas e uma disciplina próprias, e **`ml-mlops` é o curso sobre eles**: registros
de modelos, contêineres, retreino agendado e os pipelines que rodam tudo isso. O que esta aula deixa no
lugar é a parte que todos eles supõem: um modelo que é um objeto só, um arquivo que volta idêntico, uma
ficha que diz o que o fez, uma porta que confere o que entra e um teste de que as respostas servidas são
as medidas.

Para parar o servidor, vá ao segundo terminal e aperte **Ctrl+C**.
