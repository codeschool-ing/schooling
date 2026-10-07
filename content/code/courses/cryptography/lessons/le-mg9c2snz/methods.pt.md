---
title: Métodos EAP: EAP-TLS, PEAP e EAP-TTLS
version: 1
---

**O EAP é uma moldura para autenticação, não um método em si. O que um aparelho prova de fato, e
como, é decidido pelo método EAP, e três deles cobrem quase toda rede em uso.** Os três começam do
mesmo jeito: uma sessão TLS entre o aparelho e o servidor RADIUS, levada dentro do EAP, por um ponto
de acesso que não vê nada dela.

| método | o servidor se prova com | a pessoa ou o aparelho se prova com |
| --- | --- | --- |
| EAP-TLS | um certificado | um certificado próprio, no mesmo handshake TLS |
| PEAP | um certificado | uma senha, por MSCHAPv2 dentro do túnel TLS |
| EAP-TTLS | um certificado | uma senha ou outro método, dentro do túnel |

## EAP-TLS: certificados dos dois lados

O EAP-TLS é o handshake TLS da aula 10 com um acréscimo, o certificado do cliente: o aparelho
apresenta um certificado e prova que tem a chave privada, exatamente como o servidor faz. Nenhuma
senha atravessa a rede, então não há nenhuma para chutar, pescar com phishing ou reaproveitar. O custo
é um certificado em cada aparelho, emitido e renovado por uma AC, que é a PKI da aula 8 posta para
trabalhar. Organizações que gerenciam os notebooks com uma ferramenta de gestão de aparelhos emitem
esses certificados automaticamente, e aí o EAP-TLS é a escolha mais forte e a que menos dá trabalho à
equipe.

## PEAP: uma senha dentro de um túnel

O PEAP mantém o certificado do servidor e troca o do cliente por uma senha. A sessão TLS vira um
túnel, e dentro dele roda o **MSCHAPv2**, o protocolo de desafio e resposta da Microsoft, de 1999. O
PEAP com MSCHAPv2 é o padrão do Windows e o Wi-Fi corporativo mais comum do mundo, porque funciona com
as contas que a organização já tem.

Aqui está ele no laboratório. O perfil diz o método, a pessoa, a senha e, nas duas últimas linhas, o
servidor com quem o aparelho aceita conversar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O PEAP desenhado em camadas aninhadas. A camada de fora é o EAP, que leva só a identidade externa, anonymous@vereda.example, legível por todo ponto de acesso e proxy no caminho. Dentro dela, um túnel TLS até o servidor RADIUS, aberto só depois de conferido o certificado do servidor. Dentro do túnel, o MSCHAPv2 com a identidade real, ana, e o desafio e a resposta da senha, desenhados em vermelho porque são o que um túnel não conferido entregaria a um impostor.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EAP, legível no caminho: identidade externa</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">anonymous@vereda.example</text><rect x=\"50\" y=\"56\" width=\"620\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">túnel TLS, depois de conferir o certificado do servidor</text><rect x=\"80\" y=\"92\" width=\"560\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MSCHAPv2: identidade real, desafio e resposta</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ana</text></svg>", "caption": "PEAP: o que cada camada leva. O miolo vermelho só é tão seguro quanto a conferência do certificado em volta dele."}
```

```
ana@lab:~/lab$ cat peap.conf
network={
	ssid="Vereda-Equipe"
	key_mgmt=WPA-EAP
	eap=PEAP
	identity="ana"
	anonymous_identity="anonymous@vereda.example"
	password="lab only: ana na rede da equipe"
	phase2="auth=MSCHAPV2"
	ca_cert="pki/root.pem"
	domain_suffix_match="radius.vereda.example"
}
```

O `eapol_test` faz o papel do ponto de acesso e do notebook ao mesmo tempo, contra o servidor
FreeRADIUS do laboratório. A saída de depuração dele passa de mil linhas; o `vcrypt eap-log` guarda os
eventos de que esta aula fala:

```
ana@lab:~/lab$ eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 2  /C=BR/O=Vereda Fisioterapia/CN=Vereda Root CA
                           depth 1  /C=BR/O=Vereda Fisioterapia/CN=Vereda Issuing CA 1
                           depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
inside the tunnel:         inner identity sent
                           MSCHAPv2 challenge answered
                           MSCHAPv2: the server proved it knows the password
PMK:                       32 bytes, made by this session (not shown)
result:                    SUCCESS
```

Leia de cima para baixo:

- A **identidade externa**, `anonymous@vereda.example`, é o único nome enviado antes de o túnel
  existir, e todo ponto de acesso e todo proxy RADIUS no caminho conseguem lê-la. A verdadeira,
  `ana`, só passou dentro do túnel. Preencher `anonymous_identity` mantém a lista de nomes da equipe
  fora do ar.
- O **certificado do servidor** veio com a cadeia, e o aparelho o aceitou. A seção 04 é sobre essa
  linha.
- **O MSCHAPv2 deu certo nos dois sentidos**: o aparelho respondeu ao desafio do servidor, e o servidor
  respondeu ao do aparelho, provando que também conhecia a senha.
- A **PMK** saiu desta sessão. Duas sessões seguidas dão duas PMKs diferentes:

```
ana@lab:~/lab$ for i in 1 2; do eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | grep 'PMK from EAPOL'; done | sort -u | wc -l
2
```

## Por que o MSCHAPv2 nunca pode rodar fora de um túnel

O MSCHAPv2 é construído sobre o hash de senha do NT e o DES. Em 2012, pesquisadores mostraram que uma
troca MSCHAPv2 gravada se reduz a achar uma única chave DES de 56 bits, o que uma máquina dedicada
fazia em menos de um dia, e desde então a Microsoft orienta que o MSCHAPv2 só é seguro dentro de um túnel. **O PEAP é
esse túnel, e ele só protege o MSCHAPv2 se o aparelho conferiu quem está na outra ponta.** Um túnel
para o servidor errado entrega a troca justamente a quem ela devia ser escondida.

O EAP-TTLS tem o mesmo formato do PEAP e a mesma dependência. Dentro do túnel ele pode levar uma senha
pura (PAP), o que não é pior que o MSCHAPv2 quando o túnel é sólido, e não é melhor quando não é.
