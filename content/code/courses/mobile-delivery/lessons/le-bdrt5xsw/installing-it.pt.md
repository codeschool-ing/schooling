---
title: Instalando no seu computador
version: 1
---

**O Fastlane é uma gem de Ruby, e uma gem é instalada por projeto com a versão fixada, nunca uma
vez para o computador inteiro.** O projeto a lista num `Gemfile`; o **Bundler** instala exatamente
essa versão numa pasta do projeto, e todo comando roda por `bundle exec`, então dois projetos podem
usar duas versões sem que nenhum perceba.

## Ruby e Bundler

No Ubuntu e no WSL, o Ruby e o Bundler vêm dos pacotes do sistema, e o `build-essential` é para as
poucas gems que compilam algo ao instalar:

```sh
sudo apt install ruby-full ruby-bundler build-essential
```

Num Mac, o Ruby da própria Apple é antigo e não deveria ser usado para isso; a documentação do
Fastlane recomenda um Ruby do Homebrew, ou instalar o próprio Fastlane com `brew install fastlane`.
*O caminho do Mac não foi rodado para este curso.*

## O Gemfile do planner

Salve isto como `Gemfile` em `~/planner`:

```
# Gemfile: the Ruby tools of the planner's release, at exact versions
source "https://rubygems.org"
gem "fastlane", "2.228.0"
```

Diga ao Bundler para guardar as gems dentro do projeto, em `vendor/bundle`, para nada ser gravado
fora dele, e instale. Leva um ou dois minutos, porque o Fastlane traz umas cem outras gems junto:

```sh
bundle config set --local path vendor/bundle
bundle install
```

Acrescente `vendor/bundle` ao `.gitignore`; o `Gemfile.lock` que o Bundler grava é commitado, porque
é o lockfile da lição 10 para o lado Ruby.

## Cinco configurações para uma saída quieta e honesta

O Fastlane procura atualizações dele mesmo a cada execução, imprime horários, colore a saída, marca
cada linha que um comando imprime com uma seta, e manda **dados de uso anônimos** aos mantenedores a
não ser que digam para não mandar. Num pipeline e neste curso, as cinco coisas ficam desligadas.
Acrescente estas linhas ao `~/.profile`, ou ao ambiente do job de CI:

```sh
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_TIMESTAMP=1
export FASTLANE_DISABLE_COLORS=1
export FASTLANE_DISABLE_OUTPUT_FORMAT=1
export FASTLANE_OPT_OUT_USAGE=1
```

A última pertence, no espírito, ao inventário da lição 5: é uma ferramenta no seu computador
mandando dados sobre o seu projeto para outra pessoa, e parar isso é escolha sua. Depois confira que
ele responde:

```
ana@dev:~/planner$ bundle exec fastlane --version
fastlane installation at path:
/home/ana/planner/vendor/bundle/ruby/3.2.0/gems/fastlane-2.228.0/bin/fastlane
-----------------------------
fastlane 2.228.0
```
