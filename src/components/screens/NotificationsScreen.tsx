import React, { useState } from 'react';
import {
  ChevronLeft,
  Bell,
  Truck,
  AlertCircle,
  CheckCircle2,
  Megaphone,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { NotificationItem, BottomNavTab } from '../../types';

interface NotificationsScreenProps {
  notifications: NotificationItem[];
  onBack: () => void;
  onNavigateTab: (tab: BottomNavTab) => void;
  onNotificationClick?: (item: NotificationItem) => void;
}

export const NotificationsScreen: React.FC<NotificationsScreenProps> = ({
  notifications,
  onBack,
  onNavigateTab,
  onNotificationClick,
}) => {
  const [filter, setFilter] = useState<'All' | 'Alerts' | 'Announcements'>('All');

  const filtered = notifications.filter((n) => {
    if (filter === 'All') return true;
    return n.category === filter;
  });

  const getIcon = (type: NotificationItem['type']) => {
    switch (type) {
      case 'alert':
        return (
          <div className="w-10 h-10 rounded-full bg-rose-50 text-rose-500 flex items-center justify-center shrink-0">
            <Bell className="w-5 h-5 fill-rose-100 stroke-rose-500 stroke-[2]" />
          </div>
        );
      case 'update':
        return (
          <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
            <Truck className="w-5 h-5 stroke-[2]" />
          </div>
        );
      case 'route':
        return (
          <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-500 flex items-center justify-center shrink-0">
            <AlertCircle className="w-5 h-5 stroke-[2]" />
          </div>
        );
      case 'completed':
        return (
          <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
            <CheckCircle2 className="w-5 h-5 stroke-[2]" />
          </div>
        );
      case 'special':
      default:
        return (
          <div className="w-10 h-10 rounded-full bg-sky-50 text-sky-500 flex items-center justify-center shrink-0">
            <Megaphone className="w-5 h-5 stroke-[2]" />
          </div>
        );
    }
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 select-none overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-1 pb-3 bg-white border-b border-slate-100 shrink-0">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          <button
            onClick={onBack}
            className="p-1.5 -ml-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <h1 className="text-base font-bold text-slate-900 font-['Outfit']">
            Notifications
          </h1>

          <div className="w-5"></div>
        </div>

        {/* Filter Pills with Claymorphism */}
        <div className="mt-3 flex items-center gap-2">
          {(['All', 'Alerts', 'Announcements'] as const).map((tab) => {
            const isActive = filter === tab;
            return (
              <button
                key={tab}
                onClick={() => setFilter(tab)}
                className={`py-1.5 px-4 rounded-full text-xs font-bold transition-all cursor-pointer ${
                  isActive
                    ? 'clay-button-primary text-white shadow-xs'
                    : 'clay-button-secondary text-slate-600 hover:text-slate-900'
                }`}
              >
                {tab}
              </button>
            );
          })}
        </div>
      </div>

      {/* Notifications List with Clay Cards */}
      <div className="flex-1 overflow-y-auto px-5 py-3.5 space-y-2.5 no-scrollbar bg-[#F4F7F6]">
        {filtered.map((item) => (
          <div
            key={item.id}
            onClick={() => onNotificationClick && onNotificationClick(item)}
            className="p-3.5 clay-card flex items-start gap-3.5 hover:scale-[1.01] active:scale-[0.98] transition-all cursor-pointer"
          >
            {getIcon(item.type)}

            <div className="flex-1 min-w-0">
              <div className="flex items-baseline justify-between gap-2">
                <h3 className="text-xs font-extrabold text-slate-900 leading-tight font-['Outfit']">
                  {item.title}
                </h3>
              </div>
              <p className="text-[11px] text-slate-600 mt-1 leading-snug line-clamp-2 font-medium">
                {item.message}
              </p>
              <span className="text-[10px] text-slate-400 font-bold block mt-1.5">
                {item.time}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom Nav */}
      <BottomNav
        activeTab="alerts"
        onTabChange={onNavigateTab}
        unreadAlertsCount={0}
      />
    </div>
  );
};
