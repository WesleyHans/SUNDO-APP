import React from 'react';
import { Home, Plus, Bell, User } from 'lucide-react';
import { RealisticMapIcon } from './RealisticMapIcon';

export type UnifiedNavTab =
  | 'home'
  | 'live_map'
  | 'map'
  | 'report'
  | 'report_wizard'
  | 'schedule'
  | 'alerts'
  | 'notifications'
  | 'profile';

export interface BottomNavProps {
  activeTab: UnifiedNavTab | string;
  onTabChange: (tab: any) => void;
  unreadAlertsCount?: number;
  unreadCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  activeTab,
  onTabChange,
  unreadAlertsCount,
  unreadCount,
}) => {
  const alertsCount = unreadAlertsCount ?? unreadCount ?? 0;

  // Active state matching
  const isHomeActive = activeTab === 'home';
  const isMapActive = activeTab === 'live_map' || activeTab === 'map';
  const isReportActive =
    activeTab === 'report' || activeTab === 'report_wizard' || activeTab === 'my_reports';
  const isAlertsActive = activeTab === 'alerts' || activeTab === 'notifications';
  const isProfileActive = activeTab === 'profile';

  return (
    <nav
      className="w-full bg-gradient-to-b from-white via-slate-50/98 to-slate-100/95 backdrop-blur-md rounded-t-[28px] border-t border-white px-2 sm:px-4 py-2 flex items-center justify-around z-30 shrink-0 select-none transition-all"
      style={{
        boxShadow:
          '0 -8px 25px rgba(148, 163, 184, 0.22), 0 -2px 6px rgba(148, 163, 184, 0.1), inset 0 2px 3px rgba(255, 255, 255, 0.95), inset 0 -2px 4px rgba(203, 213, 225, 0.35)',
      }}
    >
      {/* 1. HOME (Claymorphic) */}
      <button
        type="button"
        onClick={() => onTabChange('home')}
        className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all cursor-pointer min-h-[50px] min-w-[56px] active:scale-95 ${
          isHomeActive
            ? 'bg-gradient-to-tr from-emerald-50 to-teal-50 text-emerald-700 font-extrabold border border-emerald-100/80'
            : 'text-slate-400 hover:text-slate-600 font-semibold hover:bg-slate-100/60'
        }`}
        style={
          isHomeActive
            ? {
                boxShadow:
                  'inset 1px 1px 2px rgba(255, 255, 255, 0.95), inset -1px -1px 2px rgba(5, 150, 105, 0.12), 2px 3px 8px rgba(5, 150, 105, 0.12)',
              }
            : undefined
        }
        aria-label="Home"
      >
        <div
          className={`p-1 rounded-xl transition-all ${
            isHomeActive
              ? 'bg-emerald-500/15 text-emerald-600 shadow-[inset_1px_1px_2px_rgba(255,255,255,0.8)]'
              : ''
          }`}
        >
          <Home
            className={`w-5 h-5 transition-transform duration-200 ${
              isHomeActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
            }`}
          />
        </div>
        <span className="text-[10px] mt-0.5 tracking-tight leading-none">Home</span>
      </button>

      {/* 2. REALISTIC LIVE MAP (Custom 3D Folded Map & Pin) */}
      <button
        type="button"
        onClick={() => onTabChange('live_map')}
        className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all cursor-pointer min-h-[50px] min-w-[56px] active:scale-95 ${
          isMapActive
            ? 'bg-gradient-to-tr from-emerald-50 to-teal-50 text-emerald-700 font-extrabold border border-emerald-100/80'
            : 'text-slate-400 hover:text-slate-600 font-semibold hover:bg-slate-100/60'
        }`}
        style={
          isMapActive
            ? {
                boxShadow:
                  'inset 1px 1px 2px rgba(255, 255, 255, 0.95), inset -1px -1px 2px rgba(5, 150, 105, 0.12), 2px 3px 8px rgba(5, 150, 105, 0.12)',
              }
            : undefined
        }
        aria-label="Live Map"
      >
        <div className="p-0.5">
          <RealisticMapIcon size={24} isActive={isMapActive} />
        </div>
        <span className="text-[10px] mt-0.5 tracking-tight leading-none">Live Map</span>
      </button>

      {/* 3. REPORT (+) (Prominent 3D Claymorphic Action Button) */}
      <button
        type="button"
        onClick={() => onTabChange('report')}
        className="flex flex-col items-center justify-center -mt-6 cursor-pointer group active:scale-90 active:translate-y-1 transition-all min-w-[62px]"
        aria-label="Report Garbage"
      >
        <div
          className={`w-14 h-14 rounded-full flex items-center justify-center text-white border-[3.5px] border-white transition-all ${
            isReportActive
              ? 'bg-gradient-to-br from-emerald-400 via-emerald-600 to-teal-700 ring-4 ring-emerald-400/30 scale-105'
              : 'bg-gradient-to-br from-emerald-400 via-emerald-500 to-teal-600 group-hover:scale-105'
          }`}
          style={{
            boxShadow:
              '0 10px 22px rgba(5, 150, 105, 0.38), -3px -3px 8px rgba(255, 255, 255, 0.7), inset 2px 2px 4px rgba(255, 255, 255, 0.65), inset -3px -3px 6px rgba(4, 120, 87, 0.6)',
          }}
        >
          <Plus className="w-7 h-7 stroke-[3] drop-shadow-sm" />
        </div>
        <span
          className={`text-[10px] mt-1 font-extrabold tracking-tight ${
            isReportActive ? 'text-emerald-800' : 'text-slate-600'
          }`}
        >
          Report
        </span>
      </button>

      {/* 4. ALERTS (Claymorphic with Badge) */}
      <button
        type="button"
        onClick={() => onTabChange('alerts')}
        className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all cursor-pointer min-h-[50px] min-w-[56px] relative active:scale-95 ${
          isAlertsActive
            ? 'bg-gradient-to-tr from-emerald-50 to-teal-50 text-emerald-700 font-extrabold border border-emerald-100/80'
            : 'text-slate-400 hover:text-slate-600 font-semibold hover:bg-slate-100/60'
        }`}
        style={
          isAlertsActive
            ? {
                boxShadow:
                  'inset 1px 1px 2px rgba(255, 255, 255, 0.95), inset -1px -1px 2px rgba(5, 150, 105, 0.12), 2px 3px 8px rgba(5, 150, 105, 0.12)',
              }
            : undefined
        }
        aria-label="Alerts"
      >
        <div className="relative p-1">
          <Bell
            className={`w-5 h-5 transition-transform duration-200 ${
              isAlertsActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
            }`}
          />
          {alertsCount > 0 && (
            <span
              className="absolute -top-0.5 -right-1 min-w-[16px] h-4 px-1 rounded-full text-white text-[9px] font-black flex items-center justify-center border border-white"
              style={{
                background: 'linear-gradient(135deg, #f43f5e 0%, #e11d48 100%)',
                boxShadow:
                  'inset 1px 1px 2px rgba(255, 255, 255, 0.65), 1px 2px 5px rgba(225, 29, 72, 0.4)',
              }}
            >
              {alertsCount > 9 ? '9+' : alertsCount}
            </span>
          )}
        </div>
        <span className="text-[10px] mt-0.5 tracking-tight leading-none">Alerts</span>
      </button>

      {/* 5. PROFILE (Claymorphic Resident Profile) */}
      <button
        type="button"
        onClick={() => onTabChange('profile')}
        className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all cursor-pointer min-h-[50px] min-w-[56px] active:scale-95 ${
          isProfileActive
            ? 'bg-gradient-to-tr from-emerald-50 to-teal-50 text-emerald-700 font-extrabold border border-emerald-100/80'
            : 'text-slate-400 hover:text-slate-600 font-semibold hover:bg-slate-100/60'
        }`}
        style={
          isProfileActive
            ? {
                boxShadow:
                  'inset 1px 1px 2px rgba(255, 255, 255, 0.95), inset -1px -1px 2px rgba(5, 150, 105, 0.12), 2px 3px 8px rgba(5, 150, 105, 0.12)',
              }
            : undefined
        }
        aria-label="Profile"
      >
        <div
          className={`p-1 rounded-xl transition-all ${
            isProfileActive
              ? 'bg-emerald-500/15 text-emerald-600 shadow-[inset_1px_1px_2px_rgba(255,255,255,0.8)]'
              : ''
          }`}
        >
          <User
            className={`w-5 h-5 transition-transform duration-200 ${
              isProfileActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
            }`}
          />
        </div>
        <span className="text-[10px] mt-0.5 tracking-tight leading-none">Profile</span>
      </button>
    </nav>
  );
};

// Also export alias ResidentBottomNav for backwards compatibility
export const ResidentBottomNav = BottomNav;
