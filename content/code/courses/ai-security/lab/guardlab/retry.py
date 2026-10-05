def ask(call, check, attempts=2):
    feedback = []
    for n in range(1, attempts + 1):
        text = call(feedback)
        problems = check(text)
        yield n, problems
        if not problems:
            return
        feedback = problems
