---
title: SoapUI, described from the outside
version: 1
---

**SoapUI is a desktop application for testing web services, and it was built for SOAP first.** It
reads a WSDL and turns it into ready-made requests, chains them into test cases, checks each answer
with assertions, and can pretend to be a service that does not exist yet. Everything in sections 05
and 06 has a screen in it. **It was not run for this course**: it is a graphical Java application,
and the machine these lessons were recorded on has no screen. What follows describes its screens in
words, and none of it is a capture.

## The product and the licence

There are two products with one name in them. **SoapUI Open Source** is free, published by
SmartBear under the European Union Public Licence, and downloaded from soapui.org; it is the one
this section describes. **ReadyAPI** is SmartBear's paid product built on it, with a nicer editor
for data-driven tests, reports and support, sold by subscription on terms SmartBear sets and can
change. Older articles call the paid one *SoapUI Pro*, the name it had before.

SoapUI also tests REST APIs, and many teams use it only for that. Its strength is still the WSDL:
for REST it has nothing to read the operations from unless you give it an OpenAPI document.

## A project from the WSDL

You start with **New SOAP Project**, give it a name and the WSDL's address,
`http://localhost:8085/invoice?wsdl`, and leave *Create sample requests* ticked. SoapUI reads the
WSDL from section 04 and builds a tree on the left:

- the project, holding the **interface** `InvoiceBinding`, named after the WSDL's binding;
- under it the operation `IssueInvoice`;
- under that a request called *Request 1*, which is the envelope of section 05 with a `?` where
  each value goes.

Opening the request shows two panes: the envelope on the left, which you edit, and the reply on the
right after you press the green arrow. The address field above them comes from `soap:address`. The
`SOAPAction` and the `content-type` are filled in from the binding, so the two headers you typed
for curl are never typed at all. That is the whole argument for a WSDL, seen from the tester's
chair.

## Test suites, cases, steps and assertions

A request on its own is a manual check. For a repeatable test you add a **TestSuite**, and inside
it a **TestCase**, which is a list of **test steps** run in order:

| step | does | the curl equivalent |
|---|---|---|
| SOAP Request | sends one envelope to one operation | one `curl --data-binary` |
| Property Transfer | copies a value out of one reply into the next request, by XPath | saving `invoiceNumber` in a shell variable |
| Groovy Script | runs code you write, for anything the other steps cannot do | a line of bash |
| Delay | waits | `sleep` |

Each SOAP Request step carries its own **assertions**, chosen from a list. The ones this lesson has
already written by hand are all there:

| assertion | checks | in `soap/check.sh` |
|---|---|---|
| Valid HTTP Status Codes | the status is one of a list | `check '…: HTTP status' 200` |
| Not SOAP Fault | the reply holds no `Fault` | `boolean(//*[local-name()="Fault"])` is `false` |
| SOAP Fault | the reply **is** a fault, for a negative case | the `500` cases |
| XPath Match | an XPath expression gives an expected value | `string(//faultcode)` is `soap:Client` |
| Contains | the reply contains a piece of text | — |
| Schema Compliance | the reply matches the types in the WSDL | — |

**Schema Compliance is the one with no line in the script.** It checks every element of the reply
against the WSDL's XML Schema, which would catch an `issuedAt` that is not a date or an
`invoiceNumber` gone missing, without an assertion per field. Lesson 10 does the same thing for
JSON with JSON Schema.

In an XPath Match assertion you declare the namespaces, and SoapUI offers a button that declares
every one the reply uses. So there `//inv:invoiceNumber` works, and the `local-name()` workaround of
section 06 is not needed.

## Mock services, and the command line

SoapUI can also generate a **MockService** from the same WSDL: a fake service, on a port you
choose, that answers each operation with a reply you edit. A team uses it to build a caller before
the real service exists, or to make the real one fail on demand. That is the idea of lesson 11,
which builds mocks for a REST dependency.

The whole project is saved as one XML file, which belongs in version control beside the code. A
script called `testrunner.sh` (`testrunner.bat` on Windows), in SoapUI's `bin` directory, runs a
project's test suites without the window and can write JUnit reports, which is how a pipeline runs
them, as Newman runs a Postman collection in lesson 6.

## You do not need SoapUI to test SOAP

SoapUI is a convenience, and a big one when a WSDL has forty operations. Nothing it sends is
special: section 05 called the service with curl, and the tools of earlier lessons can too.
Postman sends an envelope as a raw XML body with the two headers; REST Assured, in lesson 7, posts
XML and reads replies with its `XmlPath`; Karate, in lesson 8, has a `soap action` keyword for
exactly this. Choose SoapUI when the team already keeps its projects there or the WSDL is large,
and choose the tool your API tests already live in when it is not.
