---
title: Onde a aplicação o busca
version: 1
---

**Há três lugares em que um programa pode achar um segredo: no próprio código, no ambiente quando
inicia, ou pedindo-o em tempo de execução com a própria identidade. Cada passo nessa lista tira um
grupo de pessoas e de arquivos que conseguem ver o valor.** O terceiro é aquele para o qual o Secrets
Manager existe, e é menos código que os outros dois.

## Três lugares, e quem mais lê cada um

| onde | quem mais vê o valor |
|---|---|
| escrito no código ou num arquivo ao lado | todo mundo com o repositório, o histórico dele, os forks e cada build feito a partir dele |
| numa variável de ambiente definida na publicação | todo mundo que lê a configuração da publicação, mais os relatórios de falha do processo, páginas de depuração e qualquer processo filho |
| buscado em tempo de execução no Secrets Manager | quem a política do segredo permite, e toda leitura deixa um registro |

A primeira linha é o `booking.env` de duas seções atrás, e ela nunca está certa. A segunda é a
comum. Ela é menos um cofre de segredos do que um caminho mais curto da ferramenta de publicação até
o processo: numa função Lambda, como a aula 13 mostra, quem pode ler a configuração da função lê o
ambiente dela em texto puro. **A terceira mantém o valor fora de todo arquivo e de toda
configuração**: o que se publica é o nome do segredo.

## O sistema de agendamento, pedindo o segredo

Esta é a busca inteira, em Python com o boto3, o SDK da AWS que entrou em `~/aws/venv` junto com o
moto. Salve o código como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import boto3\n\n", "note": "O SDK acha as credenciais sozinho: no laboratório, a sessão que o `with_session` põe no ambiente; numa máquina da AWS, o papel que a plataforma lhe dá. Nada neste arquivo nomeia uma chave."}, {"code": "secrets = boto3.client(\"secretsmanager\")\npassword = secrets.get_secret_value(SecretId=\"clinic/booking/db\")[\"SecretString\"]\n", "note": "Uma requisição, pelo nome. Sem versão indicada, ela devolve o valor com o rótulo `AWSCURRENT`, então uma rotação chega ao próximo início do programa sem publicação."}, {"code": "print(\"connecting to the database with a password of\", len(password), \"characters\")\n", "note": "Faz as vezes da abertura da conexão com o banco. Imprime o tamanho e nunca o valor, porque uma linha de log é mais um lugar por onde um segredo vaza."}]}
```

Rode-o como o papel, com a sessão da seção anterior:

```
ana@laptop:~/aws$ with_session "$session" python3 app.py
connecting to the database with a password of 24 characters
```

## O que isto não resolve

**O programa ainda guarda a senha na memória**, e quem conseguir rodar código dentro dele, ou ler a
memória dele, a lê ali. Buscar em tempo de execução tira o segredo dos arquivos e da configuração;
não torna o programa em execução um lugar seguro. Esse é o território do curso `secure-code`.

**Um segredo buscado é guardado em cache**, ou o banco veria uma requisição ao Secrets Manager a cada
conexão. A AWS publica clientes de cache para isso, e um valor em cache precisa ser renovado depois de
uma rotação, e é por isso que `AWSPREVIOUS` continua funcionando por um tempo.

**A identidade que o busca passa a ser o que se protege.** Um papel autorizado a ler o segredo vale
tanto quanto a senha. Então a política do papel é estreita, como a versão da AWS da seção anterior
era, e o papel só é assumido pela plataforma em que o programa roda. É a pergunta da aula 6, feita a
uma máquina: quem consegue virar esta identidade, e mais alguém conseguiria? 