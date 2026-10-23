---
title: O que a função carrega, e quão velho é
version: 1
---

**Uma função vai embora com as dependências dentro dela, congeladas no momento em que foi
empacotada.** Um servidor tem as bibliotecas atualizadas quando alguém atualiza o servidor. O arquivo
zip de uma função guarda as versões que estavam instaladas no dia em que foi construído, e continua
rodando-as, sem mudança, até alguém construí-lo de novo. Uma função que funciona é uma função que
ninguém reconstrói, então as bibliotecas dela envelhecem no lugar.

A crença errada é a de que "serverless" quer dizer que o provedor mantém o software atualizado. O
Lambda atualiza o runtime, isto é, o sistema operacional e o interpretador Python, enquanto esse
runtime é suportado (a aula 3 mostrou o que acontece depois). **Tudo o que o seu código importa está
no seu arquivo zip, e ninguém atualiza isso além de você.**

## Perguntando quais versões têm vulnerabilidades conhecidas

O `pip-audit` lê uma lista de pacotes Python fixados e pergunta a uma base pública de vulnerabilidades
conhecidas sobre cada versão. Ele vai para um ambiente virtual próprio, `~/aws/tools`, ao lado do
ambiente do moto e separado dele. A aula 12 pôs o Checkov no mesmo diretório; se você o tem, as mesmas
duas linhas só acrescentam o pip-audit:

```sh
python3 -m venv ~/aws/tools
~/aws/tools/bin/pip install -q pip-audit==2.10.1
```

A função de exportação da clínica conversa com o sistema de agendamento por HTTP, e as dependências
dela foram escritas quando a função foi, em 2018:

```sh
cat > requirements.txt <<'EOF'
requests==2.19.1
EOF
```

```
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --version
pip-audit 2.10.1
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt
WARNING:pip_audit._cli:--no-deps is supported, but users are encouraged to fully hash their pinned dependencies
WARNING:pip_audit._cli:Consider using a tool like `pip-compile`: https://pip-tools.readthedocs.io/en/latest/#using-hashes
Found 10 known vulnerabilities in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.19.1  PYSEC-2018-28   2.20.0
requests 2.19.1  PYSEC-2018-28   2.20.0
requests 2.19.1  PYSEC-2023-74   2.31.0
requests 2.19.1  PYSEC-2023-74   2.31.0
requests 2.19.1  PYSEC-2026-1873 2.32.0
requests 2.19.1  PYSEC-2026-1872 2.32.4
requests 2.19.1  PYSEC-2026-2275 2.33.0
requests 2.19.1  PYSEC-2026-1873 2.32.0
requests 2.19.1  PYSEC-2026-1872 2.32.4
requests 2.19.1  PYSEC-2026-2275 2.33.0
```

`--no-deps` confere as versões escritas no arquivo e não tenta descobrir o que elas puxariam, e
`--disable-pip` deixa fazer isso sem instalar nada. Os dois avisos acima da tabela são o conselho do
próprio pip-audit: com toda dependência fixada *e com hash*, o que é auditado é comprovadamente o que
é instalado.

**Cada linha é um alerta publicado contra o `requests` 2.19.1, com a primeira versão que o corrige.**
Alguns identificadores aparecem duas vezes, que é como esta versão do pip-audit os imprimiu. A tabela
é a resposta do dia em que esta aula foi gravada. **Rode no mês que vem e ela pode estar maior**,
porque a versão não mudou e o conhecimento sobre ela mudou, e é exatamente por isso que uma varredura
é repetida em vez de aprovada uma vez.

## Corrigindo, e provando a correção

A correção é fixar uma versão mais nova. A 2.34.2 era a versão mais recente do `requests` quando esta
aula foi gravada:

```
ana@laptop:~/aws$ sed -i 's/requests==2.19.1/requests==2.34.2/' requirements.txt
ana@laptop:~/aws$ ~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt
WARNING:pip_audit._cli:--no-deps is supported, but users are encouraged to fully hash their pinned dependencies
WARNING:pip_audit._cli:Consider using a tool like `pip-compile`: https://pip-tools.readthedocs.io/en/latest/#using-hashes
No known vulnerabilities found
```

Uma auditoria limpa do arquivo é metade da prova. A outra metade é que o arquivo zip que o Lambda roda
foi construído a partir dele: **um `requirements.txt` corrigido ao lado de um pacote antigo publicado
não corrige nada**, então a função é empacotada de novo com as versões novas dentro, e publicada. Numa
conta real, `aws lambda get-function --function-name daily-export --query Configuration.LastModified`
diz então quando o código mudou pela última vez, e uma data anterior à correção é uma publicação que
não aconteceu. Essa consulta não foi executada aqui.

## O que mais há no zip

Três hábitos que mantêm o conteúdo de uma função pequeno e conhecido:

- **Empacote só o que o handler importa.** Uma biblioteca que não é importada não pode ser explorada
  pela função, e é uma linha a menos em toda auditoria futura. Um zip feito copiando o ambiente
  virtual inteiro de um desenvolvedor carrega também ferramentas de teste, notebooks e as dependências
  deles.
- **Camadas também são dependências.** Uma layer do Lambda é um arquivo zip compartilhado entre
  funções, e uma função que usa uma layer roda a versão da layer com que foi publicada. Audite a layer
  como audita a função.
- **Reconstrua por calendário, e não só quando algo muda.** Uma função em que ninguém mexeu por um ano
  é a que carrega um ano de alertas, então o build que a empacota roda também numa data marcada.

::: track devsecops
A aula 5 do curso `secure-pipeline` pôs essa mesma pergunta num pipeline, onde uma versão vulnerável
fixada quebra o build antes de a função ser empacotada. A aula 14 deste curso leva essa barreira ao
fluxo de publicação na nuvem.
:::

::: track *
Rodar esta auditoria à mão ensina o que ela diz. O lugar dela é o build, onde uma versão vulnerável
fixada para a função antes de ela ser empacotada, e a aula 14 deste curso a põe lá.
:::
