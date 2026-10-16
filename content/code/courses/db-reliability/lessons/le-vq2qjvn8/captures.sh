#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# This lesson is about a service the course does not run, so its transcripts
# are arithmetic done in psql on the lab's own server (`lab.sh base`): the
# downtime an availability percentage allows, and what two components in a row
# promise together. No managed service was contacted, and no provider's figures
# are quoted; the percentages are the ones such agreements commonly use.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base

block budget
printf "SELECT p AS availability, justify_interval(interval '30 days' * (1 - p / 100)) AS down_per_month, justify_interval(interval '365 days' * (1 - p / 100)) AS down_per_year FROM (VALUES (99.0), (99.9), (99.95), (99.99)) AS t(p);\n" | session shop

block chain
printf "SELECT round(99.95 * 99.95 / 100, 4) AS database_and_app, round(99.95 * 99.95 * 99.9 / 10000, 4) AS with_a_network_link;\nSELECT justify_interval(interval '30 days' * (1 - 99.95 * 99.95 * 99.9 / 1000000)) AS down_per_month;\n" | session shop

block credit
printf "SELECT 2000.00 AS monthly_bill, 2000.00 * 0.10 AS credit_at_10_percent, interval '3 hours' AS outage, 50000 AS orders_per_day, round(50000 / 24.0 * 3) AS orders_not_taken;\n" | session shop
