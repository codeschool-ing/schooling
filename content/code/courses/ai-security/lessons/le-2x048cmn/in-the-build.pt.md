---
title: Os dois no build
version: 1
---

Os dois tipos de verificação têm preços diferentes, então rodam em momentos diferentes. O script que
o build chama guarda os dois. Salve-o como `~/guard/ci.sh`:

```sh
cat > ~/guard/ci.sh <<'EOF'
#!/usr/bin/env bash
# ci.sh: what the build runs. The suite on every change; the rate of every
# candidate prompt, against a ceiling, when there is one.
set -u
cd ~/guard
export PATH=~/guard/bin:$PATH
status=0
guard defences data/suite.json --now "${CI_DATE:-$(date +%F)}" || status=1
for f in data/candidates/*.txt; do
  [ -e "$f" ] || continue
  guard rate "$f" data/tickets.jsonl --runs 10 --ceiling 40 || status=1
done
exit $status
EOF
```

O teto é 40%: um candidato passa quando o intervalo inteiro da sua taxa de falha fica abaixo dele. É
uma pergunta mais exigente que "a taxa está abaixo de 40%?", e de propósito. O build não está
pedindo um palpite; está pedindo que lhe mostrem.

```
ana@lab:~/guard$ CI_DATE=2026-10-09 bash ci.sh; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
PASS     files under review are approved
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 1 failing the build
data/candidates/classify.txt: 38 of 120 trials failed, 31.7% (95% interval 24.0% to 40.4%)
  upper bound 40.4% is not under the ceiling of 40%
exit status 1
```

Dois motivos para o build vermelho, e são de tipos diferentes. A chave vencida é uma promessa que
passou da data. O candidato é uma medição que não passou da barra: 40,4% é um décimo de ponto acima
do teto. **Isso não é a constatação de que o candidato é ruim.** Diz que 120 tentativas não
conseguem mostrar que ele é bom o bastante. As escolhas honestas de quem o escreveu são: rodar mais
tentativas e ver se o intervalo desce abaixo de 40%, ou tirar a frase de que o classificador nunca
precisou. Baixar o teto para deixá-lo passar não é uma delas.

## Que verificação roda quando

| verificação | precisa de | roda |
|---|---|---|
| a suíte | Python e o repositório; sem modelo, sem chave, sem rede | a cada pull request, em segundos |
| a taxa de um candidato | o modelo, e uma chave para ele se for hospedado | quando muda um arquivo sob revisão ou um candidato |
| a taxa do que está implantado | o mesmo | toda noite, contra o modelo que o fornecedor serve hoje |

A execução noturna é a que as pessoas esquecem. A aula 19 perguntou a cada fornecedor se uma versão
do modelo pode ser fixada, porque um modelo hospedado pode mudar por baixo do assistente, e nada no
repositório muda quando isso acontece. **O único jeito de perceber é medir de novo o que está
implantado, numa agenda**, e comparar com o teto, exatamente como o monitoramento da aula 22 compara
uma hora com as horas anteriores.

## A chave de que a verificação do modelo precisa

A suíte não precisa de segredo, então pode rodar no pull request de qualquer pessoa. A verificação
do modelo precisa da chave do fornecedor quando o modelo é hospedado, e as regras da aula 17 valem
para o build como para qualquer outro programa: **uma chave só dele, restrita a um modelo, com
limite de gasto**. Ela fica no cofre de segredos do sistema de CI e não no repositório, e só é
entregue a jobs que rodam código que alguém com permissão de escrita já aceitou. Um pull request
vindo de um fork que pudesse imprimir a chave no próprio log de build é o vazamento de que a aula 17
tratou, com o sistema de CI como mensageiro.

A verificação de taxa também custa dinheiro a cada execução. As 240 chamadas dela custam menos de um
real aos preços da aula 18; 240 chamadas a cada push de cada branch, num repositório movimentado,
são uma linha de orçamento que cresce sem ninguém ter decidido isso. Rodá-la só quando os arquivos
que ela mede mudam é a resposta barata, e o teto diário da aula 18 é a rede de segurança.

## O que um build vermelho significa

Toda falha desta suíte nomeia a sua correção: aprovar o arquivo, terminar o chamado, medir o
candidato com mais tentativas ou melhorá-lo. **Nenhuma delas é "rodar de novo até ficar verde".**
Nas verificações determinísticas, rodar de novo dá a mesma resposta. Na taxa, rodar de novo com
sementes novas até uma passar é escolher a amostra de que você gostou, que é o mesmo erro de relatar
uma execução à temperatura 0, cometido de propósito.
