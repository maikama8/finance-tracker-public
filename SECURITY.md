# Security

Kobo stores the ledger on the device. It has no account, no server, and no API key. The only network call is the optional live exchange-rate button, which talks to `open.er-api.com` when you ask and keeps the offline table if that call fails.

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |

## Reporting a vulnerability

Please use [GitHub private vulnerability reporting](https://github.com/maikama8/finance-tracker-public/security/advisories/new). Do not open a public issue for a vulnerability.

Include what you ran, what you expected, and what happened. A CSV or a short description of the row is enough. Leave real account numbers and personal data out.

The maintainer will acknowledge a report and follow up with a fix or an explanation. There is no bug bounty.

## What is in scope

- The ledger being corrupted or disclosed by the app itself
- CSV import treating a hostile file in a way that breaks the book beyond the bad row
- The web build loading its database files from somewhere other than the app origin

Out of scope: the exchange-rate host being down, a device backup the operating system already exposes, and someone with physical access to an unlocked device.
