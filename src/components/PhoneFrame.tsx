import React from 'react';

interface PhoneFrameProps {
  children: React.ReactNode;
  title?: string;
  screenNumber?: number;
  interactive?: boolean;
  className?: string;
}

export const PhoneFrame: React.FC<PhoneFrameProps> = ({
  children,
  title,
  screenNumber,
  interactive = true,
  className = '',
}) => {
  return (
    <div className={`flex flex-col items-center ${className}`}>
      {/* Phone Hardware Mockup */}
      <div className="relative w-[360px] h-[740px] max-w-full bg-slate-900 rounded-[44px] p-2.5 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.35)] ring-1 ring-slate-800/80 ring-offset-2 ring-offset-slate-100 select-none">
        {/* Exterior button accents */}
        <div className="absolute -left-1 top-24 w-1 h-7 bg-slate-700 rounded-l-xs"></div>
        <div className="absolute -left-1 top-36 w-1 h-12 bg-slate-700 rounded-l-xs"></div>
        <div className="absolute -left-1 top-52 w-1 h-12 bg-slate-700 rounded-l-xs"></div>
        <div className="absolute -right-1 top-32 w-1 h-16 bg-slate-700 rounded-r-xs"></div>

        {/* Screen Bezel & Display Area */}
        <div className="relative w-full h-full bg-white rounded-[36px] overflow-hidden flex flex-col border border-slate-200 shadow-inner">
          {/* iOS Dynamic Island (Pixel-perfect hardware camera pill) */}
          <div className="absolute top-2 left-1/2 -translate-x-1/2 w-22 h-4.5 bg-black rounded-full z-40 flex items-center justify-between px-2 pointer-events-none shadow-xs">
            <div className="w-2 h-2 rounded-full bg-slate-900 border border-slate-800/80 shadow-inner"></div>
            <div className="w-1.5 h-1.5 rounded-full bg-emerald-950"></div>
          </div>

          {/* Child Screen Content */}
          <div className="relative w-full h-full flex-col flex overflow-hidden">
            {children}
          </div>

          {/* iOS Home Indicator Bar */}
          <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-28 h-1 bg-slate-900/60 rounded-full z-30 pointer-events-none"></div>
        </div>
      </div>

      {/* Screen Title & Number Tag underneath for 100% replica fidelity */}
      {title && (
        <div className="mt-4 text-center">
          <p className="text-xs font-bold text-slate-800 tracking-tight">
            {screenNumber ? `${screenNumber}. ` : ''}{title}
          </p>
        </div>
      )}
    </div>
  );
};
