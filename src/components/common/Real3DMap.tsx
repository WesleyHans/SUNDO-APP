import React, { useEffect, useRef, useState } from 'react';
import * as maplibregl from 'maplibre-gl';
import { SIPALAY_ROUTE_COORDS, USER_DEFAULT_COORDS } from './RealLeafletMap';

// 3D Extruded buildings data for Sipalay City Poblacion & Barangay centers
const SIPALAY_3D_BUILDINGS_GEOJSON: GeoJSON.FeatureCollection = {
  type: 'FeatureCollection',
  features: [
    // Sipalay City Hall & Municipal Complex
    {
      type: 'Feature',
      properties: { height: 26, base_height: 0, color: '#CBD5E1', name: 'Sipalay City Hall' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4032, 9.7542],
            [122.4042, 9.7542],
            [122.4042, 9.7549],
            [122.4032, 9.7549],
            [122.4032, 9.7542],
          ],
        ],
      },
    },
    // Sipalay Public Market & Commercial Center
    {
      type: 'Feature',
      properties: { height: 18, base_height: 0, color: '#E2E8F0', name: 'Public Market' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4045, 9.7535],
            [122.4055, 9.7535],
            [122.4055, 9.7543],
            [122.4045, 9.7543],
            [122.4045, 9.7535],
          ],
        ],
      },
    },
    // Sipalay City Gym & Sports Complex
    {
      type: 'Feature',
      properties: { height: 22, base_height: 0, color: '#D1FAE5', name: 'City Gymnasium' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4022, 9.7552],
            [122.4030, 9.7552],
            [122.4030, 9.7560],
            [122.4022, 9.7560],
            [122.4022, 9.7552],
          ],
        ],
      },
    },
    // Barangay 1 Community Center & Plaza
    {
      type: 'Feature',
      properties: { height: 14, base_height: 0, color: '#F1F5F9', name: 'Barangay 1 Hall' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4048, 9.7522],
            [122.4056, 9.7522],
            [122.4056, 9.7528],
            [122.4048, 9.7528],
            [122.4048, 9.7522],
          ],
        ],
      },
    },
    // Barangay 2 Health Station & School
    {
      type: 'Feature',
      properties: { height: 16, base_height: 0, color: '#E2E8F0', name: 'Barangay 2 Center' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4068, 9.7482],
            [122.4076, 9.7482],
            [122.4076, 9.7489],
            [122.4068, 9.7489],
            [122.4068, 9.7482],
          ],
        ],
      },
    },
    // Barangay 3 Solid Waste Collection Depot
    {
      type: 'Feature',
      properties: { height: 15, base_height: 0, color: '#A7F3D0', name: 'Barangay 3 Station' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4128, 9.7420],
            [122.4138, 9.7420],
            [122.4138, 9.7428],
            [122.4128, 9.7428],
            [122.4128, 9.7420],
          ],
        ],
      },
    },
    // Coastline Port Facility
    {
      type: 'Feature',
      properties: { height: 20, base_height: 0, color: '#BAE6FD', name: 'Sipalay Port Terminal' },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [122.4010, 9.7580],
            [122.4020, 9.7580],
            [122.4020, 9.7590],
            [122.4010, 9.7590],
            [122.4010, 9.7580],
          ],
        ],
      },
    },
  ],
};

interface Real3DMapProps {
  truckProgress: number; // 0.0 to 1.0
  userLocation?: { lat: number; lng: number };
  is3DMode?: boolean;
  onTruckClick?: () => void;
  className?: string;
}

