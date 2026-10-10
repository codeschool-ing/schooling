---
title: Conferindo o próprio documento
version: 1
---

**Duas perguntas diferentes são feitas a uma especificação, e elas precisam de dois programas
diferentes.** A primeira é se o documento é um documento OpenAPI válido: todo `$ref` cai em algum
lugar, todo parâmetro de caminho está declarado, toda resposta tem descrição. A segunda é se a API se
comporta como o documento diz. Esta seção responde à primeira; o teste de contrato, duas seções
adiante, responde à segunda. Um arquivo pode passar numa e falhar na outra.

A ferramenta para a primeira é o `openapi-spec-validator`, um programa Python que o Ubuntu não
empacota. É a única coisa deste curso que não vem do repositório do Ubuntu, e o único download, que a
lição 1 anunciou quando instalou `python3-venv` e `python3-pip`.

## Um ambiente virtual, e por quê

O comando óbvio é recusado, e ele diz por quê:

```
ana@api:~/shelf$ pip install openapi-spec-validator==0.9.0
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**O Ubuntu 24.04 não deixa o `pip` instalar no Python do sistema.** Todo pacote Python da máquina até
aqui veio do `apt`, e o `apt` os controla; um pacote que o `pip` escrevesse por cima de um deles
quebraria algo que o `apt` acha que está intacto. A saída que a mensagem sugere é um **ambiente
virtual**: um diretório com os seus próprios pontos de entrada do interpretador e o seu próprio
`site-packages`, onde o `pip` pode fazer o que quiser.

Crie um dentro do projeto e instale nele com o `pip` do próprio ambiente. Este passo precisa que a
VM alcance a internet:

```
ana@api:~/shelf$ python3 -m venv ~/shelf/.venv
ana@api:~/shelf$ .venv/bin/pip install openapi-spec-validator==0.9.0 | tail -1
Successfully installed PyYAML-6.0.3 annotated-types-0.8.0 attrs-26.1.0 jsonschema-4.26.0 jsonschema-path-0.5.0 jsonschema-specifications-2025.9.1 lazy-object-proxy-1.12.0 openapi-schema-validator-0.9.0 openapi-spec-validator-0.9.0 pathable-0.6.0 pydantic-2.14.0 pydantic-core-2.50.0 pydantic-settings-2.15.0 python-dotenv-1.2.4 referencing-0.37.0 rfc3339-validator-0.1.4 rpds-py-2026.9.1 six-1.17.0 typing-extensions-4.16.0 typing-inspection-0.4.4
```

O `python3 -m venv` não imprimiu nada, que é como ele avisa que deu certo. O segundo comando
imprimiu só a última linha do `pip`, e ela vale a leitura. Você pediu um pacote e recebeu vinte.
**`==0.9.0` fixa o validador e mais nada**: os dezenove pacotes de que ele depende foram resolvidos
no dia em que isto foi gravado, e no dia em que você rodar algumas das versões deles podem ser mais
novas. Num projeto essa diferença importa, e `pip freeze` é o comando que anota cada versão
instalada, para que uma segunda máquina instale o mesmo conjunto.

`.venv` começa com ponto para que o `ls` não o liste, e nada mais no nome é especial. Nada nele
precisa ser ativado, também: rodar `.venv/bin/openapi-spec-validator` pelo caminho usa o Python do
ambiente, e rodar o `python3` puro usa o do Ubuntu. Os dois guardam cópias próprias de uma biblioteca
que ambos têm:

```
ana@api:~/shelf$ .venv/bin/python -c 'import jsonschema; print(jsonschema.__file__)'
/home/ana/shelf/.venv/lib/python3.12/site-packages/jsonschema/__init__.py
ana@api:~/shelf$ python3 -c 'import jsonschema; print(jsonschema.__file__)'
/usr/lib/python3/dist-packages/jsonschema/__init__.py
```

Então o teste de contrato, que roda com `python3`, usa o `jsonschema` que a lição 1 instalou com o
`apt`, e o validador usa o seu. Apagar o `.venv` remove tudo o que o download trouxe, e nada mais na
máquina percebe.

## O validador, num arquivo bom e num quebrado

No documento do shelf ele imprime uma linha, e o código de saída é 0:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator openapi.yaml; echo "exit $?"
openapi.yaml: OK
exit 0
```

Para ver o que ele pega, faça uma cópia com um erro: renomeie o caminho `/authors/{id}` para
`/authors/{author}` e deixe tudo o que está dentro dele como está. É o tipo de edição que acontece
quando alguém arruma nomes, e o arquivo continua sendo YAML perfeitamente bom:

```
ana@api:~/shelf$ sed 's|^  /authors/{id}:|  /authors/{author}:|' openapi.yaml > broken.yaml
ana@api:~/shelf$ diff openapi.yaml broken.yaml
111c111
<   /authors/{id}:
---
>   /authors/{author}:
ana@api:~/shelf$ .venv/bin/openapi-spec-validator broken.yaml; echo "exit $?"
broken.yaml: Validation Error: Path parameter 'author' for 'get' operation in '/authors/{author}' was not resolved
exit 1
```

O caminho agora tem um parâmetro chamado `author` que nenhuma lista `parameters` declara. Por padrão o
validador para no primeiro erro; `--validation-errors all` mostra que há um segundo, o espelho do
primeiro, já que o `id` declarado não aparece mais no caminho:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator --validation-errors all broken.yaml
broken.yaml: Validation Error: [1] Path parameter 'author' for 'get' operation in '/authors/{author}' was not resolved
broken.yaml: Validation Error: [2] Path parameter 'id' for 'get' operation in '/authors/{author}' was not resolved
broken.yaml: 2 validation errors found
```

**O código de saída é o que um pipeline lê**, `0` para um arquivo válido e `1` para um quebrado, e
por isso o mesmo comando num CI transforma uma descrição quebrada num build que falha antes que
alguém a publique.

## O que um documento válido ainda pode errar

O validador compara o documento com as regras da OpenAPI, e só com elas. Ele nunca vê o `rest.py`. Um
documento que prometesse um campo que o shelf nunca envia, um código de status que ele nunca usa ou
um endereço que ele não tem passaria, desde que prometesse tudo isso em OpenAPI correta.

O próprio documento do shelf é um exemplo. Ele passou com uma linha de saída, e ainda contém uma
regra, os treze dígitos do ISBN, que o `rest.py` não cumpre. Achar isso exige um programa que segure o
documento numa mão e o servidor em execução na outra.
