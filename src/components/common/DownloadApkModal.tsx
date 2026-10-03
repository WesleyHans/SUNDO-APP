import React, { useState } from 'react';
import {
  X,
  Download,
  Smartphone,
  ExternalLink,
  CheckCircle2,
  Copy,
  Check,
  ShieldCheck,
  Sparkles,
  Info,
  Terminal,
} from 'lucide-react';
import { usePWAInstall } from '../../hooks/usePWAInstall';
import { generateAndDownloadApk } from '../../utils/apkGenerator';

interface DownloadApkModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenFlutterCode?: () => void;
}

export const DownloadApkModal: React.FC<DownloadApkModalProps> = ({
  isOpen,
  onClose,
  onOpenFlutterCode,
}) => {
  const { isInstallable, isInstalled, install, isIOS } = usePWAInstall();
  const [copiedLink, setCopiedLink] = useState(false);
  const [copiedCmd, setCopiedCmd] = useState(false);
  const [downloadingApk, setDownloadingApk] = useState(false);
  const [activeTab, setActiveTab] = useState<'direct' | 'pwabuilder' | 'flutter'>('direct');

  if (!isOpen) return null;

  const appLiveUrl = window.location.origin;
  const pwaBuilderUrl = `https://www.pwabuilder.com/reportcard?site=${encodeURIComponent(
    appLiveUrl
  )}`;

  const handleDownloadRawApk = async () => {
    setDownloadingApk(true);
    await generateAndDownloadApk();
    setTimeout(() => setDownloadingApk(false), 3000);
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(appLiveUrl);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2500);
  };

  const handleCopyCmd = () => {
    navigator.clipboard.writeText('flutter build apk --release');
    setCopiedCmd(true);
    setTimeout(() => setCopiedCmd(false), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl w-full max-w-xl shadow-2xl border border-slate-100 overflow-hidden flex flex-col max-h-[92vh]">
        {/* Header */}
        <div className="px-6 py-4.5 bg-gradient-to-r from-emerald-700 via-emerald-600 to-teal-700 text-white flex items-center justify-between shrink-0 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-white/15 backdrop-blur-md flex items-center justify-center border border-white/20 shadow-inner">
              <Download className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-extrabold font-['Outfit'] tracking-tight">
                  Download SUNDO for Android
                </h3>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-emerald-400/30 text-emerald-100 border border-emerald-300/30">
                  APK & PWA
                </span>
              </div>
              <p className="text-xs text-emerald-100/90 font-medium">
                Install as a native standalone app on any Android device
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition-colors cursor-pointer"
            aria-label="Close modal"
          >
            <X className="w-4.5 h-4.5" />
          </button>
        </div>

        {/* Option Tabs */}
        <div className="flex border-b border-slate-100 bg-slate-50/80 px-6 pt-3 gap-2 shrink-0">
          <button
            onClick={() => setActiveTab('direct')}
            className={`pb-3 px-3 text-xs font-bold transition-all relative cursor-pointer ${
              activeTab === 'direct'
                ? 'text-emerald-700 border-b-2 border-emerald-600'
                : 'text-slate-500 hover:text-slate-800'
            }`}
          >
            ⚡ 1-Tap Mobile Install
          </button>
          <button
            onClick={() => setActiveTab('pwabuilder')}
            className={`pb-3 px-3 text-xs font-bold transition-all relative cursor-pointer ${
              activeTab === 'pwabuilder'
                ? 'text-emerald-700 border-b-2 border-emerald-600'
                : 'text-slate-500 hover:text-slate-800'
            }`}
          >
            📦 PWABuilder APK
          </button>
          <button
            onClick={() => setActiveTab('flutter')}
            className={`pb-3 px-3 text-xs font-bold transition-all relative cursor-pointer ${
              activeTab === 'flutter'
                ? 'text-emerald-700 border-b-2 border-emerald-600'
                : 'text-slate-500 hover:text-slate-800'
            }`}
          >
            🛠️ Flutter Source APK
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-5 no-scrollbar">
          {activeTab === 'direct' && (
            <div className="space-y-4">
              {/* Primary Direct Installation */}
              <div className="clay-card-mint p-5 border border-emerald-200">
                <div className="flex items-start gap-3.5">
                  <div className="w-11 h-11 rounded-2xl bg-emerald-600 text-white flex items-center justify-center shrink-0 shadow-md">
                    <Smartphone className="w-6 h-6 stroke-[2.2]" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-sm font-extrabold text-slate-900 font-['Outfit']">
                      Instant WebAPK Installation (Recommended)
                    </h4>
                    <p className="text-xs text-slate-600 mt-1 leading-relaxed">
                      Android automatically generates a signed WebAPK directly from this application. It places an official SUNDO icon on your home screen and runs in full native standalone mode with offline cache and notifications.
                    </p>

                    <div className="mt-3.5 flex flex-wrap items-center gap-2.5">
                      {isInstalled ? (
                        <div className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-emerald-100 text-emerald-800 font-bold text-xs">
                          <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                          <span>SUNDO is already installed on this device!</span>
                        </div>
                      ) : isInstallable ? (
                        <button
                          onClick={install}
                          className="px-5 py-2.5 clay-button-primary text-white text-xs font-extrabold flex items-center gap-2 shadow-md cursor-pointer active:scale-95"
                        >
                          <Download className="w-4 h-4" />
                          <span>Install SUNDO App Now</span>
                        </button>
                      ) : isIOS ? (
                        <div className="text-xs bg-white/90 p-3 rounded-xl border border-slate-200 text-slate-700">
                          <p className="font-bold text-slate-900 mb-1">iOS Safari Installation:</p>
                          <p>1. Tap the <strong>Share</strong> button in Safari toolbar.</p>
                          <p>2. Scroll down and tap <strong>Add to Home Screen</strong>.</p>
                        </div>
                      ) : (
                        <button
                          onClick={install}
                          className="px-5 py-2.5 clay-button-primary text-white text-xs font-extrabold flex items-center gap-2 shadow-md cursor-pointer active:scale-95"
                        >
                          <Download className="w-4 h-4" />
                          <span>Install / Add to Home Screen</span>
                        </button>
                      )}

                      {/* Direct APK File Download button */}
                      <a
                        href="/sundo-release.apk"
                        download="SUNDO-v1.0.0-release.apk"
                        className="px-4 py-2.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold flex items-center gap-2 shadow-sm transition-all cursor-pointer active:scale-95 no-underline"
                      >
                        <Download className="w-4 h-4 text-emerald-400" />
                        <span>Download .APK File (8.4 MB)</span>
                      </a>
                    </div>
                  </div>
                </div>
              </div>

              {/* Instructions for Android Chrome */}
              <div className="bg-slate-50 rounded-2xl p-4 border border-slate-200">
                <h5 className="text-xs font-black uppercase tracking-wider text-slate-700 font-['Outfit'] mb-2 flex items-center gap-1.5">
                  <Info className="w-3.5 h-3.5 text-emerald-600" />
                  <span>How to Install on Any Android Phone</span>
                </h5>
                <ol className="text-xs text-slate-600 space-y-2 list-decimal list-inside pl-1">
                  <li>Open this web address in <strong>Google Chrome</strong> or <strong>Samsung Internet</strong> on your phone.</li>
                  <li>Tap the three vertical dots (<strong>⋮</strong>) in the top-right corner of Chrome.</li>
                  <li>Select <strong>&quot;Install app&quot;</strong> or <strong>&quot;Add to Home screen&quot;</strong>.</li>
                  <li>Confirm installation. The app will download and install with its official icon!</li>
                </ol>
              </div>

              {/* Share link tool */}
              <div className="p-3.5 bg-white rounded-2xl border border-slate-200 flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="text-[11px] font-bold text-slate-700 truncate">App URL for phone browser:</p>
                  <p className="text-xs text-emerald-700 font-mono truncate">{appLiveUrl}</p>
                </div>
                <button
                  onClick={handleCopyLink}
                  className="px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold flex items-center gap-1.5 shrink-0 transition-colors cursor-pointer"
                >
                  {copiedLink ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  <span>{copiedLink ? 'Copied!' : 'Copy Link'}</span>
                </button>
              </div>
            </div>
          )}

          {activeTab === 'pwabuilder' && (
            <div className="space-y-4">
              <div className="bg-slate-50 p-4.5 rounded-2xl border border-slate-200">
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-2 h-2 rounded-full bg-blue-500"></span>
                  <h4 className="text-sm font-extrabold text-slate-900 font-['Outfit']">
                    Generate Signed APK via PWABuilder
                  </h4>
                </div>
                <p className="text-xs text-slate-600 leading-relaxed">
                  <strong>PWABuilder</strong> (maintained by Microsoft and Google) compiles PWA manifests into native Android `.apk` (for direct sideloading) and `.aab` (for Google Play Store).
                </p>

                <div className="mt-4 p-3 bg-white rounded-xl border border-slate-200 text-xs text-slate-700 space-y-1.5">
                  <p className="font-bold text-slate-900">3-Step Generation:</p>
                  <p>1. Click the button below to open PWABuilder with this app pre-loaded.</p>
                  <p>2. Click <strong>&quot;Package for Stores&quot;</strong> and select <strong>Android</strong>.</p>
                  <p>3. Download the generated <strong>.apk</strong> file and install it directly on your Android phone!</p>
                </div>

                <div className="mt-4 flex items-center gap-3">
                  <a
                    href={pwaBuilderUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-extrabold rounded-full flex items-center gap-2 shadow-md transition-colors cursor-pointer"
                  >
                    <span>Open in PWABuilder</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>

                  <button
                    onClick={handleCopyLink}
                    className="px-4 py-2.5 bg-white border border-slate-300 hover:bg-slate-100 text-slate-700 text-xs font-bold rounded-full flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    {copiedLink ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                    <span>Copy Web URL</span>
                  </button>
                </div>
              </div>

              <div className="p-3.5 bg-emerald-50 rounded-2xl border border-emerald-100 text-xs text-emerald-800 flex items-start gap-2.5">
                <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  All required Android PWA manifest properties (192px/512px icons, standalone mode, scope, theme colors) are 100% pre-configured and verified for PWABuilder package generation.
                </span>
              </div>
            </div>
          )}

          {activeTab === 'flutter' && (
            <div className="space-y-4">
              <div className="bg-slate-50 p-4.5 rounded-2xl border border-slate-200">
                <h4 className="text-sm font-extrabold text-slate-900 font-['Outfit'] mb-1">
                  Build APK with Flutter CLI
                </h4>
                <p className="text-xs text-slate-600 leading-relaxed mb-3">
                  You can compile a pure native Flutter APK using the Flutter Dart source code built into this project:
                </p>

                <div className="bg-slate-900 text-emerald-400 p-3.5 rounded-xl font-mono text-xs flex items-center justify-between">
                  <span>flutter build apk --release</span>
                  <button
                    onClick={handleCopyCmd}
                    className="p-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors cursor-pointer"
                    title="Copy command"
                  >
                    {copiedCmd ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>

                <div className="mt-3.5 flex items-center gap-3">
                  {onOpenFlutterCode && (
                    <button
                      onClick={() => {
                        onClose();
                        onOpenFlutterCode();
                      }}
                      className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold rounded-full flex items-center gap-1.5 transition-colors cursor-pointer"
                    >
                      <Terminal className="w-3.5 h-3.5" />
                      <span>View Flutter (Dart) Source Code</span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-3.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500 shrink-0">
          <span className="flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
            <span>SUNDO Waste Operations • Sipalay City</span>
          </span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-white border border-slate-200 hover:bg-slate-100 text-slate-700 font-bold rounded-xl transition-colors cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
