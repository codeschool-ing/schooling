---
title: O dia em que uma vaza
version: 1
---

**Uma rotação planejada e um vazamento usam os mesmos quatro passos em outra ordem.** Rotacionando
por calendário, a credencial antiga é revogada por último, porque não há nada de errado com ela e
uma interrupção seria o único dano. Depois de um vazamento, outra pessoa pode estar usando a
credencial agora mesmo, e a ordem se inverte:

1. **revogue primeiro**, e aceite que o que a usava pare de funcionar;
2. faça a nova e entregue, o que encerra a interrupção;
3. descubra para que a credencial vazada foi usada enquanto funcionava;
4. registre como ela vazou, para que o passo 1 não volte a ser preciso pelo mesmo motivo.

A interrupção do passo 1 é o preço, e costuma ser o menor: uma automação de imagens quebrada por
vinte minutos contra alguém fazendo push em `fleet` como `image-bot` enquanto ninguém percebe.

O passo 3 é a aula 12. Cada registro de lá responde uma parte: a lista do Gitea do que uma conta
enviou, o log do API server do que ela fez no cluster, o log do Vault do que ela leu.

## Um segredo que chegou ao Git

O vazamento a que este curso está mais exposto é um segredo commitado por engano: um token colado
num arquivo de values, um `.env` adicionado com `git add .`. **Apagá-lo no commit seguinte não o
remove**, e reescrever o histórico também não. Todo clone feito antes da reescrita ainda o tem, e o
mesmo vale para cada fork, cada cache de CI e cada página de pull request que mostrou o diff. O
segredo precisa ser tratado como lido por todos que podiam ler o repositório, o que quer dizer
revogá-lo e substituí-lo, aconteça o que acontecer com o histórico depois.

Dois hábitos tornam isso mais raro, e os dois apareceram antes no curso. Do lado de quem commita: o
`.sops.yaml` e o Sealed Secrets da aula 9 mantêm o valor em claro fora do repositório desde o
início. Do lado do servidor: um scanner de segredos na CI, rodando em todo pull request como o
`validate.sh`, recusa um diff que contenha algo com cara de chave. Nenhum dos dois é perfeito, e **o
procedimento de rotação é o que sobra quando os dois falham**, e por isso vale tê-lo praticado numa
tarde tranquila.

## O que este lab mudou

| credencial | antes desta aula | depois dela |
|---|---|---|
| o administrador do PostgreSQL | `initial-password`, digitada por uma pessoa | rotacionada pelo Vault, conhecida por ninguém |
| o acesso da aplicação ao banco | nenhum ainda | uma conta por pedido, uma hora cada |
| o token do `image-bot` | `automation`, feito na aula 7 | `automation-2`; o primeiro, recusado |
| o que o caminho de staging pode mudar | o cluster inteiro | o próprio namespace, e duas regras além dele |

A aula 12 parte daqui, e o último passo dela trata da linha que esta tabela deixa de fora: o token
root do Vault.
