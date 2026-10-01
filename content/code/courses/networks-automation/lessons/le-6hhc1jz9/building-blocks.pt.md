---
title: Containers, listas e folhas
version: 1
---

Quatro tipos de nó constroem quase todo modelo:

- Um **container** agrupa nós e não guarda valor nenhum: `interfaces`.
- Uma **lista** guarda entradas, cada uma identificada pela sua **chave**: `interface`, com chave
  `name`. Duas entradas com a mesma chave não podem existir, e foi isso que fez a API do
  laboratório responder `409` na aula 2 e é o que permite a uma URL RESTCONF escrever
  `interface=eth1`.
- Uma **folha** guarda um valor de um tipo: `description`.
- Uma **leaf-list** guarda vários valores de um tipo, sem chave própria: uma lista de servidores
  DNS, por exemplo.

O tipo de uma folha pode carregar restrições, e essas são as regras que um equipamento aplica.
Aqui está a folha que a aula 3 quebrou com um tamanho de prefixo 33, no código-fonte do `ietf-ip`:

```
ana@ctl:~$ grep -n -B2 -A10 "leaf prefix-length {" ietf/ietf-ip.yang | head -13
212-             if the server supports non-contiguous netmasks, as
213-             a netmask.";
214:          leaf prefix-length {
215-            type uint8 {
216-              range "0..32";
217-            }
218-            description
219-              "The length of the subnet prefix.";
220-          }
221-          leaf netmask {
222-            if-feature ipv4-non-contiguous-netmasks;
223-            type yang:dotted-quad;
224-            description
```

`uint8` é um inteiro sem sinal de 8 bits, de 0 a 255, e **`range "0..32"` o restringe aos valores
que um tamanho de prefixo IPv4 pode ter**. Nada mais no modelo ou no equipamento precisou ser
escrito para o `nc1` recusar 33: o Clixon leu aquela linha, e a mensagem de erro que ele imprimiu
na aula 3 citava o range e o arquivo.

As outras restrições que um tipo pode carregar seguem a mesma ideia:

| restrição | em | exemplo |
|---|---|---|
| `range` | números | `range "1..999"` |
| `length` | strings | `length "1..32"` |
| `pattern` | strings, como expressão regular | aquilo de que `inet:ipv4-prefix` é feito |
| `enumeration` | um conjunto fixo de palavras | `enum planned; enum active;` |

Duas estruturas ficam em volta dos nós. Um **choice** diz que exatamente uma de várias
alternativas pode estar presente: o `subnet` do `ietf-ip` é ou `prefix-length` ou `netmask`,
nunca os dois. Um **typedef** dá nome a um tipo restrito para que ele possa ser reutilizado;
`inet:ipv4-address` é um deles, definido uma vez no `ietf-inet-types` e usado nos outros módulos
do IETF.
