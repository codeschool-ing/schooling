---
title: Senhas, guardadas como bcrypt e conferidas uma vez
version: 1
---

A imagem comum de um cadastro de senhas é uma tabela de senhas cifradas, que o servidor decifra para
comparar com o que foi digitado. O que o servidor consegue decifrar, quem copia os dados e a chave dele
também consegue. Um servidor nunca precisa ler uma senha de volta. Ele só precisa conferi-la, então
guarda um **hash**: a saída de uma função de mão única, da qual a senha não pode ser calculada.

Não qualquer hash. O SHA-256 foi feito para ser barato, e barato é o que quer quem tenta adivinhar
senhas numa tabela roubada: cada palpite custa um hash. Um **hash de senha** é caro de propósito, e o
**bcrypt** é o que o Spring Security usa por padrão. Estes são os dois guardados no `SecurityConfig`:

```
{bcrypt}$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG
{bcrypt}$2a$10$IhwPr4UgX7fq7bh90QHtOeHgfrzp1Ut63qywnXNfc3YgBAKgO76hS
```

Cada um leva tudo o que é preciso para conferir uma senha contra ele, em cinco pedaços:

| pedaço | no da ana | o que é |
|---|---|---|
| `{bcrypt}` | `{bcrypt}` | um rótulo do Spring, não do bcrypt: qual codificador confere este hash |
| `$2a$` | `$2a$` | a versão do bcrypt |
| `10$` | `10$` | o **custo**: 2¹⁰ rodadas do passo caro do bcrypt; 11 dobra o tempo |
| 22 caracteres | `ZGOqa4SybKybYWez.kObuO` | o **sal**, aleatório a cada hash |
| 31 caracteres | `lRJidwtH0M8N11oKrIWVxl4mA422MiG` | o hash do sal com a senha |

## Fazendo um hash

Os dois hashes vieram de um programa curto. Ele fica no seu diretório pessoal e não no projeto, porque
é uma ferramenta que você roda uma vez, não parte da livraria. Crie `~/HashPassword.java`:

```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class HashPassword {
    public static void main(String[] args) {
        BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder();
        String hash = bcrypt.encode(args[0]);
        System.out.println(hash);
        System.out.println("matches its own hash: " + bcrypt.matches(args[0], hash));
        if (args.length > 1) {
            System.out.println("matches the hash given: " + bcrypt.matches(args[0], args[1]));
        }
    }
}
```

Ele precisa do `spring-security-crypto` e da biblioteca de log pela qual esse jar escreve. Os dois já
estão no `~/.m2`, e o plugin de dependências da aula 1 sabe escrever o classpath inteiro do projeto num
arquivo, que o `java` então lê. Rode o programa duas vezes com a mesma senha, e na segunda passe também
o hash guardado da ana. O `cd` sem argumento volta para o seu diretório pessoal:

```
ana@vm:~/bookshop$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt
ana@vm:~$ java -cp "$(cat bookshop/cp.txt)" HashPassword.java ana-reads-books
$2a$10$DJb4Yi9p3JRJ7npM1TZxteGJDauIkBKZYZY0fl/493FyqKq4XBWW6
matches its own hash: true
ana@vm:~$ java -cp "$(cat bookshop/cp.txt)" HashPassword.java ana-reads-books '$2a$10$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG'
$2a$10$cdk7/w3ZVeMjBIJTWFk22eJZgPVl0KD8qpp1hfNKoxtCRmmGXCarW
matches its own hash: true
matches the hash given: true
```

**A mesma senha deu dois hashes diferentes, e cada um confere.** O sal muda, e o sal está dentro do
hash, então o `matches` o lê de volta e calcula o hash do candidato com ele. O hash guardado da ana,
feito em outro dia com um terceiro sal, também confere. O sal é o que torna inútil uma tabela
pré-calculada de senhas comuns, e o que impede que dois usuários com a mesma senha tenham o mesmo hash,
o que contaria isso a quem lesse a tabela.

Uma senha digitada na linha de comando vai para o histórico do shell. Isso é aceitável para as duas
senhas da livraria, que esta aula imprime de qualquer jeito; para uma senha de verdade, leia com
`System.console().readPassword()`, que também não a mostra na tela.

O prefixo é a outra metade. O `PasswordEncoderFactories.createDelegatingPasswordEncoder()` monta um
codificador que lê `{bcrypt}`, `{argon2}`, `{pbkdf2}` e mais alguns, e passa cada hash ao codificador
que o prefixo nomeia. **O texto guardado diz como ele foi feito**, então um sistema pode adotar um
algoritmo mais novo para senhas novas enquanto todo hash antigo continua valendo até o dono entrar de
novo.

