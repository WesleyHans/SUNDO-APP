import React, { useState } from 'react';
import { Smartphone, Download, X, CheckCircle2, ChevronRight, Info, Sparkles } from 'lucide-react';
import { usePWAInstall } from '../../hooks/usePWAInstall';
import { SundoTruckIcon } from './SundoLogo';

interface MobileInstallBannerProps {
  onOpenApkPortal?: () => void;
}

export const MobileInstallBanner: React.FC<MobileInstallBannerProps> = ({
  onOpenApkPortal,
}) => {
  const { isInstalled, isInstallable, install, isIOS, isAndroid } = usePWAInstall();
  const [dismissed, setDismissed] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  // If already running as an installed standalone app, do not show banner
  if (isInstalled || dismissed) return null;

  const handleInstallClick = async () => {
    if (isInstallable) {
      const success = await install();
      if (!success) {
        setShowGuide(true);
      }
    } else {
      setShowGuide(true);
    }
  };

  return (
    <>
      {/* Floating Bottom Install Notification on Mobile */}
      <div className="fixed bottom-20 left-3 right-3 z-40 md:hidden animate-in slide-in-from-bottom duration-300">
        <div className="bg-slate-900/95 backdrop-blur-md border border-emerald-500/40 rounded-2xl p-3.5 shadow-2xl text-white">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center shrink-0 shadow-md">
              <SundoTruckIcon size={24} className="text-white" />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <h4 className="text-xs font-black tracking-tight text-white font-['Outfit']">
                  Install SUNDO on Your Phone
                </h4>
                <span className="text-[9px] font-bold px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400">
                  Real App
                </span>
              </div>
              <p className="text-[11px] text-slate-300 leading-tight mt-0.5">
                Run full-screen from your home screen with real-time GPS truck alerts.
              </p>

              <div className="flex items-center gap-2 mt-2.5">
                <button
                  onClick={handleInstallClick}
                  className="px-3.5 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 text-white text-xs font-black flex items-center gap-1.5 shadow-md active:scale-95 cursor-pointer"
                >
                  <Smartphone className="w-3.5 h-3.5" />
                  <span>Install App Now</span>
                </button>

                <button
                  onClick={() => setShowGuide(true)}
                  className="px-2.5 py-1.5 rounded-xl bg-slate-800 text-slate-300 text-xs font-bold hover:text-white cursor-pointer"
                >
                  How to Install?
                </button>
              </div>
            </div>

            <button
              onClick={() => setDismissed(true)}
              className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-800 cursor-pointer shrink-0"
              title="Dismiss"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Guide Modal if user taps How to Install or auto-prompt didn't trigger */}
      {showGuide && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-end sm:items-center justify-center p-3">
          <div className="bg-slate-900 border border-slate-700 rounded-3xl w-full max-w-sm p-5 text-white shadow-2xl animate-in slide-in-from-bottom duration-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-emerald-600 flex items-center justify-center">
                  <SundoTruckIcon size={20} className="text-white" />
                </div>
                <div>
                  <h3 className="text-sm font-black font-['Outfit']">How to Run as Real App</h3>
                  <p className="text-[10px] text-slate-400">Works on all Android & iPhone devices</p>
                </div>
              </div>
              <button
                onClick={() => setShowGuide(false)}
                className="p-1.5 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="py-4 space-y-3 text-xs text-slate-300">
              <div className="p-3 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl">
                <p className="font-bold text-emerald-400 text-xs mb-1">
                  1-Tap Android Installation (Google Chrome):
                </p>
                <ol className="list-decimal list-inside space-y-1.5 text-slate-300 pl-1 text-[11px]">
                  <li>
                    Tap the <strong>three dots (⋮)</strong> in the top right of Chrome.
                  </li>
                  <li>
                    Tap <strong>&quot;Install app&quot;</strong> or <strong>&quot;Add to Home screen&quot;</strong>.
                  </li>
                  <li>
                    Tap <strong>&quot;Install&quot;</strong>. Android creates the official SUNDO app icon on your home screen!
                  </li>
                </ol>
              </div>

              {isInstallable && (
                <button
                  onClick={async () => {
                    await install();
                    setShowGuide(false);
                  }}
                  className="w-full py-3 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 text-slate-950 font-black text-xs flex items-center justify-center gap-2 shadow-lg active:scale-95 cursor-pointer"
                >
                  <Smartphone className="w-4 h-4" />
                  <span>Trigger Android System Install Prompt</span>
                </button>
              )}

              <div className="pt-1 flex items-center justify-between text-[11px] text-slate-400">
                <span>Want the raw APK download file?</span>
                <a
                  href="/sundo-release.apk"
                  download="SUNDO-v1.0.0-release.apk"
                  className="text-emerald-400 font-bold hover:underline"
                >
                  Download .apk (8.4MB)
                </a>
              </div>
            </div>

            <button
              onClick={() => setShowGuide(false)}
              className="w-full py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs"
            >
              Continue in Browser
            </button>
          </div>
        </div>
      )}
    </>
  );
};
