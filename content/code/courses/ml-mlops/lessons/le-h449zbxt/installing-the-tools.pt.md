---
title: Instalando o DVC e o MLflow
version: 1
---

Os dois são pacotes Python e vão para o ambiente do curso. Com ele ativo:

```sh
pip install mlflow==3.17.0 dvc==3.67.1
```

Esta é a maior instalação do curso: o MLflow traz um servidor web, uma camada de banco de dados e o
código para carregar modelos de muitas bibliotecas. O tamanho do ambiente inteiro dado na lição 1,
cerca de um gigabyte até a última lição, é quase todo esta linha.

O DVC registra versões no Git, e o Git precisa saber quem está fazendo o commit. Uma vez por
computador:

```sh
git config --global user.name "Ana"
git config --global user.email ana@example.com
git config --global init.defaultBranch main
```

Use o seu nome e o seu endereço. `example.com` é um domínio reservado para exemplos, e por isso o
curso o usa. A verificação:

```
ana@dev:~/ml$ git --version; dvc --version; mlflow --version
git version 2.43.0
3.67.1
mlflow, version 3.17.0
```
