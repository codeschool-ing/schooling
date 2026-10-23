---
title: Varrendo os arquivos e o histórico
version: 1
---

O gitleaks é um scanner de segredos: um programa só, um conjunto de regras escritas como expressões
regulares e duas maneiras de ler um repositório. **`gitleaks dir` lê os arquivos como estão no
disco. `gitleaks git` lê as mudanças de cada commit, do primeiro ao último.** O primeiro responde se
há um segredo no código agora. O segundo responde se algum dia houve um, que depois da última seção
é a pergunta que importa.

### Instalando

Do mesmo jeito que a aula 1 instalou o uv: o release, o checksum publicado, `install`. A partir do
seu diretório home:

```
ana@vm:~$ curl -fsSLO https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_checksums.txt | grep linux_x64.tar.gz | sha256sum --check
gitleaks_8.30.1_linux_x64.tar.gz: OK
ana@vm:~$ tar -xzf gitleaks_8.30.1_linux_x64.tar.gz gitleaks
ana@vm:~$ install -m 755 gitleaks ~/.local/bin/ && rm gitleaks gitleaks_8.30.1_linux_x64.tar.gz
ana@vm:~$ gitleaks version
8.30.1
```

`sha256sum --check` imprime `OK` só quando o arquivo que você baixou é o arquivo que o projeto
publicou. O pacote também traz uma licença e um README; o comando `tar` extrai só o binário.

### Os arquivos, como estão agora

Rode a partir do projeto, com `-v` para que cada achado seja impresso inteiro em vez de só contado:

```
ana@vm:~/linkbox$ gitleaks dir --no-banner --no-color -v .
Finding:     ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
Secret:      lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Fingerprint: settings.py:generic-api-key:4

2:00AM INF scanned ~35843 bytes (35.84 KB) in 31.7ms
2:00AM WRN leaks found: 1
```

Cada campo responde a uma pergunta que quem faz a triagem do achado faria:

| campo | o que diz |
|---|---|
| `Finding` | a linha como foi escrita, para você ver o que é sem abrir o arquivo |
| `Secret` | a parte da linha que a regra casou |
| `RuleID` | qual regra casou: `generic-api-key` é a regra genérica, explicada abaixo |
| `Entropy` | o quanto o valor casado é aleatório, em bits por caractere |
| `File`, `Line` | onde está |
| `Fingerprint` | uma identidade para este achado específico, usada para marcá-lo como tratado |

**O código de saída é o veredito**: o gitleaks sai com 1 quando encontra algo e com 0 quando não
encontra nada, e é isso que permite a um estágio do pipeline usá-lo sem nenhuma cola. `--no-banner`
tira o logotipo que ele imprime primeiro, e `--no-color` os códigos de cor, que um arquivo de log
mostra como ruído.

### O histórico

A mesma varredura em todos os commits:

```
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color -v .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
Finding:     ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
Secret:      lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Commit:      3f932db1ab33201959dc1dd9270d46dc0485e297
Author:      Ana Lima
Email:       ana@example.org
Date:        2026-10-05T13:00:00Z
Fingerprint: 3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4

2:00AM INF 5 commits scanned.
2:00AM INF scanned ~8969 bytes (8.97 KB) in 224ms
2:00AM WRN leaks found: 1
```

**Ele aponta o token uma vez, no primeiro commit, embora a última seção tenha contado cinco commits
que o guardam.** `gitleaks git` lê o que cada commit *acrescentou*, as linhas que `git log -p`
mostra com um `+`, então um valor acrescentado uma vez e nunca mais mexido é um achado só, no commit
que o trouxe. A linha `Commit` nomeia esse commit por inteiro, com o autor e a data, e o fingerprint
agora começa pelo commit também, porque a mesma linha em dois commits seriam dois achados.

Essa data é o começo da janela que a próxima seção tem de fechar: o token está legível para
qualquer pessoa com o repositório desde a manhã de 5 de outubro. Na sua máquina o commit, a data e
o fingerprint são os seus, porque o seu primeiro commit foi feito em outro momento, por outra
pessoa.

### Regras genéricas e regras específicas

O gitleaks vem com regras para os tokens de uma longa lista de provedores: chaves de nuvem, tokens
do GitHub e do GitLab, provedores de pagamento, webhooks de chat. **Essas regras são precisas**
porque os tokens são desenhados para serem encontrados, com prefixo e tamanho fixos. Um token de
acesso pessoal do GitHub começa com `ghp_`, e nada mais começa assim por acaso.

O token do linkbox é invenção dele, então nenhuma regra específica o conhece, e quem o pegou foi
`generic-api-key`: uma palavra como `token`, `key` ou `secret` no nome que recebe o valor, e um
valor aleatório o bastante para ser um. A linha de entropia é esse segundo teste, medido. **A regra
genérica é a barulhenta.** Ela deixa passar um token cuja variável se chama `ADMIN` e aponta um
identificador longo e aleatório que não abre nada. Os dois tipos de erro são o motivo de um achado
passar pela triagem de uma pessoa, e de a triagem ficar por escrito, como a seção desta aula sobre o
histórico faz com este.

Se o seu projeto emite tokens, dar a eles um prefixo próprio, como `lbx_` aqui, é a coisa mais
barata que você pode fazer por todo scanner que um dia vai ler o seu código: uma regra para eles é
uma linha, e nunca se confunde com outra coisa.

### Nenhuma das duas varreduras lê tudo

`gitleaks git` lê os commits do repositório que recebe, então um branch que só existe no clone de
um colega não está nele, e um arquivo que alguém anexou a um ticket também não. `gitleaks dir` lê o
diretório que você indicar. A cópia do servidor de CI é o único lugar onde todo branch que foi
enviado acaba chegando, e é por isso que o estágio do pipeline no fim desta aula varre o histórico
lá, a cada push.
