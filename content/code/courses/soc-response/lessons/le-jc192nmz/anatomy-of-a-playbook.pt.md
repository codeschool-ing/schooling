---
title: A anatomia de um playbook
version: 1
---

Um **playbook** é a sequência escrita para um tipo de alerta. Automatizado ou não, todo playbook bom tem as
mesmas cinco partes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Um playbook como cinco caixas em fila: gatilho, enriquecer, decidir, agir, registrar. Entre decidir e agir fica uma pessoa que aprova; uma linha tracejada sai de decidir direto para registrar quando nada pode ser feito automaticamente.\"><rect x=\"10\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">gatilho</text><rect x=\"150\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">enriquecer</text><rect x=\"290\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decidir</text><rect x=\"470\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">agir</text><rect x=\"610\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">registrar</text><path d=\"M110 73 L150 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M150 73 L142.0 69.0 L142.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M250 73 L290 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M290 73 L282.0 69.0 L282.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M390 73 L470 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 73 L462.0 69.0 L462.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"430\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma pessoa</text><text x=\"430\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aprova</text><path d=\"M570 73 L610 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M610 73 L602.0 69.0 L602.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M340 96 L340 140 L660 140 L660 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M660 96 L656.0 104.0 L664.0 104.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"500\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada que uma máquina possa fazer</text></svg>", "caption": "A máquina faz a coleta e a papelada. Entre decidir e agir, uma pessoa."}
```

**Gatilho**: qual alerta o inicia, e com quais campos (aqui, o endereço pelo qual o alerta agrupou).
**Enriquecer**: os fatos reunidos antes de alguém decidir. **Decidir**: quais ações os fatos justificam, e
quais delas uma máquina pode tomar. **Agir**: a mudança em si, pela interface do próprio sistema-alvo.
**Registrar**: um chamado com o que se sabia, o que foi proposto, o que foi feito e com autorização de
quem, escrito em toda execução, inclusive nas que não fizeram nada.

A seta marcada *uma pessoa aprova* é uma escolha, não uma lei. Algumas equipes deixam um playbook bloquear
um endereço sem ninguém no circuito, depois de meses medindo que ele acertava. A ordem segura é o contrário
da tentadora: **comece com toda ação aprovada por uma pessoa, e tire a aprovação de uma ação por vez, quando
o registro mostrar que ela mereceu.**

O caminho tracejado importa tanto quanto o contínuo. Quando os fatos dizem "este é o provedor de backup", o
playbook ainda escreve o chamado e ainda avisa alguém. Um playbook que não faz nada em silêncio não se
distingue de um que falhou.
