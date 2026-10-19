---
title: Flags de um tipo seu
version: 1
---

`String`, `Int`, `Bool` e `Duration` cobrem a maioria das configurações, até que um programa
precisa de uma flag que pode ser dada duas vezes, ou de um número que tem de ser uma porta, ou de
um endereço. **`flag.Var` aceita qualquer tipo com dois métodos, `String` e `Set`**, e duas formas
mais curtas cobrem os casos comuns: `flag.Func`, para uma verificação escrita como função, e
`flag.TextVar`, para qualquer tipo que já sabe se ler de um texto. O programa abaixo usa uma de
cada, salvo como `tags/main.go`:

```schooling-example
{"language": "go", "file": "tags/main.go", "parts": [{"code": "// Command tags reads a repeatable flag, a checked number and an address.\npackage main\n\nimport (\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"net/netip\"\n\t\"strconv\"\n\t\"strings\"\n)\n\n", "note": "Três pacotes além de `flag`: `netip` para o endereço, `strconv` e `errors` para a verificação da porta."}, {"code": "// list collects every -tag it is given, in order.\ntype list []string\n\nfunc (l *list) String() string     { return strings.Join(*l, \",\") }\nfunc (l *list) Set(s string) error { *l = append(*l, s); return nil }\n\n", "note": "**`list` é um `flag.Value`: `Set` é chamado uma vez para cada vez que a flag aparece**, então ele acrescenta em vez de substituir. `String` é o que a ajuda mostra como padrão."}, {"code": "func main() {\n\tvar tags list\n\tflag.Var(&tags, \"tag\", \"a tag; repeat the flag for more\")\n\n", "note": "`flag.Var` registra a flag sem padrão próprio: o valor começa como o que `tags` já era, uma lista vazia."}, {"code": "\tport := 8080\n\tflag.Func(\"port\", \"TCP port, 1 to 65535 (default 8080)\", func(s string) error {\n\t\tn, err := strconv.Atoi(s)\n\t\tif err != nil || n < 1 || n > 65535 {\n\t\t\treturn errors.New(\"not a port\")\n\t\t}\n\t\tport = n\n\t\treturn nil\n\t})\n\n", "note": "`flag.Func` é um `Set` sem um tipo onde pendurá-lo. A função recebe o texto cru, e um erro que ela devolve vira a mensagem que o `Parse` imprime. O padrão mora na variável e no texto de ajuda, porque o pacote flag nunca o vê."}, {"code": "\tvar addr netip.Addr\n\tflag.TextVar(&addr, \"addr\", netip.MustParseAddr(\"127.0.0.1\"), \"address to listen on\")\n\tflag.Parse()\n\n", "note": "**`flag.TextVar` aceita qualquer tipo com um método `UnmarshalText`**, e `netip.Addr` tem um. O endereço é lido e conferido pelo tipo dono das regras, não por este programa."}, {"code": "\tfmt.Println(\"tags:\", tags, len(tags))\n\tfmt.Println(\"listen:\", netip.AddrPortFrom(addr, uint16(port)))\n}\n", "note": "`netip.AddrPortFrom` junta os dois num valor só, que é impresso como endereço e porta."}]}
```

A flag dada duas vezes juntou os dois valores, a porta e o endereço chegaram como valores com tipo,
e sem flag nenhuma os padrões ficaram:

```
ana@vm:~/flags$ bin/tags -tag go -tag concurrency -port 9000 -addr 192.0.2.10
tags: [go concurrency] 2
listen: 192.0.2.10:9000
ana@vm:~/flags$ bin/tags
tags: [] 0
listen: 127.0.0.1:8080
```

**Um valor recusado é recusado com o motivo que o programa deu**: `not a port` é o erro que a
função devolveu, e o texto de uso e o status 2 vêm exatamente como para uma flag embutida. O
endereço foi conferido pelo `netip`, cuja mensagem diz qual campo está errado:

```
ana@vm:~/flags$ bin/tags -port 70000; echo $?
invalid value "70000" for flag -port: not a port
Usage of bin/tags:
  -addr value
    	address to listen on (default 127.0.0.1)
  -port value
    	TCP port, 1 to 65535 (default 8080)
  -tag value
    	a tag; repeat the flag for more
2
ana@vm:~/flags$ bin/tags -addr 192.0.2.300 2>&1 | head -1
invalid value "192.0.2.300" for flag -addr: ParseAddr("192.0.2.300"): IPv4 field has value >255
```

O `2>&1 | head -1` guarda só a primeira linha, porque o texto de uso depois dela é o mesmo de
cima.

Duas escolhas desse programa valem a cópia. A verificação mora na borda, então tudo depois do
`Parse` pode confiar que `port` é uma porta. E **um tipo que já se lê sozinho é usado em vez de lido
de novo à mão**: uma verificação de endereço IPv4 escrita à mão é um lugar clássico para um bug, e
o `netip` já foi escrito.
