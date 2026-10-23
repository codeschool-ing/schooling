---
title: "Incidentes no build: SolarWinds, Codecov, tj-actions"
version: 1
---

Três incidentes, com cinco anos entre o primeiro e o último, e uma coisa em comum: **o código-fonte
que as vítimas revisaram estava certo.** O que deu errado aconteceu depois, na maquinaria que constrói,
entrega ou testa o software. Cada um é contado aqui a partir dos post-mortems e análises públicas, no
nível do que quebrou e do que o teria pegado; os detalhes que não são certos ficaram de fora.

### SolarWinds, 2020: o processo de build (E)

A SolarWinds faz o Orion, um software de monitoramento de rede instalado em muitas empresas e órgãos
de governo. Atacantes entraram no ambiente de build da SolarWinds e puseram lá um programa, que a
empresa de segurança CrowdStrike analisou depois e chamou de SUNSPOT. **Ele esperava builds do Orion e,
enquanto um rodava, trocava um arquivo-fonte por uma versão com um backdoor**, e depois punha o original
de volta. O repositório nunca conteve o backdoor. O produto compilado continha, e era assinado com o
certificado da própria SolarWinds, porque a assinatura acontecia depois do build.

As atualizações que o carregavam foram distribuídas em 2020, e o comprometimento se tornou público em
dezembro de 2020. A SolarWinds estimou em menos de 18.000 os clientes que instalaram uma versão afetada.

O que o teria pegado:

- **Um build que não pode ser alterado de fora do build**: um ambiente isolado e de vida curta, criado
  para cada execução e destruído depois, que os níveis de build mais altos do SLSA exigem. Um implante
  que persiste entre builds não tem onde morar.
- **Proveniência**: um registro assinado, feito pela plataforma de build, de exatamente qual código
  entrou. A aula 14 produz um para o linkbox.
- **Um segundo build, independente, comparado com o primeiro.** Um build reprodutível que dá bytes
  diferentes numa máquina limpa é um build que foi adulterado em algum ponto.

**A assinatura não ajudou, e essa é a lição da SolarWinds para a aula 14**: uma assinatura diz quem
publicou o artefato, não que o artefato é o que o código diz.

### Codecov, 2021: a publicação do artefato (F)

A Codecov oferecia um script Bash, o Bash Uploader, que muitos pipelines de CI baixavam e rodavam a
cada build, quase sempre com `curl` canalizado direto para o `bash`. Um atacante obteve uma credencial
por uma falha no jeito como a Codecov construía uma das suas imagens Docker e, a partir de 31 de janeiro
de 2021, a usou para modificar o script no armazenamento da Codecov. **O script modificado enviava o
ambiente do CI, com os segredos, para um servidor fora da Codecov.**

Ele foi descoberto em 1º de abril de 2021 por um cliente que comparou o SHA-256 do script que tinha
baixado com o hash publicado para ele, e viu que eram diferentes. A Codecov o divulgou em 15 de abril.

O que o teria pegado:

- **Conferir o hash antes de rodar o script**, que é literalmente como ele foi descoberto. Todo
  pipeline que canalizava o download para o `bash` sem essa conferência rodou o modificado.
- **Menos segredos no ambiente do CI**: um script que só vê um token de vida curta para um job tem
  pouco a enviar. A aula 17 constrói isso.
- **Proveniência para o arquivo publicado**: o SLSA usa a Codecov como exemplo da letra F, porque um
  registro de como o script oficial foi construído não bateria com o modificado.

### tj-actions/changed-files, 2025: uma dependência do build

`tj-actions/changed-files` é uma GitHub Action que lista os arquivos que uma mudança tocou, usada por
dezenas de milhares de repositórios. Em março de 2025 um atacante com um token roubado **apontou as
tags de versão da action para um commit novo**, cujo código imprimia os segredos do runner do CI no log
do build. Num repositório público, o log do build é público. Recebeu o CVE-2025-30066.

Os workflows que se referiam à action por tag, como `@v45`, rodaram o código novo sem nenhuma mudança
do lado deles, porque uma tag do Git pode ser movida. **Os workflows que se referiam a um hash de commit
completo continuaram rodando o código antigo**, porque um hash de commit nomeia exatamente uma árvore de
arquivos.

O que o teria pegado:

- **Fixar toda action por commit**, com a versão num comentário para as pessoas lerem, o que a aula 16
  faz no workflow do linkbox e confere com o zizmor.
- **Menor privilégio para o token do workflow**, para que o que pode vazar valha pouco.
- **Não imprimir segredos em logs**, uma proteção que os runners hospedados aplicam mascarando segredos
  conhecidos, e que este ataque contornou codificando-os.

Os três têm a mesma forma em três lugares da cadeia. Alguém confiou num passo que não controlava, no
build, num script baixado, numa tag, e o controle que teria percebido é um que compara o que chegou com
um registro do que se pretendia: proveniência, um hash, um commit.
