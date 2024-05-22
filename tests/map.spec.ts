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

test.describe('Given I see my location on the map', async () => {

  test.describe('When I click on the location marker', async () => {

    test('Then I should see a popup with the text "You are here"', async () => {
      await page.getByRole('button', { name: 'Marker' }).click();

      await expect(page.locator('div.leaflet-popup-content')).toBeVisible();
      await expect(page.locator('div.leaflet-popup-content').textContent()).resolves.toBe('You are here');
    });

    test('And when I click the close button, the popup should disapear', async () => {
      await page.locator('a.leaflet-popup-close-button').click();

      await expect(page.locator('div.leaflet-popup-content')).toBeHidden();
    });
  });
});

test.describe('Given I see the EAT buttonn', async () => {

  test.describe('When I click on the button', async () => {

    test('Then I should a boundary circle with several truck icons inside', async () => {
      await page.getByRole('button', { name: 'EAT!' }).click();

      await expect(page.locator('path.leaflet-interactive')).toBeVisible();
      await expect(page.locator(`//img[contains(@src, 'truck-solid.png')]`)).toBeTruthy();
    });

    test('And when I ckick the Reset button, the boundary circle and truck icons should disapear', async () => {
      await page.getByRole('button', { name: 'Reset' }).click();

      await expect(page.locator('path.leaflet-interactive')).toBeHidden();
      await expect(page.locator(`//img[contains(@src, 'truck-solid.png')]`)).toBeHidden();
    });
  });
});
