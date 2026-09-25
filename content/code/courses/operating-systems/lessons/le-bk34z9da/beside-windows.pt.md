---
title: Instalando ao lado do Windows
version: 1
---

Um computador pode manter o Windows e acrescentar o Linux no mesmo disco, escolhendo entre eles a
cada inicialização. Isso se chama **dual boot**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"Um disco com Windows e Ubuntu instalados lado a lado. Da esquerda para a direita: a partição EFI, compartilhada, com os dois carregadores de boot, Windows Boot Manager e GRUB; a MSR; a partição do Windows, C:, NTFS, que foi reduzida antes de dentro do Windows; a partição de Recuperação; e a partição do Ubuntu, montada como /, formatada em ext4, com um arquivo de swap dentro. O GRUB inicia primeiro e oferece um menu com os dois sistemas.\"><defs><marker id=\"db-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um disco, dois sistemas</text><rect x=\"20\" y=\"36\" width=\"60\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">EFI</text><text x=\"50.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comum</text><rect x=\"84\" y=\"36\" width=\"44\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"106.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MSR</text><rect x=\"132\" y=\"36\" width=\"250\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"257.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows (C:)</text><text x=\"257.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NTFS, reduzida antes</text><rect x=\"386\" y=\"36\" width=\"90\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"431.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recuperação</text><rect x=\"480\" y=\"36\" width=\"220\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Ubuntu (/)</text><text x=\"590.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ext4, arquivo de swap dentro</text><path d=\"M50 96 L50 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">guarda os dois carregadores: Windows Boot Manager e GRUB</text><text x=\"50\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o GRUB inicia primeiro e oferece um menu</text><path d=\"M370 100 C420 130 520 130 580 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#db-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"480\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">espaço tirado do C:, de dentro do Windows</text></svg>", "caption": "O Ubuntu fica com o espaço que o Windows cedeu e divide com ele a partição EFI. Nada do Windows é apagado, e é exatamente por isso que os passos antes de instalar importam.", "same": ["EFI", "MSR", "Windows (C:)", "Ubuntu (/)"]}
```

O Linux precisa de um espaço que o Windows está usando, e três coisas precisam acontecer **de dentro do
Windows, antes de rodar o instalador**:

1. **Suspender o BitLocker** (aula 2) e ter a chave de recuperação à mão. Mexer nas partições pode fazer
   o Windows pedir a chave na próxima inicialização.
2. **Reduzir o C:** no *Gerenciamento de Disco* do Windows: botão direito na partição, *Diminuir Volume*.
   O Windows sabe quais partes da partição dele estão em uso; deixar o próprio Windows fazer é mais
   seguro que deixar outra ferramenta adivinhar.
3. **Desligar a Inicialização Rápida** (*Painel de Controle > Opções de Energia*). Com ela ligada,
   "desligar" o Windows é na verdade uma espécie de hibernação que deixa a partição dele travada, e o
   Linux então só consegue ler, não escrever.

Depois de instalar, o computador inicia o **GRUB**, o carregador de boot do Linux, que mostra um menu
com os dois sistemas. Os dois carregadores moram lado a lado na partição EFI compartilhada da aula 2.

## O relógio três horas errado

A primeira coisa que as pessoas notam depois de configurar um dual boot é o relógio. O computador tem
um relógio de hardware, e os dois sistemas discordam sobre o que ele guarda: **o Windows guarda nele o
horário local, o Linux guarda UTC**. Em São Paulo são três horas de diferença, e cada sistema "corrige"
o relógio depois que o outro o usou.

O `timedatectl` mostra como o Linux o enxerga:

```
ana@server:~$ timedatectl
               Local time: Fri 2026-09-25 13:11:43 UTC
           Universal time: Fri 2026-09-25 13:11:43 UTC
                 RTC time: n/a
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: no
              NTP service: inactive
          RTC in local TZ: no
```

Este registro vem de uma máquina virtual que pega emprestado o relógio do computador que a roda, então
ela não tem relógio de hardware próprio: `RTC time: n/a`, e nem sincronização de horário própria. Num PC
de verdade a linha mostra o relógio de hardware, e `RTC in local TZ: no` é o hábito do Linux. A correção
de costume para o dual boot é mandar o Linux fazer o que o Windows faz:

```sh
timedatectl set-local-rtc 1    # tell Linux the hardware clock keeps local time, as Windows does
```

**Não rodado aqui**, já que esta máquina não tem relógio de hardware para mudar.
