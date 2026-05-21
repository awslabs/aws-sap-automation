// @ts-check
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ODATA_BASE = 'https://launchpad.support.sap.com/services/odata/svt/swdcuisrv/DownloadItemSet';
const ODATA_PARAMS = '$skip=0&$top=500&_EVENT=LIST&EVENT=LIST&SWTYPSC=SPP&PECCLSC=OS&INCL_PECCLSC1=OS&PECGRSC1=LINUX_X64&V=MAINT&TA=ACTUAL&$inlinecount=allpages&sap-language=de-DE';

const PRODUCTS = {
  'SWPM1': { enr: '67838200100200018544', filter: 'for NW higher than 7.0x', comment: 'SWPM 1 LATEST' },
  'SWPM2': { enr: '73555000100200007684', filter: null, comment: 'SWPM 2 LATEST' },
};

const LINKS_CSV = path.resolve(__dirname, '..', 'links.csv');

function formatDate(isoDate) {
  // "2026-04-08" -> "10.04.2026" (DD.MM.YYYY)
  const [y, m, d] = isoDate.split('-');
  return `${d}.${m}.${y}`;
}

async function main() {
  const username = process.env.SAP_USER;
  const password = process.env.SAP_PASSWORD;
  if (!username || !password) {
    console.error('SAP_USER and SAP_PASSWORD environment variables are required');
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    // SAML login
    await page.goto('https://launchpad.support.sap.com/', { waitUntil: 'networkidle', timeout: 60000 });
    await page.fill('#j_username', username);
    await page.click('#logOnFormSubmit');
    await page.waitForLoadState('networkidle');
    await page.fill('input[type=password]', password);
    await page.click('#logOnFormSubmit');
    await page.waitForURL(/launchpad\.support\.sap\.com/, { timeout: 30000 });

    const results = {};

    for (const [name, { enr, filter }] of Object.entries(PRODUCTS)) {
      const url = `${ODATA_BASE}?${ODATA_PARAMS}&ENR=${enr}`;
      const response = await page.goto(url, { waitUntil: 'networkidle' });
      const xml = await response.text();

      const entries = [...xml.matchAll(/<entry>([\s\S]*?)<\/entry>/g)].map(m => {
        const get = (field) => m[1].match(new RegExp(`<d:${field}>(.*?)<\\/d:${field}>`))?.[1] || '';
        return {
          objectId: get('Fastkey'),
          filename: get('Title'),
          description: get('Description'),
          patchLevel: get('PatchLevel'),
          releaseDate: get('ReleaseDate').split('T')[0],
          changeDate: get('ChangeDate').split('T')[0],
          downloadUrl: get('DownloadDirectLink'),
          contentInfoUrl: get('ContentInfoLink'),
        };
      });

      results[name] = filter ? entries.find(e => e.description.includes(filter)) : entries[0];
    }

    console.log(JSON.stringify(results, null, 2));

    // Update links.csv
    let csv = fs.readFileSync(LINKS_CSV, 'utf-8');
    const lines = csv.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    const cols = lines[0].replace(/^\uFEFF/, '').split(',');

    const idx = {
      url: cols.indexOf('URL'),
      dl: cols.indexOf('DOWNLOAD LINK'),
      desc: cols.indexOf('DESCRIPTION'),
      md5: cols.indexOf('MD5'),
      updated: cols.indexOf('LAST UPDATED'),
      released: cols.indexOf('SAP RELEASE DATE'),
      comment: cols.indexOf('COMMENT'),
    };

    let updated = false;
    for (let i = 1; i < lines.length; i++) {
      const fields = lines[i].split(',');
      const comment = fields[idx.comment]?.trim();

      const product = Object.values(PRODUCTS).find(p => p.comment === comment);
      if (!product) continue;

      const match = product.comment === 'SWPM 1 LATEST' ? results.SWPM1 : results.SWPM2;
      if (!match) continue;

      const newUrl = match.contentInfoUrl;
      const newDl = match.downloadUrl;
      const newDesc = match.filename;
      const newDate = formatDate(match.releaseDate);

      if (fields[idx.url] !== newUrl || fields[idx.dl] !== newDl) {
        fields[idx.url] = newUrl;
        fields[idx.dl] = newDl;
        fields[idx.desc] = newDesc;
        fields[idx.md5] = ''; // checksum not fetched
        fields[idx.updated] = formatDate(new Date().toISOString().split('T')[0]);
        fields[idx.released] = newDate;
        lines[i] = fields.join(',');
        updated = true;
      }
    }

    if (updated) {
      fs.writeFileSync(LINKS_CSV, lines.join('\n'));
      console.log('\nlinks.csv updated.');
    } else {
      console.log('\nlinks.csv already up to date.');
    }
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
