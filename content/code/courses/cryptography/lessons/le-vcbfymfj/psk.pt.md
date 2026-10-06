---
title: No que uma frase secreta se transforma
version: 1
---

**Numa rede WPA2-Personal, a frase secreta digitada em cada aparelho vira uma chave de 256 bits, e
essa chave é a mesma para todo aparelho, todo dia, até alguém trocar a frase.** A função que faz isso
é o PBKDF2, o hash lento da aula 5, com o nome da rede como sal. Dá para calculá-la sem rádio
nenhum, e é o que esta seção faz.

## A chave, calculada

O `wpa_passphrase` vem com o `wpa_supplicant`, o programa que conecta a redes Wi-Fi no Linux. Com um
nome de rede, o SSID, e uma frase secreta, ele imprime o bloco de configuração que um cliente usaria,
com a chave derivada em `psk`. A rede da recepção da Vereda, com a frase do laboratório:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Recepcao 'sala de espera, cadeira azul 2026'
network={
	ssid="Vereda-Recepcao"
	#psk="sala de espera, cadeira azul 2026"
	psk=3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84
}
```

Aquele `psk` de 64 dígitos hexadecimais é a **chave mestra par a par** (*pairwise master key*), a
PMK. Um cliente configurado com ela entra na rede sem nunca saber a frase, e é por isso que uma
empresa pode distribuir essa linha para os notebooks em vez de contar a frase à equipe. A linha
continua abrindo a rede: quem a lê na configuração de um notebook tem o mesmo que a frase daria.

A mesma frase na rede da equipe dá outra chave, porque o SSID é o sal:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Equipe 'sala de espera, cadeira azul 2026'
network={
	ssid="Vereda-Equipe"
	#psk="sala de espera, cadeira azul 2026"
	psk=e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42
}
```

E uma frase abaixo do mínimo do padrão é recusada antes de qualquer cálculo:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Recepcao 'vereda1'; echo "exit status $?"
Passphrase must be 8..63 characters
exit status 1
```

## A derivação inteira, em Python

Não há ingrediente secreto naquela saída. A derivação cabe numa função, e rodá-la reproduz as duas
chaves acima byte a byte:

```schooling-example
{
  "language": "python",
  "file": "wifi_pmk.py",
  "parts": [
    {
      "code": "import hashlib\nimport sys",
      "note": "Nada fora da biblioteca padrão: o PBKDF2 está no `hashlib`."
    },
    {
      "code": "def pmk(passphrase: str, ssid: str) -> bytes:\n    if not 8 <= len(passphrase) <= 63:\n        raise ValueError(\"a WPA passphrase has 8 to 63 characters\")\n    return hashlib.pbkdf2_hmac(\"sha1\", passphrase.encode(), ssid.encode(), 4096, 32)",
      "note": "Toda a derivação de chave do WPA2-Personal. A frase secreta é a senha, o nome da rede é o sal, a contagem é fixa em 4096 e o hash é o SHA-1. A verificação de tamanho é a regra do próprio padrão, a mesma que o `wpa_passphrase` recusou acima."
    },
    {
      "code": "passphrase = sys.argv[1]\nfor ssid in sys.argv[2:]:\n    print(f\"{ssid:16} {pmk(passphrase, ssid).hex()}\")",
      "note": "Uma frase secreta, quantos nomes de rede quiser, uma chave por nome."
    }
  ],
  "output": "Vereda-Recepcao  3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84\nVereda-Equipe    e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42"
}
```

```
ana@lab:~/lab$ python3 wifi_pmk.py 'sala de espera, cadeira azul 2026' Vereda-Recepcao Vereda-Equipe
Vereda-Recepcao  3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84
Vereda-Equipe    e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42
```

## O que decorre disso

- **Todo mundo que sabe a frase tem a PMK.** Não existe segredo por usuário. A recepcionista, os
  fisioterapeutas e o técnico que instalou o ponto de acesso têm todos a mesma chave.
- **O SSID é o sal, então um SSID comum é um sal fraco.** A aula 5 explicou por que um sal precisa ser
  único: uma tabela pré-calculada só funciona para o sal com que foi calculada. Redes com o nome
  padrão do roteador, `linksys` ou `NETGEAR`, dividem o sal com milhões de outras, e tabelas para os
  nomes e senhas mais comuns estão publicadas há anos. Um nome próprio, como `Vereda-Recepcao`, tira
  a rede de todas elas.
- **4.096 rodadas de SHA-1 eram lentas em 2004.** Hoje são baratas. Uma única placa de vídeo atual calcula
  mais de dois milhões de PMKs por segundo. O Argon2id, a resposta da aula 5, chegou onze anos tarde
  demais para este padrão, então a única coisa que encarece um palpite aqui é a frase secreta.
- **Trocar a frase é a única revogação.** Quando alguém sai da Vereda, a chave que essa pessoa
  conhecia continua abrindo a rede até a frase mudar no ponto de acesso e em todos os aparelhos.

A próxima seção mostra onde a PMK é usada, e por que alguém que nunca tocou na rede ainda consegue
testar palpites contra ela.
