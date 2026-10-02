---
title: Salt, states em YAML com Jinja em volta
version: 1
---

O Salt chama as descrições dele de **states**, guardados em arquivos `.sls` e escritos em YAML. Antes de
o YAML ser lido, cada arquivo passa pelo **Jinja**, a mesma linguagem de template que a aula 18 usa nos
templates dela, então um arquivo de state pode ter variáveis, laços e condições. O resto do vocabulário
é curto: o servidor é o **master**, o agente é o **minion**, os fatos que um minion levanta sobre a
máquina são os **grains**, e os dados que um master entrega a minions específicos, segredos entre eles,
são o **pillar**.

Não há master no laboratório. O Salt roda aqui sem master, com `salt-call --local`, como a Ana, a partir
de um diretório dela, e a configuração do minion diz onde está cada coisa:

```yaml
id: laptop
user: ana
file_client: local
root_dir: /home/ana/shop/salt/run
file_roots:
  base:
    - /home/ana/shop/salt/states
```

`file_client: local` é a chave do modo sem master: ler os states do disco desta máquina em vez de
perguntar a um master. `file_roots` é esse lugar. `root_dir` move o cache, os logs e as chaves que o
Salt guardaria em `/var` e `/etc` para o diretório da Ana, e `user: ana` faz o Salt parar de esperar
ser root. `id` é o nome do minion. Deixado por conta própria, um minion também sabe onde procuraria um
master:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc config.get master
local:
    salt
```

Um host chamado `salt`, assim como o agente do Puppet procura `puppet`.

## Um top file e um state

O **top file** diz quais states valem para quais minions. `'*'` é todo minion, e `web` nomeia o
`web.sls` no mesmo diretório:

```yaml
base:
  '*':
    - web
```

```
{% set root = '/home/ana/www' %}
{{ root }}:
  file.directory:
    - mode: '0755'

{{ root }}/index.html:
  file.managed:
    - contents: "<h1>shop</h1> on {{ grains['os'] }}"
    - mode: '0644'
    - require:
      - file: {{ root }}

reload-web:
  cmd.run:
    - name: echo reloaded >> {{ root }}/reloads.log
    - onchanges:
      - file: {{ root }}/index.html
```

Cada bloco começa com um **ID** e chama uma função de state: `file.directory`, `file.managed`,
`cmd.run`. A primeira linha é Jinja e define `root`, e `{{ grains['os'] }}` escreve na página um fato
sobre a máquina. Os dois **requisites** dizem o mesmo que os relacionamentos do Puppet diziam:
`require` põe o diretório antes do arquivo, e `onchanges` roda o comando só quando a página mudou. O
grain que ele vai usar:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc grains.item os osrelease
local:
    ----------
    os:
        Ubuntu
    osrelease:
        24.04
```

## Testar, aplicar, aplicar de novo

`test=True` é o ensaio do Salt, o equivalente do `--noop` do Puppet. `--state-output=terse` imprime uma
linha por state:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply test=True --state-output=terse
local:
  Name: /home/ana/www - Function: file.directory - Result: Differs - Started: 12:19:39.805248 - Duration: 3.905 ms
  Name: /home/ana/www/index.html - Function: file.managed - Result: Differs - Started: 12:19:39.809432 - Duration: 1.25 ms
  Name: echo reloaded >> /home/ana/www/reloads.log - Function: cmd.run - Result: Differs - Started: 12:19:39.812490 - Duration: 0.356 ms

Summary for local
------------
Succeeded: 3 (unchanged=3, changed=3)
Failed:    0
------------
Total states run:     3
Total run time:   5.511 ms
```

`Differs` nos três: nada existe ainda. Depois a execução de verdade, com as mudanças mostradas por
inteiro:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-output=changes
local:
----------
          ID: /home/ana/www
    Function: file.directory
      Result: True
     Comment: 
     Started: 12:19:41.765537
    Duration: 4.153 ms
     Changes:   
              ----------
              /home/ana/www:
                  ----------
                  directory:
                      new
----------
          ID: /home/ana/www/index.html
    Function: file.managed
      Result: True
     Comment: File /home/ana/www/index.html updated
     Started: 12:19:41.769983
    Duration: 40.501 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0644
----------
          ID: reload-web
    Function: cmd.run
        Name: echo reloaded >> /home/ana/www/reloads.log
      Result: True
     Comment: Command "echo reloaded >> /home/ana/www/reloads.log" run
     Started: 12:19:41.811959
    Duration: 4.102 ms
     Changes:   
              ----------
              pid:
                  16721
              retcode:
                  0
              stderr:
              stdout:

Summary for local
------------
Succeeded: 3 (changed=3)
Failed:    0
------------
Total states run:     3
Total run time:  48.756 ms
```

