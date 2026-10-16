#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Section `a-stand-in` shows
# soap/invoice-service.mjs whole, section `calling-it` shows soap/issue.xml
# and installs libxml2-utils with apt-get, the way this machine had it
# installed, and section `asserting` shows soap/check.sh. ../../lab.sh writes
# the project from those very blocks before anything runs. boxoffice is not
# started: nothing in this lesson talks to it. What is STAGED rather than typed:
#   - the invoice service, started in the background where the lesson starts
#     it in a second terminal; its first line, the one the lesson shows under
#     `node soap/invoice-service.mjs`, is read from its log, and so is the log
#     the lesson shows at the end of section `asserting`.
# issuedAt and verificationCode depend on the moment of the recording and
# differ on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0 and
# xmllint from libxml2 2.9.14, TZ=America/Sao_Paulo, as user ana. See
# ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 9 /home/ana/boxoffice
here /home/ana/boxoffice

H="-H 'content-type: text/xml; charset=utf-8'"
A="-H 'SOAPAction: \"urn:example:invoice:v1#IssueInvoice\"'"
U=localhost:8085/invoice

# rc_run CMD: like run, and the exit status is kept for the `echo $?` the
# lesson shows next, which a separate shell could not see.
rc_run() {
  rm -f /tmp/lab-rc; prompt; printf '%s\n' "$1"
  as_ana "script -qec $(printf '%q' "$1") /dev/null; echo \$? > /tmp/lab-rc" 2>&1 | strip
}

block start
prompt; echo 'node soap/invoice-service.mjs'
serve invoice 'node soap/invoice-service.mjs'
head -1 /tmp/lab-invoice.log

block wsdl-head
run "curl -si '$U?wsdl' | head -12"

block xmllint-version
run 'xmllint --version 2>&1 | head -1'

block call
run "curl -si $U $H $A --data-binary @soap/issue.xml"

block call-format
run "curl -s $U $H $A --data-binary @soap/issue.xml | xmllint --format -"

block fault-tax-id
run "sed 's/12345678909/123/' soap/issue.xml | curl -si $U $H $A --data-binary @-"

block no-action
run "curl -s $U $H --data-binary @soap/issue.xml | xmllint --format -"

block soap12
run "curl -si $U -H 'content-type: application/soap+xml' $A --data-binary @soap/issue.xml"

block no-amount
run "sed '/amountCents/d' soap/issue.xml | curl -s $U $H $A --data-binary @- | xmllint --format -"

block xpath-empty
rc_run "curl -s $U $H $A --data-binary @soap/issue.xml | xmllint --xpath '//invoiceNumber' -"
prompt; echo 'echo $?'; cat /tmp/lab-rc

block xpath-local
run "curl -s $U $H $A --data-binary @soap/issue.xml | xmllint --xpath 'string(//*[local-name()=\"invoiceNumber\"])' -"

block wsdl-ops
run "curl -s '$U?wsdl' | xmllint --xpath '//*[local-name()=\"operation\"]/@name' -"
run "curl -s '$U?wsdl' | xmllint --xpath '//*[local-name()=\"operation\"]/@soapAction' -"

block xpath-fault
run "sed 's/12345678909/123/' soap/issue.xml | curl -s $U $H $A --data-binary @- | xmllint --xpath 'string(//faultcode)' -"

block check
rc_run 'bash soap/check.sh'
prompt; echo 'echo $?'; cat /tmp/lab-rc

block log
prompt; echo 'node soap/invoice-service.mjs'
cat /tmp/lab-invoice.log
halt invoice
