---
title: "User data: instruções para o primeiro boot"
version: 2
---

**User data é um texto que você entrega ao provedor ao lançar uma instância.** O provedor o guarda, e
a instância pode lê-lo de volta num serviço de metadados que só ela alcança. Sozinho, isso não faz
nada. O que o torna útil é um programa presente em quase toda imagem Linux publicada, o
**cloud-init**, que roda cedo no primeiro boot, busca o user data e age de acordo.

Se o texto começa com `#!`, o cloud-init o executa como script. Se começa com `#cloud-config`, ele o
lê como um arquivo YAML de declarações, e cada chave de nível superior vai para um dos módulos do
cloud-init. A segunda forma é a preferível: em vez de um script que faz coisas numa ordem que você
precisa acertar, é uma lista do que a máquina deve ter no fim, e o cloud-init sabe a ordem.

Aqui está um para um pequeno servidor web. Cada parte dele é uma chave real do formato do cloud-init:

```schooling-example
{"language": "yaml", "file": "web.yaml", "parts": [{"code": "#cloud-config\n", "note": "Para o cloud-init a primeira linha não é comentário: é como ele sabe que o texto é um arquivo de configuração e não um script. Sem ela, o arquivo não é lido como um."}, {"code": "package_update: true\npackages:\n  - nginx\n\n", "note": "Atualiza as listas de pacotes e instala o nginx. O nome é o que o gerenciador de pacotes da imagem usa, então esta linha vale para imagens Debian e Ubuntu."}, {"code": "users:\n  - default\n  - name: ana\n    groups: [sudo]\n    shell: /bin/bash\n    sudo: \"ALL=(ALL) NOPASSWD:ALL\"\n    ssh_authorized_keys:\n      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoLEfVeFZ0GWJ/mCzAhS1R8EN1CAw6s4HI4sjd7Yuay ana@laptop\n\n", "note": "`default` mantém o usuário que a imagem já define, como `ubuntu`. `ana` ganha um shell, o grupo `sudo` e a metade pública da chave SSH dela. Ela não tem senha, então o `sudo` é liberado sem senha; essa linha é uma escolha, e uma configuração mais rígida a deixa de fora."}, {"code": "write_files:\n  - path: /var/www/html/index.html\n    content: |\n      <h1>served by HOST</h1>\n    permissions: \"0644\"\n    defer: true\n\n", "note": "Um arquivo escrito a partir da própria configuração. `defer: true` o segura até depois da instalação dos pacotes, para que ele caia no diretório que o nginx preparou, e não antes de o nginx existir."}, {"code": "runcmd:\n  - sed -i \"s/HOST/$(hostname)/\" /var/www/html/index.html\n", "note": "Comandos que rodam uma vez, no fim do primeiro boot, na ordem dada. Este escreve o hostname da própria máquina na página, para que cada instância de um grupo diga qual delas respondeu."}]}
```

A ordem em que você escreve as chaves não é a ordem em que elas rodam. O cloud-init roda em estágios,
e a própria configuração padrão dele lista que módulo pertence a qual: os usuários e as chaves SSH são
preparados no primeiro estágio, e os pacotes, os arquivos adiados e depois os comandos do `runcmd` no
último. É por isso que `write_files` leva `defer: true`, e por isso o `runcmd` pode contar com o
arquivo que edita.

## Confira antes de dar boot em qualquer coisa

Um erro no user data não impede uma máquina de dar boot. **O cloud-init registra o problema no log e
segue em frente**, então uma chave com erro de grafia é pulada e a instância sobe sem aquilo para que
a chave servia. Se a chave era a que instala a sua chave SSH, você está trancado fora de uma máquina
cujo log diria por quê.

O cloud-init consegue conferir um arquivo contra o schema dele sem dar boot em nada, e a aula 1
instalou a versão 26.2 dele, a partir do próprio código-fonte, exatamente para isso. Copie o exemplo
acima com o botão dele e salve como `web.yaml` em `~/cloud`. O `sed` abaixo faz dele o `typo.yaml`, o
mesmo arquivo com uma palavra trocada; **nada dá boot, em nuvem nenhuma**:

```
ana@laptop:~/cloud$ sed 's/ssh_authorized_keys/ssh_authorised_keys/' web.yaml > typo.yaml
ana@laptop:~/cloud$ cloud-init schema -c web.yaml
2026-10-07 10:55:03,190 - log_util.py[WARNING]: Getting data from <class 'cloudinit.sources.DataSourceNone.DataSourceNone'> failed
2026-10-07 10:55:03,190 - schema.py[WARNING]: datasource not detected, using default instance-data/user-data paths.
Valid schema web.yaml
ana@laptop:~/cloud$ cloud-init schema -c typo.yaml 2>&1 | cut -c1-120
2026-10-07 10:55:03,542 - log_util.py[WARNING]: Getting data from <class 'cloudinit.sources.DataSourceNone.DataSourceNon
2026-10-07 10:55:03,543 - schema.py[WARNING]: datasource not detected, using default instance-data/user-data paths.
Error: Cloud config schema errors: users.1: Additional properties are not allowed ('ssh_authorised_keys' was unexpected)

Error: Invalid schema: user-data

Invalid user-data typo.yaml
```

As duas linhas `WARNING` vêm antes de toda resposta, e não são sobre o seu arquivo. O cloud-init
espera estar rodando numa instância, e procura primeiro a fonte de dados, o serviço de metadados do
provedor; num laptop não há nenhum, então ele avisa e confere o arquivo sozinho. As respostas são as
linhas depois delas.

O primeiro arquivo é o de cima. O segundo tem a tal palavra escrita à moda britânica,
`ssh_authorised_keys`, e o schema a recusa: essa chave não existe, e a que existe se escreve com *z*.
A mensagem foi cortada em 120 caracteres pelo comando, que é onde termina a parte que vale ler. Num
boot de verdade o mesmo erro seria um aviso no log da instância, e a máquina subiria sem a chave.

Mais duas coisas sobre user data que decidem como usá-lo.

**Ele roda uma vez.** Os módulos acima agem no primeiro boot de cada instância e não num reboot, o que
é certo para instalar pacotes e criar usuários. Algo que precisa acontecer a cada início pertence ao
gerenciador de serviços do próprio sistema, instalado pelo user data.

**Ele não é segredo.** Qualquer processo na instância consegue ler o user data de volta no serviço de
metadados, e quem tem permissão para descrever a instância na conta também. Uma senha ou uma chave de API escrita nele fica escrita num lugar que muita coisa lê. O outro caminho é buscar o segredo no boot, no cofre de segredos do provedor,
com as permissões que a aula 7 monta; o `cloud-security` vai mais longe.

Quando uma máquina não sobe do jeito que o user data diz, o log da própria instância é onde olhar:
`cloud-init status --wait` espera o primeiro boot terminar e diz se falhou, e
`/var/log/cloud-init-output.log` guarda o que cada comando imprimiu.
