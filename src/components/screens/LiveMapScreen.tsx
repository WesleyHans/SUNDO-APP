import React, { useState, useEffect } from 'react';
import {
  Search,
  Crosshair,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  Play,
  Pause,
  AlertCircle,
  Locate,
  Layers,
  ZoomIn,
  ZoomOut,
  MapPin,
  Clock,
  CheckCircle2,
  Truck,
  Sparkles,
  Compass,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { SundoTruckIcon } from '../common/SundoLogo';
import { Real3DMap, MapStyleType, SIPALAY_WAYPOINTS } from '../common/Real3DMap';
import { USER_DEFAULT_COORDS } from '../common/RealLeafletMap';
import { TruckStatus, BottomNavTab } from '../../types';

interface LiveMapScreenProps {
  truck: TruckStatus;
  unreadCount: number;
  onNavigateTab: (tab: BottomNavTab) => void;
  onTriggerAlert: () => void;
  onUpdateTruckProgress?: (newProgress: number) => void;
}

export const LiveMapScreen: React.FC<LiveMapScreenProps> = ({
  truck,
  unreadCount,
  onNavigateTab,
  onTriggerAlert,
  onUpdateTruckProgress,
}) => {
  const [isPlaying, setIsPlaying] = useState(true);
  const [is3D, setIs3D] = useState(true); // 3D Camera Tilt Mode
  const [mapStyle, setMapStyle] = useState<MapStyleType>('streets');
  const [showLayerMenu, setShowLayerMenu] = useState(false);
  const [isCardCollapsed, setIsCardCollapsed] = useState(false);
  const [showStopsList, setShowStopsList] = useState(false);
  const [progress, setProgress] = useState(truck.pathProgress || 0.35);
  const [userCoords, setUserCoords] = useState<{ lat: number; lng: number }>({
    lat: USER_DEFAULT_COORDS.lat,
    lng: USER_DEFAULT_COORDS.lng,
  });
  const [locatingUser, setLocatingUser] = useState(false);
  const [gpsNotice, setGpsNotice] = useState<string | null>(null);

  // Timeline steps:
  // "Not Started", "On Route", "Approaching", "Nearby", "Completed"
  const steps = [
    { label: 'Not Started', value: 0.05 },
    { label: 'On Route', value: 0.35 },
    { label: 'Approaching', value: 0.65 },
    { label: 'Nearby', value: 0.85 },
    { label: 'Completed', value: 1.0 },
  ];

  // Auto-advance simulation if playing
  useEffect(() => {
    if (!isPlaying) return;
    const interval = setInterval(() => {
      setProgress((prev) => {
        const next = prev >= 0.98 ? 0.05 : prev + 0.008;
        if (onUpdateTruckProgress) onUpdateTruckProgress(next);
        return next;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [isPlaying, onUpdateTruckProgress]);

  // Determine current active step index
  const activeStepIndex =
    progress < 0.2 ? 0 : progress < 0.5 ? 1 : progress < 0.75 ? 2 : progress < 0.95 ? 3 : 4;

  // Real distance and dynamic ETA
  const currentEta = Math.max(1, Math.round(14 * (1 - progress)));
  const currentDist = (Math.max(0.1, 2.8 * (1 - progress))).toFixed(1);

  // Request actual device GPS position
  const handleGetLiveLocation = () => {
    if (!navigator.geolocation) {
      setGpsNotice('Geolocation not supported on this device');
      setTimeout(() => setGpsNotice(null), 3000);
      return;
    }
    setLocatingUser(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserCoords({
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        });
        setLocatingUser(false);
        setGpsNotice('GPS location updated!');
        setTimeout(() => setGpsNotice(null), 2500);
      },
      (err) => {
        console.warn('Geolocation notice:', err.message);
        setUserCoords({
          lat: USER_DEFAULT_COORDS.lat,
          lng: USER_DEFAULT_COORDS.lng,
        });
        setLocatingUser(false);
        setGpsNotice('Simulating Sipalay Poblacion location');
        setTimeout(() => setGpsNotice(null), 2500);
      },
      { timeout: 7000, enableHighAccuracy: true }
    );
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F4F7F6] text-slate-800 select-none overflow-hidden font-sans">
      {/* Top Floating App Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 px-4 pt-1 pointer-events-none">
        <div className="pointer-events-auto">
          <StatusBar dark={true} />

          {/* Search / Map Title Pill */}
          <div className="mt-1 clay-card px-4 py-2.5 flex items-center justify-between text-xs cursor-pointer active:scale-[0.99] transition-transform">
            <div className="flex items-center gap-2 text-slate-700">
              <Search className="w-4 h-4 text-emerald-600 stroke-[2.2]" />
              <span className="font-extrabold text-slate-900 font-['Outfit']">
                Live Truck Tracking
              </span>
            </div>
            <div className="flex items-center gap-1.5 text-emerald-800 font-bold text-[11px]">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              <span>Sipalay {is3D ? '3D' : '2D'}</span>
              <span className="text-[10px] bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full font-semibold">
                Live
              </span>
            </div>
          </div>

          {/* GPS notice toast */}
          {gpsNotice && (
            <div className="mt-2 mx-auto w-fit bg-slate-900/90 text-white text-[11px] font-semibold px-3 py-1.5 rounded-full shadow-lg backdrop-blur-sm animate-fade-in flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-emerald-400" />
              <span>{gpsNotice}</span>
            </div>
          )}
        </div>
      </div>

      {/* Real 3D / Leaflet Interactive Map Container */}
      <div className="relative flex-1 w-full min-h-0 bg-[#E5F3EE] overflow-hidden">
        <Real3DMap
          truckProgress={progress}
          userLocation={userCoords}
          is3DMode={is3D}
          mapStyle={mapStyle}
          onTruckClick={onTriggerAlert}
          className="w-full h-full"
        />

        {/* 3D Map Floating Clay Tools on Right */}
        <div className="absolute right-3.5 top-24 flex flex-col gap-2 z-10">
          {/* 3D / 2D Perspective Toggle */}
          <button
            onClick={() => setIs3D(!is3D)}
            className={`w-10 h-10 rounded-2xl flex items-center justify-center font-extrabold text-xs cursor-pointer transition-all active:scale-95 shadow-md ${
              is3D
                ? 'clay-button-primary text-white border-2 border-white'
                : 'clay-button-secondary text-slate-700'
            }`}
            title={is3D ? 'Switch to 2D Top-Down View' : 'Switch to 3D Tilted Perspective'}
          >
            {is3D ? '3D' : '2D'}
          </button>

          {/* Map Layer Switcher (Streets / Satellite / Terrain) */}
          <div className="relative">
            <button
              onClick={() => setShowLayerMenu(!showLayerMenu)}
              className="w-10 h-10 rounded-2xl clay-button-secondary flex items-center justify-center text-slate-700 hover:text-emerald-700 active:scale-95 cursor-pointer transition-all shadow-md"
              title="Change Map Layers"
            >
              <Layers className="w-4 h-4 text-emerald-700 stroke-[2.2]" />
            </button>

            {showLayerMenu && (
              <div className="absolute right-12 top-0 bg-white/95 backdrop-blur-md border border-slate-200 rounded-2xl shadow-xl p-2 w-36 space-y-1 text-xs z-30 font-semibold">
                <button
                  onClick={() => {
                    setMapStyle('streets');
                    setShowLayerMenu(false);
                  }}
                  className={`w-full text-left px-2.5 py-1.5 rounded-xl transition-colors cursor-pointer ${
                    mapStyle === 'streets'
                      ? 'bg-emerald-50 text-emerald-700 font-extrabold'
                      : 'hover:bg-slate-100 text-slate-700'
                  }`}
                >
                  🗺️ Streets
                </button>
                <button
                  onClick={() => {
                    setMapStyle('satellite');
                    setShowLayerMenu(false);
                  }}
                  className={`w-full text-left px-2.5 py-1.5 rounded-xl transition-colors cursor-pointer ${
                    mapStyle === 'satellite'
                      ? 'bg-emerald-50 text-emerald-700 font-extrabold'
                      : 'hover:bg-slate-100 text-slate-700'
                  }`}
                >
                  🛰️ Satellite
                </button>
                <button
                  onClick={() => {
                    setMapStyle('terrain');
                    setShowLayerMenu(false);
                  }}
                  className={`w-full text-left px-2.5 py-1.5 rounded-xl transition-colors cursor-pointer ${
                    mapStyle === 'terrain'
                      ? 'bg-emerald-50 text-emerald-700 font-extrabold'
                      : 'hover:bg-slate-100 text-slate-700'
                  }`}
                >
                  🏔️ Terrain
                </button>
              </div>
            )}
          </div>

          {/* Pause / Play Real Tracking */}
          <button
            onClick={() => setIsPlaying(!isPlaying)}
            className="w-10 h-10 rounded-2xl clay-button-secondary flex items-center justify-center text-slate-700 hover:text-emerald-700 active:scale-95 cursor-pointer transition-all shadow-md"
            title={isPlaying ? 'Pause truck simulation' : 'Play truck simulation'}
          >
            {isPlaying ? (
              <Pause className="w-4 h-4 text-emerald-700 stroke-[2.4]" />
            ) : (
              <Play className="w-4 h-4 text-emerald-700 fill-emerald-700" />
            )}
          </button>

          {/* Real Device GPS Geolocation button */}
          <button
            onClick={handleGetLiveLocation}
            className={`w-10 h-10 rounded-2xl clay-button-secondary flex items-center justify-center text-slate-700 active:scale-95 cursor-pointer transition-all shadow-md ${
              locatingUser ? 'animate-spin text-emerald-600' : ''
            }`}
            title="Locate my position (Real GPS)"
          >
            <Locate className="w-4 h-4 text-blue-600 stroke-[2.2]" />
          </button>

          {/* Recenter Sipalay Approaching Point */}
          <button
            onClick={() => setProgress(0.65)}
            className="w-10 h-10 rounded-2xl clay-button-secondary flex items-center justify-center text-slate-700 active:scale-95 cursor-pointer transition-all shadow-md"
            title="Recenter to approaching point"
          >
            <Crosshair className="w-4 h-4 text-slate-600 stroke-[2.2]" />
          </button>

          {/* Trigger Alert Modal preview */}
          <button
            onClick={onTriggerAlert}
            className="w-10 h-10 rounded-2xl bg-amber-50 border border-amber-300 text-amber-700 flex items-center justify-center hover:bg-amber-100 active:scale-95 cursor-pointer transition-all shadow-md"
            title="Preview Truck Approaching Alert Modal"
          >
            <AlertCircle className="w-4 h-4 text-amber-600 stroke-[2.2]" />
          </button>
        </div>

        {/* 3D Indicator Floating Badge on Left */}
        <div className="absolute left-4 top-24 z-10 pointer-events-none flex flex-col gap-1.5">
          <div className="bg-slate-900/80 backdrop-blur-md text-white text-[10px] font-bold px-3 py-1.5 rounded-full flex items-center gap-1.5 shadow-md">
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>{is3D ? '3D Perspective Tilt (54°)' : '2D Top-Down View'}</span>
          </div>

          <button
            onClick={() => setShowStopsList(true)}
            className="pointer-events-auto bg-white/90 hover:bg-white text-slate-800 text-[10px] font-bold px-3 py-1.5 rounded-full flex items-center gap-1.5 shadow-md border border-slate-200 cursor-pointer active:scale-95 transition-all"
          >
            <MapPin className="w-3 h-3 text-emerald-600" />
            <span>View 4 Route Stops</span>
          </button>
        </div>

        {/* Floating Bottom Card / Sheet with Claymorphism */}
        <div className="absolute bottom-3 left-3 right-3 z-10 clay-card p-4 transition-all duration-300">
          {/* Card Header & Collapse Toggle */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {/* Truck Icon Box */}
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100/90 border border-emerald-200/80 flex items-center justify-center p-1.5 shrink-0 shadow-xs">
                <SundoTruckIcon size={32} />
              </div>

              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-extrabold text-slate-900 font-['Outfit']">
                    {truck.name}
                  </h3>
                  <span className="clay-badge text-[10px] font-bold px-2.5 py-0.5 bg-emerald-100 text-emerald-800 border border-emerald-200">
                    On Route
                  </span>
                </div>
                <p className="text-xs text-slate-500 font-medium mt-0.5">
                  <span className="font-extrabold text-slate-900">{currentDist} km away</span>
                  <span className="text-slate-400"> • </span>
                  <span className="text-emerald-700 font-semibold">Brgy 1 Poblacion</span>
                </p>
              </div>
            </div>

            {/* ETA pill & Collapse Button */}
            <div className="flex items-center gap-2">
              <div className="text-right">
                <span className="text-[10px] font-bold text-slate-400 block tracking-wider uppercase">
                  ETA
                </span>
                <span className="text-xs font-black text-emerald-700">
                  {currentEta} mins
                </span>
              </div>

              <button
                onClick={() => setIsCardCollapsed(!isCardCollapsed)}
                className="p-1.5 rounded-xl hover:bg-slate-100 text-slate-400 hover:text-slate-600 transition-colors cursor-pointer"
                title={isCardCollapsed ? 'Expand card' : 'Collapse card'}
              >
                {isCardCollapsed ? (
                  <ChevronUp className="w-4 h-4" />
                ) : (
                  <ChevronDown className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>

          {/* Timeline Step Rail (Collapsible) */}
          {!isCardCollapsed && (
            <div className="mt-3.5 pt-3 border-t border-slate-100">
              <div className="relative flex items-center justify-between">
                {/* Connector line */}
                <div className="absolute top-2 left-2 right-2 h-0.5 bg-slate-200 -z-0"></div>
                <div
                  className="absolute top-2 left-2 h-0.5 bg-emerald-500 transition-all duration-300"
                  style={{ width: `${(activeStepIndex / (steps.length - 1)) * 96}%` }}
                ></div>

                {steps.map((st, i) => {
                  const isPassed = i <= activeStepIndex;
                  const isCurrent = i === activeStepIndex;

                  return (
                    <div
                      key={st.label}
                      onClick={() => {
                        setProgress(st.value);
                        if (onUpdateTruckProgress) onUpdateTruckProgress(st.value);
                      }}
                      className="flex flex-col items-center cursor-pointer group"
                    >
                      <div
                        className={`w-4 h-4 rounded-full border-2 transition-all flex items-center justify-center z-10 shadow-xs ${
                          isCurrent
                            ? 'clay-button-primary border-white ring-2 ring-emerald-500 scale-110'
                            : isPassed
                            ? 'bg-emerald-500 border-white'
                            : 'bg-white border-slate-300'
                        }`}
                      >
                        {isPassed && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                      </div>

                      <span
                        className={`text-[9px] mt-1 tracking-tight text-center whitespace-nowrap transition-colors ${
                          isCurrent
                            ? 'font-bold text-emerald-700'
                            : isPassed
                            ? 'font-bold text-slate-700'
                            : 'text-slate-400 font-medium'
                        }`}
                      >
                        {st.label}
                      </span>
                    </div>
                  );
                })}
              </div>

              {/* Quick speed controller */}
              <div className="mt-3 flex items-center justify-between text-[11px] text-slate-500">
                <span className="text-[10px] text-slate-400 font-semibold">
                  Driver: Tatay Berting • Plate: SAG-7821
                </span>
                <button
                  onClick={() => setShowStopsList(true)}
                  className="text-emerald-700 font-bold hover:underline cursor-pointer flex items-center gap-1"
                >
                  <span>Route Stops</span>
                  <ChevronRight className="w-3 h-3" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Route Stops Modal */}
        {showStopsList && (
          <div className="absolute inset-0 z-40 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-3 animate-fade-in">
            <div className="bg-white rounded-3xl w-full max-w-sm p-5 shadow-2xl space-y-4">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <div className="flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-emerald-600" />
                  <h3 className="font-extrabold text-sm text-slate-900 font-['Outfit']">
                    Sipalay Route Waypoints
                  </h3>
                </div>
                <button
                  onClick={() => setShowStopsList(false)}
                  className="text-xs font-bold text-slate-400 hover:text-slate-600 cursor-pointer p-1"
                >
                  ✕
                </button>
              </div>

              <div className="space-y-2.5 max-h-60 overflow-y-auto pr-1">
                {SIPALAY_WAYPOINTS.map((wp, index) => (
                  <div
                    key={wp.id}
                    className={`p-3 rounded-2xl border flex items-center justify-between text-xs ${
                      wp.status === 'completed'
                        ? 'bg-emerald-50/60 border-emerald-200 text-emerald-900'
                        : wp.status === 'current'
                        ? 'bg-amber-50/70 border-amber-200 text-amber-900 ring-2 ring-amber-400/30'
                        : 'bg-slate-50 border-slate-200 text-slate-600'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <div
                        className={`w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold text-white shrink-0 ${
                          wp.status === 'completed'
                            ? 'bg-emerald-600'
                            : wp.status === 'current'
                            ? 'bg-amber-500'
                            : 'bg-slate-400'
                        }`}
                      >
                        {wp.status === 'completed' ? '✓' : index + 1}
                      </div>
                      <div>
                        <span className="font-bold block leading-tight">{wp.name}</span>
                        <span className="text-[10px] text-slate-500">{wp.barangay}</span>
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <span className="text-[10px] font-semibold block">{wp.scheduledTime}</span>
                      <span className="text-[9px] uppercase tracking-wider font-extrabold text-emerald-700">
                        {wp.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>

              <button
                onClick={() => setShowStopsList(false)}
                className="w-full py-2.5 clay-button-primary text-white font-extrabold text-xs cursor-pointer"
              >
                Back to Map
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Claymorphic Bottom Nav with Profile and Realistic Map Icon */}
      <BottomNav
        activeTab="live_map"
        onTabChange={onNavigateTab}
        unreadAlertsCount={unreadCount}
      />
    </div>
  );
};
