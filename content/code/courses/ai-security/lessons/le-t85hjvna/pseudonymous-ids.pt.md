---
title: Um identificador que não identifica ninguém lá fora
version: 1
---

O primeiro identificador que vem à cabeça é o que a aplicação já tem para todo mundo: o e-mail.
Enviá-lo poria um dado pessoal em cada requisição, para uma finalidade de que o fornecedor não precisa,
que é exatamente o que o princípio da necessidade da aula 22 proíbe. A segunda ideia é fazer o hash do
endereço antes, e **o hash de um e-mail pode ser revertido por qualquer um capaz de adivinhar
e-mails**:

```
ana@lab:~/guard$ guard enduser --naive marcos.teixeira@example.com.br
e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894
ana@lab:~/guard$ head -3 data/emails.txt; wc -l data/emails.txt
ana.almeida@example.com.br
ana.barros@example.com.br
ana.costa@example.com.br
400 data/emails.txt
ana@lab:~/guard$ guard reverse e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894 --list data/emails.txt
found after 257 guesses: marcos.teixeira@example.com.br
```

Um SHA-256 não pode ser invertido, e não precisa ser. O `guard reverse` faz o hash de cada endereço de
uma lista e compara, e a lista aqui é só cada primeiro nome comum com cada sobrenome comum, num domínio.
O endereço foi o 257º palpite. Atacantes de verdade usam listas de milhões de endereços de vazamentos
anteriores, e um computador moderno calcula milhões de SHA-256 por segundo. O hash acrescenta um
passo, e nenhum segredo.

## Um hash com chave

O conserto é fazer o hash depender de algo que o atacante não tem. Um **HMAC** é um hash calculado com
uma chave secreta misturada, de modo que calculá-lo, e portanto conferir um palpite, exige a chave. A
versão do laboratório tem dez linhas:

```schooling-example
{"language": "python", "file": "guardlab/enduser.py", "parts": [{"code": "import hashlib\nimport hmac\n", "note": "Os dois módulos estão na biblioteca padrão do Python. O `hmac` é o que importa aqui."}, {"code": "\n\ndef end_user_id(account, key):\n    digest = hmac.new(key, account.encode(), hashlib.sha256).hexdigest()\n    return \"eu-\" + digest[:20]\n", "note": "A entrada é o id interno da conta na Tarefa, não o e-mail, então o id sobrevive a uma troca de endereço. A chave é o segredo. Vinte caracteres hexadecimais são 80 bits: nenhuma de milhões de contas vai colidir, e o id ainda cabe numa linha de log."}, {"code": "\n\ndef naive_id(email):\n    return hashlib.sha256(email.strip().lower().encode()).hexdigest()\n", "note": "A versão contra a qual esta seção argumenta, mantida para o laboratório poder revertê-la."}]}
```

Três execuções mostram as propriedades que importam:

```
ana@lab:~/guard$ guard enduser ac-7Q2M
eu-fe47aa8e7cd5e1b6f8bc
ana@lab:~/guard$ guard enduser ac-9D4H
eu-ac8948151bbc5139ccb1
ana@lab:~/guard$ guard enduser ac-7Q2M --provider provider-b
eu-4805e698e5809587d84d
ana@lab:~/guard$ guard reverse eu-fe47aa8e7cd5e1b6f8bc --list data/emails.txt; echo "exit $?"
not found in 400 guesses
exit 1
```

- **Estável.** `ac-7Q2M` dá `eu-fe47aa8e7cd5e1b6f8bc` em toda chamada, então o fornecedor consegue ver
  que quarenta requisições ruins vieram de uma pessoa, e a Tarefa consegue ligar o identificador à
  conta calculando-o de novo.
- **Diferente por fornecedor.** Com a chave do `provider-b`, a mesma conta vira
  `eu-4805e698e5809587d84d`. Se a Tarefa usa dois fornecedores e os dois vazam, ou os dois têm os
  registros requisitados, os dois conjuntos de identificadores não podem ser cruzados.
- **Irreversível sem a chave.** O dicionário que achou o hash simples não acha nada.

As chaves do laboratório são texto fixo em `keys/`, para que estas capturas imprimam os mesmos
identificadores toda vez. Uma chave de verdade é aleatória, tem pelo menos 32 bytes e fica no mesmo
cofre de segredos que a própria chave de API, nunca num arquivo ao lado do código.

## O que a chave decide

Duas consequências práticas vêm de o identificador depender de uma chave.

**Trocar a chave muda todo identificador.** Depois de uma troca, o fornecedor vê um conjunto novo de
usuários, e qualquer histórico de abuso que ele tenha atribuído aos identificadores antigos fica
solto. Às vezes é o que você quer, depois de a chave vazar, e em geral não é. Troque quando a chave
puder estar comprometida, e não por calendário.

**O identificador ainda é dado pessoal na Tarefa**, pelo raciocínio da aula 22: a Tarefa tem a chave,
então para ela o dado é pseudonimizado. Ele vai nos logs da aula 21 no lugar do e-mail. E, depois que
uma conta é eliminada, os identificadores que o fornecedor guarda apontam para uma conta que não existe
mais, então não identificam ninguém, nem para a Tarefa nem para outra pessoa.
