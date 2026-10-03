import React from 'react';
import { Wifi } from 'lucide-react';

interface StatusBarProps {
  dark?: boolean;
}

export const StatusBar: React.FC<StatusBarProps> = ({ dark = true }) => {
  const textColor = dark ? 'text-slate-900' : 'text-white';
  const fillColor = dark ? 'bg-slate-900' : 'bg-white';

  return (
    <div className={`w-full px-6 pt-3 pb-1 flex items-center justify-between text-xs font-semibold select-none z-30 ${textColor}`}>
      {/* Time */}
      <span className="tracking-tight text-[13px] font-semibold">9:41</span>

      {/* Status Icons: Cellular, Wifi, Battery */}
      <div className="flex items-center gap-1.5 ml-auto">
        {/* 4 Cellular signal bars */}
        <div className="flex items-end gap-0.5 h-3 mr-0.5">
          <span className={`w-0.75 h-1 rounded-xs ${fillColor}`}></span>
          <span className={`w-0.75 h-1.5 rounded-xs ${fillColor}`}></span>
          <span className={`w-0.75 h-2.2 rounded-xs ${fillColor}`}></span>
          <span className={`w-0.75 h-3 rounded-xs ${fillColor}`}></span>
        </div>

        {/* Wifi */}
        <Wifi className="w-3.5 h-3.5 stroke-[2.4]" />

        {/* Battery */}
        <div className="flex items-center">
          <div className={`w-5 h-2.5 rounded-[4px] border ${dark ? 'border-slate-800' : 'border-white'} p-0.5 flex items-center`}>
            <div className={`h-full w-3.5 rounded-xs ${fillColor}`}></div>
          </div>
          <div className={`w-0.5 h-1 rounded-r-xs ${fillColor}`}></div>
        </div>
      </div>
    </div>
  );
};
