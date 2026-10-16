# lesson 21

@figure('l21-cycle', 21)
def l21_cycle(lang):
    t = {
        'en': dict(entry=['entry criteria', 'one build, smoke passes,', 'right machine and data'],
                   days=['Wednesday', 'Thursday', 'Friday morning'], test='testing', susp=['suspended', '9:40 to 11:50'],
                   exit=['exit criteria', 'met or not met,', 'with evidence'], dec=['decision', 'Joana'],
                   label='A test cycle as a timeline. Entry criteria at the start: one build, the smoke test passes, the '
                         'right machine and data. Testing runs through Wednesday and Thursday, with a suspended stretch on '
                         'Thursday from 9:40 to 11:50. On Friday morning the exit criteria are reported, met or not met, '
                         'with evidence, and the decision is Joana’s.',
                   cap='Entry and exit criteria are written before the cycle starts. The tester reports against them; '
                       'the product owner decides.'),
        'pt': dict(entry=['critérios de entrada', 'um build, o smoke passa,', 'máquina e dados certos'],
                   days=['quarta', 'quinta', 'sexta de manhã'], test='teste', susp=['suspenso', '9:40 às 11:50'],
                   exit=['critérios de saída', 'cumprido ou não,', 'com evidência'], dec=['decisão', 'Joana'],
                   label='Um ciclo de teste como linha do tempo. Critérios de entrada no começo: um build, o teste de '
                         'smoke passa, máquina e dados certos. O teste corre pela quarta e pela quinta, com um trecho '
                         'suspenso na quinta das 9:40 às 11:50. Na sexta de manhã os critérios de saída são relatados, '
                         'cumpridos ou não, com evidência, e a decisão é da Joana.',
                   cap='Critérios de entrada e de saída são escritos antes de o ciclo começar. Quem testa relata contra '
                       'eles; a dona do produto decide.'),
    }[lang]
    f = Fig('l21-cycle', 680, 200, t['label'])
    box(f, 10, 50, 140, 64, t['entry'], size=9, weights=['600', None, None], stroke='--phosphor',
        fills=['--phosphor', '--paper', '--paper'])
    arrow(f, 151, 82, 169, 82)
    f.rect(170, 62, 300, 40, stroke='--wire', fill='--panel', rx=4)
    f.text(240, 82, t['test'], size=9.5, weight='600')
    f.rect(340, 62, 50, 40, stroke='--amber', fill='--ink', rx=2, dash='3 2')
    f.text(365, 122, t['susp'][0], size=9, fill='--amber', weight='600')
    f.text(365, 136, t['susp'][1], size=9, fill='--paper-dim')
    f.line(320, 66, 320, 98, stroke='--paper-dim', width=1, dash='2 3')
    for x, d in zip([245, 395, 535], t['days']):
        f.text(x, 30, d, size=9, fill='--paper-dim')
    arrow(f, 471, 82, 489, 82)
    box(f, 490, 50, 110, 64, t['exit'], size=9, weights=['600', None, None], stroke='--phosphor',
        fills=['--phosphor', '--paper', '--paper'])
    arrow(f, 601, 82, 615, 82)
    box(f, 616, 58, 58, 48, t['dec'], size=9, weights=['600', None], stroke='--amber', fills=['--amber', '--paper'])
    return f, t['cap']
