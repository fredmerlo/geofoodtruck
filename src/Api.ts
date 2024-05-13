var soda = require('soda-js');

export class Api {

  getFoodItemsFilter = (input: string): string => {
    // Regular expression that matches non-alphanumeric and non-space characters
    const alphaNumericWhitespace = /[^a-zA-Z0-9\s]/g;
    const cleanInput = input.replace(alphaNumericWhitespace, '');
    
    const wordsList = cleanInput.split(' ').map((word) => word.trim());

    const foodItems = `fooditems LIKE '%${wordsList.join('% %')}%'`;
    const inGoodStanding = `AND (status='APPROVED' OR status='REQUESTED' OR status='ISSUED')`;

    // approved, issued, and requested permits and if there are food items, filter by them
    return `${inGoodStanding} ${cleanInput.length > 0 ? `AND (${foodItems})` : ''}`;
  }

  getRadiusFilter = (input: string[]): string => {
    return `within_circle(location, ${input[0]}, ${input[1]}, ${input[2]})`;
  };

  runQuery = async (callback: any, filters: string[]) => {
    // soql client instance
    const consumer = new soda.Consumer('data.sfgov.org', {
      apiToken: 'orbgoiQ2VLgXkbNwse15yufEU',
    });

    // build radius and food items filters
    const radiusFilter = this.getRadiusFilter(filters);
    const foodItemsFilter = this.getFoodItemsFilter(filters[3]);

    await consumer.query()
    .withDataset('rqzj-sfat')
    .select('applicant, status, fooditems, location')
    .where(`${radiusFilter} ${foodItemsFilter}`)
    .getRows()
    .on('success', (rows: any) => {
      const geoJs: any = { type: 'FeatureCollection', features: [] };
      
      // map rows to geoJson features
      geoJs.features = rows.map((row: any) => {
        return {
          type: 'Feature',
          properties: {
            name: row.applicant, 
            status: row.status, 
            fooditems: row.fooditems,
            popupContent: `<div><span>${row.applicant}</span><hr /><span>${row.fooditems}</span></div>`
          }, 
          geometry: {
            type: 'Point', 
            coordinates: [row.location.longitude, row.location.latitude]
          }
        };
      });

      callback(geoJs);
    })
    .on('error', (error: any) => { 
      console.error(error);
      // return empty geoJson
      callback({ type: 'FeatureCollection', features: [] });
    });
  };
};

// sample soql query
// curl -H X-App-Token: orbgoiQ2VLgXkbNwse15yufEU https://data.sfgov.org/resource/rqzj-sfat.geojson?%24select=applicant%2C%20status%2C%20fooditems%2C%20location%20where%20within_circle%28location%2C37.784279%2C-122.40266096031468%2C1607.5135382417056%29%20AND%20status%3D%27APPROVED%27
