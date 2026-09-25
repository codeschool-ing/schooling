---
title: Antes de começar: este computador aguenta?
version: 1
---

**O Windows 11 tem requisitos de hardware que o Windows 10 não tinha**, e eles são a primeira coisa a
conferir, porque um computador que não os cumpre não pode ser atualizado do jeito normal.

| | mínimo para o Windows 11 |
|---|---|
| processador | 64 bits, 1 GHz ou mais, 2 ou mais núcleos, na lista de modelos suportados da Microsoft |
| memória | 4 GB de RAM |
| armazenamento | 64 GB |
| firmware | UEFI, capaz de Secure Boot (aula 1) |
| chip de segurança | TPM 2.0 |
| gráficos | compatível com DirectX 12 |

Duas linhas causam quase toda recusa. A **lista de processadores**: muitos computadores de antes de
2018, mais ou menos, funcionam bem mas não estão nela. E o **TPM**, o *Trusted Platform Module*, um
pequeno chip de segurança (ou um recurso do processador) que guarda chaves de criptografia. Ele muitas
vezes existe mas está desligado nas configurações do firmware.

O aplicativo **Verificação de Integridade do PC** (*PC Health Check*) da Microsoft faz essas checagens
e diz qual falhou. Num escritório, é a primeira coisa a rodar em cada máquina antes de prometer uma
atualização a alguém.

## Por que isso importa agora

O Windows 10 parou de receber atualizações de segurança gratuitas em **outubro de 2025**. Um computador
que não roda o Windows 11 pode comprar um período limitado de atualizações pagas, ou mudar para outro
sistema, mas não deveria simplesmente seguir em frente: um sistema sem atualizações de segurança está
a uma falha descoberta de ser a porta de entrada da rede do escritório.

## Três coisas para resolver antes

1. **Os dados.** Tudo o que importa no computador é copiado para outro lugar antes. Uma instalação
   limpa apaga o disco, e o instalador pergunta uma vez só.
2. **A licença.** A maioria dos computadores vendidos com Windows tem uma **licença digital** ligada
   ao hardware, e uma reinstalação na mesma máquina ativa sozinha. Senão, você precisa de uma **chave
   do produto** de 25 caracteres.
3. **A edição.** Home, Pro ou Enterprise. Para um escritório, no mínimo Pro; a aula 5 explica por quê.

Conferir a versão de uma máquina que já está rodando, antes de decidir qualquer coisa, leva um destes:

```sh
winver                          # a window with the version and build
systeminfo                      # OS name, version, install date, memory, updates
Get-ComputerInfo -Property OsName, OsVersion, OsBuildNumber   # the same, as PowerShell
```

**Nenhum destes foi rodado para esta aula**; são comandos do Windows, e a máquina de onde vêm os
registros deste curso é Linux. O `winver` abre uma janelinha; os outros dois imprimem texto.
