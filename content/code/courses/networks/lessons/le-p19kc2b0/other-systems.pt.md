---
title: As mesmas ferramentas no Windows e no macOS
version: 1
---

O `curl` está em todo sistema hoje, e isso torna os comandos desta aula portáveis:

```sh
curl.exe -sv -o NUL https://www.example.com/          # Windows 10 and later ship curl as curl.exe
Invoke-WebRequest https://www.example.com/ -Method Head   # Windows PowerShell: status and headers
curl -sv -o /dev/null https://www.example.com/        # macOS: curl is built in
```

**Nenhum deles foi rodado para esta aula.** No Windows, digite `curl.exe` em vez de `curl`: no
Windows PowerShell 5.1, `curl` é um apelido do `Invoke-WebRequest`, que aceita outras opções e imprime
de outro jeito (o PowerShell 7 tirou o apelido). Todo temporizador `-w` da seção 07 funciona no
`curl.exe` também, com as aspas do Windows.

No navegador, a aba *Rede* das ferramentas de desenvolvedor, tratada no curso web-fundamentals, mostra
as mesmas coisas por pedido: o status, os cabeçalhos, o protocolo (`h2`), e uma barra de tempo
dividida em DNS, conexão, TLS e espera pelo servidor.
