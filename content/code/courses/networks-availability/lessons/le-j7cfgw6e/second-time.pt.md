---
title: Por que registrar
version: 1
---

A maioria dos incidentes nunca é registrada, e o motivo alegado é sempre tempo: a falha foi corrigida,
os usuários voltaram a trabalhar e há outro trabalho esperando. Esse raciocínio trata o registro como um
relatório sobre este incidente. **O registro é para o próximo**, que vai parecer diferente na superfície,
ser o mesmo por baixo e chegar quando quem corrigiu este estiver fora.

O buraco negro da aula 21 é exatamente o tipo de falha que volta. Nada nele é exótico: uma regra escrita
para endurecer um roteador, um túnel cujo MTU é menor que o da rede do escritório, e conexões TCP que
supõem 1500 bytes. **Todo túnel acrescentado depois àquele roteador esbarra na mesma regra**, seja uma
segunda filial ou uma VPN para quem trabalha de casa. Quem estiver de plantão então ouve "a página abre, o
download trava" e, sem nada escrito, recomeça pelo cabo.

Com um registro, a segunda busca é uma busca de texto. "Download trava", "página pequena funciona" e
"túnel" encontram o registro, e ele diz o que rodar: um ping com Don't Fragment no MTU do túnel, uma
procura por uma regra que descarta destination unreachable, e o MSS clamping como correção. **A segunda
pessoa começa pela resposta**, e a única coisa que precisa estabelecer é se a falha é a mesma.

O registro tem outros leitores também, e cada um precisa de uma coisa diferente dele:

| leitor | o que ele precisa do registro |
|---|---|
| quem estiver de plantão da próxima vez | o sintoma nas palavras que vai buscar, e o teste que o resolveu |
| quem mexe no firewall | por que a regra importa, e o que mais depende da mensagem que ela descarta |
| quem revisa mudanças | o argumento para um teste que teria pegado isso antes de ir para produção |
| as pessoas afetadas | que a causa foi entendida, e não só que a falha sumiu |

**Um registro escrito uma semana depois é ficção com boas intenções.** A memória põe os eventos numa
ordem mais arrumada do que a real, esquece os testes que não levaram a nada e dá ao que funcionou mais
crédito do que ele mereceu. Então o registro começa durante o incidente, como notas com a hora ao lado de
cada uma, e é arrumado depois. As notas são a evidência e o registro final é o argumento construído sobre
elas.

Escrever também melhora o diagnóstico enquanto ele acontece. Uma hipótese que você precisa escrever tem de
ser específica o bastante para ser testada, e "tem alguma coisa errada com a VPN" não sobrevive ao lado de
uma coluna chamada "teste". O método da aula 21, uma hipótese de cada vez, e o registro desta aula são a
mesma disciplina vista de dois lados.
