[![Playwright Tests](https://github.com/fredmerlo/geofoodtruck/actions/workflows/test.yml/badge.svg)](https://geofoodtruck-test-report.s3.amazonaws.com/index.html)
[![GeoFoodTruck Live](https://github.com/fredmerlo/geofoodtruck/actions/workflows/deploy.yml/badge.svg)](https://d3n9iqvbhzuqoh.cloudfront.net)
# Showcase Project
`GeoFoodTruck` uses the City of San Francisco public dataset of [Mobile Food Facility Permit Registry](https://data.sfgov.org/Economy-and-Community/Mobile-Food-Facility-Permit/rqzj-sfat/about_data) (Food Trucks), to provide a Map Search application of food trucks close to me, [view screencast](#geofoodtruck-application).

### You can talk-the-talk, but can you walk-the-walk?
As a `Cloud and Software Engineering` applying my craft over several years, I've been fortunate to contribute and deliver technology solutions in multiple markets.

All the details of my career journey are documented on my [resume](https://www.linkedin.com/in/fred-merlo-ab4b10) (*talk-the-talk*), I created this project to Showcase `some` of my skills in action (*walk-the-walk*). 
#### Attribution
- I am the `Owner` of the `GeoFoodTruck` repository.
- I am the `Sole Contributor` on the `GeoFoodTruck` repository.
- My `Creative Efforts` produced all code artifacts in the `GeoFoodTruck` repository.

  **Excluding boilerplate React web application elements**

  **All 3rd-party Datasets, Frameworks and Libraries, are owned by their respective creators**

### Implementation
The goal of my implementation is to present a foundational `Cloud Product Delivery` Architecture, using Agile Methodologies, Full-Stack development and CI / CD pipelines. 

And of course showcase my applied my expertise to Design, Create and Integrate the  technologies to make it all work.

The key techonlogies are:
| Tech | Purpose |
| --- | --- |
| React | `GeoFoodTruck` web application |
| Playwright | UI Automation, UAT and Reporting |
| Terraform | Infrastructure as Code |
| Git Workflow | CI / CD for Deploy and Test |
| AWS KMS | Managed Encryption |
| AWS Cloudfront | Content Delivery, Caching and TLS Encryption in Transit |
| AWS OAC | Token Authorization for Cloudfront to S3 |
| AWS S3 | KMS Encrypted at Rest of Application Files |
| AWS WAFv2 | Cloudfont Traffic Telemetry, DoS Protection, Bot Filter, Malicious Agents Filter |
| Docker | Container for running UATs from Test Git Workflow |
#### Disclaimer
Though my implementation uses a specific techonlogy stack, the general `Cloud Product Delivery` Architecture pattern is applicable with most CSP, IaC or CI / CD.

I do not promote or endorse any of the technologies used in my implementation. My technology selection criteria basically boiled down to the following:

1. Least effort to business value objective, my use case objective is to have a complete integration with least overhead.
2. Learning/Updating technical expertise is worth the extra effort, ie: Git Workflow Playwright with Docker, Terraform WAFv2 updates.
3. Some things are just cool and fun (maybe a lil painful), ie: Leaflet and Leaflet React.

### Approach
My approach combines hands-on technical leadership and software engineering with strategic oversight, ensuring that scalable, efficient and secure cloud solutions align with business objectives.

1. #### Web Application Design and Development
   Though my expertise spans beyond solely creating web applications, most organizations produce and maintain such systems.

   `GeoFoodTruck` is a React web application, view [GeoFoodTruck Details](DETAILS.md) for more information.
2. #### Agile Business Value from Inception to Realization
   As architect I collaborate regularly with Stakeholders, Product Owners and Delivery Managers, my primary focus is to understand the business objectives and the desired outcome. I document and define Feature Workstreams, create and refine the Stories for each workstream. Each Story will usually contain one or more User Need, documented as Acceptance Criteria (AC).
   
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
   - Transparent, Frequent and Detailed feedback is paramount to supporting Agile Software Development teams. The UATs paired with the CI / CD pipeline enable `near-real-time` reporting of the application quality. The [Tests Result Report](https://geofoodtruck-test-report.s3.amazonaws.com/index.html) is published and available to all project collaborators.
      
      **Happy Path**
      ![Tests Result Happy](https://geofoodtruck-test-report.s3.amazonaws.com/tests-result-happy.png)

      **Less-Happy Path**
      ![Tests Result Less-Happy](https://geofoodtruck-test-report.s3.amazonaws.com/tests-result-less-happy.png)
3. #### Automate Everything
   Or try to Automate as much as resonably possible. The key concept is to strive for `Idempotency`, run once or 100 times, given the same input the outcome will always be the same. Eliminating manual intervention is another practice to boost Agile Development Teams productivity.

   For `GeoFoodTruck`, the CI / CD pipeline acheives `Complete Automation`, from source code modifications to Cloud deployment and Application Quality validation with UATs.

   I implemented OIDC GitHub Authentication to requet AWS temporary credentials, eliminating manual administration of AWS Keys and Secrets, necessary to provision Cloud artifacts and infrastructure. 
   
   I created two event triggered Workflows: **Deploy** and **Test**.
   - **Deploy** is activated upon detection of source code changes in the repository. Triggering a new build for the web application and a new deployment of the AWS infrastructure using the Terraform IaC templates. Terraform dynamically identifies if any modifications require infrastructure updates.
   - **Test** is activated upon successful completion of the `Deploy` workflow, using a Docker container to run all UATs to avoid blocking of the `Deploy` workflow. The `Test` workflow publishes the [Tests Result Report](https://geofoodtruck-test-report.s3.amazonaws.com/index.html) available to all project collaborators.

      **Deploy and Test in Action**

      ![CI-CD Workflow](https://geofoodtruck-test-report.s3.amazonaws.com/geofoodtruck-ci-cd.gif) 

4. #### Cloud Product Delivery
   A Well Architected Cloud product requires a thorough assessment of the workload being provisioned, at a high-level this evaluation will consider Operations, Security, Performance, Resiliency, Sustainability and Costs.

   In `GeoFoodTruck` I implemented the baseline patterns that are common for web application cloud workloads.

   - Development Operations (DevOps)

     The `GeoFoodTruck` Deploy and Test CI / CD pipeline, although unsophisticated, it is effective in representing a Minimum Viable Product to support DevOps. It very easily can be leveraged as a template for a green-field or POC projects.

     On a more robust DevOps implementations the team would have multi-stage deployments to various environments (Dev, Stage, Pre-Prod, Prod), the Test pipeline may have a scheduled Canary environment for spot-checks. Automated Issue Ticket creation, Monitoring and Telemetry Notifications, the sky is the limit of what can be accomplished.

     However the basic workflow principles apply, Build changes, Deploy changes, Validate deployment. 

   - Shift-Left Security (SecDevOps)

     `GeoFoodTruck` does not work with PII or PCI information nor does it use Authentication and Authorization, however I pupurposely applied a Shift-Left security posture, here was Terraform's moment in the spotlight.

     Using Terraform I defined, configured and provisioned the AWS services required to harden security for the `GeoFoodTruck` application. Applying Encryption at Rest, Encryption in Transit, Malicous Traffic Detection and Filtering, Access Abstraction between Web and Backend, Traffic Telemetry, to name a few. WAF provides a plethora of traffic telemetry, exportable to CloudWatch or to JSON for data science die-hards.

     My objective was to highlight the importance of a Shift-Left / Security-First mindset our development teams need to be adopting and applying.

     **Couple WAF Dashboards**

     ![Bot Detection](https://geofoodtruck-test-report.s3.amazonaws.com/waf-bot-detection.png)
     ![Sampled Requests](https://geofoodtruck-test-report.s3.amazonaws.com/waf-sampled-request.png)

   - Performance and Cost (CloudOps)

     The security hardening applied to `GeoFoodTruck` uses and S3 bucket Encryption at Rest of the application files. The downside is that putting data into S3 is free, however getting data out of S3 is `NOT` free. Fortunately Cloudfront provides content caching which actually helps with Performance improvement and Cost savings.

     Cloudfront is an AWS Global Content Deivery Network, and the Cloudfront cache is replicated by AWS, though `GeoFoodTruck` application content is relatvely small, not having to pay S3 object retrieval costs is a big plus. And as an added bonus the `GeoFoodTruck` application is available @Edge to users everywhere.

     **Cloudfront Cache Metrics**
     
     ![Cloudfront Cache](https://geofoodtruck-test-report.s3.amazonaws.com/cloudfront-cache.png)

### GeoFoodTruck Application

![GeoFoodTruck](https://raw.githubusercontent.com/fredmerlo/geofoodtruck/main/geofoodtruck.gif)
