---
title: Drivers: de onde vêm, e o scanner velho
version: 1
---

A aula 1 descreveu um driver como o código que traduz entre o kernel e um dispositivo. Esta seção é
sobre conseguir o certo, e mantê-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Três lugares de onde o driver de um dispositivo pode vir. Com o sistema: no kernel do Linux ou no próprio Windows, que cobre a maioria dos teclados, discos e placas de rede. Pelas atualizações: o Windows Update ou os pacotes de uma distribuição, que entregam versões novas testadas para o sistema. Do fabricante: o site ou a ferramenta do fabricante, em geral para impressoras, placas de vídeo e scanners.\"><defs><marker id=\"dv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">com o sistema</text><text x=\"230\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no kernel ou no próprio Windows</text><text x=\"230\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a maioria dos teclados, discos, placas de rede</text><rect x=\"20\" y=\"76\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pelas atualizações</text><text x=\"230\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Windows Update, os pacotes da distribuição</text><text x=\"230\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versões novas, testadas para o sistema</text><rect x=\"20\" y=\"132\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">do fabricante</text><text x=\"230\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o site ou a ferramenta do fabricante</text><text x=\"230\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">impressoras, placas de vídeo, scanners</text></svg>", "caption": "Quanto mais para baixo, menos o sistema sabe dele. Um driver do fabricante é o que uma atualização do sistema tem mais chance de deixar para trás."}
```

**No Linux a maioria dos drivers faz parte do kernel**, mantida junto com ele, e chega com as
atualizações do kernel. As exceções são os proprietários, placas de vídeo acima de tudo, que o Ubuntu
instala como pacotes:

```sh
lspci -k                                       # each PCI device and the driver in use
lsusb                                          # USB devices
ubuntu-drivers list                            # proprietary drivers Ubuntu can install
modinfo e1000e | head -3                       # about one kernel driver
```

**Nenhum deles foi rodado para esta aula.** O servidor em que este curso registra roda dentro de outra
máquina e não tem hardware próprio para mostrar, que é o assunto do curso de virtualização. O `lspci -k`
é o que vale lembrar: cada dispositivo, e o *Kernel driver in use*.

*No Windows*, o Gerenciador de Dispositivos é o lugar: botão direito num dispositivo para *Atualizar
driver*, *Reverter driver* (se um anterior foi guardado), *Desabilitar* e *Desinstalar*. Pela
linha de comando:

```sh
driverquery                                    # every driver, Command Prompt
pnputil /enum-drivers                          # third-party driver packages in the store
pnputil /enum-devices /problem                 # devices with a problem
```

**Não foi rodado para esta aula.** O Windows Update também oferece atualizações de drivers, algumas em
*Atualizações opcionais*, onde esperam até alguém escolhê-las.

## O scanner velho

O scanner parou depois de uma atualização de recursos. Em ordem:

1. **Gerenciador de Dispositivos**: ele está lá, com um triângulo de aviso? Então o driver falhou ao
   carregar.
2. **Reverter driver**, se o Windows trocou um que funcionava por um genérico.
3. **O site do fabricante**, atrás de um driver para a versão nova. Muitos fabricantes param depois de
   alguns anos.
4. Se não houver, as escolhas são *um driver genérico* (muitos scanners falam um padrão, o *WIA* no
   Windows e o *SANE* no Linux), **manter uma máquina na versão mais velha** enquanto ela ainda tiver
   suporte, ou *trocar o scanner*. A terceira costuma ser a mais barata ao longo de um ano.
