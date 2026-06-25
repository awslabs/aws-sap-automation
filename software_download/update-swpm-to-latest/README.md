# Update SWPM to Latest

Automatically updates SWPM 1.0 and 2.0 download links in `links.csv` to the latest versions from SAP Software Center using Playwright for authenticated access.

## Prerequisites

- Node.js 18+
- Valid SAP S-User credentials

## Setup

```bash
cd software_download/update-swpm-to-latest
npm install
npx playwright install chromium
```

## Run

```bash
export SAP_USER="S00xxxxx"
export SAP_PASSWORD="your-password"
npm run update
```

The script will:
1. Log in to SAP Support Launchpad
2. Query the OData API for latest SWPM 1.0 and SWPM 2.0 versions
3. Update all matching rows in `../links.csv` with new URLs, filenames, and dates
