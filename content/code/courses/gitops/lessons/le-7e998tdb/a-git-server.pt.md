---
title: Um servidor Git seu
version: 1
---

**A aula 1 guardou o estado desejado num repositório bare no mesmo disco.** Bastava para uma pessoa
e um laço, e não tem nada de que um time precisa: nem contas, nem permissões, nem pull requests, nem
registro de quem aprovou o quê. Esta seção o troca pelo Gitea, um servidor Git que é um programa só
e roda num container ao lado do cluster. Tudo o que esta aula faz com ele, o GitHub e o GitLab fazem
com as mesmas ideias e botões diferentes.

## Subindo o servidor

```sh
docker run -d --restart=always --name gitea --network kind -p 127.0.0.1:3000:3000 \
  -e GITEA__security__INSTALL_LOCK=true gitea/gitea:28.1.0-rootless
```

O `--network kind` o põe na mesma rede Docker do nó do cluster, então **ele tem dois endereços**:
`http://localhost:3000` do seu terminal e do seu navegador, e `http://gitea:3000` de dentro do
cluster, onde o nome do container resolve. O Argo CD da aula 3 usa o segundo. O
`INSTALL_LOCK=true` pula a página de instalação e fica com os padrões, que guardam tudo num arquivo
SQLite dentro do container.

## Uma conta e um token

A própria linha de comando do Gitea cria a primeira conta, uma administradora, e um token para ela.
O token vai para um arquivo que só você lê, e nunca para a tela:

```
ana@laptop:~$ docker exec gitea gitea admin user create --admin --username ana --password 'change-me-now' --email ana@example.org --must-change-password=false
New user 'ana' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username ana --token-name terminal --scopes write:repository,write:user --raw > ~/ana.token
ana@laptop:~$ chmod 600 ~/ana.token
ana@laptop:~$ wc -c ~/ana.token
41 /home/ana/ana.token
```

Um token é o que um programa usa no lugar da sua senha, e **ele só carrega os escopos que recebeu**:
este pode escrever em repositórios e nas configurações do seu usuário, e nada mais. Num servidor de
verdade cada pessoa cria o seu na interface web, em Settings, Applications; aqui você é a
administradora e a linha de comando é mais rápida. A interface web fica em `http://localhost:3000`
se você quiser olhar, como `ana`, com a senha acima.

## O repositório

O resto desta aula fala com a API do Gitea usando `curl`, então três variáveis de shell poupam
digitação. Ponha-as no seu terminal, ou no `~/.bashrc` para tê-las em todo terminal novo:

```sh
API=http://localhost:3000/api/v1/repos/ana/fleet
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'
```

Criar um repositório é um `POST` na lista de repositórios do usuário, e o `jq` tira três campos da
resposta longa (`sudo apt-get install jq` se você não o tiver):

```
ana@laptop:~$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"name": "fleet", "private": true}' http://localhost:3000/api/v1/user/repos | jq '{full_name, private, clone_url}'
{
  "full_name": "ana/fleet",
  "private": true,
  "clone_url": "http://localhost:3000/ana/fleet.git"
}
```

**Privado**, porque um repositório de configuração descreve a produção, e isso não é da conta de
ninguém fora do time. O Git também precisa do token, para fazer push. O helper `store` o guarda em
`~/.git-credentials`, que você deixa legível só por você:

```sh
git config --global credential.helper store
printf 'http://ana:%s@localhost:3000\n' "$(cat ~/ana.token)" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

E o `~/fleet` troca o remoto, do repositório bare para o servidor, e manda tudo para ele:

```
ana@laptop:~/fleet$ git remote set-url origin http://localhost:3000/ana/fleet.git
ana@laptop:~/fleet$ git push --quiet -u origin main
ana@laptop:~/fleet$ git ls-remote origin
f990998d0c04ea06c327242565667cd2529b864e	HEAD
f990998d0c04ea06c327242565667cd2529b864e	refs/heads/main
ana@laptop:~/fleet$ git log --oneline -1
f990998 Revert "staging: no service"
```

O `git ls-remote` pergunta ao servidor o que ele tem, e a `main` aponta para o mesmo commit que na sua
máquina: o histórico da aula 1, quatro commits, agora num servidor. O `~/fleet.git` pode ir embora
com `rm -rf ~/fleet.git`.

## De dentro do cluster

Vale conferir o segundo endereço uma vez, de um pod que pergunta a versão ao Gitea e termina:

```
ana@laptop:~/fleet$ kubectl run probe --restart=Never --image=busybox:1.37 -- wget -qO- http://gitea:3000/api/v1/version
pod/probe created
ana@laptop:~/fleet$ kubectl logs probe; echo
{"version":"28.1.0"}
ana@laptop:~/fleet$ kubectl delete pod probe
pod "probe" deleted from default namespace
```

Um pod chegou ao Gitea pelo nome do container e recebeu a versão dele de volta. Quando um agente
dentro do cluster ler este repositório, é esse o endereço que ele usa.
