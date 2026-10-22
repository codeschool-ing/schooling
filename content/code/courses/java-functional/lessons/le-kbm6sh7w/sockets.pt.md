---
title: Um socket é um cano de bytes
version: 1
---

**Um socket TCP é uma conexão entre dois programas que leva bytes nos dois sentidos, em ordem, sem perder
nenhum.** Um programa escuta numa porta com um `ServerSocket`; outro se conecta a essa porta com um
`Socket`; cada ponta então tem um `InputStream` e um `OutputStream`, os streams de bytes da aula 19, e o que
passa por eles é assunto dos dois programas. Este faz os dois papéis, um servidor numa thread virtual e um
cliente na `main`, para um único comando mostrar a conversa inteira:

```java
// Echo.java: a server and a client talking over a TCP socket on this machine
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.UncheckedIOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.List;

public class Echo {
    public static void main(String[] args) throws IOException, InterruptedException {
        try (ServerSocket server = new ServerSocket(0)) {
            Thread serving = Thread.ofVirtual().start(() -> serve(server));
            try (Socket socket = new Socket("127.0.0.1", server.getLocalPort());
                 PrintWriter out = new PrintWriter(socket.getOutputStream(), true, StandardCharsets.UTF_8);
                 BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8))) {
                for (String line : List.of("hello", "sertão", "bye")) {
                    out.println(line);
                    System.out.println("client: sent " + line + ", got " + in.readLine());
                }
            }
            serving.join();
        }
    }

    static void serve(ServerSocket server) {
        try (Socket client = server.accept();
             BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));
             PrintWriter out = new PrintWriter(client.getOutputStream(), true, StandardCharsets.UTF_8)) {
            System.out.println("server: a client connected");
            String line;
            while ((line = in.readLine()) != null) {
                out.println(line.toUpperCase());
            }
            System.out.println("server: the client closed the connection");
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
```

```
ana@vm:~/fp/net$ java Echo.java
server: a client connected
client: sent hello, got HELLO
client: sent sertão, got SERTÃO
client: sent bye, got BYE
server: the client closed the connection
```

## O que atravessou a conexão

`new ServerSocket(0)` pediu ao sistema operacional qualquer porta livre, e o `getLocalPort` disse ao
cliente qual ele ganhou. **O `accept` esperou até um cliente se conectar** e devolveu um `Socket` para
aquele cliente; um servidor de verdade o chama num laço e entrega cada socket a uma thread própria, que é
exatamente o trabalho para o qual as threads virtuais foram feitas na aula 17.

O socket levou bytes, e cada ponta os embrulhou como a aula 19 disse que seria preciso: um
`InputStreamReader` para ler e um `PrintWriter` para escrever, **com UTF-8 dito nas duas pontas**, então
`sertão` atravessou como sete bytes e uma quebra de linha, e voltou como `SERTÃO`. Se as duas pontas
tivessem dito codificações diferentes, a palavra teria atravessado com o mesmo silêncio e voltado errada.

Dois detalhes evitam que a conversa trave. O `true` em `new PrintWriter(..., true, ...)` esvazia o buffer a
cada `println`, então uma linha é enviada quando é escrita e não quando um buffer enche; sem ele o cliente
esperaria a resposta a uma linha ainda parada no próprio buffer. E o laço do servidor termina quando o
`readLine` devolve `null`, que é o que acontece **quando a outra ponta fecha a conexão**: fechar o socket do
cliente no fim do seu `try` foi como o servidor soube que a conversa tinha acabado.

Tudo aqui ficou em `127.0.0.1`, o endereço que toda máquina tem para si mesma, que nenhuma outra máquina
alcança. Um servidor que deve ser alcançável de outros lugares escuta em outro endereço, e é nesse momento
que ele precisa dos cuidados de que tratam o resto desta aula e as três últimas aulas.
