---
title: O ambiente, e o que ele não esconde
version: 1
---

O conselho de sempre é manter segredos fora do código e colocá-los em **variáveis de ambiente**, e
é um bom conselho por um motivo: o valor deixa de fazer parte de qualquer coisa que entra num
commit. O código diz *leia `PAYMENT_API_KEY`*, a máquina diz qual é o valor, e qualquer pessoa da
equipe pode ler o repositório sem receber a chave junto. É o que o `account.py` já faz com
`ACCOUNT_DB`, `ACCOUNT_UPLOADS` e `ACCOUNT_SESSION_SECONDS`, e nenhuma delas é segredo.

**O que uma variável de ambiente não faz é esconder o valor da máquina em que roda.** Esta seção
tira a chave do repositório e a põe no ambiente, e depois olha quem ainda consegue lê-la ali.

## A chave num arquivo só dela, ignorado

Na máquina de quem desenvolve, o ambiente costuma ser preenchido a partir de um arquivo pequeno que
nunca sai dali. Em `~/leaky`, crie o `payment.env` com `nano payment.env`:

```sh
# leaky/payment.env
# The payment key, for this machine only. Never committed: *.env is in .gitignore.
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
```

Depois diga ao git para nunca pegar arquivos terminados em `.env`, confira que ele obedece e varra
o diretório de novo:

```
ana@nft:~/leaky$ echo '*.env' > .gitignore
ana@nft:~/leaky$ git status --short
?? .gitignore
ana@nft:~/leaky$ git check-ignore -v payment.env
.gitignore:1:*.env	payment.env
ana@nft:~/leaky$ git add .gitignore && git commit -q -m "keep env files out of the repository"
ana@nft:~/leaky$ gitleaks dir --no-banner --no-color --redact --verbose
Finding:     PAYMENT_API_KEY=REDACTED
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.875000
File:        payment.env
Line:        3
Fingerprint: payment.env:generic-api-key:3

4:53PM INF scanned ~360 bytes (360 bytes) in 4.37ms
4:53PM WRN leaks found: 1
```

O `git status` lista o `.gitignore` novo e **não lista o `payment.env`**, e o `check-ignore` diz a
regra que o esconde: a linha 1 do `.gitignore`, `*.env`. Um `git add .` daqui em diante o deixa de
fora.

E o `gitleaks dir` o aponta, o que está certo. A chave está num arquivo deste disco, e uma varredura
do diretório serve para isso. As duas varreduras agora discordam por um motivo que vale guardar: o
`git` diz o que o repositório guarda, e o `dir` diz o que a máquina guarda. A opção `--redact` troca
o valor por `REDACTED` no relatório, para que a saída da própria varredura, guardada no log de um
pipeline, não vire o próximo lugar por onde a chave vaza.

## Um serviço iniciado com ela

O padrão é o mesmo para qualquer programa: preencher o ambiente e então iniciar o programa, que lê o
valor quando precisa. O `account.py` não tem uso para uma chave de pagamento, mas é um serviço real
nesta máquina, e a pergunta é a mesma para qualquer processo. Pare-o se estiver rodando e inicie-o no
primeiro terminal, com o arquivo carregado:

```
ana@nft:~/boxoffice$ set -a; . ~/leaky/payment.env; set +a
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
```

O `set -a` faz de toda variável que o próximo comando definir uma variável exportada, então
`. ~/leaky/payment.env` põe `PAYMENT_API_KEY` no ambiente de tudo o que for iniciado neste terminal,
e o `set +a` desliga isso de novo. Agora, no segundo terminal, pergunte ao sistema com o que o
serviço foi iniciado:

```
ana@nft:~/boxoffice$ pgrep -f '^python3 account.py'
141
ana@nft:~/boxoffice$ tr '\0' '\n' < /proc/$(pgrep -f '^python3 account.py')/environ | grep KEY
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
ana@nft:~/boxoffice$ ps eww -p $(pgrep -f '^python3 account.py') | grep -o 'PAYMENT_API_KEY=[^ ]*'
PAYMENT_API_KEY=nft7Zq2vRmX9kLp4Tn8Wc3Yb6Hd1Jf5G
ana@nft:~/boxoffice$ sudo -u nobody cat /proc/$(pgrep -f '^python3 account.py')/environ
cat: /proc/141/environ: Permission denied
```

