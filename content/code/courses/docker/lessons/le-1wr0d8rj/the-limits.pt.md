---
title: Onde o truque para de funcionar
version: 1
---

**Uma ferramenta em container só enxerga o que recebe: os arquivos que você monta, as variáveis de
ambiente que você passa, a rede a que o Docker a conecta.** É essa a força dela, e cada limite do
truque vem daí. Cada um é fácil de contornar depois que você sabe reconhecê-lo.

## Arquivos fora da montagem não existem

O invólucro monta o diretório atual e mais nada. Um caminho que sai dele falha, com uma mensagem que
diz que o arquivo não existe, e não que ele está fora da montagem:

```
ana@vm:~/ops$ echo "x: 1" > ../other.yaml
ana@vm:~/ops$ yq ".x" ../other.yaml
Error: open ../other.yaml: no such file or directory
```

O arquivo está ali, um diretório acima, no host. Dentro do container, `../other.yaml` é
`/other.yaml`, que não existe. **Quando uma ferramenta em container diz que um arquivo que você está
vendo não existe, confira se o caminho sai do diretório montado.** A correção é rodar a ferramenta a
partir de um diretório que contenha tudo de que ela precisa, ou montar o outro diretório também.

## Cada execução inicia um container

```
ana@vm:~/ops$ time yq --version
yq (https://github.com/mikefarah/yq/) version v4.54.1

real	0m0.318s
user	0m0.015s
sys	0m0.025s
```

**Cerca de um terço de segundo para um `yq --version`**, quase tudo do Docker montando e desmontando
o container. Ninguém repara nisso uma vez. Um laço de shell que chama o invólucro para cada um de mil
arquivos gasta minutos só com inicializações, e aí o certo é dar todos os arquivos à ferramenta numa
execução só, ou instalá-la.

## As credenciais precisam ser entregues

A ferramenta de linha de comando da AWS também é publicada como imagem:

```
ana@vm:~/ops$ docker run --rm amazon/aws-cli:latest --version
aws-cli/2.37.9 Python/3.14.6 Linux/6.18.44-fc-v70 docker/x86_64.amzn.2023
```

A versão voltou, e nada mais vai funcionar ainda: a ferramenta procura credenciais em `~/.aws` e em
variáveis de ambiente, e o container não tem nenhuma das duas. Montar a configuração do host somente
leitura, `-v "$HOME/.aws":/root/.aws:ro`, ou passar as variáveis com `-e`, faz funcionar, **e também
entrega essas credenciais a seja lá o que houver nessa imagem**. Para uma ferramenta vinda da imagem
oficial do próprio fabricante, é a mesma confiança de instalá-la; para uma imagem de origem
desconhecida, é dar a sua conta na nuvem a um estranho. A aula 20 mostra como conferir a origem de
uma imagem. O laboratório desta aula não tem conta AWS, então esse passo não foi executado aqui.

## Outras coisas que um container não alcança

- **Um programa gráfico** precisa de uma tela, que um container não tem sem trabalho extra.
  Ferramentas de terminal são as que combinam com este truque.
- **Os serviços de rede do host** em `localhost` são do host, não do container: dentro de um
  container, `localhost` é o próprio container. A aula 23 explica, e mostra como alcançar o host
  quando for preciso.
- **No Docker Desktop, os arquivos montados atravessam para uma VM**, como a aula 5 desenhou, e uma
  ferramenta que lê milhares de arquivos pequenos fica visivelmente mais lenta do que no Linux.
