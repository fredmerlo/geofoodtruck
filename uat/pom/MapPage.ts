import { expect, Page, Locator } from "@playwright/test";

export class MapPage {
  readonly page: Page;
  readonly contentPopup: Locator;
  readonly buttonPopupClose: Locator;
  readonly boundaryCircle: Locator;
  readonly iconsTruck: Locator;

  constructor(page: Page) {
    this.page = page;
    this.contentPopup = page.locator('div.leaflet-popup-content');
    this.buttonPopupClose = page.getByLabel('Close popup');
    this.boundaryCircle = page.locator('path.leaflet-interactive');
    this.iconsTruck = page.locator(`//img[contains(@src, 'truck-solid.png')]`);
  }

  async isPopupOpen() {
    await expect(this.contentPopup).toBeVisible();
  }

  async hasPopupText(text: string) {
    await expect(this.contentPopup.textContent()).resolves.toContain(text);
  }

  async closePopup() {
    await this.buttonPopupClose.click();
  }

  async isPopupClosed() {
    await expect(this.contentPopup).toBeHidden();
  }

  async hasButton( buttonName: string) {
    const locator: Locator = this.page.getByRole('button', { name: buttonName });
    await expect(locator).toBeVisible();
  }

  async clickButton(buttonName: string) {
    const locator: Locator = this.page.getByRole('button', { name: buttonName });
    await locator.click();
  }

  async isBoundaryCircleVisible() {
    await expect(this.boundaryCircle).toBeVisible();
  }

  async isBoundaryCircleHidden() {
    await expect(this.boundaryCircle).toBeHidden();
  }

  async areTruckIconsVisible() {
    await expect(this.iconsTruck).toBeTruthy();
  }

  async areTruckIconsHidden() {
    await expect(this.iconsTruck).toBeHidden();
  }
}
