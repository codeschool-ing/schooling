---
title: A test set decides, not a feeling
version: 2
---

The usual way to judge a prompt is to try it on one or two inputs, read the replies, and decide it
looks good. That judges the inputs you happened to pick, and it is how the weak prompt of the previous
reading section would pass: try it on a glowing review, get `positive`, ship it. **A prompt is
judged by a test set**: a handful of inputs whose right answers were decided by a person
beforehand, run through the prompt, and counted.

## Eight messages with known labels

This is a test set for the café's labeller. Each line has an id, the label a person gave it, and
the message, separated by tabs:

```
ana@lab:~/pe$ cat tests.tsv
r1	positive	Lovely cinnamon bun and the oat flat white was perfect. Will come back on Sunday.
r2	mixed	Waited fifteen minutes for a tea at noon. The staff were kind about it.
r3	negative	The soup was cold and nobody came to take it back.
r4	positive	Best bread in the neighbourhood, still warm at eight.
r5	negative	Great, another forty minutes for a coffee. Wonderful service.
r6	not_a_review	Do you open on public holidays?
r7	mixed	The cake was dry but the coffee made up for it.
r8	positive	O pão de queijo estava ótimo e o café também.
```

It is small on purpose, and it is not random. **Each line is there for a reason.** `r1` and `r3`
are the easy cases that any prompt should get. `r2` and `r7` are mixed. `r5` is sarcastic. `r6` is a
question. `r8` is in Portuguese. A test set that held only easy cases would score every prompt well
and tell you nothing.

Scoring is a comparison, so a short program does it. It reads the test set and a file of replies,
one per line in the same order, prints each mismatch and counts the matches:

```
ana@lab:~/pe$ cat score.py
import sys

tests = [line.rstrip("\n").split("\t") for line in open(sys.argv[1], encoding="utf-8")]
replies = [line.rstrip("\n") for line in open(sys.argv[2], encoding="utf-8")]
right = 0
for (tid, want, text), got in zip(tests, replies):
    if got == want:
        right += 1
    else:
        print("%s  wanted %-13s got %s" % (tid, want, got))
print("%d of %d right" % (right, len(tests)))
```

## Scoring the weak prompt and the strong one

`label.py` runs a template over the test set: it puts each message where `{message}` is, asks the
model at temperature 0, and writes each reply on one line, in the same order as the tests:

```
ana@lab:~/pe$ cat label.py
import subprocess, sys

template = open(sys.argv[1], encoding="utf-8").read()
for line in open(sys.argv[2], encoding="utf-8"):
    tid, want, text = line.rstrip("\n").split("\t")
    prompt = template.replace("{message}", text)
    reply = subprocess.run(["ask", prompt, "--temperature", "0", "--plain"],
                           capture_output=True, text=True).stdout
    print(" ".join(reply.split()))
ana@lab:~/pe$ python3 label.py prompts/weak.txt tests.tsv > replies-weak.txt
ana@lab:~/pe$ cat replies-weak.txt
This review is positive. The reviewer mentions that the cinnamon bun and oat flat white were "perfect", which suggests a high level of satisfaction with their experience. They also express a desire to return, indicating that they will likely be a repeat customer.
This review is mixed, but leaning towards being slightly negative. The reviewer waited a long time for their tea, which is a inconvenience, but they mention that the staff were "kind about it", which suggests that the staff's attitude made up for the wait. However, the wait itself is still a negative experience.
This review is negative. The reviewer mentions that the soup was cold, which is a significant flaw in the food, and that no one came to take it back, implying poor customer service.
This review is positive. The reviewer is expressing their satisfaction with the bread, stating that it is the "best" in the neighborhood and that it is still warm at 8, implying that it is freshly baked and of high quality.
This review is positive. The reviewer mentions "Great" and "Wonderful service", which indicate a high level of satisfaction with their experience.
This review is neutral. It's a question being asked, rather than a statement or opinion, so it doesn't convey a positive or negative sentiment.
This review is mixed, but leaning towards being slightly negative. The reviewer mentions that the cake was "dry", which is a negative characteristic. However, they also mention that the coffee was a redeeming factor, which suggests that the reviewer was able to find some positive aspect of their experience. Overall, the tone is somewhat lukewarm and disappointed, but not entirely negative.
Essa review é positiva. Embora o texto seja em português e não contenha muitas palavras, a presença de "estava ótimo" e "também" indica que o reviewer gostou do pão de queijo e do café.
ana@lab:~/pe$ python3 score.py tests.tsv replies-weak.txt
r1  wanted positive      got This review is positive. The reviewer mentions that the cinnamon bun and oat flat white were "perfect", which suggests a high level of satisfaction with their experience. They also express a desire to return, indicating that they will likely be a repeat customer.
r2  wanted mixed         got This review is mixed, but leaning towards being slightly negative. The reviewer waited a long time for their tea, which is a inconvenience, but they mention that the staff were "kind about it", which suggests that the staff's attitude made up for the wait. However, the wait itself is still a negative experience.
r3  wanted negative      got This review is negative. The reviewer mentions that the soup was cold, which is a significant flaw in the food, and that no one came to take it back, implying poor customer service.
r4  wanted positive      got This review is positive. The reviewer is expressing their satisfaction with the bread, stating that it is the "best" in the neighborhood and that it is still warm at 8, implying that it is freshly baked and of high quality.
r5  wanted negative      got This review is positive. The reviewer mentions "Great" and "Wonderful service", which indicate a high level of satisfaction with their experience.
r6  wanted not_a_review  got This review is neutral. It's a question being asked, rather than a statement or opinion, so it doesn't convey a positive or negative sentiment.
r7  wanted mixed         got This review is mixed, but leaning towards being slightly negative. The reviewer mentions that the cake was "dry", which is a negative characteristic. However, they also mention that the coffee was a redeeming factor, which suggests that the reviewer was able to find some positive aspect of their experience. Overall, the tone is somewhat lukewarm and disappointed, but not entirely negative.
r8  wanted positive      got Essa review é positiva. Embora o texto seja em português e não contenha muitas palavras, a presença de "estava ótimo" e "também" indica que o reviewer gostou do pão de queijo e do café.
0 of 8 right
```

