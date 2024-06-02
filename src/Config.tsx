import React, { useEffect, useState, createContext, useContext } from 'react';

const ConfigContext = createContext(null);

export const Provider = ({ children }: any) => {
  const [config, setConfig] = useState(null);

  const fetchConfig = async () => {
    setConfig((window as any).getConfig());
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
