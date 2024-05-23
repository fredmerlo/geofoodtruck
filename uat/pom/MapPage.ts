import { expect, Page, Locator } from "@playwright/test";

export class MapPage {
  readonly page: Page;
  readonly markerMyLocation: Locator;
  readonly popupContent: Locator;
  readonly buttonPopupClose: Locator;
  readonly buttonEat: Locator;
  readonly buttonReset: Locator;
  readonly boundaryCircle: Locator;
  readonly iconsTruck: Locator;

  constructor(page: Page) {
    this.page = page;
    this.markerMyLocation = page.getByRole('button', { name: 'Marker' });
    this.popupContent = page.locator('div.leaflet-popup-content');
    this.buttonPopupClose = page.locator('a.leaflet-popup-close-button');
    this.buttonEat = page.getByRole('button', { name: 'EAT!' });
    this.buttonReset = page.getByRole('button', { name: 'Reset' });
    this.boundaryCircle = page.locator('path.leaflet-interactive');
    this.iconsTruck = page.locator(`//img[contains(@src, 'truck-solid.png')]`);
  }

  async hasMyLocation()  {
    await expect(this.markerMyLocation).toBeVisible();
  }

  async clickMyLocation() {
    await this.markerMyLocation.click();
  }

  async isPopupOpen() {
    await expect(this.popupContent).toBeVisible();
  }

  async hasPopupText(text: string) {
    await expect(this.popupContent.textContent()).resolves.toContain(text);
  }

  async closePopup() {
    await this.buttonPopupClose.click();
  }

  async isPopupClosed() {
    await expect(this.popupContent).toBeHidden();
  }

  async hasButton( buttonName: string) {
    if (buttonName === 'EAT!') {
      await expect(this.buttonEat).toBeVisible();
    }

    if (buttonName === 'Reset') {
      await expect(this.buttonReset).toBeVisible();
    }
  }

  async clickButton(buttonName: string) {
    if (buttonName === 'EAT!') {
      await this.buttonEat.click();
    }

    if (buttonName === 'Reset') {
      await this.buttonReset.click();
    }
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
