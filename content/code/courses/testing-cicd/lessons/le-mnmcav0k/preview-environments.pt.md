---
title: Um ambiente por pull request
version: 1
---

A homologação compartilhada tem um problema de agenda: duas equipes querem testar duas mudanças ao
mesmo tempo, e uma espera ou as duas testam uma mistura. Um **ambiente de prévia**, também chamado de
*efêmero* ou *de revisão*, resolve isso criando um ambiente novo para cada pull request, implantando o
build daquele pull request nele e destruindo-o quando o pull request fecha.

No laboratório um ambiente é um diretório e uma porta, então uma prévia para o pull request 42 é barata
de mostrar:

```
ana@laptop:~/shipquote$ cat ~/envs/pr-42/config.env
SHIPQUOTE_PORT=8442
ana@laptop:~/shipquote$ time ops/deploy.sh pr-42 dist/shipquote-1.5.0.tar.gz
smoke: http://127.0.0.1:8442 is up and running 1.5.0

real	0m0.168s
user	0m0.035s
sys	0m0.032s
ana@laptop:~/shipquote$ kill $(cat ~/envs/pr-42/pid) && rm -rf ~/envs/pr-42 && ls ~/envs
dev
production
staging
```

Uma linha de configuração, um deploy, e o smoke test passou: **0,168 segundo** para criar um ambiente
e provar que ele responde. Depois ele é parado e apagado, e `~/envs` volta a ter os três permanentes.
Numa plataforma de verdade os passos são os mesmos, e mais lentos: criar a infraestrutura, muitas vezes
a partir da mesma definição da homologação; implantar; postar o endereço no pull request para quem
revisa poder clicar; destruir tudo no merge.

## O que elas compram, e o que custam

Ambientes de prévia deixam quem revisa **ver** uma mudança em vez de imaginá-la, e deixam várias
mudanças serem testadas ao mesmo tempo sem uma pisar na outra. Também impõem uma disciplina útil: se
um ambiente precisa ser criado do nada para cada pull request, a definição dele precisa estar completa e
automatizada, o que fecha de quebra a maior parte do desvio da seção 07.

O custo está nas partes que não encolhem. Uma prévia precisa de dados, que deveriam ser semeados e
nunca copiados da produção; precisa de integrações, em geral sandboxes divididas por todas as prévias;
e precisa de orçamento, porque quarenta pull requests abertos podem virar quarenta ambientes. Equipes
definem um prazo de vida, destroem as prévias de pull requests parados, e criam prévias das partes que
importam para quem revisa em vez do sistema inteiro.

## A regra que a prévia do laboratório segue

A prévia rodou **o mesmo artefato** da homologação e da produção, `shipquote-1.5.0.tar.gz`, com
configuração própria. Uma prévia que monta a própria versão especial, com depuração ligada ou uma
transportadora falsa embutida, mostraria a quem revisa algo que nunca vai ser implantado. O build do
pull request é o que vai para a prévia, montado do mesmo jeito que um release.