**None of eight.** Every reply is a paragraph, and `score.py` compares a paragraph with one word.
Read past the form, and the failures are still not all the same problem:

- `r1` to `r4` and `r7` hold the right label, inside a sentence. **The right answer in the wrong
  form** is a wrong answer to a program. The prompt never said what form the answer takes.
- `r6` is the question, and the model did not answer it this time: it invented a label, `neutral`,
  that the café does not use. The prompt never said a message could be something other than a
  review, or what to call it.
- `r8` is a label in the wrong language. The message was in Portuguese and so was the reply; the
  prompt never said which language the labels are in.
- `r5` is the sarcasm, read literally: "Great" and "Wonderful service" are positive words.

The strong prompt says all four out loud: the form, the questions, the language and the sarcasm:

```
ana@lab:~/pe$ python3 label.py prompts/strong.txt tests.tsv > replies-strong.txt
ana@lab:~/pe$ cat replies-strong.txt
positive
mixed
negative
positive
positive
not_a_review
mixed
positive
ana@lab:~/pe$ python3 score.py tests.tsv replies-strong.txt
r5  wanted negative      got positive
7 of 8 right
```

Seven of eight, and the one left is `r5`, **the sarcasm, even though the strong prompt names
sarcasm as an edge case**. That is the useful result. The count says the format, the language and
the questions are fixed, and it says exactly what is not.

## When zero-shot is enough, and when to move on

The count decides, against a bar you set before running it. If the café needs every complaint to
reach the manager, a sarcastic complaint filed as `positive` is the one error it cannot accept, and
seven of eight is not enough however good it looks.

What to try next depends on the kind of failure:

| the failure | the next move |
|---|---|
| the right answer in the wrong form | state the format; lesson 18 and lesson 19 check it |
| a whole kind of input not handled | name it in the prompt as an edge case |
| an edge case named and still missed | show it: examples, lesson 21 |
| the model does not know the facts | supply them: context, lesson 24, or retrieval, lesson 11 |

The third row is where `r5` sits. A description of sarcasm did not move the model; an example of a
sarcastic message with its label often shows the boundary better than a sentence describing it.
Lesson 21 tries it on this test set, and counts.

**Two warnings about the test set itself.** Eight messages is enough to find the kinds of failure
above and far too few to measure an error rate: one more miss moves the score by twelve and a half points. A test
set worth trusting grows every time a real message is labelled wrong, and that message goes in
with its right label. And the test set is for testing. If its messages become the examples in the
prompt, the prompt will score well on them for the wrong reason, which lesson 21 comes back to.
