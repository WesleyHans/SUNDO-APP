import React from 'react';
import { SundoLogo } from '../common/SundoLogo';
import { CitySkylineGraphic } from '../common/CityIllustration';
import { StatusBar } from '../common/StatusBar';

interface SplashScreenProps {
  onContinue?: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onContinue }) => {
  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-gradient-to-b from-emerald-50/60 via-white to-emerald-50/40 select-none overflow-hidden text-slate-800">
      <StatusBar dark={true} />

      {/* Decorative top leaf pattern */}
      <div className="absolute top-2 right-4 w-28 h-28 pointer-events-none opacity-20">
        <svg viewBox="0 0 100 100" fill="none">
          <path
            d="M80 10C50 10 30 35 25 65C45 68 70 55 80 10Z"
            fill="#10B981"
          />
          <path
            d="M80 10C55 35 40 50 25 65"
            stroke="#059669"
            strokeWidth="3"
            strokeLinecap="round"
          />
        </svg>
      </div>

      <div className="absolute top-12 -left-6 w-20 h-20 pointer-events-none opacity-15">
        <svg viewBox="0 0 100 100" fill="none">
          <path
            d="M20 10C50 10 70 35 75 65C55 68 30 55 20 10Z"
            fill="#34D399"
          />
        </svg>
      </div>

      {/* Main Center Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 -mt-6">
        <SundoLogo size="xl" showSubtitle={true} />
      </div>

      {/* Bottom Area */}
      <div className="w-full flex flex-col items-center z-10">
        {/* Slogan */}
        <div className="mb-4 text-center">
          <h2 className="text-base font-bold tracking-wide text-slate-800 font-['Outfit']">
            Track. Prepare. Collect.
          </h2>

          {/* 3 Pagination dots */}
          <div className="flex items-center justify-center gap-1.5 mt-3">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-600 transition-all"></span>
            <span className="w-2 h-2 rounded-full bg-slate-300"></span>
            <span className="w-2 h-2 rounded-full bg-slate-300"></span>
          </div>
        </div>

        {/* City Skyline & Hills Silhouette at bottom */}
        <div className="w-full">
          <CitySkylineGraphic />
        </div>
      </div>

      {/* Interactive tap anywhere overlay if interactive */}
      {onContinue && (
        <button
          onClick={onContinue}
          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          aria-label="Continue to Welcome Screen"
        />
      )}
    </div>
  );
};
