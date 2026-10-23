"""Lesson 8: EDR, endpoint detection and response."""
from figures import Fig, T, figure


@figure('l08-loop', 8)
def loop():
    f = Fig('l08-loop', 720, 270, T(
        'The parts of an EDR as a loop. On the machine, a sensor records processes, logins, files '
        'and connections as telemetry. The telemetry is sent off the machine and kept. Rules run '
        'over it and raise an alert. A person reads the alert and acts on the machine: keeps the '
        'evidence, stops the process, isolates the host. A second arrow from the kept telemetry '
        'goes to hunting, a person asking a question no rule asked.',
        'As partes de um EDR em ciclo. Na máquina, um sensor registra processos, logins, arquivos '
        'e conexões como telemetria. A telemetria é enviada para fora da máquina e guardada. '
        'Regras rodam sobre ela e geram um alerta. Uma pessoa lê o alerta e age na máquina: guarda '
        'a evidência, para o processo, isola o host. Uma segunda seta, da telemetria guardada, vai '
        'para a caça, uma pessoa fazendo uma pergunta que nenhuma regra fez.'))
    f.rect(20, 40, 190, 150, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(32, 58, 'web', size=12, anchor='start', mono=True, weight='600')
    f.rect(40, 80, 150, 40, stroke='--phosphor', fill='--scan', width=1.3, rx=3)
    f.text(115, 100, T('sensor', 'sensor'), size=10.5)
    f.text(115, 145, T('processes, logins,', 'processos, logins,'), size=9.5, fill='--paper-dim')
    f.text(115, 160, T('files, connections', 'arquivos, conexões'), size=9.5, fill='--paper-dim')
    boxes = [(270, T('telemetry, kept', 'telemetria, guardada')), (430, T('rules', 'regras')),
             (580, T('alert', 'alerta'))]
    for x, label in boxes:
        f.rect(x, 80, 120 if x < 580 else 110, 40, stroke='--phosphor', fill='--panel', width=1.3, rx=3)
        f.text(x + (60 if x < 580 else 55), 100, label, size=10.5)
    f.line(190, 100, 270, 100, stroke='--paper-dim', width=1.4, arrow=True)
    f.line(390, 100, 430, 100, stroke='--paper-dim', width=1.4, arrow=True)
    f.line(550, 100, 580, 100, stroke='--paper-dim', width=1.4, arrow=True)
    f.arrow([(635, 120), (635, 225), (115, 225), (115, 190)], stroke='--amber', width=1.4)
    f.text(375, 243, T('response: keep evidence, stop, isolate', 'resposta: guardar evidência, parar, isolar'),
           size=10, fill='--amber')
    f.arrow([(330, 120), (330, 165), (420, 165)], stroke='--paper-dim', width=1.2, dash='4 3')
    f.text(428, 165, T('hunting: a question no rule asked', 'caça: uma pergunta que nenhuma regra fez'),
           size=9.5, anchor='start', fill='--paper-dim')
    f.text(360, 22, T('detection and response', 'detecção e resposta'), size=11, weight='600', fill='--paper-dim')
    return f, T('The sensor only writes things down. Everything that decides happens off the machine.',
                'O sensor só anota. Tudo o que decide acontece fora da máquina.')


@figure('l08-gap', 8)
def gap():
    f = Fig('l08-gap', 720, 220, T(
        'A timeline of one second with the sensor looking every fifth of a second, five looks drawn '
        'as ticks. A process that lives two milliseconds starts and ends between two ticks and is '
        'never seen. A process that lives half a second spans two or three ticks and is recorded at '
        'the first one.',
        'Uma linha do tempo de um segundo com o sensor olhando a cada quinto de segundo, cinco '
        'olhadas desenhadas como marcas. Um processo que vive dois milissegundos começa e termina '
        'entre duas marcas e nunca é visto. Um processo que vive meio segundo cobre duas ou três '
        'marcas e é registrado na primeira.'))
    x0, x1 = 60, 660
    f.line(x0, 150, x1, 150, stroke='--paper-dim', width=1.2)
    for i in range(6):
        x = x0 + i * (x1 - x0) / 5
        f.line(x, 140, x, 160, stroke='--phosphor', width=1.6)
        f.text(x, 176, f'{i * 0.2:.1f} s', size=9.5, mono=True, fill='--paper-dim')
    f.text(360, 200, T('the sensor looks at /proc at each tick', 'o sensor olha o /proc em cada marca'),
           size=9.5, fill='--phosphor')
    # short process
    f.rect(170, 92, 6, 20, stroke='--amber', fill='--amber', width=1, rx=1)
    f.text(173, 80, T('/bin/true, 2 ms: never seen', '/bin/true, 2 ms: nunca visto'), size=9.5, fill='--amber')
    # long process
    f.rect(330, 92, 300, 20, stroke='--phosphor', fill='--scan', width=1.3, rx=2)
    f.text(480, 102, T('sleep 0.5: seen at 0.6 s', 'sleep 0.5: visto em 0,6 s'), size=9.5)
    f.text(360, 28, T('polling five times a second', 'olhando cinco vezes por segundo'), size=11, weight='600',
           fill='--paper-dim')
    return f, T('Anything that starts and ends between two looks leaves no trace in the file.',
                'O que começa e termina entre duas olhadas não deixa rastro no arquivo.')
