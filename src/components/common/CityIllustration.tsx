import React from 'react';

export const CitySkylineGraphic: React.FC<{ className?: string }> = ({ className = '' }) => {
  return (
    <div className={`w-full overflow-hidden relative ${className}`}>
      <svg
        viewBox="0 0 400 130"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-auto"
        preserveAspectRatio="none"
      >
        {/* Sky gradient subtle */}
        <defs>
          <linearGradient id="skyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#E0F2FE" stopOpacity="0.4" />
            <stop offset="100%" stopColor="#DCFCE7" stopOpacity="0.6" />
          </linearGradient>
          <linearGradient id="hillGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#34D399" />
            <stop offset="100%" stopColor="#059669" />
          </linearGradient>
        </defs>

        {/* Distant Mountains / Hills (Sipalay's famous karst hills) */}
        <path
          d="M-20 100 Q 60 40 140 85 Q 220 50 300 80 Q 380 45 420 90 L420 130 L-20 130 Z"
          fill="#A7F3D0"
          opacity="0.5"
        />

        {/* City Buildings Skyline */}
        <g fill="#93C5FD" opacity="0.65">
          {/* Building 1 */}
          <rect x="30" y="45" width="28" height="70" rx="3" />
          <rect x="34" y="50" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />
          <rect x="46" y="50" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />
          <rect x="34" y="62" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />
          <rect x="46" y="62" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />
          <rect x="34" y="74" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />
          <rect x="46" y="74" width="6" height="7" rx="1" fill="#FFFFFF" opacity="0.8" />

          {/* Building 2 Tower */}
          <rect x="68" y="28" width="34" height="88" rx="4" fill="#60A5FA" opacity="0.6" />
          <rect x="74" y="34" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />
          <rect x="88" y="34" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />
          <rect x="74" y="48" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />
          <rect x="88" y="48" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />
          <rect x="74" y="62" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />
          <rect x="88" y="62" width="8" height="9" rx="1" fill="#FFFFFF" opacity="0.9" />

          {/* Building 3 */}
          <rect x="115" y="52" width="26" height="65" rx="2" />
          {/* Building 4 Mid */}
          <rect x="250" y="35" width="32" height="80" rx="3" fill="#60A5FA" opacity="0.55" />
          <rect x="290" y="48" width="28" height="68" rx="2" />
          <rect x="325" y="60" width="22" height="56" rx="2" />
          <rect x="355" y="40" width="30" height="76" rx="3" fill="#60A5FA" opacity="0.6" />
        </g>

        {/* Forefront Lush Green Hills and Bushes */}
        <path
          d="M-10 115 Q 40 90 90 108 Q 150 92 210 110 Q 280 88 340 105 Q 390 95 420 112 L420 130 L-10 130 Z"
          fill="url(#hillGrad)"
        />

        {/* Tree clusters */}
        <circle cx="20" cy="100" r="16" fill="#047857" />
        <circle cx="36" cy="98" r="14" fill="#10B981" />
        <circle cx="50" cy="104" r="11" fill="#059669" />

        <circle cx="170" cy="106" r="15" fill="#10B981" />
        <circle cx="188" cy="102" r="18" fill="#047857" />
        <circle cx="204" cy="108" r="13" fill="#34D399" />

        <circle cx="360" cy="100" r="17" fill="#047857" />
        <circle cx="380" cy="96" r="15" fill="#10B981" />
        <circle cx="395" cy="104" r="12" fill="#059669" />
      </svg>
    </div>
  );
};

