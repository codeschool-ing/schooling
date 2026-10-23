---
title: O que você pede, e o lock compilado a partir disso
version: 1
---

O `requirements.txt` da aula 5 mistura duas coisas diferentes numa lista plana: **o que o linkbox
pede** (Flask e gunicorn) e **o que esses dois precisam hoje** (outros seis). Ninguém consegue dizer
pelo arquivo qual é qual, então ninguém consegue dizer se o `markupsafe` pode ser removido, nem por
que o `packaging` está na imagem. A correção são dois arquivos com dois papéis.

- **`requirements.in`** diz o que o serviço pede, como faixas que uma pessoa escolheu e sabe
  defender.
- **`requirements.txt`** é compilado a partir dele por uma ferramenta: todo pacote para o qual as
  faixas resolvem, numa versão exata, com o hash de cada arquivo que essa versão publica, e um
  comentário dizendo quem puxou cada um. Ninguém o edita à mão.

Salve o primeiro como `requirements.in`:

@@FENCE 1@@

E o que os testes pedem, compilado do mesmo jeito, como `requirements-dev.in`:

@@FENCE 2@@

Os limites inferiores são as versões para as quais a aula 5 subiu, além dos avisos, então nenhuma
compilação volta para baixo deles. Os limites superiores param no próximo major, onde uma atualização
vira decisão de uma pessoa.

### O compilador mantém o que encontra

O `uv pip compile` resolve as faixas e escreve o lock. Ele tem um comportamento que vale conhecer
antes de ser surpreendido: **quando o arquivo de saída já existe, ele mantém as versões já fixadas
ali** se elas ainda cabem nas faixas. Rodado contra o arquivo da aula 5, ainda no lugar:

@@FENCE 3@@

O gunicorn mudou, porque `>=26.2` o obrigou. `click` e `markupsafe` ficaram nas versões da aula 5,
porque ainda cabiam. Isso é um recurso: um lock muda o mínimo possível, então a revisão da mudança lê
só o que mudou. Aqui não é o que se quer, porque esta é a primeira compilação e o arquivo antigo nunca
foi um lock. Então os dois arquivos antigos saem, e a compilação começa limpa, com os hashes:

@@FENCE 4@@

O `--generate-hashes` escreve, sob cada pin, o SHA-256 de cada arquivo que o PyPI publica para aquela
versão: uma wheel por plataforma e versão do Python, e o arquivo de código-fonte. Só o `markupsafe`
publica dezenas, que são a maior parte dos 169 hashes do `requirements.txt`. **Um hash fixa os bytes,
não só a versão**: se alguém trocasse um arquivo no índice, ou um espelho servisse outro, a instalação
o recusaria, como a aula 12 mostrou com um hash que não batia. O `--exclude-newer` é a data de que a
próxima seção trata.

### Instale só o que o lock nomeia

O lock só é lock se toda instalação o respeitar. Salve o estágio de testes como `ci/test.sh`:

@@FENCE 5@@

O `--require-hashes` faz o instalador recusar qualquer pacote que não tenha hash no arquivo, o que
também quer dizer que uma dependência que ninguém fixou não entra escondida: o ambiente dos testes é
o lock, ou nada.

@@FENCE 6@@

### Para onde foi o `packaging`

O `requirements.txt` compilado não tem `packaging`, e o motivo é a atualização, não a compilação. As
mesmas faixas com o gunicorn abaixo de 23 o compilam de volta, com o comentário que diz quem o quis:

@@FENCE 7@@

**O lock agora diz por que cada pacote está ali.** `# via gunicorn` é a resposta à pergunta que a
aula 13 só conseguiu levantar. O lock de desenvolvimento ainda traz o `packaging`, porque o pytest
precisa dele, e esse nunca chega à imagem.

@@FIGURE lock@@
