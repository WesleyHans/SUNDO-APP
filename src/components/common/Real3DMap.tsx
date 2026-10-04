import React, { useEffect, useRef, useState, useCallback } from 'react';
import * as maplibregl from 'maplibre-gl';
import L from 'leaflet';
import { SIPALAY_ROUTE_COORDS, USER_DEFAULT_COORDS, RoutePoint } from './RealLeafletMap';

// Collection Waypoints in Sipalay City
export const SIPALAY_WAYPOINTS: {
  id: string;
  name: string;
  barangay: string;
  lat: number;
  lng: number;
  status: 'completed' | 'current' | 'upcoming';
  scheduledTime: string;
}[] = [
  {
    id: 'wp-1',
    name: 'Depot & Material Recovery',
    barangay: 'Barangay 3',
    lat: 9.7425,
    lng: 122.4135,
    status: 'completed',
    scheduledTime: '07:30 AM',
  },
  {
    id: 'wp-2',
    name: 'Health Station & Elementary',
    barangay: 'Barangay 2',
    lat: 9.7485,
    lng: 122.4072,
    status: 'completed',
    scheduledTime: '08:15 AM',
  },
  {
    id: 'wp-3',
    name: 'Poblacion Plaza & Market',
    barangay: 'Barangay 1',
    lat: 9.7548,
    lng: 122.4038,
    status: 'current',
    scheduledTime: '09:00 AM',
  },
  {
    id: 'wp-4',
    name: 'Port Coastal Terminal',
    barangay: 'Barangay 1',
    lat: 9.7588,
    lng: 122.4018,
    status: 'upcoming',
    scheduledTime: '09:45 AM',
  },
];

// 3D Extruded buildings data for Sipalay City Center
const SIPALAY_3D_BUILDINGS_GEOJSON: GeoJSON.FeatureCollection = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: { height: 28, base_height: 0, color: '#CBD5E1', name: 'Sipalay City Hall' },
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
    {
      type: 'Feature',
      properties: { height: 16, base_height: 0, color: '#F1F5F9', name: 'Barangay 1 Hall' },
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
  ],
};

export type MapStyleType = 'streets' | 'satellite' | 'terrain';

interface Real3DMapProps {
  truckProgress: number; // 0.0 to 1.0
  userLocation?: { lat: number; lng: number };
  is3DMode?: boolean;
  mapStyle?: MapStyleType;
  onTruckClick?: () => void;
  className?: string;
  zoom?: number;
  onZoomChange?: (z: number) => void;
}

