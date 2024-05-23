import { test, expect, type Page } from '@playwright/test';

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

  test('Given I see my location on the map', async () => {
    await expect(page.getByRole('button', { name: 'Marker' })).toBeVisible();
  });

  test('When I click on my location marker', async () => {
    await page.getByRole('button', { name: 'Marker' }).click();
  });

  test('Then I should see a popup with the text "You are here"', async () => {
    const popup = await page.locator('div.leaflet-popup-content');

    await expect(popup).toBeVisible();
    await expect(popup.textContent()).resolves.toBe('You are here');
  });

  test('When I click the popup close button', async () => {
    await page.locator('a.leaflet-popup-close-button').click();
  });

  test('Then I should see the popup disapear', async () => {
    await expect(page.locator('div.leaflet-popup-content')).toBeHidden();
  });
});

test.describe('Basic Food Search', async () => {

  test('Given I see the EAT! and Reset buttons', async () => {
    await expect(page.getByRole('button', { name: 'EAT!' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Reset' })).toBeVisible();
  });

  test('When I click the EAT! button', async () => {
    await page.getByRole('button', { name: 'EAT!' }).click();
  });

  test('Then I should a boundary circle with several truck icons inside', async () => {
    await expect(page.locator('path.leaflet-interactive')).toBeVisible();
    await expect(page.locator(`//img[contains(@src, 'truck-solid.png')]`)).toBeTruthy();
  });

  test('When I click the Reset button', async () => {
    await page.getByRole('button', { name: 'Reset' }).click();
  });

  test('Then I should see the boundary circle and truck icons should disapear', async () => {
    await expect(page.locator('path.leaflet-interactive')).toBeHidden();
    await expect(page.locator(`//img[contains(@src, 'truck-solid.png')]`)).toBeHidden();
  });
});
