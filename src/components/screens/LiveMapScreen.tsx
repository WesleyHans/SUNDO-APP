import React, { useState, useEffect } from 'react';
import {
  Search,
  Crosshair,
  ChevronRight,
  Play,
  Pause,
  AlertCircle,
  Locate,
  Layers,
  Compass,
  RotateCw,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { SundoTruckIcon } from '../common/SundoLogo';
import { Real3DMap } from '../common/Real3DMap';
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
  const [progress, setProgress] = useState(truck.pathProgress || 0.35);
  const [userCoords, setUserCoords] = useState<{ lat: number; lng: number }>({
    lat: USER_DEFAULT_COORDS.lat,
    lng: USER_DEFAULT_COORDS.lng,
  });
  const [locatingUser, setLocatingUser] = useState(false);

  // Timeline steps from the reference design:
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
        const next = prev >= 0.98 ? 0.05 : prev + 0.012;
        if (onUpdateTruckProgress) onUpdateTruckProgress(next);
        return next;
      });
    }, 1200);
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
      alert('Geolocation is not supported by your browser.');
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
      },
      (err) => {
        console.warn('Geolocation notice:', err.message);
        setUserCoords({
          lat: USER_DEFAULT_COORDS.lat,
          lng: USER_DEFAULT_COORDS.lng,
        });
        setLocatingUser(false);
      },
      { timeout: 8000, enableHighAccuracy: true }
    );
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F4F7F6] text-slate-800 select-none overflow-hidden">
      {/* Top Search / Header Floating Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 px-4 pt-1 pointer-events-none">
        <div className="pointer-events-auto">
          <StatusBar dark={true} />

          {/* Clay Search Pill: Q Live Truck Tracking > */}
          <div className="mt-1 clay-card px-4 py-2.5 flex items-center justify-between text-xs cursor-pointer active:scale-[0.99] transition-transform">
            <div className="flex items-center gap-2 text-slate-700">
              <Search className="w-4 h-4 text-emerald-600 stroke-[2.2]" />
              <span className="font-extrabold text-slate-900 font-['Outfit']">Live Truck Tracking</span>
            </div>
            <div className="flex items-center gap-1.5 text-emerald-800 font-bold text-[11px]">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              <span>Sipalay 3D</span>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Real 3D WebGL OpenStreetMap Engine */}
      <div className="relative flex-1 w-full h-full bg-[#E5F3EE] overflow-hidden">
        <Real3DMap
          truckProgress={progress}
          userLocation={userCoords}
          is3DMode={is3D}
          onTruckClick={onTriggerAlert}
          className="w-full h-full z-0"
        />

        {/* 3D Map Floating Clay Tools on Right */}
        <div className="absolute right-3.5 top-24 flex flex-col gap-2.5 z-10">
          {/* 3D / 2D Perspective Toggle Button */}
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

          {/* Recenter Sipalay Poblacion */}
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

        {/* 3D Indicator Floating Badge */}
        <div className="absolute left-4 top-24 z-10 pointer-events-none">
          <div className="bg-slate-900/80 backdrop-blur-md text-white text-[10px] font-bold px-3 py-1.5 rounded-full flex items-center gap-1.5 shadow-md">
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
            <span>{is3D ? '3D Perspective Tilt (58°)' : '2D Top-Down View'}</span>
          </div>
        </div>

        {/* Floating Bottom Card / Sheet with Claymorphism */}
        <div className="absolute bottom-3 left-3 right-3 z-10 clay-card p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {/* Truck Icon Box */}
              <div className="w-13 h-13 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100/90 border border-emerald-200/80 flex items-center justify-center p-1.5 shrink-0 shadow-xs">
                <SundoTruckIcon size={34} />
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
                </p>
              </div>
            </div>

            {/* ETA pill */}
            <div className="text-right">
              <span className="text-[10px] font-bold text-slate-400 block tracking-wider uppercase">ETA</span>
              <span className="text-xs font-black text-emerald-700">
                {currentEta} minutes
              </span>
            </div>
          </div>

          {/* Timeline Step Rail (Not Started -> On Route -> Approaching -> Nearby -> Completed) */}
          <div className="mt-4 pt-3 border-t border-slate-100">
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
                      className={`w-4.5 h-4.5 rounded-full border-2 transition-all flex items-center justify-center z-10 shadow-xs ${
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
          </div>
        </div>
      </div>

      {/* Bottom Nav */}
      <BottomNav
        activeTab="live_map"
        onTabChange={onNavigateTab}
        unreadAlertsCount={unreadCount}
      />
    </div>
  );
};
