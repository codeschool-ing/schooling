---
title: Limite de taxa, e pelo que ele pode contar
version: 1
---

Uma regra por taxa conta requisições e age sobre quem manda demais. A `login-rate` da loja diz:

- **contar por** `IP`, o endereço de onde a requisição veio;
- **numa** janela de 300 segundos;
- **só** requisições cujo caminho começa com `/login`, a instrução de escopo (*scope-down
  statement*);
- **bloquear** um endereço quando ele passou de 100 delas na janela.

Uma pessoa fazendo login manda um punhado de requisições. Um programa testando uma lista de senhas
roubadas manda milhares, e um limite de cem em cinco minutos o para sem incomodar pessoa nenhuma. O
limite é por endereço: mil endereços diferentes, cada um abaixo dele, são mil endereços que o WAF deixa
passar, e é por isso que esta regra é uma camada e não a defesa.

## A janela

`EvaluationWindowSec` pode ser 60, 120, 300 ou 600 segundos, e o limite pode ser tão baixo quanto 10.
**A regra bloqueia enquanto o endereço está acima do limite e o deixa passar de novo quando a taxa na
janela cai abaixo dele**, sozinha, sem ninguém desbloquear nada. A contagem não é instantânea: a AWS
documenta um pequeno atraso entre um endereço cruzar o limite e o bloqueio valer, então algumas
requisições depois da centésima passam. Um limite de taxa é um freio, não um muro, e é dimensionado para
um tipo de tráfego e não para um número exato.

Vale fazer a conta antes de escolher o número. Um atacante a 3 requisições por segundo passa de 100 em
menos de 34 segundos. Uma loja cujo próprio app repete um login falho 5 vezes, atrás de uma operadora
móvel que põe 40 clientes atrás de um endereço, manda 200 em cinco minutos ruins, de pessoas que não
fizeram nada errado. **O segundo caso é o que dói**, porque derruba clientes reais em silêncio.

## Contar por outra coisa que não o endereço

`AggregateKeyType` pode ser `IP`, `FORWARDED_IP`, `CONSTANT` ou `CUSTOM_KEYS`:

| chave | conta | quando |
|---|---|---|
| `IP` | por endereço de origem | o padrão, e certo quando o cliente conecta direto |
| `FORWARDED_IP` | por endereço num cabeçalho como `X-Forwarded-For` | atrás de um proxy ou CDN em que o WAF não está |
| `CONSTANT` | todas as requisições que o escopo casa, juntas | um teto para um endpoint, seja quem for que chame |
| `CUSTOM_KEYS` | por combinação de até cinco chaves: um cabeçalho, um cookie, um argumento de query, o caminho | por chave de API, ou por sessão, em vez de por endereço |

`FORWARDED_IP` confia num cabeçalho que o cliente pode escrever. Só é certo quando algo na frente, sob
controle da equipe, o define, e o web ACL é informado de qual cabeçalho e do que fazer com um ausente ou
malformado. Contar por um cabeçalho que o atacante controla deixa o atacante escolher uma contagem nova
a cada requisição.

## Onde fica um limite de taxa

Ponha regras por taxa **depois** do conjunto de IPs e antes do grupo gerenciado, como as da loja. O conjunto de IPs é certo e decide primeiro. Uma requisição de um endereço já acima do
limite é então recusada
antes de as regras gerenciadas olharem para ela, então o registro no log dela nomeia a regra de taxa como
o motivo, que é o registro que a equipe vai querer ler. Uma regra de taxa para o site inteiro, sem escopo
e com um limite generoso de alguns milhares, é uma segunda regra comum: custa uma regra e pega um único
endereço martelando tudo.
