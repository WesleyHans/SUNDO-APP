import React from 'react';

interface SundoLogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showSubtitle?: boolean;
  className?: string;
}

export const SundoTruckIcon: React.FC<{ size?: number; className?: string }> = ({ size = 64, className = '' }) => (
  <img
    src="/sundo-brand-logo.png"
    alt="SUNDO recycling truck with a leaf, location pin, and route"
    width={1499}
    height={1049}
    className={className}
    style={{ width: size, height: size * 1049 / 1499, objectFit: 'contain', flexShrink: 0 }}
  />
);

export const SundoLogo: React.FC<SundoLogoProps> = ({
  size = 'md',
  showSubtitle = true,
  className = '',
}) => {
  const iconSizes = { sm: 64, md: 100, lg: 144, xl: 180 };
  const titleSizes = {
    sm: 'text-xl tracking-tight',
    md: 'text-3xl tracking-tight',
    lg: 'text-4xl tracking-tight',
    xl: 'text-5xl tracking-tight',
  };
  const subtitleSizes = { sm: 'text-[9px]', md: 'text-[11px]', lg: 'text-[13px]', xl: 'text-sm' };

  return (
    <div className={`flex flex-col items-center text-center ${className}`}>
      <SundoTruckIcon size={iconSizes[size]} />
      <span className={`font-black text-emerald-800 mt-1 font-['Outfit'] uppercase ${titleSizes[size]}`}>
        SUNDO
      </span>
      {showSubtitle && (
        <div className={`text-slate-600 font-medium leading-tight mt-1 max-w-[220px] ${subtitleSizes[size]}`}>
          Smart Urban Navigation
          <div className="text-slate-500 font-normal">for Dynamic Waste Operations</div>
        </div>
      )}
    </div>
  );
};
