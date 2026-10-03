import React, { useState } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Clock,
  Trash2,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { SundoTruckIcon } from '../common/SundoLogo';
import { SCHEDULE_ITEMS } from '../../data/mockData';
import { BottomNavTab } from '../../types';

interface ScheduleScreenProps {
  initialViewMode?: 'today' | 'this_week' | 'calendar';
  forceView?: 'list' | 'calendar';
  onBack: () => void;
  onNavigateTab: (tab: BottomNavTab) => void;
  unreadCount?: number;
}

export const ScheduleScreen: React.FC<ScheduleScreenProps> = ({
  initialViewMode = 'today',
  forceView,
  onBack,
  onNavigateTab,
  unreadCount = 2,
}) => {
  const [activeTab, setActiveTab] = useState<'today' | 'this_week' | 'calendar'>(
    forceView === 'calendar' ? 'calendar' : forceView === 'list' ? 'today' : initialViewMode
  );
  const [selectedDay, setSelectedDay] = useState<number>(12);

  const calendarDays = [
    { day: 27, currentMonth: false },
    { day: 28, currentMonth: false },
    { day: 29, currentMonth: false },
    { day: 30, currentMonth: false },
    { day: 31, currentMonth: false },
    { day: 1, currentMonth: true },
    { day: 2, currentMonth: true },

    { day: 3, currentMonth: true },
    { day: 4, currentMonth: true },
    { day: 5, currentMonth: true },
    { day: 6, currentMonth: true },
    { day: 7, currentMonth: true },
    { day: 8, currentMonth: true },
    { day: 9, currentMonth: true },

    { day: 10, currentMonth: true },
    { day: 11, currentMonth: true },
    { day: 12, currentMonth: true, hasCollection: true },
    { day: 13, currentMonth: true, hasCollection: true },
    { day: 14, currentMonth: true, hasCollection: true },
    { day: 15, currentMonth: true },
    { day: 16, currentMonth: true },

    { day: 17, currentMonth: true },
    { day: 18, currentMonth: true },
    { day: 19, currentMonth: true, hasCollection: true },
    { day: 20, currentMonth: true },
    { day: 21, currentMonth: true },
    { day: 22, currentMonth: true },
    { day: 23, currentMonth: true },

    { day: 24, currentMonth: true },
    { day: 25, currentMonth: true },
    { day: 26, currentMonth: true, hasCollection: true },
    { day: 27, currentMonth: true },
    { day: 28, currentMonth: true },
    { day: 29, currentMonth: true },
    { day: 30, currentMonth: true },
  ];

  const currentView = forceView === 'calendar' ? 'calendar' : forceView === 'list' ? 'today' : activeTab;
  const selectedSchedule = SCHEDULE_ITEMS.find((s) => s.dayOfMonth === selectedDay) || SCHEDULE_ITEMS[0];

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F4F7F6] text-slate-800 select-none overflow-hidden">
      {/* Top Header */}
      <div className="px-5 pt-1 pb-3 bg-white/95 backdrop-blur-md border-b border-slate-100 shrink-0 shadow-xs">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          <button
            onClick={onBack}
            className="p-1.5 -ml-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer active:scale-95"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <h1 className="text-base font-extrabold text-slate-900 font-['Outfit']">
            Collection Schedule
          </h1>

          <div className="w-5"></div>
        </div>

        {/* Claymorphic Segmented Filter Tabs */}
        {!forceView && (
          <div className="mt-3 bg-slate-200/60 p-1 rounded-full flex items-center shadow-inner">
            <button
              onClick={() => setActiveTab('today')}
              className={`flex-1 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer text-center ${
                activeTab === 'today'
                  ? 'clay-button-primary text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Today
            </button>
            <button
              onClick={() => setActiveTab('this_week')}
              className={`flex-1 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer text-center ${
                activeTab === 'this_week'
                  ? 'clay-button-primary text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              This Week
            </button>
            <button
              onClick={() => setActiveTab('calendar')}
              className={`flex-1 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer text-center ${
                activeTab === 'calendar'
                  ? 'clay-button-primary text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Calendar
            </button>
          </div>
        )}

        {/* Static tabs for gallery showcase */}
        {forceView && (
          <div className="mt-3 bg-slate-200/60 p-1 rounded-full flex items-center shadow-inner">
            <div
              className={`flex-1 py-1.5 rounded-full text-xs font-bold text-center ${
                forceView === 'list' ? 'clay-button-primary text-white' : 'text-slate-600'
              }`}
            >
              Today
            </div>
            <div className="flex-1 py-1.5 rounded-full text-xs font-semibold text-center text-slate-600">
              This Week
            </div>
            <div
              className={`flex-1 py-1.5 rounded-full text-xs font-bold text-center ${
                forceView === 'calendar' ? 'clay-button-primary text-white' : 'text-slate-600'
              }`}
            >
              Calendar
            </div>
          </div>
        )}
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto px-5 py-3.5 no-scrollbar space-y-4">
        {/* VIEW 1: Schedule List (Screen 8) */}
        {currentView !== 'calendar' && (
          <div>
            <h2 className="text-xs font-extrabold text-slate-900 font-['Outfit'] mb-3 tracking-wide uppercase">
              Tuesday, Nov 12, 2024
            </h2>

            <div className="space-y-3">
              {SCHEDULE_ITEMS.map((item) => {
                const isToday = item.statusTag === 'Today';
                const isUpcoming = item.statusTag === 'Upcoming';

                return (
                  <div
                    key={item.id}
                    className="clay-card p-4 flex items-center justify-between hover:scale-[1.01] transition-all"
                  >
                    <div className="flex items-center gap-3.5">
                      <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100/90 border border-emerald-200/80 flex items-center justify-center p-1.5 shrink-0 shadow-xs">
                        <SundoTruckIcon size={30} />
                      </div>

                      <div>
                        <h3 className="text-xs font-extrabold text-slate-900 leading-snug font-['Outfit']">
                          {item.barangay}
                        </h3>
                        <p className="text-[11px] text-slate-600 font-semibold mt-0.5">
                          {item.timeWindow}
                        </p>
                        <p className="text-[10px] text-slate-400 font-medium">
                          {item.route}
                        </p>
                      </div>
                    </div>

                    {/* Clay Status Badge */}
                    <div>
                      {isToday && (
                        <span className="clay-badge text-[10px] font-extrabold px-3 py-1 bg-emerald-100 text-emerald-800 border border-emerald-200">
                          Today
                        </span>
                      )}
                      {isUpcoming && (
                        <span className="clay-amber-badge text-[10px] font-extrabold px-3 py-1">
                          Upcoming
                        </span>
                      )}
                      {!isToday && !isUpcoming && (
                        <span className="text-[10px] font-medium px-2.5 py-1 rounded-full bg-slate-100 text-slate-600 border border-slate-200">
                          {item.statusTag}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* VIEW 2: Calendar View (Screen 9) */}
        {currentView === 'calendar' && (
          <div className="space-y-4">
            {/* Month Navigator with Clay Card */}
            <div className="clay-card p-4">
              <div className="flex items-center justify-between mb-3 px-1">
                <button className="p-1 rounded-full hover:bg-slate-100 text-slate-400 hover:text-slate-700 cursor-pointer">
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <h2 className="text-sm font-black text-slate-900 tracking-tight font-['Outfit']">
                  November 2024
                </h2>
                <button className="p-1 rounded-full hover:bg-slate-100 text-slate-400 hover:text-slate-700 cursor-pointer">
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              {/* Days of week header */}
              <div className="grid grid-cols-7 text-center text-[10px] font-bold text-slate-400 mb-2">
                <span>Sun</span>
                <span>Mon</span>
                <span>Tue</span>
                <span>Wed</span>
                <span>Thu</span>
                <span>Fri</span>
                <span>Sat</span>
              </div>

              {/* Calendar Clay Numbers Grid */}
              <div className="grid grid-cols-7 gap-y-2 text-center text-xs">
                {calendarDays.map((d, index) => {
                  const isSelected = d.currentMonth && d.day === selectedDay;
                  const hasDot = d.currentMonth && d.hasCollection;

                  return (
                    <button
                      key={index}
                      onClick={() => d.currentMonth && setSelectedDay(d.day)}
                      disabled={!d.currentMonth}
                      className={`h-8 w-8 mx-auto rounded-full flex flex-col items-center justify-center relative transition-all cursor-pointer ${
                        isSelected
                          ? 'clay-button-primary text-white font-extrabold shadow-md scale-105'
                          : d.currentMonth
                          ? 'text-slate-800 hover:bg-slate-100 font-semibold'
                          : 'text-slate-300 pointer-events-none'
                      }`}
                    >
                      <span>{d.day}</span>
                      {hasDot && !isSelected && (
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 absolute bottom-0.5"></span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Collection Details Section (Claymorphic) */}
            <div>
              <h3 className="text-xs font-extrabold text-slate-900 font-['Outfit'] mb-2.5 uppercase tracking-wide">
                Collection Details
              </h3>

              <div className="clay-card-mint p-4.5 space-y-3.5">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-2xl bg-white text-emerald-700 flex items-center justify-center p-1.5 shrink-0 shadow-xs border border-emerald-200">
                    <SundoTruckIcon size={30} />
                  </div>
                  <div>
                    <h4 className="text-sm font-extrabold text-emerald-950 font-['Outfit']">
                      {selectedSchedule.barangay} - {selectedSchedule.route}
                    </h4>
                  </div>
                </div>

                <div className="flex items-center gap-2.5 text-slate-700 text-xs font-semibold">
                  <Clock className="w-4 h-4 text-emerald-700" />
                  <span>{selectedSchedule.timeWindow}</span>
                </div>

                <div className="flex items-center gap-2.5 text-slate-700 text-xs font-semibold">
                  <Trash2 className="w-4 h-4 text-emerald-700" />
                  <span>{selectedSchedule.wasteType}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom Nav */}
      <BottomNav
        activeTab="schedule"
        onTabChange={onNavigateTab}
        unreadAlertsCount={unreadCount}
      />
    </div>
  );
};
