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

test('click_on_my_location_marker_displays_you_are_here_popup', async ({ }) => {
  await page.getByRole('button', { name: 'Marker' }).click();
  await expect(page.locator('div.leaflet-popup-content')).toBeVisible();

  await page.getByLabel('Close popup').click();
  await expect(page.locator('div.leaflet-popup-content')).toBeHidden();
});

test('click_on_eat_button_displays_circle_and_nine_images', async ({ }) => {
  await page.getByRole('button', { name: 'EAT!' }).click();
  await expect(page.getByRole('img').locator('path')).toBeVisible();
  await expect(page.locator('img.leaflet-marker-icon.leaflet-zoom-animated.leaflet-interactive')).toBeVisible();
  
  await page.getByRole('button', { name: 'Reset' }).click();
  await expect(page.getByRole('img').locator('path')).toBeHidden();
  await expect(page.locator('img.leaflet-marker-icon.leaflet-zoom-animated.leaflet-interactive')).toHaveCount(1);
});
