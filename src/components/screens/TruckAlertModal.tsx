import React from 'react';
import { Bell, Clock, ArrowRight } from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { SundoTruckIcon } from '../common/SundoLogo';

interface TruckAlertModalProps {
  etaMinutes?: number;
  onViewTruck: () => void;
  onDismiss: () => void;
  isStandalone?: boolean; // When viewed as standalone Screen 7 in preview
}

export const TruckAlertModal: React.FC<TruckAlertModalProps> = ({
  etaMinutes = 10,
  onViewTruck,
  onDismiss,
  isStandalone = false,
}) => {
  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-slate-900/60 backdrop-blur-sm text-slate-800 select-none overflow-hidden">
      {/* Background simulated map view when in standalone mode */}
      {isStandalone && (
        <div className="absolute inset-0 -z-10 bg-emerald-50/70 overflow-hidden filter blur-[2px] opacity-70">
          <svg viewBox="0 0 360 480" className="w-full h-full object-cover">
            <path d="M0 0 L120 0 Q70 120 100 240 Q130 360 60 480 L0 480 Z" fill="#BAE6FD" />
            <path d="M70 280 Q180 190 280 90" stroke="#059669" strokeWidth="8" fill="none" />
            <circle cx="240" cy="140" r="14" fill="#3B82F6" />
          </svg>
        </div>
      )}

      <StatusBar dark={!isStandalone} />

      {/* Center Claymorphic Alert Card */}
      <div className="flex-1 flex items-center justify-center px-6 py-4">
        <div className="w-full max-w-[320px] clay-card p-6 flex flex-col items-center text-center animate-in zoom-in-95 duration-200">
          {/* Top Amber Bell Badge with Clay styling and floating animation */}
          <div className="w-18 h-18 rounded-full bg-gradient-to-tr from-amber-400 to-amber-200 border-4 border-white flex items-center justify-center text-amber-900 shadow-lg mb-3 animate-float">
            <Bell className="w-9 h-9 fill-amber-300 stroke-amber-800 stroke-[2]" />
          </div>

          {/* Truck Illustration */}
          <div className="my-2 hover:scale-105 transition-transform">
            <SundoTruckIcon size={95} />
          </div>

          {/* Alert Title */}
          <h2 className="text-xl font-black text-slate-900 tracking-tight mt-1 font-['Outfit']">
            SUNDO Alert
          </h2>

          {/* Subtitle */}
          <p className="text-xs text-slate-600 mt-1 max-w-[220px] leading-relaxed font-medium">
            Garbage truck is approaching your area.
          </p>

          {/* Amber Clay ETA Box */}
          <div className="w-full mt-4 py-3 px-4 clay-amber-badge flex items-center justify-center gap-2 border border-amber-300/80">
            <Clock className="w-4 h-4 text-amber-700 stroke-[2.4]" />
            <span className="text-xs font-bold text-amber-900">
              Estimated arrival: <span className="font-extrabold text-amber-950">{etaMinutes} minutes</span>
            </span>
          </div>

          {/* Primary Clay Button */}
          <button
            onClick={onViewTruck}
            className="w-full mt-5 py-4 px-6 clay-button-primary text-white font-bold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-md"
          >
            <span>View Truck</span>
            <ArrowRight className="w-4 h-4" />
          </button>

          {/* Dismiss Button */}
          <button
            onClick={onDismiss}
            className="mt-3 text-xs text-slate-500 hover:text-slate-800 font-bold cursor-pointer transition-colors py-1 px-3 rounded-full hover:bg-slate-100"
          >
            Dismiss
          </button>
        </div>
      </div>

      <div className="pb-4"></div>
    </div>
  );
};
