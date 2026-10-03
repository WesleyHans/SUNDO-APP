import React, { useEffect, useRef } from 'react';
import L from 'leaflet';

export interface RoutePoint {
  lat: number;
  lng: number;
  barangay?: string;
  name?: string;
}

// Real street coordinates across Poblacion / Barangay 1, 2, 3 in Sipalay City, Negros Occidental
export const SIPALAY_ROUTE_COORDS: RoutePoint[] = [
  { lat: 9.7425, lng: 122.4135, barangay: 'Barangay 3', name: 'Barangay 3 Collection Depot' },
  { lat: 9.7442, lng: 122.4110 },
  { lat: 9.7460, lng: 122.4085 },
  { lat: 9.7485, lng: 122.4072, barangay: 'Barangay 2', name: 'Barangay 2 Health Center' },
  { lat: 9.7505, lng: 122.4058 },
  { lat: 9.7528, lng: 122.4045 },
  { lat: 9.7548, lng: 122.4038, barangay: 'Barangay 1', name: 'Barangay 1 Poblacion Plaza' },
  { lat: 9.7570, lng: 122.4025 },
  { lat: 9.7588, lng: 122.4018, name: 'Sipalay City Port Road' },
];

export const USER_DEFAULT_COORDS: RoutePoint = {
  lat: 9.7540,
  lng: 122.4048,
  barangay: 'Barangay 1',
  name: 'Your Location (Juan Dela Cruz)',
};

interface RealLeafletMapProps {
  truckProgress: number; // 0.0 to 1.0
  userLocation?: { lat: number; lng: number };
  onTruckClick?: () => void;
  className?: string;
}

