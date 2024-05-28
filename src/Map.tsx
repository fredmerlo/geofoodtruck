import React, { useState } from 'react';
import { MapContainer, Marker, Popup, TileLayer, useMapEvents } from 'react-leaflet';
import { createControlComponent } from '@react-leaflet/core';
import { SearchControl, SearchControlOptions } from './SearchComponent';
import { LatLngExpression } from 'leaflet';
import { UseConfig } from './Config';

// sample geoJasonData
// <SearchControl position='topleft' data={geoJsonData} />
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import geoJsonData from './SampleData';

let center: LatLngExpression = [37.784279, -122.407234] as LatLngExpression; // Default center San Francisco

// create search control component
const Search = createControlComponent((options: SearchControlOptions) => new SearchControl(options));

// create location marker component
const MyLocation: React.FC = () => {
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
  const config: any = UseConfig();

  return (    
    <MapContainer id='map' center={center} zoom={16} style={{ height: '100vh', width: '100%' }}>
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">
          OpenStreetMap</a> contributors'
      />
      <MyLocation />
      <Search position='topleft' endpoint={config.distribution} />
    </MapContainer>
  )
};

export default Map;
