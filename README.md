[![Playwright Tests](https://github.com/fredmerlo/geofoodtruck/actions/workflows/test.yml/badge.svg)](https://geofoodtruck-test-report.s3.amazonaws.com/index.html)
[![GeoFoodTruck Live](https://github.com/fredmerlo/geofoodtruck/actions/workflows/deploy.yml/badge.svg)](https://d3n9iqvbhzuqoh.cloudfront.net)
# Showcase Project
`GeoFoodTruck` uses the City of San Francisco public dataset of Mobile Food Vendors Registry (Food Trucks), to provide a Map Search application of food trucks close to me, [view screencast](#geofoodtruck-application).

### You can talk-the-talk, but can you walk-the-walk?
As a `Cloud and Software Engineering` applying my craft over several years, I've been fortunate to contribute and deliver technology solutions in multiple markets.

All the details of my career journey are documented on my [resume](https://www.linkedin.com/in/fred-merlo-ab4b10) (*talk-the-talk*), I created this project to Showcase `some` of my skills in action (*walk-the-walk*). 
#### Attribution
- I am the `Owner` of the `GeoFoodTruck` repository.
- I am the `Sole Contributor` on the `GeoFoodTruck` repository.
- My `Creative Efforts` produced all code artifacts in the `GeoFoodTruck` repository.

  **Excluding boilerplate React web application elements**

  **All 3rd-party Frameworks and Libraries, are owned by their respective creators**

### Implementation Focus
Specifically my implementation demonstrates the following:

1. #### Web Application Design and Development
   Though my expertise spans beyond solely creating web applications, most organizations produce and maintain such systems.

   `GeoFoodTruck` is a React web application, view [GeoFoodTruck Details](DETAILS.md) for more information.
2. #### Agile Business Value from Inception to Realization
   As an architect I collaborate regularly with Stakeholders, Product Owners and Delivery Managers, my primary focus is to understand the business objectives and the desired outcome. I document and define Feature Workstream, create and refine the Stories for the workstream. Each Story will usually contain one or more User Need, documented as Acceptance Criteria (AC).
   
   - ACs document a specific User Need described in Layman Terms and written in `GIVEN-WHEN-THEN` syntax.

      ```
      GIVEN I see my location marker
      WHEN I click on my location marker
      THEN I should see a popup with the text "You are here"
      ```
   - The Behavior described by the AC is then codified to a User Accptance Test (UAT). This development technique is known as Behavior Driven Developmet (BDD). From the previous AC, this would be the corresponding UAT, using [Playwright](https://playwright.dev) UI Automation and integrated with Page Object Model ([POM](https://playwright.dev/docs/pom)) pattern, resulting in clean tests that closely follow the AC definition.

      ```
      test('My Location Marker', async () => {
         // POM instance
         const mapPage = new MapPage(page);

         // GIVEN I see my location marker
         await mapPage.hasButton('Marker');

         // WHEN I click on my location marker
         await mapPage.clickButton('Marker');

         // THEN I should see a popup
         await mapPage.isPopupOpen();

         // with the text "You are here"
         await mapPage.hasPopupText('You are here');
      });
      ```
   - Transparent, Frequent and Detailed feedback is paramount to supporting Agile Software Development teams. The UATs paired with the CI / CD pipeline enable `near-real-time` reporting of the application quality. The [Tests Result Report](https://geofoodtruck-test-report.s3.amazonaws.com/index.html) is published and available to all.
      
      **Happy Path**
      ![Tests Result Happy](https://geofoodtruck-test-report.s3.amazonaws.com/tests-result-happy.png)

      **Less-Happy Path**
      ![Tests Result Less-Happy](https://geofoodtruck-test-report.s3.amazonaws.com/tests-result-less-happy.png)
3. #### Automated Continuous Integration and Deployment (CI / CD)
4. #### Cloud Product Delivery
   A Well Architected Cloud product requires a thorough assessment of the workload being provisioned, at a high-level this evaluation will consider Operations, Security, Performance, Resiliency, Sustainability and Costs.

   In `GeoFoodTruck` I implemented a sub-set of foundational patterns that are common for web application cloud workloads.

   - Development Operations (DevOps)

   - Shift-Left Security (SecDevOps)

   - Performance and Cost (CloudOps)

### GeoFoodTruck Application
![GeoFoodTruck](https://raw.githubusercontent.com/fredmerlo/geofoodtruck/main/geofoodtruck.gif)

