---
title: Fixar versões, e quanto custa
version: 1
---

`flask==3.1.3` é uma **versão fixada**: exatamente essa versão, e nenhuma outra. `flask>=3.1` é um
**intervalo**: essa versão ou qualquer mais nova. A escolha entre os dois é uma troca, e vale ver os
dois lados antes de escolher.

| | versões exatas (`==`) | intervalos (`>=`, `~=`) |
|---|---|---|
| o que é instalado | a mesma coisa toda vez, em toda máquina | o que for mais novo no dia |
| um alerta novo | fica até alguém subir a versão | é corrigido sozinho, quando a correção cai no intervalo |
| um lançamento quebrado | nunca chega de surpresa | chega na próxima instalação, sem aviso |
| o que exige | uma rotina de atualização | confiar que todo lançamento do intervalo é bom |

**Numa aplicação, fixe**, e atualize de propósito. Um deploy que instala código diferente na terça
do que na segunda, sem mudança nenhuma no repositório, não dá para reproduzir, revisar nem reverter.
O argumento de segurança e o de confiabilidade apontam para o mesmo lado: você quer saber exatamente
o que está rodando. Uma **biblioteca** publicada para outros usarem é o caso oposto: ela declara
intervalos, para que as aplicações que a usam consigam resolver uma versão só para todos.

### Fixe tudo, não só o que você nomeou

O arquivo da seção anterior fixa três pacotes e deixa o pip escolher as versões das dependências
deles: MarkupSafe, Werkzeug, urllib3 e o resto. Essas são instaladas por intervalo, então o projeto
"fixado" muda por baixo do mesmo jeito. O `pip freeze` imprime todo pacote de um ambiente na versão
exata, e um arquivo feito com ele fixa também as dependências transitivas; ferramentas como
`pip-tools` e `uv` escrevem o mesmo tipo de **arquivo de trava** completo a partir de uma lista curta
do que você pediu. Nenhuma das duas foi executada para este curso.

### Fixe os bytes também

Um número de versão nomeia um lançamento. Não prova que o arquivo baixado é o arquivo que foi
publicado. O pip consegue verificar isso com um **hash** escrito ao lado de cada versão. O `pip hash`
calcula um a partir de um arquivo baixado:

```
(.venv) ana@vm:~/sc/deps$ pip download --no-deps --progress-bar off -d ~/wheels jinja2==3.1.6
Collecting jinja2==3.1.6
  Using cached jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Using cached jinja2-3.1.6-py3-none-any.whl (134 kB)
Saved /home/ana/wheels/jinja2-3.1.6-py3-none-any.whl
Successfully downloaded jinja2
(.venv) ana@vm:~/sc/deps$ pip hash ~/wheels/jinja2-3.1.6-py3-none-any.whl
/home/ana/wheels/jinja2-3.1.6-py3-none-any.whl:
--hash=sha256:85ece4451f492d0c13c5dd7c13a64681a86afae63a5f347908daf103ce6d2f67
```

Um requisito escrito como `jinja2==3.1.6 --hash=sha256:85ec…` faz o pip recusar qualquer arquivo cujo
resumo seja diferente, e com `--require-hashes` ele recusa qualquer requisito sem hash. Isso protege
contra um download adulterado ou trocado, não contra uma falha no próprio lançamento publicado:
**uma auditoria verifica o que foi publicado, e um hash verifica que você recebeu isso.**
