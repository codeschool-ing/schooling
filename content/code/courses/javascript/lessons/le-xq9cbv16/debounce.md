---
title: Waiting until the typing stops
version: 1
---

A search box that queries a server on every `input` event (lesson 12) sends a request per keystroke,
most of which are out of date before they arrive. **Debouncing waits until the events have stopped
for a while, and then acts once**:

```html
<!doctype html>
<input id="q" placeholder="Search the shelf">
<script>
  function debounce(fn, ms) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), ms);
    };
  }

  const search = (text) => console.log(`searching for "${text}"`);
  const searchSoon = debounce(search, 300);
  let keystrokes = 0;

  document.querySelector("#q").addEventListener("input", (event) => {
    keystrokes += 1;
    searchSoon(event.target.value);
  });
  window.report = () => console.log("keystrokes:", keystrokes);
</script>
```

```
ana@dev:~/js$ page search.html --do 'focus #q' --do 'press i' --do 'press r' --do 'press a' --do 'press c' --do 'press e' --do 'wait 400' --do 'press m' --do 'press a' --do 'wait 400' --do 'eval report()'
-- focus #q
-- press i
-- press r
-- press a
-- press c
-- press e
-- wait 400
searching for "irace"
-- press m
-- press a
-- wait 400
searching for "iracema"
-- eval report()
keystrokes: 7
```

`page` typed `irace`, paused 400 ms, typed `ma`, and paused again. **Seven keystrokes, two searches**:
one for `irace`, when the first pause outlasted the 300 ms wait, and one for `iracema`.

## How `debounce` works

It is a closure (lesson 6) around one variable, `timer`. Every call **cancels the timer that the
previous call set and starts a new one**. While keys keep coming faster than 300 ms apart, each
timer is cancelled before it can fire. Only when a key is followed by 300 ms of silence does a timer
survive, and it calls `search` with the last value. The wait is a judgement: long enough to skip the
gaps inside a word, short enough that the user does not notice it.

## Its sibling, throttle

**Throttling runs at most once per interval, however many events arrive**, instead of waiting for them
to stop. It suits events that never stop while something is happening, such as scrolling or resizing,
where you want regular updates during the movement, not one at the end. Both are a handful of lines
around `setTimeout`, and both exist in utility libraries under those names.