export const RealLeafletMap: React.FC<RealLeafletMapProps> = ({
  truckProgress,
  userLocation = USER_DEFAULT_COORDS,
  onTruckClick,
  className = '',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const truckMarkerRef = useRef<L.Marker | null>(null);
  const userMarkerRef = useRef<L.Marker | null>(null);

  // Calculate current interpolated truck position along the real road coords
  const calculateTruckPos = (progress: number): [number, number] => {
    const clamped = Math.max(0, Math.min(1, progress));
    const totalSegments = SIPALAY_ROUTE_COORDS.length - 1;
    const segmentProgress = clamped * totalSegments;
    const index = Math.floor(segmentProgress);
    const remainder = segmentProgress - index;

    if (index >= totalSegments) {
      const last = SIPALAY_ROUTE_COORDS[totalSegments];
      return [last.lat, last.lng];
    }

    const p1 = SIPALAY_ROUTE_COORDS[index];
    const p2 = SIPALAY_ROUTE_COORDS[index + 1];

    const lat = p1.lat + (p2.lat - p1.lat) * remainder;
    const lng = p1.lng + (p2.lng - p1.lng) * remainder;
    return [lat, lng];
  };

  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) return; // already initialized

    // Center on Sipalay City Poblacion
    const initialCenter: [number, number] = [9.7515, 122.4065];
    const map = L.map(mapContainerRef.current, {
      center: initialCenter,
      zoom: 15,
      zoomControl: false,
      attributionControl: false,
    });

    mapRef.current = map;

    // Use OpenStreetMap tiles as explicitly requested
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    // Draw the claymorphic green collection route polyline
    const routeLatLngs: [number, number][] = SIPALAY_ROUTE_COORDS.map((p) => [p.lat, p.lng]);

    // Outer soft green halo shadow
    L.polyline(routeLatLngs, {
      color: 'rgba(5, 150, 105, 0.3)',
      weight: 12,
      lineCap: 'round',
      lineJoin: 'round',
    }).addTo(map);

    // Primary solid green clay route
    L.polyline(routeLatLngs, {
      color: '#059669',
      weight: 7,
      opacity: 0.95,
      lineCap: 'round',
      lineJoin: 'round',
    }).addTo(map);

    // Inner dashed mint stripe highlight
    L.polyline(routeLatLngs, {
      color: '#A7F3D0',
      weight: 3,
      dashArray: '5, 8',
      opacity: 0.95,
      lineCap: 'round',
    }).addTo(map);

    // Add Barangay Label Badges matching mockup style
    const barangayMarkers = [
      { name: 'Barangay 1', lat: 9.7552, lng: 122.4035 },
      { name: 'Barangay 2', lat: 9.7490, lng: 122.4075 },
      { name: 'Barangay 3', lat: 9.7428, lng: 122.4138 },
    ];

    barangayMarkers.forEach((b) => {
      const badgeIcon = L.divIcon({
        className: 'custom-barangay-label',
        html: `
          <div style="
            background: white;
            color: #0F172A;
            font-size: 10px;
            font-weight: 700;
            padding: 3px 10px;
            border-radius: 9999px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.15);
            border: 1px solid #E2E8F0;
            white-space: nowrap;
            text-align: center;
            font-family: 'Plus Jakarta Sans', sans-serif;
            pointer-events: auto;
          ">
            ${b.name}
          </div>
        `,
        iconSize: [80, 24],
        iconAnchor: [40, 12],
      });

      L.marker([b.lat, b.lng], { icon: badgeIcon, interactive: false }).addTo(map);
    });

    // Create User Location Pin ("Your Location")
    const userIcon = L.divIcon({
      className: 'custom-user-pin',
      html: `
        <div style="position: relative; display: flex; flex-direction: column; align-items: center; width: 90px; margin-left: -45px; margin-top: -24px;">
          <!-- Radar ring -->
          <div style="
            position: absolute;
            top: 2px;
            width: 28px;
            height: 28px;
            background: rgba(59, 130, 246, 0.25);
            border-radius: 9999px;
            animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
          "></div>
          <!-- Dot -->
          <div style="
            width: 14px;
            height: 14px;
            background: #2563EB;
            border: 2.5px solid #FFFFFF;
            border-radius: 9999px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.25);
            z-index: 2;
          "></div>
          <!-- Pill tag -->
          <div style="
            margin-top: 3px;
            background: #1E293B;
            color: #FFFFFF;
            font-size: 8.5px;
            font-weight: 700;
            padding: 2px 8px;
            border-radius: 9999px;
            white-space: nowrap;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
            font-family: 'Plus Jakarta Sans', sans-serif;
            z-index: 2;
          ">
            Your Location
          </div>
        </div>
      `,
      iconSize: [0, 0],
      iconAnchor: [0, 0],
    });

    const userMarker = L.marker([userLocation.lat, userLocation.lng], {
      icon: userIcon,
      zIndexOffset: 500,
    }).addTo(map);
    userMarkerRef.current = userMarker;

    // Create Truck Marker with SVG
    const initialTruckPos = calculateTruckPos(truckProgress);
    const truckIcon = L.divIcon({
      className: 'custom-truck-pin',
      html: `
        <div style="
          position: relative;
          width: 44px;
          height: 44px;
          margin-left: -22px;
          margin-top: -22px;
          cursor: pointer;
        ">
          <!-- Pulse aura -->
          <div style="
            position: absolute;
            inset: -4px;
            background: rgba(16, 185, 129, 0.35);
            border-radius: 9999px;
            animation: pulse 1.8s infinite;
          "></div>
          <!-- White disc -->
          <div style="
            width: 44px;
            height: 44px;
            background: white;
            border: 2.5px solid #059669;
            border-radius: 9999px;
            box-shadow: 0 4px 10px rgba(5,150,105,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
          ">
            <!-- Mini Truck SVG -->
            <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
              <rect x="3" y="6" width="13" height="10" rx="2" fill="#10B981" />
              <path d="M16 9H20L22 12V16H16V9Z" fill="#059669" />
              <circle cx="7" cy="17" r="2.5" fill="#1E293B" />
              <circle cx="18" cy="17" r="2.5" fill="#1E293B" />
              <circle cx="7" cy="17" r="1" fill="#FFFFFF" />
              <circle cx="18" cy="17" r="1" fill="#FFFFFF" />
              <path d="M6 10L10 10" stroke="white" stroke-width="1.5" stroke-linecap="round" />
            </svg>
          </div>
        </div>
      `,
      iconSize: [0, 0],
      iconAnchor: [0, 0],
    });

    const truckMarker = L.marker(initialTruckPos, {
      icon: truckIcon,
      zIndexOffset: 1000,
    }).addTo(map);

    if (onTruckClick) {
      truckMarker.on('click', onTruckClick);
    }

    truckMarkerRef.current = truckMarker;

    // Invalidate size after mount
    setTimeout(() => {
      map.invalidateSize();
    }, 250);

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Update truck position smoothly when truckProgress changes
  useEffect(() => {
    if (!truckMarkerRef.current) return;
    const newPos = calculateTruckPos(truckProgress);
    truckMarkerRef.current.setLatLng(newPos);
  }, [truckProgress]);

  // Update user location if changed
  useEffect(() => {
    if (!userMarkerRef.current) return;
    userMarkerRef.current.setLatLng([userLocation.lat, userLocation.lng]);
  }, [userLocation]);

  return (
    <div className={`relative w-full h-full overflow-hidden ${className}`}>
      <div ref={mapContainerRef} className="w-full h-full" />
    </div>
  );
};