export const WelcomeSceneGraphic: React.FC<{ className?: string }> = ({ className = '' }) => {
  return (
    <div className={`w-full relative rounded-2xl overflow-hidden shadow-xs border border-emerald-100/60 bg-gradient-to-b from-sky-50 via-emerald-50/40 to-emerald-100/50 ${className}`}>
      <svg
        viewBox="0 0 340 220"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-auto select-none"
      >
        {/* Soft Sun in sky */}
        <circle cx="280" cy="46" r="22" fill="#FEF08A" opacity="0.75" />
        <circle cx="280" cy="46" r="30" fill="#FEF9C3" opacity="0.35" />

        {/* Soft Clouds */}
        <g fill="#FFFFFF" opacity="0.8">
          <ellipse cx="60" cy="36" rx="28" ry="12" />
          <ellipse cx="76" cy="30" rx="18" ry="14" />
          <ellipse cx="46" cy="38" rx="14" ry="10" />

          <ellipse cx="200" cy="48" rx="22" ry="10" />
          <ellipse cx="212" cy="44" rx="14" ry="11" />
        </g>

        {/* City Buildings in background */}
        <g opacity="0.75">
          <rect x="25" y="60" width="36" height="95" rx="3" fill="#BAE6FD" />
          <rect x="30" y="68" width="8" height="10" rx="1" fill="#FFFFFF" />
          <rect x="45" y="68" width="8" height="10" rx="1" fill="#FFFFFF" />
          <rect x="30" y="86" width="8" height="10" rx="1" fill="#FFFFFF" />
          <rect x="45" y="86" width="8" height="10" rx="1" fill="#FFFFFF" />
          <rect x="30" y="104" width="8" height="10" rx="1" fill="#FFFFFF" />
          <rect x="45" y="104" width="8" height="10" rx="1" fill="#FFFFFF" />

          {/* Central Highrise */}
          <rect x="68" y="38" width="44" height="118" rx="4" fill="#93C5FD" />
          <rect x="75" y="46" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="94" y="46" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="75" y="66" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="94" y="66" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="75" y="86" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="94" y="86" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="75" y="106" width="10" height="12" rx="1" fill="#FFFFFF" />
          <rect x="94" y="106" width="10" height="12" rx="1" fill="#FFFFFF" />

          {/* Right Building */}
          <rect x="235" y="55" width="40" height="100" rx="3" fill="#7DD3FC" />
          <rect x="242" y="64" width="9" height="10" rx="1" fill="#FFFFFF" />
          <rect x="258" y="64" width="9" height="10" rx="1" fill="#FFFFFF" />
          <rect x="242" y="82" width="9" height="10" rx="1" fill="#FFFFFF" />
          <rect x="258" y="82" width="9" height="10" rx="1" fill="#FFFFFF" />
        </g>

        {/* Green Trees and street lamp */}
        <circle cx="126" cy="136" r="20" fill="#10B981" />
        <circle cx="140" cy="130" r="16" fill="#059669" />
        <circle cx="218" cy="138" r="18" fill="#10B981" />
        <circle cx="230" cy="132" r="15" fill="#047857" />

        {/* Street Lamp with Solar / Eco badge */}
        <line x1="285" y1="92" x2="285" y2="155" stroke="#475569" strokeWidth="2.5" />
        <path d="M285 92 Q295 90 298 98" stroke="#475569" strokeWidth="2" fill="none" />
        <circle cx="298" cy="100" r="3.5" fill="#FDE047" />

        {/* Clean Asphalt Road */}
        <rect x="0" y="152" width="340" height="52" fill="#334155" />
        {/* Road Curb */}
        <rect x="0" y="150" width="340" height="4" fill="#94A3B8" />
        {/* Road Markings (Dashed white line) */}
        <line x1="10" y1="178" x2="50" y2="178" stroke="#F8FAFC" strokeWidth="3" strokeDasharray="14 10" />
        <line x1="70" y1="178" x2="150" y2="178" stroke="#F8FAFC" strokeWidth="3" strokeDasharray="14 10" />
        <line x1="170" y1="178" x2="250" y2="178" stroke="#F8FAFC" strokeWidth="3" strokeDasharray="14 10" />
        <line x1="270" y1="178" x2="330" y2="178" stroke="#F8FAFC" strokeWidth="3" strokeDasharray="14 10" />

        {/* The Green SUNDO Garbage Truck driving right */}
        <g id="welcome-truck" transform="translate(68, 92) scale(0.95)">
          {/* Leaves sprouting */}
          <path d="M48 38C42 16 26 4 10 8C6 24 18 38 40 40Z" fill="#34D399" />
          <path d="M46 32C52 18 64 10 78 14C80 28 70 38 52 34Z" fill="#10B981" />

          {/* Truck Back Body */}
          <rect x="52" y="36" width="82" height="50" rx="9" fill="#10B981" />
          <rect x="56" y="40" width="74" height="42" rx="6" fill="#059669" />

          {/* Recycling Symbol on truck */}
          <g transform="translate(93, 61) scale(0.55)">
            <path d="M0 -15L3.5 -8H-3.5L0 -15Z" fill="#ECFDF5" />
            <path d="M0 -8C5 -8 9 -5 11 -1L8 0C7 -3 3.5 -5 0 -5V-8Z" fill="#ECFDF5" />
            <path d="M14 8L9 11L9 5L14 8Z" fill="#ECFDF5" />
            <path d="M9 8C6 12 2 14 -3 13L-2.5 10C1 11 4 9 6 6L9 8Z" fill="#ECFDF5" />
            <path d="M-14 6L-12 0L-7 5L-14 6Z" fill="#ECFDF5" />
            <path d="M-9 3C-11 -1 -11 -6 -7 -9L-5 -7.5C-7.5 -4.5 -7.5 -0.5 -6 2L-9 3Z" fill="#ECFDF5" />
          </g>

          {/* Truck Cab */}
          <path d="M22 52C22 46 26 42 32 42H52V86H22V52Z" fill="#10B981" />
          {/* Cab Window */}
          <path d="M27 47H47C48.5 47 49.5 48 49.5 49.5V66H25C25 63 25.5 54 27 47Z" fill="#E0F2FE" />
          <circle cx="23" cy="74" r="3" fill="#FDE047" />

          {/* Chassis */}
          <rect x="25" y="84" width="108" height="6" rx="2" fill="#1E293B" />

          {/* Wheels */}
          <circle cx="38" cy="91" r="12" fill="#1E293B" />
          <circle cx="38" cy="91" r="7" fill="#64748B" />
          <circle cx="38" cy="91" r="3" fill="#F8FAFC" />

          <circle cx="94" cy="91" r="12" fill="#1E293B" />
          <circle cx="94" cy="91" r="7" fill="#64748B" />
          <circle cx="94" cy="91" r="3" fill="#F8FAFC" />

          <circle cx="118" cy="91" r="12" fill="#1E293B" />
          <circle cx="118" cy="91" r="7" fill="#64748B" />
          <circle cx="118" cy="91" r="3" fill="#F8FAFC" />
        </g>

        {/* Grass Verge at very bottom */}
        <rect x="0" y="204" width="340" height="16" fill="#10B981" />
      </svg>
    </div>
  );
};
