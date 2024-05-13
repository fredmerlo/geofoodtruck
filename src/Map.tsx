import React, { useState } from 'react';
import { MapContainer, Marker, Popup, TileLayer, useMapEvents } from 'react-leaflet';
import { createControlComponent } from '@react-leaflet/core';
import { SearchControl, SearchControlOptions } from './SearchComponent';
import { LatLngExpression } from 'leaflet';

let center: LatLngExpression = [37.784279, -122.407234] as LatLngExpression; // Default center San Francisco

// sample geoJasonData
// const geoJsonData: any = {
//   "type": "FeatureCollection",
//   "features": [
//     {
//       "type": "Feature",
//       "properties": {
//         "name": "Example Point",
//         "amenity": "School",
//         "popupContent": "This is where the school is."
//       },
//       "geometry": {
//         "type": "Point",
//         "coordinates": [-0.09, 51.505]
//       }
//     }
//   ]
// };

// create search control component
const Search = createControlComponent((options: SearchControlOptions) => new SearchControl(options));

// create location marker component
function MyLocation() {
  const [position, setPosition] = useState(center)
  const map = useMapEvents({
    click(e) {
      setPosition(e.latlng)
      map.flyTo(e.latlng, map.getZoom()) 
    },
  });

  return position === null ? null : (
    <Marker position={position}>
      <Popup>You are here</Popup>
    </Marker>
  );
};

// create map component
const Map: React.FC = () => {  

  return (
    <MapContainer id='map' center={center} zoom={16} style={{ height: '100vh', width: '100%' }}>
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">
          OpenStreetMap</a> contributors'
      />
      <MyLocation />
      <Search position='topleft' />
    </MapContainer>
  )
};

export default Map;
