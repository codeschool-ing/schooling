---
title: Quando a preparação falha
version: 1
---

É na preparação que a maioria das pessoas desiste de um curso como este, quase sempre por causa de
uma única linha de saída que pareceu uma catástrofe e era uma coisa pequena. Estas são as falhas que
você mais provavelmente vai encontrar nesta aula, cada uma com o que imprime e o que resolve. Todas
foram produzidas de propósito, na máquina de onde vêm as transcrições.

## `uv: command not found`

O terminal que rodou o `pipx ensurepath` ainda estava aberto:

```
ana@vm:~$ uv --version
bash: line 1: uv: command not found
```

O `pipx ensurepath` gravou o novo `PATH` nos arquivos de inicialização do shell, e um terminal lê
esses arquivos uma vez, quando abre. **Abra um terminal novo**, ou rode `source ~/.bashrc` neste. Se
um terminal novo ainda não acha o uv, `ls ~/.local/bin` diz se o `pipx install uv` terminou.

## `Couldn't import Django`

Um diretório de projeto, e o script de gerenciamento do Django rodado com o Python do sistema:

```
ana@vm:~/hello-django$ python3 manage.py check
Traceback (most recent call last):
  File "/home/ana/hello-django/manage.py", line 11, in main
    from django.core.management import execute_from_command_line
ModuleNotFoundError: No module named 'django'

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/home/ana/hello-django/manage.py", line 22, in <module>
    main()
  File "/home/ana/hello-django/manage.py", line 13, in main
    raise ImportError(
ImportError: Couldn't import Django. Are you sure it's installed and available on your PYTHONPATH environment variable? Did you forget to activate a virtual environment?
ana@vm:~/hello-django$ uv run python manage.py check
System check identified no issues (0 silenced).
```

**O Django está instalado no `.venv` do projeto, não no Python do sistema**, e `python3` sozinho é o
do sistema. A mensagem do Django acerta o palpite: nenhum ambiente virtual estava ativo. A correção é
o segundo comando. O `uv run` roda um comando dentro do ambiente do projeto, conferindo antes contra
o arquivo de trava, então nada precisa ser ativado; todo comando deste curso que roda Python dentro de
um projeto começa com ele. Ativar o ambiente com `source .venv/bin/activate`, como faz a aula 18 de
`python`, também funciona, uma vez por terminal.

## `That port is already in use`

Um servidor iniciado uma segunda vez enquanto o primeiro ainda rodava:

```
ana@vm:~/hello-django$ uv run python manage.py runserver 8000
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).

You have 18 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
Run 'python manage.py migrate' to apply them.
Error: That port is already in use.
```

Só um programa pode escutar numa porta. O primeiro servidor continua rodando em algum lugar, muitas
vezes num terminal de que você esqueceu. Vá até ele e aperte **Ctrl-C**, ou ache-o com
`ss -ltnp | grep 8000`, que dá o nome do processo dono da porta. A outra saída é uma porta
diferente, `runserver 8010`, que funciona e deixa o servidor esquecido rodando. O aviso sobre
migrações é real e inofensivo aqui: a próxima seção explica.

## Qualquer outra coisa

**Leia o que ele imprimiu antes de pesquisar.** A última linha de um traceback é a causa; as linhas
de cima são o caminho que o programa fez até ali. Uma mensagem que diz um comando para rodar, como as
duas primeiras acima, quer dizer exatamente isso. E se a saída de uma aula difere da sua só numa
hora, num número de processo ou numa data, nada está errado: isso muda a cada execução.
