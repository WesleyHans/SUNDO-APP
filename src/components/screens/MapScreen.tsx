import React, { useState } from 'react';
import {
  Search,
  Crosshair,
  Locate,
  Truck,
  MapPin,
  AlertCircle,
  Clock,
  Layers,
  Sparkles,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { ResidentBottomNav } from '../layout/BottomNav';
import { Real3DMap } from '../common/Real3DMap';
import {
  ResidentUser,
  GarbageReport,
  CollectionVehicle,
  ResidentTab,
} from '../../types/resident';

interface ResidentMapScreenProps {
  user: ResidentUser;
  reports: GarbageReport[];
  vehicle: CollectionVehicle;
  onNavigateTab: (tab: ResidentTab) => void;
  onOpenReportWizard: () => void;
  onSelectReport: (report: GarbageReport) => void;
}

export const ResidentMapScreen: React.FC<ResidentMapScreenProps> = ({
  user,
  reports,
  vehicle,
  onNavigateTab,
  onOpenReportWizard,
  onSelectReport,
}) => {
  const [is3D, setIs3D] = useState(true);
  const [selectedReportOnMap, setSelectedReportOnMap] = useState<GarbageReport | null>(null);

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F8FAFC] text-slate-800 select-none overflow-hidden font-sans">
      {/* Top Floating App Bar */}
      <div className="absolute top-0 left-0 right-0 z-20 px-4 pt-1 pointer-events-none">
        <div className="pointer-events-auto">
          <StatusBar dark={true} />

          {/* Search / Status Pill */}
          <div className="mt-1 clay-card px-4 py-2.5 flex items-center justify-between text-xs shadow-md">
            <div className="flex items-center gap-2">
              <Search className="w-4 h-4 text-emerald-700 stroke-[2.4]" />
              <span className="font-extrabold text-slate-900 font-['Outfit']">
                Sipalay OpenStreetMap
              </span>
            </div>
            <div className="flex items-center gap-1.5 text-emerald-800 font-bold text-[11px]">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              <span>Barangay 1 Active</span>
            </div>
          </div>
        </div>
      </div>

      {/* Map Surface (Real 3D / 2D WebGL OSM Engine) */}
      <div className="relative flex-1 w-full h-full bg-[#E5F3EE] overflow-hidden">
        <Real3DMap
          truckProgress={vehicle.routeProgress}
          userLocation={{ lat: 9.7540, lng: 122.4048 }}
          is3DMode={is3D}
          className="w-full h-full z-0"
        />

        {/* 3D Map Floating Tools */}
        <div className="absolute right-3.5 top-24 flex flex-col gap-2.5 z-10">
          <button
            onClick={() => setIs3D(!is3D)}
            className={`w-10 h-10 rounded-2xl flex items-center justify-center font-extrabold text-xs cursor-pointer shadow-md transition-all active:scale-95 ${
              is3D ? 'clay-button-primary text-white' : 'clay-button-secondary text-slate-700'
            }`}
            title={is3D ? 'Switch to 2D Top-Down' : 'Switch to 3D View'}
          >
            {is3D ? '3D' : '2D'}
          </button>

          <button
            onClick={() => alert(`Your current location: Barangay 1, Sipalay City (Lat: 9.7540, Lng: 122.4048)`)}
            className="w-10 h-10 rounded-2xl clay-button-secondary flex items-center justify-center text-slate-700 active:scale-95 cursor-pointer shadow-md"
            title="Locate my position"
          >
            <Locate className="w-4 h-4 text-blue-600 stroke-[2.2]" />
          </button>

          <button
            onClick={onOpenReportWizard}
            className="w-10 h-10 rounded-2xl bg-emerald-50 border border-emerald-300 text-emerald-700 flex items-center justify-center active:scale-95 cursor-pointer shadow-md"
            title="Report garbage at this location"
          >
            <MapPin className="w-4 h-4 text-emerald-600 stroke-[2.2]" />
          </button>
        </div>

        {/* Active Vehicle Live Status Banner (Section 11 Spec) */}
        <div className="absolute top-24 left-4 z-10 pointer-events-none max-w-[220px]">
          {vehicle.isTrackingAvailable ? (
            <div className="bg-white/95 backdrop-blur-md px-3 py-1.5 rounded-2xl border border-emerald-200 text-slate-900 shadow-md">
              <span className="text-[10px] font-extrabold text-emerald-800 flex items-center gap-1.5 uppercase tracking-wide">
                <Truck className="w-3.5 h-3.5 text-emerald-700" />
                <span>Collection Vehicle</span>
              </span>
              <p className="text-[11px] font-bold text-slate-800 leading-tight mt-0.5">
                Currently collecting near your area.
              </p>
              <p className="text-[10px] text-slate-500 font-medium">
                {vehicle.vehicleNumber} • ETA: ~{vehicle.etaMinutes} min
              </p>
            </div>
          ) : (
            <div className="bg-white/95 backdrop-blur-md px-3 py-1.5 rounded-2xl border border-slate-200 text-slate-500 shadow-md text-[11px] font-medium">
              Live tracking is currently unavailable.
            </div>
          )}
        </div>

        {/* Bottom Floating Card: Garbage Reports List on Map */}
        <div className="absolute bottom-3 left-3 right-3 z-10 clay-card p-3.5 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-black text-slate-900 font-['Outfit'] uppercase tracking-wider">
              Garbage Reports Nearby ({reports.length})
            </span>
            <button
              onClick={() => onNavigateTab('report')}
              className="text-xs font-bold text-emerald-700 hover:underline cursor-pointer"
            >
              + Report Here
            </button>
          </div>

          {/* Quick horizontal scroll of neighborhood reports */}
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
            {reports.map((r) => (
              <div
                key={r.id}
                onClick={() => onSelectReport(r)}
                className="p-2 rounded-xl bg-slate-50 border border-slate-200 hover:border-emerald-300 flex items-center gap-2.5 shrink-0 cursor-pointer min-w-[210px]"
              >
                <img src={r.photoUrl} alt="trash" className="w-9 h-9 rounded-lg object-cover" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-mono font-bold text-emerald-800 truncate">
                      {r.id.slice(10)}
                    </span>
                    <span className="text-[9px] font-extrabold px-1.5 py-0.2 bg-white rounded-md border text-slate-700">
                      {r.status}
                    </span>
                  </div>
                  <p className="text-[11px] font-bold text-slate-800 truncate">{r.garbageType}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 5-Tab Resident Bottom Nav */}
      <ResidentBottomNav
        activeTab="map"
        onTabChange={onNavigateTab}
        unreadCount={0}
      />
    </div>
  );
};
