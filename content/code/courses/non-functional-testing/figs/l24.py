"""Lesson 24: five minutes, spent; and where an alert goes."""
from figures import Fig, T, figure


@figure('l24-budget', 24)
def budget():
    f = Fig('l24-budget', 720, 270, T(
        'A time line of five minutes, starting when the five-minute error ratio passes 2%. A few '
        'seconds go on scraping and evaluating the rule. Then two minutes of for, while the alert '
        'is pending. Then 30 seconds of Alertmanager group_wait. Then the paging service rings a '
        'phone, a few seconds more. The rest, a little over two minutes, is the margin for a person '
        'to wake and acknowledge before the five minutes are up. Below it, the same line with '
        'for set to five minutes: the for alone reaches the end of the five minutes, and the '
        'notification arrives after it.',
        'Uma linha do tempo de cinco minutos, começando quando a razão de erro de cinco minutos passa '
        'de 2%. Alguns segundos vão na coleta e na avaliação da regra. Depois dois minutos de for, '
        'com o alerta pendente. Depois 30 segundos de group_wait do Alertmanager. Depois o serviço '
        'de plantão toca um telefone, mais alguns segundos. O resto, um pouco mais de dois minutos, '
        'é a margem para uma pessoa acordar e confirmar antes de acabarem os cinco minutos. Abaixo, '
        'a mesma linha com o for em cinco minutos: o for sozinho chega ao fim dos cinco minutos, e o '
        'aviso chega depois.'))
    x0, W = 60, 600
    px = W / 300.0                      # pixels per second
    def seg(y, start, secs, label, stroke, fill='--panel', text='--paper', mono=False):
        f.rect(x0 + start * px, y, secs * px, 34, stroke=stroke, fill=fill, width=1.3, rx=2)
        if label:
            f.text(x0 + (start + secs / 2) * px, y + 17, label, size=10, fill=text, mono=mono)
    f.text(x0, 26, T('the ratio passes 2%', 'a razão passa de 2%'), size=10.5, anchor='start', fill='--amber')
    f.text(x0 + W, 26, T('5 minutes', '5 minutos'), size=10.5, anchor='end', fill='--amber')
    for x in (x0, x0 + W):
        f.line(x, 36, x, 226, stroke='--amber', width=1.2, dash='4 3')
    y = 56
    seg(y, 0, 10, '', '--paper-dim')
    seg(y, 10, 120, 'for: 2m', '--phosphor', fill='--scan', mono=True)
    seg(y, 130, 30, 'group_wait', '--paper-dim', mono=True)
    seg(y, 160, 10, '', '--paper-dim')
    seg(y, 170, 130, T('margin to wake and acknowledge', 'margem para acordar e confirmar'), '--wire')
    f.text(x0 + 5 * px, y + 50, T('scrape, evaluate', 'coleta, avaliação'), size=9.5, anchor='start')
    f.text(x0 + 165 * px, y + 50, T('phone rings', 'telefone toca'), size=9.5)
    y = 156
    seg(y, 0, 10, '', '--paper-dim')
    seg(y, 10, 290, 'for: 5m', '--amber', fill='--scan', mono=True)
    f.text(x0 + W + 8, y + 17, T('then', 'depois'), size=10, anchor='start', fill='--amber')
    f.text(x0 + W / 2, 246, T('with for: 5m the requirement is broken before anybody is told',
                               'com for: 5m o requisito quebra antes de alguém ser avisado'),
           size=10.5, fill='--amber')
    return f, T("Lesson 1's five minutes, spent. Each block is a setting somebody chose.",
                'Os cinco minutos da aula 1, gastos. Cada bloco é uma configuração que alguém escolheu.')


@figure('l24-routing', 24)
def routing():
    f = Fig('l24-routing', 720, 300, T(
        'Prometheus on the left sends firing alerts to Alertmanager in the middle. Alertmanager '
        'groups them, holds back the error ratio alert while BoxofficeDown is firing, and routes by '
        'label: alerts with severity page go to PagerDuty, which calls the person on call and, if '
        'nobody acknowledges, the secondary. Everything else goes to the team queue by e-mail, read '
        'in working hours.',
        'O Prometheus, à esquerda, manda os alertas que disparam para o Alertmanager, no meio. O '
        'Alertmanager os agrupa, segura o alerta da razão de erro enquanto o BoxofficeDown está '
        'disparando, e encaminha pelo rótulo: alertas com severity page vão para o PagerDuty, que '
        'liga para quem está de plantão e, se ninguém confirmar, para o reserva. Todo o resto vai '
        'para a fila da equipe por e-mail, lida em horário de trabalho.'))
    f.rect(20, 120, 130, 60, stroke='--phosphor', fill='--scan', width=1.4)
    f.lines(85, 150, ['Prometheus', T('decides it fires', 'decide que dispara')], size=10)
    f.arrow([(152, 150), (226, 150)], stroke='--paper-dim')
    f.rect(230, 80, 170, 140, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(315, 100, 'Alertmanager', size=11, weight='600')
    f.lines(315, 160, [T('group', 'agrupa'), T('inhibit', 'inibe'), T('route by label', 'encaminha pelo rótulo'),
                       T('repeat every 4h', 'repete a cada 4h')], size=10, gap=17)
    f.arrow([(402, 120), (476, 80)], stroke='--amber')
    f.text(440, 84, 'severity="page"', size=9.5, mono=True, anchor='end', fill='--amber')
    f.arrow([(402, 190), (476, 228)], stroke='--paper-dim')
    f.text(446, 226, T('the rest', 'o resto'), size=9.5, anchor='end')
    f.rect(480, 50, 220, 70, stroke='--amber', fill='--panel', width=1.4)
    f.lines(590, 85, ['PagerDuty, Opsgenie', T('call the person on call,', 'liga para quem está de plantão,'),
                      T('then the secondary', 'depois para o reserva')], size=10)
    f.rect(480, 200, 220, 56, stroke='--wire', fill='--panel', width=1.2)
    f.lines(590, 228, [T('the team queue, by e-mail', 'a fila da equipe, por e-mail'),
                       T('read in working hours', 'lida em horário de trabalho')], size=10)
    return f, T('Prometheus decides that an alert fires. Alertmanager decides who hears about it, and when.',
                'O Prometheus decide que um alerta dispara. O Alertmanager decide quem fica sabendo, e quando.')