**Qualquer um logado como `ana` lê a chave com um comando**, de um de dois lugares. O
`/proc/<pid>/environ` guarda o ambiente com que um processo foi iniciado, separado por bytes zero,
que o `tr` transforma em linhas; o `ps` com `e` imprime a mesma coisa depois do comando. A última
linha é a fronteira: `nobody` é outro usuário na mesma máquina e recebe `Permission denied`. O
ambiente é protegido exatamente tanto quanto a conta que roda o processo, e não mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l18-reach\" aria-label=\"Um processo, python3 account.py, iniciado com PAYMENT_API_KEY no ambiente, dentro de uma fronteira tracejada chamada usuário ana. Dentro da fronteira, dois jeitos de ler o valor, os dois permitidos: o arquivo /proc/&lt;pid&gt;/environ e o comando ps eww. Fora da fronteira, o usuário nobody pede o mesmo arquivo e recebe Permission denied. À direita, três jeitos de o valor sair do processo sem ninguém decidir: todo processo filho herda uma cópia, uma linha de log ou uma página de erro pode imprimi-lo, e um relatório de falha pode coletá-lo.\"><defs><marker id=\"l18-reach-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-reach-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">protegido tanto quanto a conta que o roda, e não mais</text><path d=\"M30.0 44.0 L450.0 44.0 L450.0 220.0 L30.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"38.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">usuário ana</text><rect x=\"200.0\" y=\"76.0\" width=\"220.0\" height=\"62.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"310.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">python3 account.py</text><text x=\"310.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">PAYMENT_API_KEY=…</text><rect x=\"48.0\" y=\"160.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"133.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/proc/&lt;pid&gt;/environ</text><rect x=\"240.0\" y=\"160.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ps eww</text><path d=\"M200.0 120.0 L150.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-phosphor)\"></path><path d=\"M295.0 138.0 L295.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-phosphor)\"></path><text x=\"372.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">lê</text><rect x=\"48.0\" y=\"236.0\" width=\"110.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"103.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nobody</text><text x=\"170.0\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Permission denied</text><text x=\"590.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">e cópias que ele leva para fora</text><rect x=\"490.0\" y=\"74.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">todo processo filho</text><path d=\"M420.0 107.0 L486.0 92.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path><rect x=\"490.0\" y=\"126.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma linha de log, uma página de erro</text><path d=\"M420.0 107.0 L486.0 144.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path><rect x=\"490.0\" y=\"178.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"590.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um relatório de falha</text><path d=\"M420.0 107.0 L486.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-reach-nf-ah-amber)\"></path></svg>", "caption": "O ambiente pode ser lido pela conta que roda o processo, e viaja com tudo o que o processo inicia ou imprime."}
```

Para um notebook, isso basta. Num servidor, é o começo de uma lista de lugares por onde o valor
viaja sem ninguém ter decidido:

- **Processos filhos o herdam.** Tudo o que o serviço inicia, um comando de shell, um script
  auxiliar, um relator de falhas, recebe uma cópia do ambiente inteiro, chave incluída.
- **Logs e páginas de erro o imprimem.** Uma página de depuração que lista o ambiente, uma linha de
  início que imprime a configuração "para ajudar", um job de CI que roda `env` ou rastreia o shell
  com `set -x`. A aula 19 acrescenta a regra de que uma linha de log nunca carrega um segredo.
- **Relatórios de falha e pacotes de suporte o coletam.** Ferramentas de rastreamento de erros podem
  capturar o ambiente e as variáveis locais a cada exceção, e um pacote de diagnóstico anexado a um
  chamado muitas vezes traz os dois.
- **Ferramentas de contêiner e de orquestração o mostram.** O ambiente de um contêiner faz parte da
  configuração dele, que qualquer um com permissão de inspecioná-lo consegue ler.

## Para onde vão os segredos numa implantação de verdade

Um **gerenciador de segredos** é um serviço cujo trabalho todo é guardar segredos: ele os armazena
cifrados, entrega cada um só à identidade autorizada a lê-lo, registra cada leitura e consegue
trocar um valor sem uma implantação. HashiCorp Vault, AWS Secrets Manager, Google Cloud Secret
Manager e Azure Key Vault são os comuns. Um sistema de CI tem a sua versão menor, como os secrets do
GitHub Actions ou as variáveis de CI/CD do GitLab, que também mascaram o valor no log do job. **A
aplicação pede o valor ao iniciar, e o valor nunca existe em nenhum arquivo que a equipe escreve.**

Duas regras valem qualquer que seja a escolha, e um testador confere as duas lendo o código:

- **Um segredo não tem valor padrão.** O `ACCOUNT_DB` tem um, `data/account.db`, e isso está certo:
  um caminho faltando não deve parar o serviço. Uma chave de pagamento faltando deve, então o código
  a lê como `os.environ["PAYMENT_API_KEY"]`, que levanta um erro ao iniciar, e nunca com um valor
  padrão escrito ao lado, que poria uma chave válida de volta no arquivo.
- **Um segredo nunca é impresso.** Nem numa linha de início, nem numa mensagem de erro, nem na saída
  de um teste. Se algo precisa mostrar que uma chave está definida, mostra que ela está definida.
