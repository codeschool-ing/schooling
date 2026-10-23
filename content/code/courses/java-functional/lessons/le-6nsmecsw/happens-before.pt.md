---
title: Happens-before
version: 1
---

**O modelo de memória do Java é um conjunto de regras sobre quais escritas uma leitura pode ver.** A
ideia central é uma relação chamada **happens-before** (acontece-antes): se a ação A acontece-antes da
ação B, então tudo o que A escreveu é visível para B, e B não pode parecer ter rodado antes de A.
Quando duas ações em threads diferentes não têm happens-before entre elas, e pelo menos uma escreve
numa variável que a outra toca, o programa tem uma **condição de corrida de dados** (data race), e o
modelo não promete quase nada sobre o que é lido.

A relação é criada por uma lista curta de coisas, e cada ferramenta de concorrência do Java é uma
delas:

| isto | acontece-antes de | então |
|---|---|---|
| uma ação numa thread | toda ação posterior na mesma thread | uma thread vê o próprio trabalho em ordem |
| `t.start()` | toda ação em `t` | a thread nova vê o que foi escrito antes de ela começar |
| toda ação em `t` | o retorno de outra thread de `t.join()` | depois do `join`, quem chamou vê todos os resultados da thread |
| liberar um lock (saída de `synchronized`, `unlock`) | a próxima aquisição do mesmo lock | aula 14 |
| uma escrita num campo `volatile` | toda leitura posterior desse campo | aula 13 |
| o fim das escritas de um construtor em campos `final` | qualquer thread que veja o objeto | seção 05 |
| pôr numa coleção concorrente, completar um `Future` | tirar de lá, ler o resultado | aulas 15 e 16 |

A relação é **transitiva**: se A acontece-antes de B e B acontece-antes de C, então A acontece-antes
de C. É isso que deixa uma escrita `volatile` publicar todo um lote de escritas comuns feitas antes
dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas linhas do tempo, a thread A em cima e a thread B embaixo. Em A, x = 1 vem antes da liberação de um lock. Em B, a aquisição do mesmo lock vem antes da leitura de x. Uma seta da liberação até a aquisição é a aresta happens-before, e como a relação é transitiva, x = 1 acontece-antes da leitura, que vê 1.\"><defs><marker id=\"hb-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"hb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread A</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">thread B</text><path d=\"M90 40 L116 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M440 40 L700 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M90 150 L326 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M680 150 L700 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><rect x=\"120\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">x = 1</text><rect x=\"300\" y=\"22\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">libera o lock</text><rect x=\"330\" y=\"132\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">obtém o lock</text><rect x=\"540\" y=\"132\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">r = x  // 1</text><path d=\"M240 40 L296 40\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#hb-ah-paperdim)\"></path><path d=\"M370 58 L400 128\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#hb-ah-phosphor)\"></path><path d=\"M470 150 L536 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#hb-ah-paperdim)\"></path><text x=\"460\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">happens-before</text></svg>", "caption": "Uma aresta entre threads, mais a ordem dentro de cada thread, ordena tudo o que vem antes com tudo o que vem depois.", "same": ["thread A", "thread B"]}
```

## Por que o `join` bastou na aula 11

Todo programa da aula 11 tinha threads escrevendo resultados que a `main` imprimia depois, sem
`volatile` e sem lock, e eles estavam certos. **O `join` cria uma aresta happens-before**: tudo o que a
thread fez fica visível para a thread que voltou do `join`. O mesmo vale para o `start`, no sentido
contrário, e é por isso que um lambda pode ler os valores que a sua thread recebeu antes do `start`.

```java
// Joined.java: a plain field, made visible by join
public class Joined {
    static long total;

    public static void main(String[] args) throws InterruptedException {
        Thread adder = new Thread(() -> {
            for (int i = 1; i <= 1_000_000; i++) {
                total += i;
            }
        });
        adder.start();
        adder.join();
        System.out.println("total after join: " + total);
    }
}
```

```
ana@vm:~/fp/memory$ java Joined.java
total after join: 500000500000
```

`total` é um campo comum escrito por uma thread e lido por outra, e a resposta sai certa toda vez,
porque a leitura vem depois do `join`. Tire o `join` e o programa tem uma condição de corrida: a `main`
pode imprimir 0, uma soma parcial ou a completa. **Um programa concorrente correto é aquele em que todo
par de acessos conflitantes está ordenado por happens-before**; o resto das aulas de concorrência deste
curso são os jeitos de arranjar isso.
