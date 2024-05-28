import React, { useEffect, useState, createContext, useContext } from 'react';

const ConfigContext = createContext(null);

export const Provider = ({ children }: any) => {
  const [config, setConfig] = useState(null);

  const fetchConfig = async () => {
    try {
      const response = await fetch("/config.json");

      if (!response.ok) {
        throw new Error("Failed to fetch configuration");
      }

      const config = await response.json();
      setConfig(config);

    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchConfig();
  }, []);

  if (!config) {
    return <div>Loading configuration...</div>;
  }

  return (
    <ConfigContext.Provider value={config}>
      {children}
    </ConfigContext.Provider>
  );
};

export const UseConfig = () => {
  return useContext(ConfigContext);
};
