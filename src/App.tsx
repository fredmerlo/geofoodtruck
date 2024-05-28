import React from 'react';
import Map from './Map';
import './App.css';
import { Provider } from './Config';

const App = () => {
  return (
    <Provider>
      <div className="Map">
        <Map />
      </div>
    </Provider>
  );
}

export default App;
