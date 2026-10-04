import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import 'leaflet/dist/leaflet.css';
import 'maplibre-gl/dist/maplibre-gl.css';
import './index.css';
import { registerSW } from 'virtual:pwa-register';

// Register service worker for instant native Android installation
registerSW({ immediate: true });

createRoot(document.getElementById('root')!).render(<App />);