export const Real3DMap: React.FC<Real3DMapProps> = ({
  truckProgress,
  userLocation = USER_DEFAULT_COORDS,
  is3DMode = true,
  mapStyle = 'streets',
  onTruckClick,
  className = '',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const leafletMapRef = useRef<L.Map | null>(null);
  const [usingFallback, setUsingFallback] = useState(false);

  // Markers
  const truckMarkerRef = useRef<maplibregl.Marker | null>(null);
  const userMarkerRef = useRef<maplibregl.Marker | null>(null);
  const leafletTruckMarkerRef = useRef<L.Marker | null>(null);
  const leafletUserMarkerRef = useRef<L.Marker | null>(null);

  // Interpolate position and heading along real Sipalay road
  const calculateTruckPosAndAngle = useCallback(
    (progress: number): { lng: number; lat: number; angle: number } => {
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

      const dLng = p2.lng - p1.lng;
      const dLat = p2.lat - p1.lat;
      const rad = Math.atan2(dLng, dLat);
      const angle = (rad * 180) / Math.PI;

      return { lng, lat, angle };
    },
    []
  );

  // Tile URL resolver
  const getTileUrl = (style: MapStyleType): string[] => {
    switch (style) {
      case 'satellite':
        return [
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        ];
      case 'terrain':
        return [
          'https://a.tile.opentopomap.org/{z}/{x}/{y}.png',
          'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
          'https://c.tile.opentopomap.org/{z}/{x}/{y}.png',
        ];
      case 'streets':
      default:
        // CartoDB Voyager: Crisp, modern vector-styled raster tiles with high uptime and free CDN
        return [
          'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          'https://b.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          'https://c.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          'https://d.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
        ];
    }
  };

  // Check WebGL availability safely
  const isWebGLAvailable = (): boolean => {
    try {
      const canvas = document.createElement('canvas');
      return !!(
        window.WebGLRenderingContext &&
        (canvas.getContext('webgl') || canvas.getContext('experimental-webgl'))
      );
    } catch {
      return false;
    }
  };

  // --- INITIALIZE MAPLIBRE (PRIMARY 3D ENGINE) ---
  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Check if WebGL is supported
    if (!isWebGLAvailable()) {
      console.warn('WebGL is not supported in this environment. Falling back to Leaflet engine.');
      setUsingFallback(true);
      return;
    }

    const center: [number, number] = [122.4065, 9.7515]; // Sipalay Center

    try {
      const map = new maplibregl.Map({
        container: mapContainerRef.current,
        style: {
          version: 8,
          sources: {
            'raster-tiles': {
              type: 'raster',
              tiles: getTileUrl(mapStyle),
              tileSize: 256,
              attribution: '&copy; CartoDB &copy; OpenStreetMap contributors',
            },
            'sipalay-3d-buildings': {
              type: 'geojson',
              data: SIPALAY_3D_BUILDINGS_GEOJSON,
            },
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
            {
              id: 'base-tiles',
              type: 'raster',
              source: 'raster-tiles',
              minzoom: 0,
              maxzoom: 20,
            },
            // Outer route halo glow
            {
              id: 'route-glow',
              type: 'line',
              source: 'collection-route',
              layout: { 'line-join': 'round', 'line-cap': 'round' },
              paint: {
                'line-color': '#059669',
                'line-width': 16,
                'line-opacity': 0.35,
                'line-blur': 4,
              },
            },
            // Route main line
            {
              id: 'route-line',
              type: 'line',
              source: 'collection-route',
              layout: { 'line-join': 'round', 'line-cap': 'round' },
              paint: {
                'line-color': '#10B981',
                'line-width': 7,
                'line-opacity': 0.95,
              },
            },
            // Inner dashes
            {
              id: 'route-dashes',
              type: 'line',
              source: 'collection-route',
              layout: { 'line-join': 'round', 'line-cap': 'round' },
              paint: {
                'line-color': '#FFFFFF',
                'line-width': 2.5,
                'line-dasharray': [3, 4],
              },
            },
            // 3D Buildings Extrusion
            {
              id: '3d-buildings',
              type: 'fill-extrusion',
              source: 'sipalay-3d-buildings',
              paint: {
                'fill-extrusion-color': [
                  'case',
                  ['has', 'color'],
                  ['get', 'color'],
                  '#CBD5E1',
                ],
                'fill-extrusion-height': ['get', 'height'],
                'fill-extrusion-base': ['get', 'base_height'],
                'fill-extrusion-opacity': 0.88,
              },
            },
          ],
        },
        center: center,
        zoom: 15.3,
        pitch: is3DMode ? 54 : 0,
        bearing: is3DMode ? -16 : 0,
        attributionControl: false,
      });

      mapRef.current = map;

      // Add Waypoint Markers
      SIPALAY_WAYPOINTS.forEach((wp) => {
        const el = document.createElement('div');
        el.className = 'waypoint-marker';
        const isCurrent = wp.status === 'current';
        const isCompleted = wp.status === 'completed';

        el.innerHTML = `
          <div style="display: flex; flex-direction: column; align-items: center; cursor: pointer;">
            <div style="
              width: ${isCurrent ? '20px' : '14px'};
              height: ${isCurrent ? '20px' : '14px'};
              border-radius: 9999px;
              background: ${isCurrent ? '#10B981' : isCompleted ? '#059669' : '#94A3B8'};
              border: 2.5px solid #FFFFFF;
              box-shadow: 0 3px 8px rgba(0,0,0,0.25);
              display: flex;
              align-items: center;
              justify-content: center;
            ">
              ${isCompleted ? '<span style="color:white;font-size:8px;font-weight:900;">✓</span>' : ''}
            </div>
            <div style="
              background: rgba(255,255,255,0.92);
              backdrop-filter: blur(4px);
              color: #0F172A;
              font-size: 8.5px;
              font-weight: 700;
              padding: 2px 6px;
              border-radius: 6px;
              margin-top: 3px;
              white-space: nowrap;
              border: 1px solid rgba(226,232,240,0.8);
              box-shadow: 0 2px 5px rgba(0,0,0,0.12);
              font-family: 'Plus Jakarta Sans', sans-serif;
            ">
              ${wp.name.split('&')[0]}
            </div>
          </div>
        `;
        new maplibregl.Marker({ element: el }).setLngLat([wp.lng, wp.lat]).addTo(map);
      });

      // User Marker
      const userEl = document.createElement('div');
      userEl.innerHTML = `
        <div style="position: relative; display: flex; flex-direction: column; align-items: center;">
          <div style="
            position: absolute;
            top: -5px;
            width: 30px;
            height: 30px;
            background: rgba(37, 99, 235, 0.25);
            border-radius: 9999px;
            animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
          "></div>
          <div style="
            width: 16px;
            height: 16px;
            background: #2563EB;
            border: 3px solid #FFFFFF;
            border-radius: 9999px;
            box-shadow: 0 4px 10px rgba(37,99,235,0.6);
            z-index: 2;
          "></div>
          <div style="
            margin-top: 3px;
            background: #1E293B;
            color: #FFFFFF;
            font-size: 8.5px;
            font-weight: 800;
            padding: 2px 8px;
            border-radius: 9999px;
            white-space: nowrap;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            font-family: 'Plus Jakarta Sans', sans-serif;
            border: 1px solid rgba(255,255,255,0.3);
            z-index: 2;
          ">
            You (Brgy 1)
          </div>
        </div>
      `;
      const userMarker = new maplibregl.Marker({ element: userEl })
        .setLngLat([userLocation.lng, userLocation.lat])
        .addTo(map);
      userMarkerRef.current = userMarker;

      // 3D Truck Marker
      const truckPos = calculateTruckPosAndAngle(truckProgress);
      const truckEl = document.createElement('div');
      truckEl.className = 'custom-3d-truck-marker';
      truckEl.innerHTML = `
        <div style="
          position: relative;
          width: 54px;
          height: 54px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        ">
          <!-- Proximity radar pulse -->
          <div style="
            position: absolute;
            inset: 0;
            background: rgba(16, 185, 129, 0.25);
            border-radius: 9999px;
            animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
          "></div>

          <!-- Radar radius ring -->
          <div style="
            position: absolute;
            width: 48px;
            height: 48px;
            border: 1.5px dashed rgba(5, 150, 105, 0.6);
            border-radius: 9999px;
          "></div>

          <!-- Clay Truck Disc -->
          <div style="
            position: relative;
            width: 42px;
            height: 42px;
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            border: 3px solid #FFFFFF;
            border-radius: 9999px;
            box-shadow: 0 8px 18px rgba(5, 150, 105, 0.45), inset 2px 2px 4px rgba(255,255,255,0.4);
            display: flex;
            align-items: center;
            justify-content: center;
            transform: translateY(-2px);
          ">
            <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
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

      if (onTruckClick) {
        truckEl.addEventListener('click', onTruckClick);
      }

      const truckMarker = new maplibregl.Marker({ element: truckEl })
        .setLngLat([truckPos.lng, truckPos.lat])
        .addTo(map);
      truckMarkerRef.current = truckMarker;

      // Handle ResizeObserver
      const resizeObserver = new ResizeObserver(() => {
        map.resize();
      });
      resizeObserver.observe(mapContainerRef.current);

      setTimeout(() => {
        map.resize();
      }, 150);

      return () => {
        resizeObserver.disconnect();
        map.remove();
        mapRef.current = null;
      };
    } catch (err) {
      console.warn('MapLibre init error, falling back to Leaflet:', err);
      setUsingFallback(true);
    }
  }, [mapStyle]);

  // --- FALLBACK LEAFLET ENGINE (IF WEBGL NOT AVAILABLE) ---
  useEffect(() => {
    if (!usingFallback) return;
    if (!mapContainerRef.current) return;
    if (leafletMapRef.current) return;

    try {
      const center: [number, number] = [9.7515, 122.4065];
      const map = L.map(mapContainerRef.current, {
        center,
        zoom: 15,
        zoomControl: false,
        attributionControl: false,
      });

      leafletMapRef.current = map;

      // Add CartoDB Voyager tiles
      L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        maxZoom: 19,
        subdomains: 'abcd',
        attribution: '&copy; CartoDB &copy; OpenStreetMap',
      }).addTo(map);

      // Route lines
      const routeCoords: [number, number][] = SIPALAY_ROUTE_COORDS.map((p) => [p.lat, p.lng]);
      L.polyline(routeCoords, {
        color: 'rgba(5, 150, 105, 0.3)',
        weight: 12,
        lineCap: 'round',
        lineJoin: 'round',
      }).addTo(map);

      L.polyline(routeCoords, {
        color: '#10B981',
        weight: 6,
        lineCap: 'round',
        lineJoin: 'round',
      }).addTo(map);

      // Waypoints
      SIPALAY_WAYPOINTS.forEach((wp) => {
        const icon = L.divIcon({
          className: 'leaflet-custom-wp',
          html: `
            <div style="display:flex;flex-direction:column;align-items:center;">
              <div style="width:12px;height:12px;background:#10B981;border:2px solid #fff;border-radius:9999px;box-shadow:0 2px 5px rgba(0,0,0,0.3);"></div>
              <span style="font-size:8px;font-weight:700;background:#fff;padding:1px 4px;border-radius:4px;margin-top:2px;box-shadow:0 1px 3px rgba(0,0,0,0.2);">${wp.name.split(' ')[0]}</span>
            </div>
          `,
          iconSize: [60, 30],
          iconAnchor: [30, 6],
        });
        L.marker([wp.lat, wp.lng], { icon }).addTo(map);
      });

      // User Marker
      const userIcon = L.divIcon({
        className: 'leaflet-custom-user',
        html: `
          <div style="display:flex;flex-direction:column;align-items:center;">
            <div style="width:16px;height:16px;background:#2563EB;border:3px solid #fff;border-radius:9999px;box-shadow:0 4px 8px rgba(37,99,235,0.5);"></div>
            <span style="background:#1E293B;color:#fff;font-size:8px;font-weight:800;padding:2px 6px;border-radius:9999px;margin-top:2px;">You</span>
          </div>
        `,
        iconSize: [40, 30],
        iconAnchor: [20, 8],
      });
      leafletUserMarkerRef.current = L.marker([userLocation.lat, userLocation.lng], {
        icon: userIcon,
      }).addTo(map);

      // Truck Marker
      const truckPos = calculateTruckPosAndAngle(truckProgress);
      const truckIcon = L.divIcon({
        className: 'leaflet-custom-truck',
        html: `
          <div style="width:38px;height:38px;background:linear-gradient(135deg,#10B981,#059669);border:3px solid #fff;border-radius:9999px;display:flex;align-items:center;justify-content:center;box-shadow:0 6px 14px rgba(5,150,105,0.4);">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none"><rect x="3" y="6" width="13" height="10" rx="2" fill="#FFFFFF"/><path d="M16 9H20L22 12V16H16V9Z" fill="#A7F3D0"/><circle cx="7" cy="17" r="2.5" fill="#064E3B"/><circle cx="18" cy="17" r="2.5" fill="#064E3B"/></svg>
          </div>
        `,
        iconSize: [38, 38],
        iconAnchor: [19, 19],
      });
      leafletTruckMarkerRef.current = L.marker([truckPos.lat, truckPos.lng], { icon: truckIcon })
        .addTo(map)
        .on('click', () => {
          if (onTruckClick) onTruckClick();
        });

      const resizeObserver = new ResizeObserver(() => {
        map.invalidateSize();
      });
      resizeObserver.observe(mapContainerRef.current);

      setTimeout(() => map.invalidateSize(), 150);

      return () => {
        resizeObserver.disconnect();
        map.remove();
        leafletMapRef.current = null;
      };
    } catch (e) {
      console.error('Leaflet init error:', e);
    }
  }, [usingFallback]);

  // Update 3D Camera Pitch & Bearing
  useEffect(() => {
    if (!mapRef.current) return;
    mapRef.current.easeTo({
      pitch: is3DMode ? 54 : 0,
      bearing: is3DMode ? -16 : 0,
      duration: 800,
    });
  }, [is3DMode]);

  // Smoothly update truck position
  useEffect(() => {
    const { lng, lat } = calculateTruckPosAndAngle(truckProgress);

    if (truckMarkerRef.current) {
      truckMarkerRef.current.setLngLat([lng, lat]);
    }
    if (leafletTruckMarkerRef.current) {
      leafletTruckMarkerRef.current.setLatLng([lat, lng]);
    }
  }, [truckProgress, calculateTruckPosAndAngle]);

  // Update user location pin
  useEffect(() => {
    if (userMarkerRef.current) {
      userMarkerRef.current.setLngLat([userLocation.lng, userLocation.lat]);
    }
    if (leafletUserMarkerRef.current) {
      leafletUserMarkerRef.current.setLatLng([userLocation.lat, userLocation.lng]);
    }
  }, [userLocation]);

  return (
    <div className={`relative w-full h-full overflow-hidden ${className}`}>
      <div ref={mapContainerRef} className="w-full h-full min-h-[300px]" />
    </div>
  );
};
