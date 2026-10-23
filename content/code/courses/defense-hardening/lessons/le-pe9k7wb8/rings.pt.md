---
title: Anéis, poucas máquinas primeiro
version: 1
---

**Uma atualização vai primeiro para poucas máquinas, e para o resto só quando as primeiras continuam
bem.** Cada grupo é um **anel**. O primeiro anel são máquinas cuja falha é barata e notada depressa:
os notebooks da própria equipe de TI, uma cópia de teste do servidor, uma estação cujo usuário liga no
momento em que algo fica estranho. O último anel é o que o escritório não pode perder. A Microsoft
chama a mesma ideia de anéis de implantação para atualizações do Windows; provedores de nuvem chamam de
distribuição escalonada; a forma é a mesma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l17-rings\" aria-label=\"Três anéis um dentro do outro. O de dentro, anel um, tem o desk e as máquinas da própria equipe de TI: falhar é barato e é notado rápido. O do meio tem as estações comuns. O de fora tem o web, o portal, que o escritório não pode perder. Uma atualização anda para fora, um anel por vez, e para se um anel informar problema.\"><defs><marker id=\"l17-rings-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"230.0\" cy=\"130.0\" r=\"115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><circle cx=\"230.0\" cy=\"130.0\" r=\"80\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><circle cx=\"230.0\" cy=\"130.0\" r=\"42\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"230.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">anel um</text><text x=\"230.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk</text><text x=\"230.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estações</text><text x=\"230.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M275.0 130.0 L390.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-rings-dh-ah-paper-dim)\"></path><text x=\"420.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">anel um</text><text x=\"420.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">falhar é barato e notado rápido</text><text x=\"420.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">meio</text><text x=\"420.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estações comuns</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fora</text><text x=\"420.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o escritório não pode perder</text><text x=\"420.0\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a atualização anda para fora, e para se der problema</text></svg>", "caption": "Cada anel é uma aposta menor que o seguinte."}
```

No laboratório há dois anéis: o `desk` primeiro, o `web` depois. Comece os dois na versão `1.0`, a
partir do `admin`, depois de apontar o `web` para o repositório do mesmo jeito que o `desk`:

```
root@web:~# mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list; apt-get update -q >/dev/null
ana@admin:~$ for h in desk web; do ssh $h "sudo apt-get install -y -q jatoba-health=1.0 >/dev/null 2>&1; jatoba-health"; done
jatoba-health 1.0
portal 200
jatoba-health 1.0
portal 200
```

As duas máquinas rodam a `1.0`, e as duas alcançam o portal: `portal 200`.

## Anel um

A atualização vai só para o `desk`:

```
ana@admin:~$ ssh desk "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^(Preparing|Unpacking|Setting)\"; jatoba-health"
Preparing to unpack .../jatoba-health_1.1_all.deb ...
Unpacking jatoba-health (1.1) over (1.0) ...
Setting up jatoba-health (1.1) ...
jatoba-health 1.1
portal 200
```

O dpkg diz o que fez em três linhas: desempacotou a `1.1` sobre a `1.0` e depois a configurou. O
programa rodou em seguida e o portal continua respondendo. **Esta é a checagem para a qual o anel um
existe**, e numa distribuição de verdade ela não é um comando: as máquinas do primeiro anel rodam por
um dia ou uma semana, o suporte fica atento, o monitoramento é observado, e só então o segundo anel
começa.

## Anel dois

O `desk` está bem, então o `web` recebe a mesma atualização, e o resultado é lido de volta nas duas:

```
ana@admin:~$ ssh web "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^Setting\"; jatoba-health"
Setting up jatoba-health (1.1) ...
jatoba-health 1.1
portal 200
ana@admin:~$ for h in desk web; do printf "%s " $h; ssh $h "dpkg-query -W jatoba-health"; done
desk jatoba-health	1.1
web jatoba-health	1.1
```

O `dpkg-query -W` informa o que está instalado, e é nisso que um relatório de situação de patches deve
se apoiar, não numa lista de comandos que alguém mandou. O mesmo hábito do passo de verificação da aula
16: a versão na máquina é a evidência.

## Quanto tempo entre anéis

O intervalo é uma troca, e o prazo decide. Um intervalo de uma semana pega a atualização ruim que leva
dias para aparecer, um vazamento de memória lento ou um job mensal que quebra; também deixa o último
anel exposto uma semana a mais. Para um achado P4, uma semana é de graça. Para uma falha na lista de
exploradas, o P1 da aula 16 dá sete dias para tudo, então os anéis encolhem para horas, e **o primeiro
anel ainda vale a pena**: uma hora em poucas máquinas pega a atualização que nem consegue instalar, que
é a maioria das ruins.

Em escala, o mesmo laço é escrito uma vez e rodado por uma ferramenta: um playbook do Ansible com
`serial:` definido, a configuração centralizada da aula 3 fazendo exatamente isso, ou a gestão de
patches de um produto de endpoint. O laço do transcrito acima é essa ideia numa linha.
