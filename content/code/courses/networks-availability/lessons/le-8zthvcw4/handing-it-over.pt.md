---
title: Entregando o arquivo, e apagando
version: 1
---

O servidor raramente tem as ferramentas para analisar uma captura com conforto, e quem vai analisá-la
muitas vezes é outra pessoa. **O arquivo pcap é a unidade que viaja**: tirado no servidor com o
`tcpdump`, aberto em qualquer lugar com o Wireshark ou o `tshark`, byte a byte o mesmo.

O `tshark` por acaso estava instalado em `web1`, então a primeira pergunta do analista pôde ser feita
ali mesmo:

```
ana@web1:~$ tshark -r web1.pcap -q -z http,tree

=======================================================================================================================================
HTTP/Packet Counter:
Topic / Item            Count         Average       Min Val       Max Val       Rate (ms)     Percent       Burst Rate    Burst Start  
---------------------------------------------------------------------------------------------------------------------------------------
Total HTTP Packets      8                                                       0.4302        100%          0.0800        0.000        
 HTTP Response Packets  4                                                       0.2151        50.00%        0.0400        0.000        
  2xx: Success          3                                                       0.1613        75.00%        0.0300        0.000        
   200 OK               3                                                       0.1613        100.00%       0.0300        0.000        
  4xx: Client Error     1                                                       0.0538        25.00%        0.0100        0.000        
   404 Not Found        1                                                       0.0538        100.00%       0.0100        0.000        
  ???: broken           0                                                       0.0000        0.00%         -             -            
  5xx: Server Error     0                                                       0.0000        0.00%         -             -            
  3xx: Redirection      0                                                       0.0000        0.00%         -             -            
  1xx: Informational    0                                                       0.0000        0.00%         -             -            
 HTTP Request Packets   4                                                       0.2151        50.00%        0.0400        0.000        
  GET                   4                                                       0.2151        100.00%       0.0400        0.000        
 Other HTTP Packets     0                                                       0.0000        0.00%         -             -            

---------------------------------------------------------------------------------------------------------------------------------------
```

Oito pacotes HTTP, quatro requisições e quatro respostas: três `200 OK` e um `404 Not Found`, a mesma
contagem que o `grep` deu na seção anterior. **O menu de estatísticas lê um arquivo, então lê um
arquivo vindo de qualquer lugar**, e não precisa de privilégio para isso.

Quando o arquivo viaja, ele vai por algo criptografado, `scp` ou `sftp` da aula 8 de `networks`, e quem
recebe roda o `capinfos` e compara a linha `SHA256` com a tirada no servidor. Nada disso foi rodado
aqui.

## Uma captura é uma cópia dos dados dos outros

**Tudo o que passou pelo fio está no arquivo**, legível por quem conseguir ler o arquivo. Nesta aula
isso foi uma página de teste. Num servidor de verdade é o que os clientes mandaram: conteúdo de
formulários, cookies de sessão, endereços de e-mail, qualquer coisa que um protocolo sem criptografia
leve. Capturar é copiar esses dados, e as obrigações que vêm com dados pessoais vêm com o arquivo.

**Três hábitos mantêm isso proporcional**, e nenhum deles custa nada:

- Capture o mínimo que responde à pergunta: um filtro de captura para o host e a porta em questão, e
  um snap length curto quando só os cabeçalhos importam.
- Mantenha a captura curta: `-c`, ou um anel de poucos arquivos, nunca uma captura deixada rodando
  porque ninguém lembrou de pará-la.
- Apague quando a pergunta tiver resposta, no servidor e em toda cópia, e diga no chamado que apagou.

Um arquivo de captura com modo `-rw-r--r--` num diretório pessoal por seis meses é o contrário dos
três, e é o padrão que esta aula produziu.
