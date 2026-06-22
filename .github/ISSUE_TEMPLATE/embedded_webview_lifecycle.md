---
name: Embedded WebView lifecycle improvement
about: Track the follow-up work for the embedded browser controller flow
title: "Improve embedded WebView lifecycle and controller API"
labels: enhancement
assignees: ''
---

## Why this matters

The first public release is live, but the embedded WebView flow still needs a cleaner lifecycle.

Right now the package has a basic embedded browser API, but the controller handoff should be reviewed so it feels predictable for real apps. The goal is to make this part of the plugin easier to use, easier to test, and safer before the next release.

## What to improve

- Review how `openEmbedded()` returns or exposes the controller.
- Avoid closing the embedded page just to return a controller.
- Keep the API simple for normal users.
- Keep access to the underlying `InAppWebViewController` for advanced users.
- Make events like `pageStarted`, `pageFinished`, and `dismissed` consistent.
- Update the example app so the behavior is clear.
- Add at least one test or manual test note for Android.

## Done when

- Embedded WebView opens and stays visible.
- Controller access works without confusing navigation behavior.
- README/example docs match the real behavior.
- CI passes.
- Version `0.1.2` can be prepared after the fix.
