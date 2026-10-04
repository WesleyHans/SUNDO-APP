import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';
// Retire the previous simulator's service worker on this origin.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(registrations => Promise.all(registrations.map(registration => registration.unregister()))).catch(() => {});
}
createRoot(document.getElementById('root')!).render(<App />);
