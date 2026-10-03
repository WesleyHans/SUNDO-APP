import React from 'react';

interface SundoLogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showSubtitle?: boolean;
  className?: string;
}

export const SundoTruckIcon: React.FC<{ size?: number; className?: string }> = ({ size = 64, className = '' }) => {
  return (
    <div className={`relative inline-flex items-center justify-center ${className}`} style={{ width: size, height: size * 0.85 }}>
      <svg
        viewBox="0 0 160 135"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-sm"
      >
        {/* Sprouting Eco Leaves above cab */}
        <g id="sprouting-leaves">
          {/* Main Leaf */}
          <path
            d="M52 48C46 22 28 8 10 12C6 30 20 46 44 48C46.8 48.2 49.5 48.2 52 48Z"
            fill="#34D399"
          />
          <path
            d="M52 48C36 34 26 22 10 12"
            stroke="#059669"
            strokeWidth="3"
            strokeLinecap="round"
          />
          {/* Second Leaf */}
          <path
            d="M50 42C56 24 72 15 88 20C90 38 78 52 56 46C53.8 45.4 51.8 43.8 50 42Z"
            fill="#10B981"
          />
          <path
            d="M50 42C64 33 76 26 88 20"
            stroke="#047857"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
        </g>

        {/* Truck Body (Back Container) */}
        <rect x="58" y="44" width="86" height="54" rx="10" fill="#10B981" />
        <rect x="62" y="48" width="78" height="46" rx="7" fill="#059669" />

        {/* Truck Cab (Front) */}
        <path
          d="M26 62C26 55.3726 31.3726 50 38 50H58V98H26V62Z"
          fill="#10B981"
        />
        {/* Cab Windshield */}
        <path
          d="M32 56H52C53.6569 56 55 57.3431 55 59V76H30C30 73 30.5 63 32 56Z"
          fill="#E0F2FE"
        />
        {/* Windshield Shine */}
        <path
          d="M36 58L33 73"
          stroke="#BAE6FD"
          strokeWidth="2"
          strokeLinecap="round"
        />

        {/* Headlight */}
        <circle cx="26" cy="84" r="3.5" fill="#FDE047" />

        {/* Side Bumper & Grille */}
        <rect x="22" y="88" width="8" height="8" rx="2" fill="#334155" />
        <rect x="56" y="50" width="4" height="48" fill="#047857" />

        {/* Recycling Emblem inside Container */}
        <g transform="translate(101, 71) scale(0.68)">
          <path
            d="M0 -18L4 -10H-4L0 -18Z"
            fill="#ECFDF5"
          />
          <path
            d="M0 -10C6 -10 11 -6 13 -1L10 0.5C8.5 -3.5 4.5 -6.5 0 -6.5V-10Z"
            fill="#ECFDF5"
          />
          <path
            d="M16 10L10 14L10 6L16 10Z"
            fill="#ECFDF5"
          />
          <path
            d="M10 10C7 15 2 18 -4 17L-3.5 13.5C0.5 14.5 4.5 12 6.5 8L10 10Z"
            fill="#ECFDF5"
          />
          <path
            d="M-16 8L-14 0L-8 6L-16 8Z"
            fill="#ECFDF5"
          />
          <path
            d="M-11 4C-13 -1 -13 -7 -9 -11L-6.5 -9C-9.5 -5.5 -9.5 -0.5 -7.5 3L-11 4Z"
            fill="#ECFDF5"
          />
        </g>

        {/* Chassis Under-rail */}
        <rect x="30" y="96" width="112" height="7" rx="3" fill="#1E293B" />

        {/* Front Wheel */}
        <circle cx="44" cy="103" r="14" fill="#1E293B" />
        <circle cx="44" cy="103" r="8" fill="#64748B" />
        <circle cx="44" cy="103" r="3.5" fill="#F8FAFC" />

        {/* Back Wheels (Double) */}
        <circle cx="104" cy="103" r="14" fill="#1E293B" />
        <circle cx="104" cy="103" r="8" fill="#64748B" />
        <circle cx="104" cy="103" r="3.5" fill="#F8FAFC" />

        <circle cx="132" cy="103" r="14" fill="#1E293B" />
        <circle cx="132" cy="103" r="8" fill="#64748B" />
        <circle cx="132" cy="103" r="3.5" fill="#F8FAFC" />
      </svg>
    </div>
  );
};

export const SundoLogo: React.FC<SundoLogoProps> = ({
  size = 'md',
  showSubtitle = true,
  className = '',
}) => {
  const iconSizes = {
    sm: 52,
    md: 84,
    lg: 110,
    xl: 140,
  };

  const titleSizes = {
    sm: 'text-xl tracking-tight',
    md: 'text-3xl tracking-tight',
    lg: 'text-4xl tracking-tight',
    xl: 'text-5xl tracking-tight',
  };

  const subtitleSizes = {
    sm: 'text-[9px]',
    md: 'text-[11px]',
    lg: 'text-[13px]',
    xl: 'text-sm',
  };

  return (
    <div className={`flex flex-col items-center text-center ${className}`}>
      <SundoTruckIcon size={iconSizes[size]} />
      
      <h1 className={`font-black text-emerald-800 tracking-tight mt-1 font-['Outfit'] uppercase ${titleSizes[size]}`}>
        SUNDO
      </h1>

      {showSubtitle && (
        <div className={`text-slate-600 font-medium leading-tight mt-1 max-w-[220px] ${subtitleSizes[size]}`}>
          Smart Urban Navigation
          <div className="text-slate-500 font-normal">for Dynamic Waste Operations</div>
        </div>
      )}
    </div>
  );
};
