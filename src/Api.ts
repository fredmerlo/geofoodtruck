var soda = require('soda-js');

export class Api {

  getFoodItemsFilter = (input: string): string => {
    // Regular expression that matches non-alphanumeric and non-space characters
    const alphaNumericWhitespace = /[^a-zA-Z0-9\s]/g;
    const cleanInput = input.replace(alphaNumericWhitespace, '');
    const lowerCaseWords = cleanInput.split(' ').map((word) => word.trim().toLocaleLowerCase());

    const buildLikeClauses = lowerCaseWords.reduce((acc: any, word: any) => {
      const pascalCaseWord = word.charAt(0).toUpperCase() + word.slice(1);
      const likeTerm = `(fooditems LIKE '%${word}%' OR fooditems LIKE '%${pascalCaseWord}%')`;

      acc.push(likeTerm);
      return acc;
    }, []);

    // the version of the soql api is Case Sensitive
    // need to search for both lower and pascal case words
    const foodItems = `AND ${buildLikeClauses.join(' AND ')}`;
    const inGoodStanding = `AND (status='APPROVED' OR status='REQUESTED' OR status='ISSUED')`;

    // approved, issued, and requested permits and if there are food items, filter by them
    return `${inGoodStanding} ${cleanInput.length > 0 ? `${foodItems}` : ''}`;
  }

  getRadiusFilter = (input: string[]): string => {
    return `within_circle(location, ${input[0]}, ${input[1]}, ${input[2]})`;
  };

  runQuery = async (callback: any, filters: string[]) => {
    // soql client instance
    const consumer = new soda.Consumer('d3n9iqvbhzuqoh.cloudfront.net');

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
