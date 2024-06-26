import { expect, Page, Locator } from "@playwright/test";

export enum DirectionX { left, right, none };
export enum DirectionY { up, down, none };

export class MapPage {
  readonly page: Page;
  readonly contentPopup: Locator;
  readonly buttonPopupClose: Locator;
  readonly boundaryCircle: Locator;
  readonly iconsTruck: Locator;
  readonly inputFindFood: Locator;
  readonly selectDistance: Locator;
  readonly map: Locator;
  readonly mapWaitTime: number = 2500;

  constructor(page: Page) {
    this.page = page;
    this.contentPopup = page.locator('.leaflet-popup-content');
    this.buttonPopupClose = page.getByLabel('Close popup');
    this.boundaryCircle = page.locator('path.leaflet-interactive');
    this.iconsTruck = page.locator(`//img[contains(@src, 'truck-solid.png')]`);
    this.inputFindFood = page.locator('#searchInput');
    this.selectDistance = page.locator('#searchSelect');
    this.map = page.locator('#map');
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
    const locator = this.page.getByRole('button', { name: buttonName });
    await locator.waitFor({ state: 'visible' });
    await expect(locator).toBeVisible();
  }

  async clickButton(buttonName: string) {
    const locator = this.page.getByRole('button', { name: buttonName });
    locator.waitFor({ state: 'visible' });
    await locator.click();
  }

  async isBoundaryCircleVisible() {
    await expect(this.boundaryCircle).toBeVisible();
  }

  async isBoundaryCircleHidden() {
    await expect(this.boundaryCircle).toBeHidden();
  }

  async areTruckIconsVisible() {
    await expect(this.iconsTruck).not.toBeFalsy();
  }

  async areTruckIconsHidden() {
    await expect(this.iconsTruck).toBeHidden();
  }

  async clickSelectDistance() {
    await this.selectDistance.click();
  }

  async clickSelectDistanceOption(option: string) {
    await this.selectDistance.selectOption(option);
  }

  async typeInputFindFood(text: string) {
    await this.inputFindFood.fill(text);
  }

  async pixelsFor(miles: number) {
    const p = await this.page.evaluate((miles) => {      
      return (window as any).milesToPixels(miles);
    }, miles);

    return p;
  }

  async clickMapForDistance(milesX: number, milesY: number) {
    const mapBox = await this.map.boundingBox();
    
    await expect(mapBox).not.toBeNull();

    const cleanBox: any = mapBox;
    const mapCenterX = cleanBox.x + cleanBox.width / 2;
    const mapCenterY = cleanBox.y + cleanBox.height / 2;

    const pX = await this.pixelsFor(milesX);
    const pY = await this.pixelsFor(milesY);

    await this.map.click({ button: 'left', position: { x: pX + mapCenterX, y: pY + mapCenterY }, force: true });
    await this.page.waitForTimeout(this.mapWaitTime);
  }

  async clickMapToPan(steps: number, x: DirectionX, y: DirectionY) {
    const mapBox = await this.map.boundingBox();
    
    await expect(mapBox).not.toBeNull();

    const cleanBox: any = mapBox;
    const mapCenterX = cleanBox.x + cleanBox.width / 2;
    const mapCenterY = cleanBox.y + cleanBox.height / 2;
    
    const pX = x === DirectionX.none ? 0 : x === DirectionX.left ? -1 : 1;
    const pY = y === DirectionY.none ? 0 : y === DirectionY.up ? -1 : 1;

    for (let i = 0; i < steps; i++) {
      await this.map.click({ button: 'left', position: { x: (pX *  mapCenterX) + mapCenterX, y: (pY * (mapCenterY - 2) ) + mapCenterY }, force: true });
      await this.page.waitForTimeout(this.mapWaitTime);
    }
  }

  async keyPress(key: string) {
    await this.inputFindFood.click();
    await this.inputFindFood.press(key);
  }

  async pageRefresh() {
    await this.page.reload({ waitUntil: 'domcontentloaded'});
  }

  async hasValueInputFindFood(search: string) {
    await expect(this.inputFindFood).toHaveValue(search);
  }
}
