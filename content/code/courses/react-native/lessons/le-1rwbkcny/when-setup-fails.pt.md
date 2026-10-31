---
title: Quando a preparação falha
version: 1
---

**Quase toda preparação que falha, falha de um entre seis jeitos, e cada um tem um sintoma que dá para
reconhecer.** Esta seção é a lista. Volte a ela sempre que um comando de uma aula mais adiante parar
antes de começar: quase sempre a causa está aqui, e não na aula.

## O `node` não é encontrado, ou responde com a versão errada

`command not found` logo depois de instalar quase sempre quer dizer que o terminal foi aberto antes de
a instalação mudar o `PATH`. Feche-o e abra outro. Se não resolver, pergunte ao shell onde ele procura
e o que encontra:

```sh
echo $PATH
which -a node
```

O `~/.local/bin` precisa estar na primeira resposta. Se a segunda imprimir **dois** caminhos, um Node.js
mais antigo instalado de outro jeito (um pacote do sistema, o `nvm`, o Homebrew) está sendo encontrado
primeiro. Remova esse, ou garanta que o `~/.local/bin` venha antes no `PATH`. Duas instalações são uma
armadilha que reabre toda vez que um terminal começa, então resolver isso agora sai mais barato que
resolver na aula 12.

## O npm diz `EACCES`

`EACCES` é uma recusa de permissão: o npm tentou escrever num lugar onde o seu usuário não pode. Este
curso nunca instala nada globalmente e nunca precisa de `sudo` para o npm. Se você vir esse erro, a
causa mais comum é um `node_modules` ou um cache do npm que um `sudo npm` anterior deixou pertencendo
ao root. Encontre-o com `ls -l` e devolva-o a você com `sudo chown -R "$USER" <a pasta>`, em vez de
rodar o npm como root de novo, o que torna a próxima recusa mais provável.

## O download trava, ou falha com um erro de certificado

O `npm install` e o `npx` buscam em `registry.npmjs.org`. A rede de uma escola ou de um escritório que
inspeciona o tráfego o reassina com o próprio certificado, e o Node.js o recusa com um erro que cita
um certificado da cadeia. A solução é dessa rede: os administradores publicam o certificado, e
`NODE_EXTRA_CA_CERTS` apontando para esse arquivo diz ao Node.js para confiar nele. **Nunca desligue a
verificação** para passar: isso faz todo download dali em diante aceitar a resposta de qualquer um. Se
você está numa rede assim e não consegue o certificado, o caminho na nuvem da seção anterior evita o
problema inteiro.

## O Expo CLI espera, e depois reclama da rede

Alguns comandos do Expo perguntam aos servidores do Expo quais versões de pacote combinam com o seu
SDK. Sem conexão, ou atrás de uma rede que os bloqueia, eles esperam e depois desistem. Definir
`EXPO_OFFLINE=1` no terminal diz ao CLI para usar a tabela de versões que vem dentro do pacote `expo`,
que é o que ele teria ouvido de qualquer forma. O `npx expo install` da aula 3 é onde você tem mais
chance de precisar disso.

## Linux: `ENOSPC: System limit for number of file watchers reached`

O servidor de desenvolvimento observa cada arquivo do projeto para ver se mudou, e um projeto com
`node_modules` tem dezenas de milhares. O Linux limita quantos arquivos um usuário pode observar. A
mensagem engana: `ENOSPC` normalmente quer dizer *sem espaço no dispositivo*, e aqui quer dizer *sem
observadores sobrando*. Aumente o limite, como root, de um jeito que sobreviva a uma reinicialização:

```sh
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-watches.conf
sudo sysctl --system
```

## Windows: tudo funciona e é muito lento

Um projeto em `/mnt/c` está no disco do Windows, e o WSL chega a ele por uma camada de tradução que é
lenta para muitos arquivos pequenos. Um `npm install` que leva minutos em vez de segundos é o sintoma.
Mova o projeto para a pasta pessoal do próprio WSL, `~`, e abra-o dali com o suporte a WSL do seu
editor.

## Quando não é nenhum desses

Leia o **primeiro** erro da saída, não o último: o npm e o Expo CLI imprimem várias linhas de
consequências depois da causa. Pesquise essa primeira linha entre aspas, com o nome da ferramenta. E
confira o disco: `df -h ~` mostra o espaço livre, e um disco cheio faz quase toda ferramenta desta
lista falhar com uma mensagem sobre outra coisa.
