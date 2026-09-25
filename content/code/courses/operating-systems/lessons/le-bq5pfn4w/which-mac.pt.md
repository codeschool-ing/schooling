---
title: Qual Mac, qual macOS
version: 1
---

**A Apple faz o hardware e o sistema juntos**, então a pergunta "este computador aguenta?" tem uma
resposta mais curta do que no Windows: cada versão do macOS diz quais modelos de Mac suporta, e um
Mac está na lista ou não está. Não há TPM para ligar nem lista de processadores para ler.

O que importa é **que tipo de chip** está dentro, porque isso muda como o Mac inicia, como você chega
às ferramentas de reparo e por quanto tempo ele vai ter suporte.

| | Apple silicon | Intel |
|---|---|---|
| vendido | desde o fim de 2020 (M1, M2, M3 e seguintes) | de 2006 a 2023 |
| como saber | *Sobre Este Mac* diz **Chip** | *Sobre Este Mac* diz **Processador** |
| chegar à Recuperação | segurar o **botão de ligar** | segurar **Command-R** ao iniciar |
| último macOS | ainda atual | **macOS Tahoe 26**, segundo a Apple |

A Apple disse que o macOS Tahoe 26, de 2025, é a **última versão para Macs Intel**. Um Mac Intel
continua funcionando depois disso, e recebe atualizações de segurança por um tempo, mas um Mac comprado
em 2019 está mais perto do fim do suporte do que a idade dele sugere.

## Nomes e números

Cada versão tem um nome e um número: o Sonoma era 14, o Sequoia 15. A partir de 2025 o número segue o
ano, então a versão depois do Sequoia é o **Tahoe 26**, não 16. Chamados de suporte, requisitos de apps
e os próprios documentos da Apple usam os dois, e o número é o que se compara.

O menu Apple da barra de menus, **Sobre Este Mac**, mostra o chip, a memória e a versão. Os mesmos
dados, em texto, vêm do Terminal:

```sh
sw_vers                                  # ProductName, ProductVersion, BuildVersion
uname -m                                 # arm64 on Apple silicon, x86_64 on Intel
system_profiler SPHardwareDataType       # model, chip, memory, serial number
```

**Nenhum destes foi rodado para esta aula.** São comandos do macOS, e a máquina de onde vêm os
registros deste curso é Linux. O `uname` é o que você já conhece da aula 1, e num Mac ele imprime
`arm64` ou `x86_64`, conforme o chip.

## Antes de mexer em qualquer coisa

As mesmas três perguntas da aula 2, mais uma:

1. **Os dados.** Tudo o que importa no Mac é copiado para outro lugar antes, com o **Time Machine**
   para um disco externo ou copiando as pastas.
2. **A Conta Apple.** De quem é a conta em que ele está? Anote a resposta; ela decide a seção 04.
3. **O modelo.** Apple silicon ou Intel, e qual macOS o modelo suporta.
4. **A licença.** Não há com o que se preocupar. O macOS vem com o Mac e reinstalá-lo é de graça.
