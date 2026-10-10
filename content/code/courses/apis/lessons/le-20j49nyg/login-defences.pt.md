---
title: Um login que não entrega nada
version: 1
---

**Um login que falhou não pode dizer se a conta existe, nem nas palavras nem no tempo.** Um formulário
que responde "usuário inexistente" a um nome e "senha errada" a outro conta a um estranho quem tem
conta, e em alguns serviços só isso já é informação privada.

O `passwords.py` diz "wrong name or password" nos dois casos, e a crença comum é que isso resolve. Não
resolve, porque a resposta também tem uma duração. Um login para um nome que existe roda o Argon2id;
um login que parasse em "linha inexistente" responderia assim que o banco respondesse. Cronometrar
algumas respostas separaria os dois.

Por isso o `login` confere todo nome que falhou contra o `DECOY`, o hash de um texto aleatório feito
quando o programa começa, com os mesmos parâmetros de todos os outros hashes. Quatro logins que
falharam, dois da Ana com senha errada e dois de um nome que não existe:

```
ana@api:~/shelf$ for name in ana nobody ana nobody; do python3 -c "import time, passwords; t = time.perf_counter(); passwords.login('$name', 'not her password'); print('$name', round((time.perf_counter() - t) * 1000), 'ms')"; done
ana 143 ms
nobody 139 ms
ana 139 ms
nobody 130 ms
```

E só a consulta ao banco, que é tudo o que um nome desconhecido custaria se o `login` retornasse
assim que a linha faltasse:

```
ana@api:~/shelf$ python3 -c "import time, passwords; t = time.perf_counter(); passwords.accounts().execute('SELECT * FROM users WHERE name = ?', ('nobody',)).fetchone(); print(round((time.perf_counter() - t) * 1000, 1), 'ms')"
0.6 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Tempo de um login que falhou, medido: ana com senha errada, 143 ms; o nome desconhecido nobody, conferido contra o decoy, 139 ms; só a consulta ao banco, que é tudo o que um nome desconhecido custaria sem o decoy, 0.6 ms.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, senha errada</text><rect x=\"250\" y=\"30\" width=\"371.8\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"629.8\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">143 ms</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, conferido contra o decoy</text><rect x=\"250\" y=\"72\" width=\"361.40000000000003\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"619.4000000000001\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">139 ms</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, se o login voltasse na hora</text><rect x=\"250\" y=\"114\" width=\"2\" height=\"20\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.6 ms</text><line x1=\"250\" y1=\"160\" x2=\"640.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"250.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"250.0\" y1=\"156\" x2=\"250.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"380.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><line x1=\"380.0\" y1=\"156\" x2=\"380.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"510.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"510.0\" y1=\"156\" x2=\"510.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"640.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><line x1=\"640.0\" y1=\"156\" x2=\"640.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"445.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">milissegundos</text></svg>", "caption": "As duas primeiras barras são a resposta que o decoy compra: quem cronometra a resposta não as distingue. A terceira é o que um nome desconhecido custaria sem ele."}
```

Entre 130 e 143 ms nos quatro, contra 0,6 ms sem o decoy. Os poucos milissegundos entre eles são o
ruído comum de uma máquina fazendo outras coisas; um estranho cronometrando respostas pela rede vê
muito mais ruído que isso, e nada do tamanho do hash.

Três detalhes o mantêm honesto:

| detalhe | por quê |
|---|---|
| o decoy usa o `HASHER`, então acompanha qualquer mudança de parâmetros | um decoy feito com os antigos levaria outro tempo |
| o `login` retorna `False` para um nome desconhecido mesmo se o decoy conferisse | não tem como conferir, já que ninguém conhece o texto aleatório, mas o código não depende disso |
| o novo hash só acontece depois de uma senha correta | um login bem-sucedido pode demorar mais; um que falhou não tem nada a revelar |

**O cadastro é a outra porta.** O `passwords.py register` diz que o nome já existe, o que é honesto e,
para uma livraria, aceitável; um serviço em que ter conta já é sensível responde igual a todo cadastro
e manda os detalhes para o endereço informado.

O que esta seção não impede é alguém tentar muitas senhas contra uma conta, ou uma senha contra
muitas. O hash deixa cada tentativa cara para os dois lados, e limitar quantas vezes um cliente pode
tentar é a lição 12.
