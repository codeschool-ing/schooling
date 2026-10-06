---
title: Usando um hash para o trabalho que ele faz
version: 1
---

**Um hash responde bem a uma pergunta: estes são os mesmos bytes que aqueles?** Usado para isso,
ele é uma das ferramentas mais confiáveis do curso. Os erros vêm de lhe fazer outras perguntas,
como "quem enviou isto?" ou "esta senha está certa?", para as quais ele nunca foi feito.

## Conferindo um download

A versão do portal da Vereda vem com um arquivo `SHA256SUMS`, a convenção que a maioria das
distribuições Linux e dos projetos de código aberto segue: uma linha por arquivo, o resumo e o nome.

```
ana@lab:~/lab$ cd data/release && cat SHA256SUMS
d166d210e0c958cff1ac86e2119274eced40fe304a2cc7762953ad0058e54d7e  NOTES.txt
7a3cfae88053ea853e98e2211769a0cf9f605d6f761aff2878059628177a6a3f  portal-2.4.1.tar
ana@lab:~/lab$ cd data/release && sha256sum -c SHA256SUMS
NOTES.txt: OK
portal-2.4.1.tar: OK
```

O `sha256sum -c` recalcula cada resumo e compara. Agora um byte é acrescentado ao arquivo, o tamanho
de uma transferência que deu errado ou de um arquivo que alguém adulterou:

```
ana@lab:~/lab$ cd data/release && printf x >> portal-2.4.1.tar && sha256sum -c SHA256SUMS; echo "exit status $?"
NOTES.txt: OK
portal-2.4.1.tar: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit status 1
```

O código de saída é 1, que é o que um script ou uma esteira de deploy confere. Uma esteira que baixa
algo e o instala deveria recusar nessa linha, não registrar um aviso e seguir em frente.

## O que a verificação prova, e o que não prova

Um resumo que confere prova que o arquivo tem **os mesmos bytes do arquivo de onde o resumo foi
calculado**. Não prova nada sobre quem calculou o resumo. Se um atacante controla o servidor que
hospeda tanto o arquivo quanto o `SHA256SUMS`, ele troca os dois, e a verificação passa. Então:

- um resumo **no mesmo servidor** que o arquivo pega corrupção e mais nada;
- um resumo obtido **por outro canal**, como um anúncio da versão, o índice assinado de um
  gerenciador de pacotes ou um colega lendo em voz alta, pega adulteração no servidor de download;
- um resumo **assinado** com a chave de quem publica (`SHA256SUMS.asc` com OpenPGP, ou um pacote do
  Sigstore) prova quem responde pelo arquivo, que é a assinatura da aula 3 aplicada à impressão
  digital da aula 4.

## Dando nome às coisas pelo conteúdo

Um resumo é um nome que não consegue mentir sobre o conteúdo, e vários sistemas o usam assim:

- o **Git** dá nome a cada commit, árvore e arquivo pelo hash. O id de um commit identifica o
  conteúdo exato de todo o histórico por trás dele;
- **imagens de contêiner** são baixadas por tag, `portal:2.4.1`, que o registro pode mover, ou por
  resumo, `portal@sha256:…`, que ninguém consegue mover. Deploys fixam o resumo;
- **arquivos de lock de pacotes** (`package-lock.json`, `go.sum`, `poetry.lock`) guardam um resumo
  por dependência, então o build recusa uma dependência cujo conteúdo mudou sob o mesmo número de
  versão.

Em todos esses casos, o hash ser resistente a colisões é o que torna o nome confiável, e é por isso
que a saída do Git do SHA-1 importa.

## As perguntas para as quais um hash não serve

| pergunta | não um hash simples, porque | use em vez dele |
|---|---|---|
| esta senha está certa? | um hash rápido deixa um atacante testar bilhões de palpites por segundo | uma KDF lenta e com sal, aula 5 |
| quem conhece o nosso segredo enviou isto? | qualquer um consegue calcular um hash | HMAC, aula 6 |
| quem escreveu isto? | um hash não tem chave | uma assinatura, aula 3 |
| dá para esconder este valor calculando o hash dele? | um valor curto ou previsível é achado testando candidatos | cifragem, ou um hash com chave |

A última linha pega muita gente. Calcular o hash de um CPF, de um telefone ou de um e-mail não o
anonimiza: há só cerca de um bilhão de CPFs válidos, e calcular o hash de todos leva minutos num
notebook. Um identificador com hash continua sendo dado pessoal, e a LGPD o trata assim.
