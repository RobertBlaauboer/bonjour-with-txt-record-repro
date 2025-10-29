# Bonjour Service Discovery Issue Reproduction

Minimal iOS app to reproduce an issue with Bonjour service discovery in GitHub Actions.

## The Issue

We're seeing different behavior when using NWBrowser's `.bonjour` vs `.bonjourWithTXTRecord` for service discovery, only in CI environments.

## What This Does

- Searches for `_test._tcp` services using NWBrowser
- Runs on iPhone 16 Pro simulator
- Tests both `.bonjour` and `.bonjourWithTXTRecord` descriptors
- Logs everything to a file

## How to See the Difference

The GitHub Actions workflow runs 2 parallel jobs - one for each browser type:

1. Go to the Actions tab
2. Look for the two matrix jobs: `bonjour` and `bonjourWithTXTRecord`
3. Download the artifacts from each run
4. Compare the logs to see how service discovery differs
5. Note that the `bonjour` logs indicate a service was found but the `bonjourWithTXTRecord` logs do not

The switch between browser types is in `ServiceBrowser.swift` line 24, controlled by the `BROWSER_TYPE` environment variable.
