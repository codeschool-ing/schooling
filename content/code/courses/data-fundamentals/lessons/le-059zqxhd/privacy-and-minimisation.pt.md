---
title: Coletando só o que a pergunta precisa
version: 1
---

**Cada coluna de dado pessoal que você coleta é algo que depois você precisa proteger, explicar,
entregar quando o titular pede, e responder por ela se vazar.** Então o que coletar é decidido pelo que a
pergunta precisa, e nada além disso.

Isso também é a lei. A **LGPD**, a Lei Geral de Proteção de Dados (Lei 13.709, de 2018), lista os seus
princípios no artigo 6, e dois deles decidem a coleta. **Finalidade**: o dado pessoal é tratado para um
propósito legítimo, específico e informado ao titular. **Necessidade**: não mais dele do que esse
propósito exige. A ANPD, a Autoridade Nacional de Proteção de Dados, fiscaliza. Uma coluna coletada
"caso seja útil um dia" ainda não tem finalidade, e reprova no primeiro teste antes que alguém a leia.

## Três jeitos de precisar de menos

O modelo de demanda de Caio precisa de viagens por estação por hora. A tabela de viagens guarda muito
mais: o cliente, o telefone dele, o segundo exato, o cartão usado para pagar. Antes de copiar qualquer
coisa:

- **deixe de fora** o que nenhuma pergunta precisa. O modelo nunca lê o telefone nem o cartão, então a
  cópia não os tem;
- **reduza a precisão** do que só é preciso de forma aproximada. Viagens por hora precisam da hora, não
  do segundo; da faixa de idade do cliente, não da data de nascimento;
- **pseudonimize** o que só é preciso para distinguir pessoas. Contar viagens por cliente exige saber
  que duas viagens foram do mesmo cliente, não quem é esse cliente.

## Um hash não é um disfarce

**Pseudonimizar** é trocar um identificador por um substituto que é sempre o mesmo para a mesma pessoa,
para que junções e contagens continuem funcionando, e que não pode ser revertido sem algo guardado longe
do dado. O erro comum é achar que um hash simples faz isso. **Um hash simples de um número de telefone é
o mesmo número disfarçado**, por dois motivos.

O primeiro é que qualquer um consegue calculá-lo. O SHA-256 não tem segredo nenhum, então um parceiro
com uma lista de números de telefone pode passar a lista pelo hash e procurar coincidências na sua coluna
"anônima". O segundo é que não existem tantos números de telefone. Um celular em Curitiba é `+55 41 9`
seguido de oito dígitos: cem milhões de candidatos, uma lista curta o bastante para passar inteira pelo
hash e guardar, depois do que todo hash simples de um celular de Curitiba pode ser consultado.

Um **hash com chave** resolve os dois. O HMAC mistura uma chave secreta ao hash, então sem a chave
ninguém consegue calcular o substituto de um número, e uma lista de palpites não coincide com nada. O
programa abaixo pseudonimiza três clientes dos dois jeitos, e depois faz o papel do parceiro: passa a
própria lista de números pelo SHA-256 simples, o único jeito que ele tem, e procura por eles. A chave é
lida do ambiente, nunca escrita no programa, que é como um segredo fica fora do código. Salve como
`collect/pseudo.py`:

```python
# collect/pseudo.py
import hashlib
import hmac
import os

KEY = os.environ["RODA_PSEUDO_KEY"].encode()    # kept apart from the code and the data


def plain(phone):
    return hashlib.sha256(phone.encode()).hexdigest()[:16]


def keyed(phone):
    return hmac.new(KEY, phone.encode(), hashlib.sha256).hexdigest()[:16]


customers = {"C0001": "+5541900000101", "C0002": "+5541900000202",
             "C0003": "+5541900000303"}
print("customer  plain hash        keyed hash")
for customer, phone in customers.items():
    print(f"{customer}     {plain(phone)}  {keyed(phone)}")

# a partner has its own list of phone numbers, and no key
partner = ["+5541900000202", "+5541900000999", "+5541900000303"]
guesses = {plain(p) for p in partner}
print("partner's guesses found among plain hashes:",
      sum(plain(p) in guesses for p in customers.values()))
print("partner's guesses found among keyed hashes:",
      sum(keyed(p) in guesses for p in customers.values()))
```

No laboratório, a chave é um valor que você digita; na Roda Livre, ela fica num cofre de segredos,
legível pelo pipeline e por mais ninguém:

```
ana@lab:~/roda/collect$ RODA_PSEUDO_KEY=lab-key-not-a-secret python pseudo.py
customer  plain hash        keyed hash
C0001     727cde8c0392b39e  bdda5187e6a17a41
C0002     cb072d5af983448a  957123a6462942b7
C0003     4b1e901121ca526b  4c0a9b09f320c5b1
partner's guesses found among plain hashes: 2
partner's guesses found among keyed hashes: 0
```

**Dois dos três números do parceiro são encontrados entre os hashes simples, e nenhum entre os hashes
com chave.** O parceiro agora sabe que dois clientes dele andam na Roda Livre, a partir de uma coluna que
não tinha número de telefone nenhum.

## Continua sendo dado pessoal

Um hash com chave é um pseudônimo, não uma anonimização. Quem tem a chave consegue calcular o substituto
de qualquer número e religá-lo, e a definição de dado anonimizado da LGPD, no artigo 12, exclui o dado
que pode ser reidentificado por meios razoáveis. Então a cópia pseudonimizada continua sendo dado
pessoal, com tudo o que isso implica: precisa de finalidade, é protegida, e é apagada quando o titular
pede. Pseudonimizar diminui o estrago de um vazamento; não tira o dado da lei.

A chave agora é a coisa mais sensível do pipeline. Perca-a e os pseudônimos nunca mais poderão ser
religados; troque-a e todo substituto muda, então os clientes deste ano deixam de se juntar aos do ano
passado. As duas são decisões a tomar antes da primeira cópia, com quem responde pela privacidade na
empresa, o que na Roda Livre é uma pergunta que Davi leva aos fundadores em vez de resolver sozinho.
