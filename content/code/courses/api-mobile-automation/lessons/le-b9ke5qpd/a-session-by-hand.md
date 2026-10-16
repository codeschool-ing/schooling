---
title: A session by hand, with curl
version: 1
---

**Before any test library, hold a session yourself**: start it, find an element, tap it, read the
screen, end it, one curl command each. A test does nothing else. When one fails, the first thing to
find in the server's log is the request it was making.

That needs a device, and this lesson has a way round it you can use too: **Appium's fake driver**.
Appium's own developers test the server with it. It answers the real WebDriver protocol, through
the real server. But its "app" is an XML file describing a screen, and its "device" is that file in
memory. Nothing is drawn and nothing is installed, so it runs on any computer, emulator or not.
**It is a stand-in, and this section says so wherever it matters.** What you learn from it is the
protocol, never how Tickets behaves.

## The fake driver and its app

Install it like the Android driver. It is published under Appium's own name on npm rather
than in Appium's list of drivers, so it is named by its package. The list that follows asks which
drivers the project now has. `grep` keeps the lines that name one:

```
ana@laptop:~/boxoffice$ npx appium driver install --source=npm @appium/fake-driver@6.2.4 2>&1 | tail -3
i Driver fake@6.2.4 successfully installed
- automationName: Fake
- platformNames: ["Fake"]
ana@laptop:~/boxoffice$ npx appium driver list --installed 2>&1 | grep 'installed ('
- uiautomator2@8.7.0 [installed (npm)]
- fake@6.2.4 [installed (npm)]
```

**The server loads its drivers when it starts**, so a driver installed while it runs is not there
yet. Stop the server with Ctrl-C in its terminal and start it again:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1
[Appium] Welcome to Appium v3.8.0
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
[Appium] Available drivers:
[Appium]   - uiautomator2@8.7.0 (automationName 'UiAutomator2')
[Appium]   - fake@6.2.4 (automationName 'Fake')
```

The fake driver's app is a model of a screen. This one copies the list screen of Tickets from
lesson 14: the same classes and the same resource ids, the banner and the error line hidden as the
app hides them, three rows. A real driver builds this tree from the device. Here it is written by
hand, and its text is left out because the fake driver cannot read text from a model anyway.
Save it as `appium/tickets-model.xml`:

```xml
<!-- appium/tickets-model.xml: Tickets's list screen, as a model for Appium's fake driver -->
<app name="Tickets" width="1080" height="2400">
  <android.widget.TextView id="example.tickets:id/banner" visible="false" />
  <android.widget.Button id="example.tickets:id/refresh" left="42" top="180" width="294" height="126" />
  <android.widget.TextView id="example.tickets:id/error" visible="false" />
  <android.widget.ListView id="example.tickets:id/shows" left="42" top="306" width="996" height="2052">
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
  </android.widget.ListView>
</app>
```

And the capabilities that ask for a session of it, in a file so the command stays short. The path
to the app is relative to the folder the server was started in. Save it as `appium/fake-caps.json`:

```json
{
  "capabilities": {
    "alwaysMatch": {
      "platformName": "Fake",
      "appium:automationName": "Fake",
      "appium:app": "appium/tickets-model.xml"
    }
  }
}
```

## Starting the session

`POST /session` with the capabilities. Before the right request, the wrong one,
because almost everybody meets this error early: capabilities without the `appium:` prefix of
section 02.

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session -H 'content-type: application/json' -d '{"capabilities":{"alwaysMatch":{"platformName":"Fake","automationName":"Fake"}}}' | jq '.value | {error, message}'
{
  "error": "invalid argument",
  "message": "All non-standard capabilities should have a vendor prefix. The following capabilities did not have one: automationName"
}
```

The server checked the names before looking for a driver, and refused. Now with the file:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session -H 'content-type: application/json' -d @appium/fake-caps.json | jq
{
  "value": {
    "capabilities": {
      "platformName": "Fake",
      "automationName": "Fake",
      "app": "appium/tickets-model.xml"
    },
    "sessionId": "d7a40f7d-27ad-4e1e-b316-b3fd4dd6e58e"
  }
}
```

The answer repeats the capabilities the session got, prefixes removed, and gives it an id. **Every
later request names the session in its path.** Copy the id into a variable, as you copied a
token in lesson 3. Yours will be a different one:

```
ana@laptop:~/boxoffice$ SESSION=d7a40f7d-27ad-4e1e-b316-b3fd4dd6e58e
```

## Finding an element and tapping it

A find names a **strategy** and a value. Here the strategy is `id`, which on Android means the
resource id, and the value is the one lesson 14 gave the button.

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/refresh"}' | jq
{
  "value": {
    "element-6066-11e4-a52e-4f735466cecf": "1",
    "ELEMENT": "1"
  }
}
```

The answer is a reference to the element. Its key is long because the W3C chose one that could
never clash with a real field name. Its value, `1`, is the element's id **inside this session**,
and the next requests use it in their paths. A tap is a click in WebDriver's vocabulary:

```
ana@laptop:~/boxoffice$ curl -s -X POST localhost:4723/session/$SESSION/element/1/click -H 'content-type: application/json' -d '{}'; echo
{"value":null}
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element/1/attribute/clicks; echo
{"value":"1"}
```

`null` is the protocol's way of saying *done, and nothing to report*. The second request reads an
attribute called `clicks`, which only the fake driver keeps. It counts taps so that its own tests
can prove one arrived. A real app answers a tap by changing its screen, and a real test checks the
screen.

## When nothing matches

The list screen has no `remind` switch; it belongs to the show's screen. Ask for it anyway:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/remind"}' | jq '.value | {error, message}'
{
  "error": "no such element",
  "message": "An element could not be located on the page using the given search parameters."
}
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/remind"}'
404
```

`no such element`, with the status **404**. It is the error a test meets most often, and it means exactly one thing: at the moment the server
looked, nothing on the screen matched. It does not say whether the element is missing for good or
simply not drawn yet. Section 06 is about telling those apart.

## The whole screen

`GET …/source` returns the tree the driver is searching:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/source | jq -r .value
<!-- appium/tickets-model.xml: Tickets's list screen, as a model for Appium's fake driver -->
<AppiumAUT><app name="Tickets" width="1080" height="2400">
  <android.widget.TextView id="example.tickets:id/banner" visible="false" />
  <android.widget.Button id="example.tickets:id/refresh" left="42" top="180" width="294" height="126" />
  <android.widget.TextView id="example.tickets:id/error" visible="false" />
  <android.widget.ListView id="example.tickets:id/shows" left="42" top="306" width="996" height="2052">
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
  </android.widget.ListView>
</app></AppiumAUT>
```

The fake driver returns its model with a wrapper, `AppiumAUT`, around it. **On a real device this
is the most useful request in Appium**: UiAutomator2 answers with the live tree. Every node carries
its class, its `resource-id`, its `text`, its `content-desc` and its `bounds`, the attributes lesson
14 named. When a locator finds nothing, read the source and look for the element the way the driver
sees it.

## Ending it

```
ana@laptop:~/boxoffice$ curl -s -X DELETE localhost:4723/session/$SESSION; echo
{"value":null}
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/source | jq '.value | {error, message}'
{
  "error": "invalid session id",
  "message": "A session is either terminated or not started"
}
```

`DELETE` ends the session and frees the device for the next one. Any request to the old id
afterwards is `invalid session id`. **A test that dies without the `DELETE` leaves its session
open** until the server's timeout for idle sessions closes it. With a real device, the next test can
then wait for a device that is still busy. Test code ends its session in a block
that runs whether the test passed or not, which section 05 does.
