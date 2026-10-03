import React, { useState } from 'react';
import {
  ChevronLeft,
  Settings,
  MapPin,
  Bookmark,
  Bell,
  Navigation,
  HelpCircle,
  Info,
  LogOut,
  ChevronRight,
  Check,
  Download,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { UserProfile, BottomNavTab } from '../../types';

interface ProfileScreenProps {
  user: UserProfile;
  onBack: () => void;
  onNavigateTab: (tab: BottomNavTab) => void;
  onLogout: () => void;
  onUpdateUser?: (updated: Partial<UserProfile>) => void;
  onOpenDownloadApk?: () => void;
}

export const ProfileScreen: React.FC<ProfileScreenProps> = ({
  user,
  onBack,
  onNavigateTab,
  onLogout,
  onUpdateUser,
  onOpenDownloadApk,
}) => {
  const [locationAllowed, setLocationAllowed] = useState(user.locationPermission);
  const [notificationModalOpen, setNotificationModalOpen] = useState(false);
  const [aboutModalOpen, setAboutModalOpen] = useState(false);

  const toggleLocation = () => {
    const next = !locationAllowed;
    setLocationAllowed(next);
    if (onUpdateUser) onUpdateUser({ locationPermission: next });
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 select-none overflow-hidden">
      {/* Top Header */}
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
            Profile
          </h1>

          <button
            onClick={() => setAboutModalOpen(true)}
            className="p-1.5 -mr-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer"
            aria-label="Settings"
          >
            <Settings className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Main Profile Content */}
      <div className="flex-1 overflow-y-auto px-5 py-4 no-scrollbar space-y-4 bg-[#F4F7F6]">
        {/* User Card with Claymorphic Mint */}
        <div className="clay-card-mint flex items-center gap-3.5 p-4">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 text-white flex items-center justify-center font-bold text-lg shrink-0 shadow-md border-2 border-white">
            {user.name.split(' ').map((n) => n[0]).join('')}
          </div>

          <div className="min-w-0 flex-1">
            <h2 className="text-sm font-extrabold text-slate-900 truncate font-['Outfit']">
              {user.name}
            </h2>
            <p className="text-xs text-slate-500 truncate font-medium">{user.email}</p>
            <p className="text-xs text-emerald-800 font-mono mt-0.5 font-bold">{user.phone}</p>
          </div>
        </div>

        {/* Menu Items List inside Clay Card */}
        <div className="clay-card p-2 divide-y divide-slate-100">
          {/* Address */}
          <div className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors">
            <div className="flex items-center gap-3 min-w-0">
              <span className="text-emerald-700">
                <MapPin className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">Address</span>
            </div>
            <div className="flex items-center gap-1.5 text-right min-w-0">
              <span className="text-xs text-slate-500 truncate max-w-[130px] font-medium">
                {user.address}
              </span>
              <ChevronRight className="w-4 h-4 text-slate-400 shrink-0" />
            </div>
          </div>

          {/* Saved Addresses */}
          <div className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors">
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <Bookmark className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">Saved Addresses</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>

          {/* Notification Settings */}
          <div
            onClick={() => setNotificationModalOpen(true)}
            className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors"
          >
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <Bell className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">Notification Settings</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>

          {/* Location Permission */}
          <div
            onClick={toggleLocation}
            className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors"
          >
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <Navigation className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">Location Permission</span>
            </div>
            <div className="flex items-center gap-1">
              <span className={`text-xs font-extrabold ${locationAllowed ? 'text-emerald-600' : 'text-slate-400'}`}>
                {locationAllowed ? 'Allowed' : 'Disabled'}
              </span>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>
          </div>

          {/* Help & Support */}
          <div
            onClick={() => alert('Sipalay City Environment and Natural Resources Office (CENRO)\nHotline: (034) 473-2100\nEmail: cenro@sipalaycity.gov.ph')}
            className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors"
          >
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <HelpCircle className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">Help & Support</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>

          {/* Download APK / Install */}
          <div
            onClick={onOpenDownloadApk}
            className="p-3 flex items-center justify-between cursor-pointer hover:bg-emerald-50/50 rounded-xl transition-colors bg-emerald-50/30 border border-emerald-100/50"
          >
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <Download className="w-4 h-4 stroke-[2.2]" />
              </span>
              <div>
                <span className="text-xs font-extrabold text-slate-900 block leading-tight">Install / Download APK</span>
                <span className="text-[10px] text-emerald-700 font-medium">Standalone Android mobile app</span>
              </div>
            </div>
            <span className="px-2 py-0.5 rounded-full text-[9px] font-extrabold bg-emerald-100 text-emerald-800">
              Android
            </span>
          </div>

          {/* About SUNDO */}
          <div
            onClick={() => setAboutModalOpen(true)}
            className="p-3 flex items-center justify-between cursor-pointer hover:bg-slate-50 rounded-xl transition-colors"
          >
            <div className="flex items-center gap-3">
              <span className="text-emerald-700">
                <Info className="w-4 h-4 stroke-[2.2]" />
              </span>
              <span className="text-xs font-bold text-slate-800">About SUNDO</span>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>
        </div>

        {/* Logout Button */}
        <div className="pt-2 pb-2 flex justify-center">
          <button
            onClick={onLogout}
            className="flex items-center gap-2 text-rose-600 hover:text-rose-700 font-bold text-xs py-2.5 px-6 clay-button-secondary cursor-pointer"
          >
            <LogOut className="w-4 h-4 text-rose-600 stroke-[2.2]" />
            <span>Logout</span>
          </button>
        </div>
      </div>

      {/* About Modal */}
      {aboutModalOpen && (
        <div className="absolute inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-6 z-30">
          <div className="bg-white rounded-2xl p-5 w-full max-w-[280px] text-center shadow-xl">
            <h3 className="text-sm font-bold text-slate-900 font-['Outfit']">About SUNDO</h3>
            <p className="text-xs text-slate-600 mt-2 leading-relaxed">
              SUNDO (Smart Urban Navigation for Dynamic Waste Operations) is the official solid waste tracking platform for Sipalay City, Negros Occidental.
            </p>
            <p className="text-[10px] text-slate-400 mt-2">Version 1.0.0 (Official Release)</p>
            <button
              onClick={() => setAboutModalOpen(false)}
              className="mt-4 w-full py-2 bg-emerald-600 text-white rounded-xl text-xs font-semibold"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Notification Settings Modal */}
      {notificationModalOpen && (
        <div className="absolute inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-6 z-30">
          <div className="bg-white rounded-2xl p-5 w-full max-w-[280px] shadow-xl space-y-3">
            <h3 className="text-sm font-bold text-slate-900 font-['Outfit']">Notification Alerts</h3>
            <div className="space-y-2 text-xs">
              <label className="flex items-center justify-between">
                <span>Truck Approaching (10m)</span>
                <input type="checkbox" defaultChecked className="accent-emerald-600" />
              </label>
              <label className="flex items-center justify-between">
                <span>Route Rescheduling</span>
                <input type="checkbox" defaultChecked className="accent-emerald-600" />
              </label>
              <label className="flex items-center justify-between">
                <span>Weekly Schedule Reminder</span>
                <input type="checkbox" defaultChecked className="accent-emerald-600" />
              </label>
            </div>
            <button
              onClick={() => setNotificationModalOpen(false)}
              className="mt-2 w-full py-2 bg-emerald-600 text-white rounded-xl text-xs font-semibold"
            >
              Save Preferences
            </button>
          </div>
        </div>
      )}

      {/* Bottom Nav */}
      <BottomNav
        activeTab="profile"
        onTabChange={onNavigateTab}
        unreadAlertsCount={2}
      />
    </div>
  );
};
