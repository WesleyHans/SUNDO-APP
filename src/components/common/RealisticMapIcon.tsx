import React from 'react';

interface RealisticMapIconProps {
  className?: string;
  size?: number;
  isActive?: boolean;
}

export const RealisticMapIcon: React.FC<RealisticMapIconProps> = ({
  className = '',
  size = 24,
  isActive = false,
}) => {
  return (
    <div
      className={`relative inline-flex items-center justify-center transition-transform duration-200 ${
        isActive ? 'scale-110 -translate-y-0.5' : 'hover:scale-105'
      } ${className}`}
      style={{ width: size, height: size }}
    >
      <svg
        viewBox="0 0 48 48"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-sm overflow-visible"
      >
        <defs>
          {/* Folds Gradients for Realistic 3D Paper Depth */}
          <linearGradient id="mapFoldLeft" x1="6" y1="12" x2="18" y2="40" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#E2E8F0" />
            <stop offset="60%" stopColor="#CBD5E1" />
            <stop offset="100%" stopColor="#94A3B8" />
          </linearGradient>

          <linearGradient id="mapFoldCenter" x1="18" y1="8" x2="30" y2="36" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#F1F5F9" />
            <stop offset="50%" stopColor="#E2E8F0" />
            <stop offset="100%" stopColor="#CBD5E1" />
          </linearGradient>

          <linearGradient id="mapFoldRight" x1="30" y1="12" x2="42" y2="40" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#E2E8F0" />
            <stop offset="70%" stopColor="#CBD5E1" />
            <stop offset="100%" stopColor="#94A3B8" />
          </linearGradient>

          {/* Grass & River Patterns on Map */}
          <linearGradient id="mapRiver" x1="8" y1="18" x2="38" y2="34" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#60A5FA" />
            <stop offset="100%" stopColor="#3B82F6" />
          </linearGradient>

          {/* 3D Glossy Pin Gradient */}
          <linearGradient id="pinGloss" x1="28" y1="5" x2="36" y2="24" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#F87171" />
            <stop offset="40%" stopColor="#EF4444" />
            <stop offset="100%" stopColor="#B91C1C" />
          </linearGradient>

          <linearGradient id="pinEmeraldGloss" x1="28" y1="5" x2="36" y2="24" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#34D399" />
            <stop offset="40%" stopColor="#10B981" />
            <stop offset="100%" stopColor="#047857" />
          </linearGradient>

          {/* Soft Ground Shadow Filter */}
          <filter id="pinShadow" x="22" y="21" width="16" height="10" filterUnits="userSpaceOnUse">
            <feDropShadow dx="0" dy="2" stdDeviation="1.5" floodColor="#0F172A" floodOpacity="0.35" />
          </filter>
        </defs>

        {/* --- MAP FOLD 1: Left Panel --- */}
        <path
          d="M6 13.5L18 9V35.5L6 40V13.5Z"
          fill="url(#mapFoldLeft)"
        />
        {/* Left Panel Land & Terrain Accent */}
        <path
          d="M6 18C9 17 12 18 18 15V24C13 26 9 24 6 25V18Z"
          fill="#BBF7D0"
          fillOpacity="0.75"
        />

        {/* --- MAP FOLD 2: Center Panel --- */}
        <path
          d="M18 9L30 13.5V40L18 35.5V9Z"
          fill="url(#mapFoldCenter)"
        />
        {/* Center Panel Water / Road Ribbon */}
        <path
          d="M18 21C22 23 26 21 30 24V28C25 25 21 27 18 25V21Z"
          fill="url(#mapRiver)"
          fillOpacity="0.7"
        />

        {/* --- MAP FOLD 3: Right Panel --- */}
        <path
          d="M30 13.5L42 9V35.5L30 40V13.5Z"
          fill="url(#mapFoldRight)"
        />
        {/* Right Panel Land Patch */}
        <path
          d="M30 27C34 25 38 27 42 24V32C38 34 34 32 30 33V27Z"
          fill="#BBF7D0"
          fillOpacity="0.75"
        />

        {/* Contour & Fold Crease Lines */}
        <line x1="18" y1="9" x2="18" y2="35.5" stroke="#94A3B8" strokeWidth="1" strokeLinecap="round" />
        <line x1="30" y1="13.5" x2="30" y2="40" stroke="#94A3B8" strokeWidth="1" strokeLinecap="round" />

        {/* GPS Routing Track Line (winding through all folds) */}
        <path
          d="M10 32C14 26 16 30 22 24C26 19 28 22 32 18"
          stroke={isActive ? '#059669' : '#10B981'}
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeDasharray="0.5 3.5"
        />
        <path
          d="M10 32C14 26 16 30 22 24C26 19 28 22 32 18"
          stroke={isActive ? '#10B981' : '#34D399'}
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Pin Cast Shadow on Map Surface */}
        <ellipse
          cx="32"
          cy="25.5"
          rx="4"
          ry="2"
          fill="#1E293B"
          fillOpacity="0.4"
        />

        {/* 3D Realistic Glossy Map Pin */}
        <g className="transition-transform duration-300">
          {/* Main Pin Teardrop Body */}
          <path
            d="M32 9C28.6863 9 26 11.6863 26 15C26 19.5 32 25 32 25C32 25 38 19.5 38 15C38 11.6863 35.3137 9 32 9Z"
            fill={isActive ? 'url(#pinEmeraldGloss)' : 'url(#pinGloss)'}
            stroke="#FFFFFF"
            strokeWidth="1.2"
          />

          {/* Inner Pin White Dot */}
          <circle cx="32" cy="14.5" r="2.4" fill="#FFFFFF" />

          {/* Glossy Specular Reflection Bubble */}
          <ellipse
            cx="29.8"
            cy="12.2"
            rx="1.4"
            ry="0.8"
            transform="rotate(-30 29.8 12.2)"
            fill="#FFFFFF"
            fillOpacity="0.75"
          />
        </g>
      </svg>
    </div>
  );
};