export const Real3DMap: React.FC<Real3DMapProps> = ({
  truckProgress,
  userLocation = USER_DEFAULT_COORDS,
  is3DMode = true,
  onTruckClick,
  className = '',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const truckMarkerRef = useRef<maplibregl.Marker | null>(null);
  const userMarkerRef = useRef<maplibregl.Marker | null>(null);
  const [headingAngle, setHeadingAngle] = useState(0);

  // Interpolate position and heading along real Sipalay road
  const calculateTruckPosAndAngle = (progress: number): { lng: number; lat: number; angle: number } => {
    const clamped = Math.max(0, Math.min(1, progress));
    const totalSegments = SIPALAY_ROUTE_COORDS.length - 1;
    const segmentProgress = clamped * totalSegments;
    const index = Math.floor(segmentProgress);
    const remainder = segmentProgress - index;

    if (index >= totalSegments) {
      const last = SIPALAY_ROUTE_COORDS[totalSegments];
      return { lng: last.lng, lat: last.lat, angle: -45 };
    }

    const p1 = SIPALAY_ROUTE_COORDS[index];
    const p2 = SIPALAY_ROUTE_COORDS[index + 1];

    const lat = p1.lat + (p2.lat - p1.lat) * remainder;
    const lng = p1.lng + (p2.lng - p1.lng) * remainder;

    // Calculate heading angle in degrees for 3D truck orientation
    const dLng = p2.lng - p1.lng;
    const dLat = p2.lat - p1.lat;
    const rad = Math.atan2(dLng, dLat);
    const angle = (rad * 180) / Math.PI;

    return { lng, lat, angle };
  };

  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) return;

    // Sipalay City Center
    const center: [number, number] = [122.4065, 9.7515];

    const map = new maplibregl.Map({
      container: mapContainerRef.current,
      style: {
        version: 8,
        sources: {
          // OpenStreetMap standard tile server
          'osm-tiles': {
            type: 'raster',
            tiles: [
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ],
            tileSize: 256,
            attribution: '&copy; OpenStreetMap contributors',
          },
          // 3D Sipalay Buildings source
          'sipalay-3d-buildings': {
            type: 'geojson',
            data: SIPALAY_3D_BUILDINGS_GEOJSON,
          },
          // Collection Route Line source
          'collection-route': {
            type: 'geojson',
            data: {
              type: 'Feature',
              properties: {},
              geometry: {
                type: 'LineString',
                coordinates: SIPALAY_ROUTE_COORDS.map((p) => [p.lng, p.lat]),
              },
            },
          },
        },
        layers: [
          // Base OpenStreetMap tiles layer
          {
            id: 'osm-layer',
            type: 'raster',
            source: 'osm-tiles',
            minzoom: 0,
            maxzoom: 19,
          },
          // Route Glow Layer (outer 3D halo)
          {
            id: 'route-glow',
            type: 'line',
            source: 'collection-route',
            layout: {
              'line-join': 'round',
              'line-cap': 'round',
            },
            paint: {
              'line-color': '#059669',
              'line-width': 14,
              'line-opacity': 0.35,
              'line-blur': 3,
            },
          },
          // Primary Green Collection Route Layer
          {
            id: 'route-line',
            type: 'line',
            source: 'collection-route',
            layout: {
              'line-join': 'round',
              'line-cap': 'round',
            },
            paint: {
              'line-color': '#059669',
              'line-width': 7,
              'line-opacity': 0.95,
            },
          },
          // Inner dashed stripe
          {
            id: 'route-dashes',
            type: 'line',
            source: 'collection-route',
            layout: {
              'line-join': 'round',
              'line-cap': 'round',
            },
            paint: {
              'line-color': '#A7F3D0',
              'line-width': 2.5,
              'line-dasharray': [3, 4],
            },
          },
          // 3D Extruded Buildings Layer
          {
            id: '3d-buildings-extrusion',
            type: 'fill-extrusion',
            source: 'sipalay-3d-buildings',
            paint: {
              'fill-extrusion-color': [
                'case',
                ['has', 'color'],
                ['get', 'color'],
                '#E2E8F0',
              ],
              'fill-extrusion-height': ['get', 'height'],
              'fill-extrusion-base': ['get', 'base_height'],
              'fill-extrusion-opacity': 0.85,
            },
          },
        ],
      },
      center: center,
      zoom: 15.2,
      pitch: is3DMode ? 58 : 0, // 3D Camera Tilt
      bearing: is3DMode ? -18 : 0, // 3D Angled Perspective
      attributionControl: false,
    });

    mapRef.current = map;

    // Add 3D Floating Barangay Badges
    const barangayMarkers = [
      { name: 'Barangay 1', lng: 122.4035, lat: 9.7552 },
      { name: 'Barangay 2', lng: 122.4075, lat: 9.7490 },
      { name: 'Barangay 3', lng: 122.4138, lat: 9.7428 },
    ];

    barangayMarkers.forEach((b) => {
      const el = document.createElement('div');
      el.className = 'custom-3d-badge';
      el.innerHTML = `
        <div style="
          background: #FFFFFF;
          color: #0F172A;
          font-size: 10px;
          font-weight: 800;
          padding: 4px 12px;
          border-radius: 9999px;
          box-shadow: 4px 6px 14px rgba(0,0,0,0.18), 0 0 0 1px rgba(255,255,255,0.8);
          border: 1px solid #E2E8F0;
          white-space: nowrap;
          font-family: 'Plus Jakarta Sans', sans-serif;
          transform: perspective(600px) rotateX(15deg);
        ">
          ${b.name}
        </div>
      `;
      new maplibregl.Marker({ element: el }).setLngLat([b.lng, b.lat]).addTo(map);
    });

    // Add User Location Pin ("Your Location") in 3D
    const userEl = document.createElement('div');
    userEl.className = 'custom-user-pin-3d';
    userEl.innerHTML = `
      <div style="position: relative; display: flex; flex-direction: column; align-items: center; cursor: pointer;">
        <div style="
          position: absolute;
          top: -2px;
          width: 32px;
          height: 32px;
          background: rgba(37, 99, 235, 0.25);
          border-radius: 9999px;
          animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
        "></div>
        <div style="
          width: 15px;
          height: 15px;
          background: #2563EB;
          border: 3px solid #FFFFFF;
          border-radius: 9999px;
          box-shadow: 0 4px 10px rgba(37,99,235,0.5);
          z-index: 2;
        "></div>
        <div style="
          margin-top: 4px;
          background: #1E293B;
          color: #FFFFFF;
          font-size: 8.5px;
          font-weight: 700;
          padding: 2.5px 8px;
          border-radius: 9999px;
          white-space: nowrap;
          box-shadow: 0 3px 8px rgba(0,0,0,0.25);
          font-family: 'Plus Jakarta Sans', sans-serif;
          z-index: 2;
        ">
          Your Location
        </div>
      </div>
    `;

    const userMarker = new maplibregl.Marker({ element: userEl })
      .setLngLat([userLocation.lng, userLocation.lat])
      .addTo(map);
    userMarkerRef.current = userMarker;

    // Add 3D Garbage Truck Marker with dynamic shadow
    const truckData = calculateTruckPosAndAngle(truckProgress);
    const truckEl = document.createElement('div');
    truckEl.className = 'custom-3d-truck-marker';
    truckEl.innerHTML = `
      <div style="
        position: relative;
        width: 52px;
        height: 52px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
      ">
        <!-- 3D Ground Cast Shadow -->
        <div style="
          position: absolute;
          bottom: 2px;
          width: 38px;
          height: 14px;
          background: rgba(0, 0, 0, 0.35);
          border-radius: 9999px;
          filter: blur(3px);
          transform: rotate(20deg);
        "></div>

        <!-- 3D Radar Wave Ring -->
        <div style="
          position: absolute;
          inset: 0;
          background: rgba(16, 185, 129, 0.3);
          border-radius: 9999px;
          animation: pulse 1.8s infinite;
        "></div>

        <!-- 3D Clay Truck Disc -->
        <div style="
          position: relative;
          width: 44px;
          height: 44px;
          background: linear-gradient(135deg, #10B981 0%, #059669 100%);
          border: 3px solid #FFFFFF;
          border-radius: 9999px;
          box-shadow: 0 8px 18px rgba(5, 150, 105, 0.4), inset 2px 2px 4px rgba(255,255,255,0.4);
          display: flex;
          align-items: center;
          justify-content: center;
          transform: translateY(-4px);
        ">
          <svg viewBox="0 0 24 24" width="24" height="24" fill="none">
            <rect x="3" y="6" width="13" height="10" rx="2" fill="#FFFFFF" />
            <path d="M16 9H20L22 12V16H16V9Z" fill="#A7F3D0" />
            <circle cx="7" cy="17" r="2.5" fill="#064E3B" />
            <circle cx="18" cy="17" r="2.5" fill="#064E3B" />
            <circle cx="7" cy="17" r="1" fill="#FFFFFF" />
            <circle cx="18" cy="17" r="1" fill="#FFFFFF" />
            <path d="M6 10L10 10" stroke="#059669" stroke-width="1.5" stroke-linecap="round" />
          </svg>
        </div>
      </div>
    `;

    const truckMarker = new maplibregl.Marker({ element: truckEl })
      .setLngLat([truckData.lng, truckData.lat])
      .addTo(map);

    if (onTruckClick) {
      truckEl.addEventListener('click', onTruckClick);
    }

    truckMarkerRef.current = truckMarker;

    setTimeout(() => {
      map.resize();
    }, 200);

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Update 3D Camera Pitch when is3DMode toggles
  useEffect(() => {
    if (!mapRef.current) return;
    mapRef.current.easeTo({
      pitch: is3DMode ? 58 : 0,
      bearing: is3DMode ? -18 : 0,
      duration: 1000,
    });
  }, [is3DMode]);

  // Smoothly update 3D truck position as progress advances
  useEffect(() => {
    if (!truckMarkerRef.current) return;
    const { lng, lat, angle } = calculateTruckPosAndAngle(truckProgress);
    truckMarkerRef.current.setLngLat([lng, lat]);
    setHeadingAngle(angle);
  }, [truckProgress]);

  // Update user location pin if changed
  useEffect(() => {
    if (!userMarkerRef.current) return;
    userMarkerRef.current.setLngLat([userLocation.lng, userLocation.lat]);
  }, [userLocation]);

  return (
    <div className={`relative w-full h-full overflow-hidden ${className}`}>
      <div ref={mapContainerRef} className="w-full h-full" />
    </div>
  );
};
