---
title: Guardando em cache o que não muda
version: 2
---

Toda execução de CI começa limpa, e começar limpo é caro: cada dependência baixada de novo, cada
pacote desempacotado, cada cache de compilador frio. **Um cache** guarda uma cópia de algo lento de
produzir entre execuções, sob uma chave que diz quando a cópia ainda vale. Eis a diferença, medida
criando o mesmo ambiente virtual duas vezes com o `uv`, a partir de um cache vazio.
`export UV_CACHE_DIR=/tmp/uv-cold` aponta o uv para um diretório novo e vazio, só neste terminal, e
`unset UV_CACHE_DIR` o devolve depois:

```
ana@laptop:~/shipquote$ time (uv venv -q -p 3.13 /tmp/v1 && VIRTUAL_ENV=/tmp/v1 uv pip install -q -r requirements-dev.txt)

real	0m1.099s
user	0m0.466s
sys	0m0.726s
ana@laptop:~/shipquote$ time (uv venv -q -p 3.13 /tmp/v2 && VIRTUAL_ENV=/tmp/v2 uv pip install -q -r requirements-dev.txt)

real	0m0.167s
user	0m0.079s
sys	0m0.106s
ana@laptop:~/shipquote$ du -sh /tmp/uv-cold
17M	/tmp/uv-cold
```

A primeira instalação baixou e desempacotou os três pacotes fixados e as dependências deles, e levou
**1,099 segundo**; a segunda, lendo os mesmos arquivos do cache, levou **0,167**. O cache ocupa 17 MB.
Neste laboratório a economia é pequena, porque o `uv` é rápido e o projeto quase não tem
dependências; num projeto com centenas de pacotes, ou que os compila, a mesma comparação vira minutos
contra segundos, em cada execução.

## A chave é toda a dificuldade

Um cache só vale enquanto o que o produziu não mudou. Os serviços pedem que você escolha uma
**chave** para cada entrada e só a restauram quando a chave bate. Para dependências a chave natural é
um hash do arquivo que as fixa, aqui `requirements-dev.txt`, mais o sistema operacional e a versão da
linguagem:

```yaml
key: ${{ runner.os }}-py3.13-${{ hashFiles('requirements-dev.txt') }}
```

Mude uma versão fixada e a chave muda, então a próxima execução começa de um cache vazio e monta um
novo. **Uma chave frouxa demais restaura arquivos velhos**: um cache com chave só no sistema
operacional serviria os pacotes do mês passado depois de uma versão mudar, e a execução testaria uma
combinação que não existe mais no repositório.

## O que não guardar em cache

Guarde o que é **derivado de entradas fixadas e caro de reconstruir**: pacotes baixados,
dependências compiladas, o binário de uma ferramenta. Não guarde:

- **os resultados da coisa que você está testando**, como um build compilado do seu próprio código
  ou um banco de teste deixado pela última execução. A execução deixaria de começar do que foi
  commitado;
- **nada compartilhado entre branches sem o branch na chave**, se um branch pode mudá-lo. O workflow
  deste repositório desliga o cache do linter por esse motivo, com um comentário explicando que um
  cache compartilhado por todos os branches não faz parte do que um pull request mudou.

Um cache é uma otimização, e uma otimização não pode mudar a resposta. **Se limpar o cache muda se
uma execução passa, o cache estava escondendo alguma coisa**, e a execução que passa sem ele é a
que merece crédito.
