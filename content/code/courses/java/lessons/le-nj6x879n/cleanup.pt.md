---
title: Fazer a limpeza, e o método que nunca foi chamado
version: 1
---

O coletor recupera memória. Um objeto pode guardar coisas que não são memória: um arquivo aberto, uma
conexão de rede, um bloqueio numa linha do banco de dados. **Nada na coleta de lixo fecha essas
coisas**, e a primeira resposta do Java para isso, um método que o coletor chamaria num objeto antes
de liberá-lo, acabou sendo um dos erros conhecidos da linguagem. Vale uma seção saber por quê, porque
código antigo está cheio dele.

## `finalize`, depreciado para remoção

Toda classe herda de `Object` um método `finalize()`, e uma classe podia sobrescrevê-lo esperando que
o coletor o chamasse na saída. `Tidy` faz isso:

```java
// Tidy.java
public class Tidy {
    @Override
    protected void finalize() {
        System.out.println("finalize ran");
    }

    public static void main(String[] args) {
        new Tidy();
        System.out.println("main ends");
    }
}
```
```
ana@vm:~/lifecycle$ javac Tidy.java
Tidy.java:4: warning: [removal] finalize() in Object has been deprecated and marked for removal
    protected void finalize() {
                   ^
1 warning
ana@vm:~/lifecycle$ java Tidy
main ends
```

Duas coisas deram errado, e só uma foi anunciada.

**O compilador avisou**, sem ninguém pedir: o `finalize()` está depreciado e **marcado para remoção**
desde o Java 18, então um JDK futuro nem vai chamá-lo. Um aviso `[removal]` é o tipo mais forte de
depreciação, e a lição 39 mostra como uma biblioteca marca assim um método seu.

**E o programa imprimiu `main ends` e mais nada.** O objeto virou lixo na mesma linha em que foi
criado, e o `finalize` nunca rodou: o programa terminou antes de o coletor ter algum motivo para
rodar, e a JVM não coleta o heap na saída. Esse é o defeito de projeto numa linha de saída.
**Ninguém sabe quando, nem se, um finalizador roda**, então não se pode confiar nele para fechar um
arquivo que outra parte do programa quer abrir, nem para soltar um bloqueio por que outro usuário
está esperando.

## O que o substituiu

Duas coisas, para duas situações:

- **Feche você mesmo, num ponto conhecido.** Uma classe que guarda algo a ser liberado implementa um
  método `close()`, e o código que o abriu chama `close()` quando termina, o que o Java torna difícil
  de esquecer com o `try`-with-resources. Essa é a lição 37, e é a resposta quase sempre.
- **`java.lang.ref.Cleaner`, como rede de segurança.** Um `Cleaner` executa uma ação depois que um
  objeto ficou inalcançável, e, ao contrário do `finalize`, a ação não consegue trazer o objeto de
  volta à vida. Ele tem a mesma incerteza sobre o *quando*, então é um recurso de reserva para algo
  que alguém esqueceu de fechar, nunca o jeito principal de fechar.

**A regra que esta lição deixa é a mesma regra duas vezes**: a memória é assunto do coletor e não
precisa de nada de você, e tudo o mais que um objeto guarda é seu para liberar num momento que você
escolhe.