## Lento de propósito, e por isso conferido uma vez

O **HTTP Basic** manda usuário e senha num cabeçalho `Authorization` em toda requisição, em base64, que
é uma codificação e não cifra: quem vê a requisição lê a senha. Basic só é aceitável sobre HTTPS, e a
livraria deste curso responde HTTP puro em `localhost`, onde nada atravessa uma rede.

Ele também custaria uma verificação bcrypt em toda requisição. Eis esse custo, medido: cinco pedidos
de token, que rodam o bcrypt, e depois cinco requisições levando um token, que não rodam:

```
ana@vm:~/bookshop$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{time_total}\n' -u ana:ana-reads-books -X POST localhost:8080/auth/token; done
0.068564
0.067145
0.067239
0.069804
0.069891
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{time_total}\n' -H "Authorization: Bearer $(cat ana.token)" localhost:8080/books/1; done
0.047668
0.009704
0.007936
0.007902
0.007915
```

Os números são segundos por requisição e mudam a cada execução, mas a forma não muda: cerca de 0.068
com bcrypt, e cerca de 0.008 com um token depois que a primeira requisição aquece. Essa lentidão é a
proteção, e ninguém quer pagá-la em toda requisição. Então a livraria pede a senha uma vez, em
`/auth/token`, e responde com um token que toda requisição seguinte leva no lugar dela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 360\" role=\"img\" aria-label=\"Uma sequência entre o cliente da ana e a livraria. Primeiro, POST /auth/token com HTTP Basic: o servidor confere a senha com bcrypt e responde com um token. Depois cada requisição leva o token num cabeçalho bearer, e o servidor confere a assinatura e a validade, sem senha nenhuma. Isso se repete até o token expirar.\"><defs><marker id=\"sq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"130\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o cliente da ana</text><rect x=\"500\" y=\"14\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a livraria</text><line x1=\"210\" y1=\"48\" x2=\"210\" y2=\"350\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"580\" y1=\"48\" x2=\"580\" y2=\"350\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"90\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma vez</text><path d=\"M 210 92 L 578 92\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /auth/token</text><text x=\"395.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Basic YW5h…</text><rect x=\"590\" y=\"96\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"660\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bcrypt: lento de propósito</text><path d=\"M 580 140 L 212 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {&quot;accessToken&quot;:&quot;eyJ…&quot;}</text><path d=\"M 210 200 L 578 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /orders/1</text><text x=\"395.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><rect x=\"590\" y=\"204\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"660\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assinatura e exp: rápido</text><path d=\"M 580 244 L 212 244\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M 210 290 L 578 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST /orders</text><text x=\"395.0\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Authorization: Bearer eyJ…</text><rect x=\"590\" y=\"294\" width=\"140\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"660\" y=\"309\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assinatura e exp: rápido</text><path d=\"M 580 334 L 212 334\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sq-ah)\"></path><text x=\"395.0\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201</text><path d=\"M 188 180 L 178 180 L 178 340 L 188 340\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"168\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">toda requisição, até o exp</text></svg>", "caption": "A senha atravessa a rede uma vez, para obter um token. Toda requisição depois disso leva o token, que o servidor confere sem a senha e sem consultar nada.", "same": []}
```

Uma senha errada recebe 401 e a certa recebe o token:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -u ana:wrong -X POST localhost:8080/auth/token
401
ana@vm:~/bookshop$ curl -si -w '\n' -u ana:ana-reads-books -X POST localhost:8080/auth/token
HTTP/1.1 200 
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Type: application/json
Content-Length: 298
Date: Thu, 22 Oct 2026 22:14:05 GMT

{"accessToken":"eyJraWQiOiJPWk9odmt2Ui1tOVpKOUM3N2xxUm5yN0E0VVMxdk1obkpuR0hLcDl1eGJnIiwiYWxnIjoiSFMyNTYifQ.eyJpc3MiOiJib29rc2hvcCIsInN1YiI6ImFuYSIsImV4cCI6MTc5MjcwODE0NSwiaWF0IjoxNzkyNzA3MjQ1LCJzY29wZSI6Im9yZGVycyJ9.MpSSa089W22PreCSDmsz487vOif-x5m4WV5aRyScMgQ","tokenType":"Bearer","expiresIn":900}
```

Os usuários aqui vivem em memória, no `SecurityConfig`, o que basta para duas contas e é errado para
uma loja. Uma loja de verdade os guarda numa tabela e dá ao Spring Security um `UserDetailsService` que
a lê; o `JdbcUserDetailsManager` é o pronto. A verificação não muda: um hash guardado com seu prefixo,
e o codificador delegante.
