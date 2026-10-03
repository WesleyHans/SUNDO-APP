import React from 'react';
import { Home, MapPin, Plus, Calendar, Bell } from 'lucide-react';

export type UnifiedNavTab = 'home' | 'live_map' | 'map' | 'report' | 'report_wizard' | 'schedule' | 'alerts' | 'notifications' | 'profile';

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

  // Normalize active tab matching
  const isHomeActive = activeTab === 'home';
  const isMapActive = activeTab === 'live_map' || activeTab === 'map';
  const isReportActive = activeTab === 'report' || activeTab === 'report_wizard' || activeTab === 'my_reports';
  const isScheduleActive = activeTab === 'schedule' || activeTab === 'schedule_calendar';
  const isAlertsActive = activeTab === 'alerts' || activeTab === 'notifications';

  return (
    <nav className="w-full bg-white/95 backdrop-blur-md border-t border-slate-100/90 px-2 sm:px-4 py-1 flex items-center justify-around z-30 shrink-0 shadow-[0_-4px_24px_rgba(0,0,0,0.04)] select-none">
      {/* 1. Home */}
      <button
        type="button"
        onClick={() => onTabChange('home')}
        className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all cursor-pointer min-h-[50px] min-w-[54px] active:scale-95 ${
          isHomeActive
            ? 'text-emerald-700 font-extrabold'
            : 'text-slate-400 hover:text-slate-600 font-semibold'
        }`}
        aria-label="Home"
      >
        <Home
          className={`w-5 h-5 transition-transform duration-200 ${
            isHomeActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
          }`}
        />
        <span className="text-[10px] mt-1 tracking-tight leading-none">Home</span>
        {isHomeActive && <span className="w-1 h-1 bg-emerald-600 rounded-full mt-0.5" />}
      </button>

      {/* 2. Live Map */}
      <button
        type="button"
        onClick={() => onTabChange('live_map')}
        className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all cursor-pointer min-h-[50px] min-w-[54px] active:scale-95 ${
          isMapActive
            ? 'text-emerald-700 font-extrabold'
            : 'text-slate-400 hover:text-slate-600 font-semibold'
        }`}
        aria-label="Live Map"
      >
        <MapPin
          className={`w-5 h-5 transition-transform duration-200 ${
            isMapActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
          }`}
        />
        <span className="text-[10px] mt-1 tracking-tight leading-none">Live Map</span>
        {isMapActive && <span className="w-1 h-1 bg-emerald-600 rounded-full mt-0.5" />}
      </button>

      {/* 3. REPORT (Prominent Elevated Action Button) */}
      <button
        type="button"
        onClick={() => onTabChange('report')}
        className="flex flex-col items-center justify-center -mt-5 cursor-pointer group active:scale-95 transition-transform min-w-[60px]"
        aria-label="Report Garbage"
      >
        <div
          className={`w-13 h-13 rounded-full flex items-center justify-center text-white shadow-xl border-3 border-white transition-all ${
            isReportActive
              ? 'bg-gradient-to-tr from-emerald-600 to-teal-500 ring-3 ring-emerald-400/40 scale-105'
              : 'bg-gradient-to-tr from-emerald-500 to-teal-500 shadow-emerald-500/30 group-hover:scale-105'
          }`}
        >
          <Plus className="w-7 h-7 stroke-[3]" />
        </div>
        <span
          className={`text-[10px] mt-1 font-extrabold tracking-tight ${
            isReportActive ? 'text-emerald-800' : 'text-slate-600'
          }`}
        >
          Report
        </span>
      </button>

      {/* 4. Schedule */}
      <button
        type="button"
        onClick={() => onTabChange('schedule')}
        className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all cursor-pointer min-h-[50px] min-w-[54px] active:scale-95 ${
          isScheduleActive
            ? 'text-emerald-700 font-extrabold'
            : 'text-slate-400 hover:text-slate-600 font-semibold'
        }`}
        aria-label="Collection Schedule"
      >
        <Calendar
          className={`w-5 h-5 transition-transform duration-200 ${
            isScheduleActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
          }`}
        />
        <span className="text-[10px] mt-1 tracking-tight leading-none">Schedule</span>
        {isScheduleActive && <span className="w-1 h-1 bg-emerald-600 rounded-full mt-0.5" />}
      </button>

      {/* 5. Alerts */}
      <button
        type="button"
        onClick={() => onTabChange('alerts')}
        className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all cursor-pointer min-h-[50px] min-w-[54px] relative active:scale-95 ${
          isAlertsActive
            ? 'text-emerald-700 font-extrabold'
            : 'text-slate-400 hover:text-slate-600 font-semibold'
        }`}
        aria-label="Alerts"
      >
        <div className="relative">
          <Bell
            className={`w-5 h-5 transition-transform duration-200 ${
              isAlertsActive ? 'stroke-[2.5] scale-110 text-emerald-600' : 'stroke-[1.8]'
            }`}
          />
          {alertsCount > 0 && (
            <span className="absolute -top-1 -right-1.5 w-4 h-4 bg-red-500 text-white rounded-full text-[9px] font-bold flex items-center justify-center border-2 border-white shadow-xs">
              {alertsCount > 9 ? '9+' : alertsCount}
            </span>
          )}
        </div>
        <span className="text-[10px] mt-1 tracking-tight leading-none">Alerts</span>
        {isAlertsActive && <span className="w-1 h-1 bg-emerald-600 rounded-full mt-0.5" />}
      </button>
    </nav>
  );
};

// Also export alias ResidentBottomNav for backwards compatibility
export const ResidentBottomNav = BottomNav;
