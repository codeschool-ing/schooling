"""Lesson 23: Cloud Shell."""
from figures import Fig, T, figure


@figure('l23-sessions', 23)
def sessions():
    f = Fig('l23-sessions', 720, 250, T(
        'Three Cloud Shell sessions, Monday, Tuesday and Friday, each drawn as a separate machine started '
        'from Google\'s image. Each holds things that are lost when it ends: packages installed with apt, '
        'files in /tmp, running programs. Under all three, one home directory, a small persistent disk, is '
        'attached to each machine in turn and keeps what is saved in it, including .customize_environment, '
        'which is run as root at each start. A note says that after many weeks unused the home directory is '
        'deleted too.',
        'Três sessões do Cloud Shell, segunda, terça e sexta, cada uma desenhada como uma máquina separada '
        'iniciada da imagem do Google. Cada uma guarda coisas que se perdem quando ela acaba: pacotes '
        'instalados com apt, arquivos em /tmp, programas rodando. Embaixo das três, um diretório home, um '
        'pequeno disco persistente, é preso a cada máquina por vez e guarda o que foi salvo nele, inclusive o '
        '.customize_environment, que roda como root a cada início. Uma nota diz que depois de muitas semanas '
        'sem uso o diretório home também é apagado.'))
    for i, day in enumerate((T('Monday', 'segunda'), T('Tuesday', 'terça'), T('Friday', 'sexta'))):
        x = 20 + i * 235
        f.rect(x, 20, 210, 100, stroke='--wire', fill='--panel', width=1.2, dash='4 3')
        f.text(x + 105, 38, T(f'a fresh machine', 'uma máquina nova'), size=10)
        f.text(x + 105, 54, day, size=9, fill='--paper-dim')
        f.text(x + 105, 78, T('apt packages, /tmp,', 'pacotes apt, /tmp,'), size=9, fill='--paper-dim')
        f.text(x + 105, 94, T('running programs: lost', 'programas rodando: perdidos'), size=9, fill='--paper-dim')
        f.line(x + 105, 122, x + 105, 156, stroke='--phosphor', width=1.4)
    f.rect(20, 158, 680, 50, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(360, 176, T('one home directory, attached to each in turn', 'um diretório home, preso a cada uma por vez'), size=10.5)
    f.text(360, 194, '~/.bashrc · ~/.config/gcloud · ~/.customize_environment', size=9, mono=True, fill='--phosphor')
    f.text(360, 232, T('kept between sessions; deleted after many weeks unused', 'guardado entre sessões; apagado depois de muitas semanas sem uso'),
           size=9.5, fill='--paper-dim')
    return f, T('The machine is new every time; only the home directory comes back.',
                'A máquina é nova toda vez; só o diretório home volta.')
