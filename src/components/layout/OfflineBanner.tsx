import React from 'react';
import { WifiOff, RefreshCw } from 'lucide-react';

interface OfflineBannerProps {
  isOffline: boolean;
  onSync?: () => void;
  pendingSyncCount?: number;
}

export const OfflineBanner: React.FC<OfflineBannerProps> = ({
  isOffline,
  onSync,
  pendingSyncCount = 0,
}) => {
  if (!isOffline && pendingSyncCount === 0) return null;

  return (
    <div
      className={`w-full py-1.5 px-4 text-xs font-semibold flex items-center justify-between z-40 transition-all ${
        isOffline
          ? 'bg-amber-500 text-white'
          : 'bg-emerald-600 text-white'
      }`}
    >
      <div className="flex items-center gap-2">
        <WifiOff className="w-3.5 h-3.5" />
        <span>
          {isOffline
            ? 'You are offline. Reports will sync automatically once reconnected.'
            : `${pendingSyncCount} offline report ready to sync.`}
        </span>
      </div>

      {onSync && (
        <button
          onClick={onSync}
          className="flex items-center gap-1 text-[11px] underline font-bold cursor-pointer"
        >
          <RefreshCw className="w-3 h-3" />
          <span>Sync Now</span>
        </button>
      )}
    </div>
  );
};
