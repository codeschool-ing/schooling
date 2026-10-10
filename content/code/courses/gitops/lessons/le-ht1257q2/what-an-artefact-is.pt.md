---
title: O que é um artefato, e o que ele promete
version: 1
---

**Um artefato é a saída de um build, guardada para nunca precisar ser construída de novo.** Uma
imagem de container, um chart do Helm, um `.jar`, um pacote npm, um tarball de um site estático: cada
um é produzido uma vez, a partir de um commit, e dali em diante é baixado, nunca reconstruído. A aula
5 construiu o `bulletin:1.1` uma vez e rodou os mesmos bytes no staging e na produção, e essa é a
ideia inteira.

Três propriedades fazem um artefato merecer o nome, e cada uma das próximas seções testa uma delas:

- **Ele é imutável.** Depois de publicado, os bytes por trás de uma referência não mudam. Se mudarem,
  um teste no staging não diz nada sobre o que a produção baixa uma hora depois.
- **Ele é endereçável.** Há um nome que quer dizer exatamente esses bytes. Uma tag é um nome que
  alguém escolheu e pode mover; um **digest**, o SHA-256 do conteúdo, é um nome que o conteúdo
  escolheu e ninguém consegue mover.
- **Ele tem proveniência.** Alguém sabe dizer qual código, qual commit e qual build o produziram. Os
  três 1.0 que batiam na aula 5 foram o começo disso, e a aula 8 transforma isso em algo que uma
  máquina confere, e não em algo com que as pessoas concordam.

**Onde os artefatos moram é um registry ou um gerenciador de repositórios.** Um registry OCI, como o
que este curso roda na porta 5001, guarda imagens e qualquer outra coisa empacotada do jeito OCI,
charts do Helm inclusive. Um gerenciador de repositórios, Artifactory ou Nexus, guarda esses e todo
outro formato que uma empresa use, e acrescenta o que uma empresa precisa em volta: caches de
repositórios públicos, regras de acesso, retenção. Um arranjo GitOps depende de um deles tanto quanto
do Git: **o Git diz qual artefato, o registry o guarda**, e se algum dos dois mentir, o cluster roda
algo que ninguém decidiu.
