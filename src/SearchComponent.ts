import { Map, DomEvent, DomUtil, Control, ControlOptions, geoJSON, Layer, icon, LatLng, Marker, LatLngExpression, Circle } from 'leaflet';
import { GeoJsonObject, Feature } from 'geojson';
import { Api } from './Api';

export interface SearchControlOptions extends ControlOptions {
    data?: GeoJsonObject; // optionall GeoJsonObject data to render results without search api
};

export class SearchControl extends Control {
  options: SearchControlOptions;
  geoLayer: any;  // leaflet isn't quite fully TypeScripted
  markerArray: Marker[];
  searchBounds?: Circle;
  api?: Api;

  constructor(options: SearchControlOptions) {
    super(options);
    this.options = options || { data: {}};
    this.geoLayer = geoJSON();
    this.markerArray = new Array<Marker>();
    this.searchBounds = undefined;
    this.api = new Api();
  };

  // Run search usiig select and input values
  private runSearch(select: HTMLSelectElement, input: HTMLInputElement) {
    const searchFilters = this.addSearchArea(select.value);
    const searchInput = input.value;

    // setup search filters and call api
    searchFilters.push(searchInput);
    this.api?.runQuery(this.processResults, searchFilters);
  }

  // Add popup to each feature
  private onEachFeature(feature: Feature, layer: Layer) {
    if (feature.properties && feature.properties.popupContent) {
      layer.bindPopup(feature.properties.popupContent);
    }
  };

  // Add markers for the features
  private addMarker(feature: Feature, latlng: LatLng, markers: Marker[]) {
    const mark = new Marker(latlng, {
      bubblingMouseEvents: false, 
      icon: icon({
        iconUrl: '/truck-solid.png',
        shadowUrl: '',
        iconSize: [25, 25],
        iconAnchor: [22, 25],
        popupAnchor: [-12, -22],
      })
    });

    markers.push(mark);
    return mark;
  };

  // Add search boundary to map
  // using that trig from back in high school
  private addSearchArea(distance: string) {
    // Extract latitude and longitude from center
    const center = this.geoLayer._map.getCenter();
    const latitude = center.lat;
    const longitude = center.lng;

    // Convert distance from string to number
    const distanceMiles = parseFloat(distance);
    
    // Convert latitude from degrees to radians
    const latitudeRadians = latitude * Math.PI / 180;

    // Calculate degrees longitude per mile at the given latitude
    const degreesPerMile = 1 / (69.172 * Math.cos(latitudeRadians));

    // Calculate change in longitude for the given distance in miles
    const deltaLongitude = distanceMiles * degreesPerMile;

    // Compute new longitude
    const newLongitude = longitude + deltaLongitude;

    // Create new LatLngExpression
    const newLatLng: LatLngExpression = [latitude, newLongitude];

    // Calculate distance between center and newLatLng
    const radius = this.geoLayer._map.distance(center, newLatLng);

    // clear previous search bounds
    if (this.searchBounds) {
      this.searchBounds.remove();
    }
    
    this.searchBounds = new Circle(center, {radius: radius}).addTo(this.geoLayer._map);
    this.geoLayer._map.flyToBounds(this.searchBounds.getBounds());

    // cleanup no results popup
    this.searchBounds.on('click', (event) => { 
      this.searchBounds?.unbindPopup();;
    });

    // return geo bounds for radius search
    return [latitude.toString(), longitude.toString(), radius.toString()];
  };

  // Process results from search api
  processResults = (geoJs: any) => {
    if (geoJs) {
      this.clearFeatures();
      
      if (geoJs.features.length > 0) {         
        // search results to map    
        this.geoLayer.addData(geoJs);
      } else {
        // display a no results popup
        this.searchBounds?.bindPopup('No results found.').togglePopup();
      }
    }
  };

  private clearSearchArea() {
    // clean up previous search bounds
    if (this.searchBounds) {
      this.searchBounds.unbindPopup();
      this.searchBounds.remove();
    }
  }
  
  private clearFeatures() {
    // clean up previous markers and popups
    this.markerArray.forEach((mark) => {
      mark.remove();
    });
    this.markerArray = [];
    this.geoLayer.clearLayers();
  }

  // Add search control to map
  onAdd(map: Map) {
    // create search control markup
    const control = DomUtil.create('div', 'leaflet-control');
    control.style.position = 'absolute';
    control.style.left = '50px';
    control.style.width = '399px';

    const controlGroup = DomUtil.create('div', 'input-group', control);

    // search input markup
    const input = DomUtil.create('input', 'form-control input-sm', controlGroup);
    input.id = 'searchInput';
    input.style.color = 'blue';
    input.placeholder = 'Find Food';
    input.style.width = '168px';

    // distance drop-down markup
    const span = DomUtil.create('span', 'btn-group', controlGroup);
    span.role = 'group';
    span.ariaLabel = 'The Buttons';
    const select = DomUtil.create('select', 'btn btn-default btn-sm dropdown-toggle', span);
    select.id = 'searchSelect';
    select.style.color = 'blue';
    select.style.height = '30px';

    // radius distance options in miles
    select.innerHTML = '<option value="0.25" selected>Near Me</option>'+
    '<option value="1">1 Mile</option>'+
    '<option value="2">2 Miles</option>';

    // search button markup
    const eat = DomUtil.create('button', 'btn btn-success btn-sm', span);
    eat.id = 'searchButton';
    eat.type = 'button';
    eat.innerHTML = 'EAT!';

    // reset button markup
    const reset = DomUtil.create('button', 'btn btn-primary btn-sm', span);
    reset.id = 'resetButton';
    reset.type = 'button';
    reset.innerHTML = 'Reset';

    // event handlers for searching
    input.onkeyup = (event: any) => {
      if (event.keyCode === 13) {
        // get search distance and search input text
        this.runSearch(select, input);
      }
    };

    eat.onclick = (event: any) => {
        // get search distance and search input text
        this.runSearch(select, input);
    };

    reset.onclick = (event: any) => {
        // reset search results
        this.clearFeatures();
        this.clearSearchArea();
    };

    // prevent map click event
    DomEvent.disableClickPropagation(control);
    
    // prevent map contextmenu event
    DomEvent.on(control, 'contextmenu', (ev) => {
      DomEvent.stopPropagation(ev);
    });
    
    // prevent map scroll event
    DomEvent.disableScrollPropagation(control);
    
    // features with markers and popups
    this.geoLayer = geoJSON(undefined, {
      onEachFeature: this.onEachFeature,
      pointToLayer: (feature: Feature, latlng: LatLng) => {
        return this.addMarker(feature, latlng, this.markerArray);
      },
    }).addTo(map);
    
    return control;
  };
};
