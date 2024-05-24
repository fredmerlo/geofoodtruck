import { test, Page } from '@playwright/test';
import { MapPage } from '../pom/MapPage';

test.describe.configure({ mode: 'serial' });

let page: Page;

test.beforeAll(async ({ browser }) => {
  page = await browser.newPage();
  
  await page.goto('https://d3n9iqvbhzuqoh.cloudfront.net/');
});

test.afterAll(async () => {
  await page.close();
});

test.describe('Initial Map view', async () => {
  
  test(`GIVEN I see my location marker
WHEN I click on my location marker
THEN I should see a popup with the text "You are here"
  `, async () => {
    const mapPage = new MapPage(page);
    await mapPage.hasButton('Marker');
    await mapPage.clickButton('Marker');
    await mapPage.isPopupOpen();
    await mapPage.hasPopupText('You are here');
  });

  test(`GIVEN I see my location Popup is open
WHEN I click the popup close button
THEN I should not see the popup
  `, async () => {
    const mapPage = new MapPage(page);
    await mapPage.isPopupOpen();
    await mapPage.closePopup();
    await mapPage.isPopupClosed();
  });
});

test.describe('Basic Food Search', async () => {

  test(`GIVEN I see the EAT! button
WHEN I click on the EAT! button
THEN I should a boundary circle
AND I should see several truck icons inside
  `, async () => {
    const mapPage = new MapPage(page);
    await mapPage.hasButton('EAT!');
    await mapPage.clickButton('EAT!');
    await mapPage.isBoundaryCircleVisible();
    await mapPage.areTruckIconsVisible();
  });

  test(`GIVEN I see the Reset button
WHEN I click on the Reset button
THEN I should not see the boundary circle
AND I should not see any truck icons
  `, async () => {
    const mapPage = new MapPage(page);
    await mapPage.hasButton('Reset');
    await mapPage.clickButton('Reset');
    await mapPage.isBoundaryCircleHidden();
    await mapPage.areTruckIconsHidden();
  });
});

test.describe('Food Search', async () => {

  test(`GIVEN I see the Find Food input
WHEN I type "gyro" in the input
AND I click on the EAT! button
THEN I should see a popup with the text "No results found"
`, async () => {
    const mapPage = new MapPage(page);
    await mapPage.typeInputFindFood('gyro');
    await mapPage.clickButton('EAT!');
    await mapPage.isPopupOpen();
    await mapPage.hasPopupText('No results found');
  });

  test(`GIVEN I see the "No results found" popup
WHEN I click on the distance dropdown
AND I click on the "1 mile" option
AND I click on the EAT! button
THEN I should see several truck icons
`, async () => {
    const mapPage = new MapPage(page);
    await mapPage.isPopupOpen();
    await mapPage.hasPopupText('No results found');
    await mapPage.clickSelectDistance();
    await mapPage.clickSelectDistanceOption('1');
    await mapPage.clickButton('EAT!');
    await mapPage.areTruckIconsVisible();
  });
});
