---
title: Três bancos numa máquina sua
version: 1
---

Da próxima aula em diante, quase toda seção mostra um comando e o que o servidor respondeu, e o
sentido de mostrar a resposta é você rodar o mesmo comando e comparar. **A plataforma não roda banco
nenhum para você.** Você monta o laboratório uma vez, no seu computador, e todo exercício do curso é
feito ali.

O laboratório é uma máquina Linux com **Docker Engine** e três contêineres: MongoDB 8.0, Redis 7.4 e
Cassandra 5.0, das imagens oficiais do Docker Hub. Contêineres são a ferramenta certa aqui por um
motivo próprio deste curso: três produtos, cada um com modo cluster, significam até seis cópias de um
mesmo servidor rodando ao mesmo tempo na aula 15. Como pacotes, seriam seis diretórios de
configuração e seis serviços para manter separados; como contêineres, é um comando para cada, e
`docker rm -f` devolve a máquina ao que era.

Toda transcrição do curso foi gravada numa máquina assim, que as aulas chamam de laboratório: Ubuntu
24.04, Docker Engine 29, um usuário chamado `ana` numa máquina chamada `vm`. O seu prompt vai trazer
os seus nomes. As respostas vão bater, tirando os ids que os servidores geram, os endereços dentro da
rede do Docker e os tempos, que mudam a cada execução de qualquer forma.

## Se você fez o curso `docker`, você já tem isso

A aula 5 do `docker` monta exatamente esta máquina, uma máquina virtual chamada `vm` com Docker
Engine dentro. Ligue-a, abra um shell nela e pule para a próxima seção: só faltam as três imagens.

## Três jeitos de ter a máquina

| | o que é | quanto custa |
| --- | --- | --- |
| **uma máquina virtual com Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu 24.04 com um comando, no Windows, no macOS ou no Linux, com o Docker Engine instalado dentro | 2 processadores, 4 GB de memória e 30 GB de disco enquanto roda; no seu sistema, só o próprio Multipass |
| instalado | Docker Desktop no Windows ou no macOS; Docker Engine direto num computador que já roda Linux | as mesmas imagens e a mesma memória, tiradas do computador que você usa para tudo |
| online | um GitHub Codespace, ou o Play with Docker, no navegador | nada no seu computador; uma cota mensal de horas grátis, ou uma sessão apagada depois de algumas horas, em termos que a empresa que oferece define e pode mudar |

**A máquina virtual é a recomendada porque tem o mesmo formato do laboratório.** Quando a sua saída
difere de uma transcrição, a diferença vale a leitura, e não é efeito colateral da instalação. E ela
não custa nada perder: as aulas 13, 15 e 18 derrubam servidores de propósito, e uma máquina que você
pode apagar e refazer é o lugar certo para isso.

**Instalado funciona em todas as aulas.** O Docker Desktop roda uma pequena VM Linux própria,
dimensionada nas configurações dele; dê a ela pelo menos 4 GB de memória, ou o cluster de três nós do
Cassandra das aulas 16 a 19 não sobe. No Linux, o Docker Engine no seu próprio computador é o
laboratório sem a liberdade de jogá-lo fora.

**Online aparece para você saber que existe, não como recomendação.** Uma sessão apagada leva os seus
dados junto, e as aulas 17 a 19 precisam de cerca de 1,5 GB de memória só para o Cassandra, que nem
toda máquina online gratuita tem. Nenhuma aula depende de uma cota grátis que outra pessoa pode
mudar.

## Quanto o laboratório pesa

Medido no laboratório, para você saber com o que está concordando antes de começar:

```
ana@vm:~$ docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|mongo|redis|cassandra"
REPOSITORY:TAG   SIZE
cassandra:5.0    541MB
redis:7.4        182MB
mongo:8.0        1.28GB
```

Cerca de 2 GB de disco para as três imagens, antes de qualquer dado. A memória pesa mais, e a próxima
seção a mede com os três rodando.

## Num Mac com Apple silicon

Ali o Multipass cria uma máquina `arm64`, e as três imagens oficiais são publicadas para `arm64`,
então todo comando funciona sem mudança. As únicas diferenças que você vai ver estão em linhas que
mencionam a arquitetura.
