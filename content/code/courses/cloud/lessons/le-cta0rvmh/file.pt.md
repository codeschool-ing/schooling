---
title: "Armazenamento de arquivos: um sistema de arquivos, várias máquinas"
version: 1
---

Um serviço gerenciado de arquivos é **um sistema de arquivos em rede que outra pessoa opera**: EFS
na AWS, Azure Files, Filestore no Google Cloud. As máquinas o montam com o cliente que o sistema
operacional já tem, NFS no Linux e SMB no Windows. O Azure Files fala os dois, o EFS fala NFS.
Montado, ele é um diretório como outro qualquer, e nada no programa que o usa precisa saber que está
na rede. Na AWS a montagem é uma linha, escrita aqui para a aula e não executada, porque não há
conta:

```sh
sudo mount -t nfs4 -o nfsvers=4.1 fs-0123456789abcdef0.efs.sa-east-1.amazonaws.com:/ /shared
```

O que ele oferece e um volume não oferece é **várias máquinas lendo e gravando os mesmos arquivos ao mesmo
tempo**, com o serviço mantendo o sistema de arquivos consistente. Dois servidores web atrás de um
balanceador de carga veem a imagem que um usuário enviou por qualquer um deles. O EFS guarda os
dados em várias zonas da região, então instâncias em zonas diferentes montam o mesmo sistema de
arquivos. Ele cresce e encolhe com o que está guardado, então não há tamanho para escolher, e **é
cobrado pelos gigabytes de fato guardados**, o contrário de um volume.

## Quando é a ferramenta certa

Um programa escrito para um diretório compartilhado. Muito software foi escrito assim: um gerenciador de conteúdo
que grava uploads em `wp-content/uploads`, duas aplicações legadas que trocam arquivos por um
diretório onde uma escreve e a outra consulta, uma farm de build compartilhando cache, os diretórios
pessoais de um grupo de usuários Linux. Reescrever qualquer um deles para falar com um repositório
de objetos é trabalho de verdade, e um serviço de arquivos permite levá-los para a nuvem sem
alteração.

::: track devops devsecops
O curso de `kubernetes` encontrou essa divisão com outros nomes. Um PersistentVolumeClaim que pede
`ReadWriteOnce` em geral é atendido por um volume de bloco, e um que pede `ReadWriteMany` precisa de
um serviço de arquivos por trás, porque só um sistema de arquivos que alguém opera para você pode
ser gravado por pods em vários nós ao mesmo tempo.
:::

::: track *
Plataformas de contêineres encontram a mesma divisão com outros nomes. Armazenamento que um nó grava
em geral é um volume de bloco, e armazenamento que pods em vários nós gravam ao mesmo tempo precisa
de um serviço de arquivos por trás, porque um volume de bloco fica anexado a uma máquina.
:::

## Quanto custa

O preço é a outra metade da resposta. **O EFS Standard custa 0,5700 USD por GB-mês em
`sa-east-1`, contra 0,1520 de um volume `gp3`**, e a próxima seção põe as duas linhas lado a lado.
Parte da diferença é a replicação entre zonas e parte é o serviço operando o sistema de arquivos
por você. O EFS tem faixas mais baratas para arquivos que quase ninguém abre, que a tabela do curso
não traz; o curso de fornecedor traz.

Ele também traz os hábitos de todo sistema de arquivos em rede. **Cada operação de arquivo é uma ida
e volta pela rede**, então trabalho que mexe em milhares de arquivos pequenos, como um `npm install`
ou um checkout do Git, roda muito mais devagar ali do que num volume. O travamento funciona e também
custa uma ida e volta. E um diretório compartilhado é estado compartilhado: duas máquinas gravando
o mesmo arquivo no mesmo instante ainda precisam que a aplicação decida qual gravação vence.
