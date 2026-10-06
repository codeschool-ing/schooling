---
title: Quatro gerações, e por que a primeira caiu
version: 1
---

**A segurança do Wi-Fi teve quatro nomes em vinte e cinco anos, e cada um existe porque o anterior
falhou.** O WEP foi quebrado menos de quatro anos depois de lançado. O WPA foi um conserto que
precisava rodar no hardware do WEP. O WPA2 trouxe o AES e foi o padrão por catorze anos. O WPA3
corrige a única fraqueza que o WPA2 manteve, que é o assunto das duas próximas seções.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo da segurança do Wi-Fi. WEP, 1997, com RC4 e um CRC, quebrado em 2001, desenhado em vermelho. WPA, 2003, RC4 com TKIP, um conserto de emergência, obsoleto em 2012. WPA2, 2004, AES-CCMP, o padrão até 2018. WPA3, 2018, AES com SAE no lugar da chave derivada da frase secreta, desenhado em azul.\"><defs><marker id=\"gen-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><polyline points=\"30,150 700,150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#gen-ah-wire)\"></polyline><rect x=\"40\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WEP</text><text x=\"115\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC4 + CRC-32</text><text x=\"115\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">quebrado em 2001</text><polyline points=\"115,120 115,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"115\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1997</text><rect x=\"205\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA</text><text x=\"280\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC4 + TKIP</text><text x=\"280\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um conserto, aposentado</text><polyline points=\"280,120 280,146\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"280\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2003</text><rect x=\"370\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA2</text><text x=\"445\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AES-CCMP</text><text x=\"445\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a frase é tudo</text><polyline points=\"445,120 445,146\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"445\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2004</text><rect x=\"535\" y=\"40\" width=\"150\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WPA3</text><text x=\"610\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AES + SAE</text><text x=\"610\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">atual</text><polyline points=\"610,120 610,146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"610\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2018</text></svg>", "caption": "Cada geração existe porque a anterior falhou. Vermelho: quebrado; azul: atual.", "same": ["WEP", "WPA", "WPA2", "WPA3"]}
```

## WEP: a primitiva certa, usada do jeito errado

O WEP, *Wired Equivalent Privacy* (1997), cifrava cada quadro com o RC4, uma cifra de fluxo. O RC4
precisa de uma chave que nunca se repete, pelo mesmo motivo dos modos de contador da aula 1. A
resposta do WEP foi colar um IV de 24 bits na frente da chave compartilhada e mandar o IV às claras
junto com o quadro. Isso cometeu três erros de uma vez:

- **24 bits acabam.** Existem só uns 16,7 milhões de IVs. Uma rede movimentada passa por todos em
  horas, e muitas placas recomeçavam do zero toda vez que eram ligadas, então as repetições vinham
  bem antes. Cada repetição é um fluxo de chave reutilizado.
- **A chave e o IV eram combinados por concatenação**, e os primeiros bytes de saída do RC4 vazam
  informação sobre a chave quando as chaves são aparentadas desse jeito. Com quadros suficientes, a
  própria chave compartilhada podia ser calculada, e ferramentas publicadas faziam isso em minutos.
- **A verificação de integridade era um CRC-32**, uma soma de verificação para ruído de linha, e não
  um MAC. Um CRC é linear, então alterar bits escolhidos de um quadro e acertar a soma para combinar
  não exige chave nenhuma.

Além disso, todo aparelho da rede usava a mesma chave, e nada a trocava automaticamente. Trocar uma
chave WEP significava passar em cada aparelho.

**A lição para quem defende é curta: o WEP não é uma configuração de segurança.** Um aparelho que só
fala WEP é tratado como um aparelho sem cifragem nenhuma. Ele vai para uma rede isolada só dele, sem
nada nela que valha a pena ler, até ser substituído.

## WPA e TKIP: um conserto sob uma restrição

Em 2003 o setor precisava de uma correção para milhões de placas que só sabiam rodar RC4 no hardware.
O WPA introduziu o **TKIP**, que manteve o RC4 e mudou tudo em volta dele. Ele misturava uma chave
nova para cada quadro a partir de um contador de 48 bits, acrescentou uma verificação de mensagem de
verdade chamada Michael e recusava quadros cujo contador andasse para trás. Era uma medida de
emergência projetada para ser substituída, e foi. O padrão de 2012 tornou o TKIP obsoleto, e os
equipamentos atuais o recusam.

## WPA2: AES e CCMP

O WPA2 (2004) trocou a cifra inteira: **CCMP**, que é o AES em modo contador com uma etiqueta
CBC-MAC. Isso é cifragem autenticada, a propriedade que a aula 1 pediu ao GCM, construída com a mesma
cifra de bloco e uma construção diferente. Nada prático foi encontrado contra o CCMP em si em vinte
anos. O que o WPA2 manteve é o jeito de combinar a chave quando a rede tem senha. A próxima seção
calcula essa chave, e a seguinte mostra por que a senha passa a ser toda a segurança.

| | cifra | integridade | situação |
| --- | --- | --- | --- |
| WEP | RC4, IV de 24 bits | CRC-32 | quebrado; trate como aberto |
| WPA | RC4 com TKIP | Michael | obsoleto desde 2012 |
| WPA2 | AES-CCMP | CBC-MAC | sólido, se a senha for |
| WPA3 | AES-CCMP ou GCMP | CBC-MAC ou GMAC | atual |
