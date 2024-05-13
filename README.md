# Getting Started with the GeoFoodTruck app

### Pre-Requisites
1. Install Node v18 for your operating system

   [Node v18 download page](https://nodejs.org/download/release/v18.19.1/)

   To verify that Node v18 has been correctly installed in your system.

   Use a shell terminal, run the following command:

   ```
   node --version
   ```
   This should display `v18.##.#`

2. Clone the `geofoodtruck` into a local directory on your system
   
   Use a shell terminal, run the following commands:

   ```
   cd <app-clone-directory>/geofoodtruck/
   npm install
   ```
### Approach Rationale
The challenge is about Food with GeoLocation data, this begs to be a `Map Search Solution`, so why not.

### Technology Choice
The primary objective was to have a reasonably useful application with low to moderate time investemnt. So with that in mind these were my selections:

- React 18, no Redux keeps it simple
- [Leaflet](https://leafletjs.com/) OSS javascript interactive maps, with strong community support, and Typescript support (somewhat).
- [Soda-ts](https://github.com/data-depo/soda-ts) OpenData client in Typescript, although OpenData is a fairly basic API using a Soda client is a productivity accelerator decision.

### So how did it go?
It has been a few years since I last used mapping and geolocation technologies, this was an opportunity to get back into the fray so to speak. I've always have fun and learn plenty when dealing with mapping stuff.

### My workflow
- Frist I took time to understand the source Soda data set, to see what the data looked like, assess the data structures and identify any potential challenges.
- Next I identified Soda clients that I could leverage, its http how hard can it be? Famous last words.
- Next I began the web application setup and development with Leaflet, in my experience this area is the most time consuming so I wanted to get that tackled early on.

As anticipated there was a learning curve with familiarizing myself with the Leaflet platform and Apis, but being familiar with mapping technologies it wasn't exceedingly challenging.

Having completed with the Map and UI tasks, I proceeded on integrating with the Soda client and dataset.

This is where the churn occured.

Soda clients for Typescript and javascript are quite dated, not having been maintained in several years. My choice in using somewhat-newer web frameworks was actually a handicap with the dated implementations of the Soda clients available to my technology.

### Overall
I was able to get the idea out of my head and into working software, took a tad-bit longer than what I had considered particularly in areas where I didn't expect. It's software development never a dull moment.

I appreciate your team sharing this challenge, it has been by far the most enjoyable I've had. Thank you for the opportunity.

![GeoFoodTruck](https://raw.githubusercontent.com/fredmerlo/geofoodtruck/main/geofoodtruck.gif)

#
### This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).


### Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.\
You will also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).
