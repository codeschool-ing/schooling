---
title: Lendo todos os roteadores de uma vez
version: 2
---

O backup reaproveita o inventário Nornir da aula 8, reduzido aos três roteadores, e pede a cada um
a sua configuração em execução pelo NAPALM. O projeto é um diretório novo, `~/net` no `ctl`, montado
a partir de duas aulas anteriores: o `config.yaml` da aula 8 e os dois arquivos de inventário que
não mudam, e os dados, o template e o `render.py` da aula 10, que a seção 07 usa. O Git também
precisa saber quem está fazendo os commits, uma vez por conta:

```
ana@ctl:~$ git config --global user.name ana && git config --global user.email ana@example.net && git config --global init.defaultBranch main
ana@ctl:~$ mkdir -p net/inventory net/templates && cp config.yaml net/ && cp inventory/groups.yaml inventory/defaults.yaml net/inventory/ && cp -r tpl/data tpl/render.py net/ && cp tpl/templates/frr.j2 net/templates/
```

O único arquivo de inventário que muda é a lista de hosts, que aqui são os três roteadores e mais
nada. `net/inventory/hosts.yaml`:

```yaml
---
core1:
  hostname: core1.example.net
  groups: [routers]
edge1:
  hostname: edge1.example.net
  groups: [routers]
edge2:
  hostname: edge2.example.net
  groups: [routers]
```

O mesmo script depois faz commit do que tiver mudado:

```schooling-example
{
  "language": "python",
  "file": "backup.py",
  "parts": [
    {
      "code": "import pathlib\nimport subprocess\nimport sys\n\nfrom nornir import InitNornir\nfrom nornir_napalm.plugins.tasks import napalm_get\n\nnr = InitNornir(config_file=\"config.yaml\")"
    },
    {
      "code": "result = nr.run(task=napalm_get, getters=[\"config\"], getters_options={\"config\": {\"retrieve\": \"running\"}})\n\nrepo = pathlib.Path(\"backups\")\nfor host, r in sorted(result.items()):\n    if r.failed:",
      "note": "**Todos os roteadores de uma vez, só leitura.** `napalm_get` com o getter `config` pede a cada roteador a configuração em execução; nada é alterado em lugar nenhum."
    },
    {
      "code": "        print(f\"{host}: FAILED, kept the previous copy: {str(r[0].exception).splitlines()[0]}\")\n        continue\n    (repo / f\"{host}.conf\").write_text(r[0].result[\"config\"][\"running\"])\n\n\ndef git(*args):\n    return subprocess.run([\"git\", \"-C\", str(repo), *args], capture_output=True, text=True, check=True).stdout\n\n\ngit(\"add\", \"--all\")\nchanged = git(\"diff\", \"--cached\", \"--name-only\").split()",
      "note": "**Um roteador que não respondeu é dito em voz alta.** O arquivo dele fica como estava, e esse é o perigo: o repositório continua parecendo completo, com uma cópia um dia mais velha a cada noite."
    },
    {
      "code": "if changed:\n    git(\"commit\", \"--quiet\", \"-m\", \"backup: \" + \", \".join(f.removesuffix(\".conf\") for f in changed))\n    print(\"committed:\", \", \".join(changed))\nelse:\n    print(\"no change since the last backup\")",
      "note": "**Um commit só quando algo mudou**, com o nome do que mudou. O histórico vira uma lista de mudanças, e uma noite sem nada não deixa rastro."
    },
    {
      "code": "sys.exit(1 if result.failed else 0)",
      "note": "**O código de saída carrega a falha**, então o que rodar isto toda noite, cron ou pipeline, consegue distinguir um backup parcial de um bom."
    }
  ]
}
```

`napalm_get` é a interface de getters da aula 8, rodada pelo Nornir em todos os hosts em
paralelo. O getter `config` devolve um dicionário com `running`, `startup` e `candidate`; o FRR
não mantém uma configuração de startup separada nesta montagem, então só `running` é pedido.
Outras plataformas acrescentariam `startup` ao backup, e a diferença entre as duas merece um
alerta próprio: uma mudança que nunca foi salva some no próximo reload.

O repositório é um repositório Git comum, sem remote, criado uma vez:

```
ana@ctl:~$ cd net && git init --quiet backups && ls
backup.py
backups
compare.py
config.yaml
data
inventory
render.py
restore.py
templates
```

A primeira execução grava os três arquivos e faz commit deles:

```
ana@ctl:~$ cd net && python backup.py
committed: core1.conf, edge1.conf, edge2.conf
ana@ctl:~$ cd net && git -C backups log --oneline
4ad37d6 backup: core1, edge1, edge2
```

**O arquivo é exatamente o que o roteador mandou**, nada removido, nada reordenado. Isso é uma
escolha. Um backup que limpasse a entrada seria uma cópia do que o script achou que importava, e
no dia em que importasse, a linha que foi limpa seria justamente a que falta. Limpar é papel da
comparação, que a seção 07 faz.