O diretório é novo, o arquivo é novo com modo `0644`, e o comando rodou porque o arquivo mudou; para o
`cmd.run` o Salt informa o id do processo e o código de saída, `retcode: 0`. **O resumo é a linha para
ler primeiro**: três states, três mudados, nenhum com falha. A segunda execução:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-output=terse
local:
  Name: /home/ana/www - Function: file.directory - Result: Clean - Started: 12:19:45.107657 - Duration: 3.479 ms
  Name: /home/ana/www/index.html - Function: file.managed - Result: Clean - Started: 12:19:45.111405 - Duration: 2.912 ms
  Name: echo reloaded >> /home/ana/www/reloads.log - Function: cmd.run - Result: Clean - Started: 12:19:45.115564 - Duration: 0.011 ms

Summary for local
------------
Succeeded: 3
Failed:    0
------------
Total states run:     3
Total run time:   6.402 ms
```

`Clean` nos três. O comando também está limpo, porque o `onchanges` não achou nada que tivesse mudado.

Depois, a mesma edição à mão de antes, e uma execução que imprime só os states que fizeram alguma coisa:

```
ana@laptop:~/shop/salt$ echo "<h1>closed</h1>" > ~/www/index.html
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-verbose=False
local:
----------
          ID: /home/ana/www/index.html
    Function: file.managed
      Result: True
     Comment: File /home/ana/www/index.html updated
     Started: 12:19:47.147139
    Duration: 286.153 ms
     Changes:   
              ----------
              diff:
                  --- 
                  +++ 
                  @@ -1 +1 @@
                  -<h1>closed</h1>
                  +<h1>shop</h1> on Ubuntu
----------
          ID: reload-web
    Function: cmd.run
        Name: echo reloaded >> /home/ana/www/reloads.log
      Result: True
     Comment: Command "echo reloaded >> /home/ana/www/reloads.log" run
     Started: 12:19:47.434693
    Duration: 4.56 ms
     Changes:   
              ----------
              pid:
                  16891
              retcode:
                  0
              stderr:
              stdout:

Summary for local
------------
Succeeded: 3 (changed=2)
Failed:    0
------------
Total states run:     3
Total run time: 293.895 ms
```

O diff conta a história inteira: a edição à mão é a linha `-`, a descrição é a linha `+`, e a linha `+`
já traz `Ubuntu`, preenchido a partir do grain. Dois states mudaram, e o terceiro, o diretório, já
estava certo.

## A ordem, e o renderer na frente do YAML

O Salt executa os states na ordem em que estão escritos no arquivo, a menos que um requisite diga
outra coisa. Ele os numera para isso, e o `state.show_sls` mostra o que recebeu depois que o Jinja
rodou:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.show_sls web --out=yaml | grep -E "^  [^ ]|order"
  /home/ana/www:
    - order: 10000
  /home/ana/www/index.html:
    - order: 10001
  reload-web:
    - order: 10002
```

Dez mil, dez mil e um, dez mil e dois: a ordem do arquivo. Mas o `state.show_sls` vale mais do que isso.
**O Jinja roda primeiro e produz texto, e só então o texto é lido como YAML**, então um erro num template
pode produzir um state perfeitamente válido que diz outra coisa. Ler o resultado renderizado é como
você vê o que o Salt vai de fato fazer.

Com um master, o mesmo `web.sls` é aplicado do master a todos os minions de uma vez, com `salt '*'
state.apply`, e os minions o executam no instante em que o comando chega. Essa é a metade push do Salt,
pelas conexões que os minions abriram. O mesmo canal roda qualquer comando avulso em todos os minions,
`salt '*' cmd.run 'uptime'`, o que faz de um master do Salt um controle remoto, além de uma descrição.
