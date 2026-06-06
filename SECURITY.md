# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security
vulnerabilities. Email `security@example.com` (replace with the
real address) with:

- A description of the vulnerability
- Steps to reproduce
- A proof-of-concept (if possible)

We aim to acknowledge within 48 hours and patch within 7 days for
critical issues, 30 days for lower severity.

## What is in scope

- The Godot plugin code (`addons/meta_sdk/`)
- The GDExtension C++ / Objective-C++ code
- The CocoaPods integration

## What is out of scope

- The Meta (Facebook) SDK itself — report Meta SDK vulnerabilities
  to Meta's bug bounty program.
- godot-cpp — report upstream.
