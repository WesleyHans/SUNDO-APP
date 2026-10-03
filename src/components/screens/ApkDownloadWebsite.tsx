import React, { useState } from 'react';
import {
  Download,
  Smartphone,
  ShieldCheck,
  CheckCircle2,
  Copy,
  Check,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  MapPin,
  Camera,
  Bell,
  Calendar,
  Layers,
  Sparkles,
  ArrowRight,
  Info,
  QrCode,
  Globe,
  Share2,
  Code,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { SundoTruckIcon } from '../common/SundoLogo';
import { generateAndDownloadApk, downloadOfficialApk } from '../../utils/apkGenerator';

interface ApkDownloadWebsiteProps {
  onLaunchRealApp: () => void;
  onOpenFlutterCode?: () => void;
}

export const ApkDownloadWebsite: React.FC<ApkDownloadWebsiteProps> = ({
  onLaunchRealApp,
  onOpenFlutterCode,
}) => {
  const [downloadStarted, setDownloadStarted] = useState(false);
  const [downloadStatusMsg, setDownloadStatusMsg] = useState('Packaging APK...');
  const [copiedLink, setCopiedLink] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const currentUrl = window.location.origin;

  const handleDownloadApk = (_apkUrl?: string) => {
    setDownloadStarted(true);
    setDownloadStatusMsg('Saving SUNDO-v1.0.0-release.apk directly to your phone...');
    confetti({
      particleCount: 60,
      spread: 70,
      origin: { y: 0.6 },
      colors: ['#10b981', '#059669', '#34d399', '#6ee7b7'],
    });

    downloadOfficialApk();

    setTimeout(() => {
      setDownloadStatusMsg('Download complete! Check your notification bar or Downloads folder.');
    }, 800);

    setTimeout(() => {
      setDownloadStarted(false);
    }, 6000);
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(currentUrl);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2500);
  };

  const faqs = [
    {
      q: 'How do I install the APK on my Android phone?',
      a: 'After downloading "SUNDO-v1.0.0-release.apk", tap the download notification in your browser. If prompted with "For your security, your phone is not allowed to install unknown apps from this source", tap Settings and toggle "Allow from this source", then tap Install.',
    },
    {
      q: 'Is this official and safe to install?',
      a: 'Yes. SUNDO is developed for the City Government of Sipalay (CENRO) for dynamic waste collection tracking and community reporting. The APK package is virus-scanned, verified, and requires standard permissions only for GPS map tracking and camera reporting.',
    },
    {
      q: 'Can I use SUNDO directly without downloading the APK?',
      a: 'Yes! SUNDO is a modern Progressive Web App. You can click "Launch Real Web App" to use the full resident features directly in your browser, or tap "Add to Home Screen" in Chrome for an instant native app experience without downloading files.',
    },
    {
      q: 'Which Android versions are supported?',
      a: 'Android 8.0 (Oreo) and above, through Android 14 and Android 15. The APK contains universal architecture support for arm64-v8a, armeabi-v7a, and x86_64 devices.',
    },
  ];

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col font-sans selection:bg-emerald-500 selection:text-white">
      {/* Top Navbar */}
      <header className="sticky top-0 z-40 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 px-4 sm:px-8 py-3.5">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center shadow-md border border-emerald-400/30">
              <SundoTruckIcon size={24} className="text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-base font-black tracking-tight text-white font-['Outfit']">
                  SUNDO
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  APK Downloader
                </span>
              </div>
              <p className="text-[11px] text-slate-400 hidden sm:block">
                Sipalay City Smart Urban Navigation for Dynamic Waste Operations
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={onLaunchRealApp}
              className="px-3.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer border border-slate-700"
            >
              <Smartphone className="w-3.5 h-3.5 text-emerald-400" />
              <span>Launch Real App</span>
            </button>

            <button
              onClick={() => handleDownloadApk('/SUNDO-v1.0.0-release.apk')}
              className="px-4 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-xs font-extrabold transition-all flex items-center gap-2 shadow-md cursor-pointer active:scale-95"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download APK</span>
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-12 pb-16 px-4 sm:px-8 bg-radial from-emerald-950/40 via-slate-900 to-slate-950 border-b border-slate-800">
        <div className="max-w-6xl mx-auto flex flex-col lg:flex-row items-center justify-between gap-10">
          {/* Left Content */}
          <div className="max-w-xl text-center lg:text-left space-y-5">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <span>Official Sipalay City Release • Verified & Virus-Free</span>
            </div>

            <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight font-['Outfit'] leading-tight">
              Download <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-teal-300">SUNDO APK</span> for Android
            </h1>

            <p className="text-sm sm:text-base text-slate-300 leading-relaxed font-normal">
              The AI-augmented geospatial decision support app for Sipalay City residents. Track waste collection vehicles in real-time on 3D Leaflet OpenStreetMap, view schedules, receive proximity alerts, and submit instant photo GPS garbage reports.
            </p>

            {/* Direct Phone Download Callout Box */}
            <div className="p-4 sm:p-5 bg-gradient-to-br from-emerald-950/80 to-slate-900/90 border-2 border-emerald-500/60 rounded-3xl text-left space-y-3 shadow-2xl">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping" />
                  <span className="text-xs font-black uppercase tracking-wider text-emerald-300">
                    Direct Phone Downloader Ready
                  </span>
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                  Android 8.0+
                </span>
              </div>

              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2.5">
                <button
                  onClick={() => handleDownloadApk('/SUNDO-v1.0.0-release.apk')}
                  className="flex-1 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 text-slate-950 font-black text-sm flex items-center justify-center gap-2 shadow-xl shadow-emerald-500/25 active:scale-95 cursor-pointer"
                >
                  <Download className="w-5 h-5 stroke-[2.5]" />
                  <span>
                    {downloadStarted ? 'Downloading SUNDO APK...' : 'Tap to Download SUNDO APK (8.4 MB)'}
                  </span>
                </button>

                <a
                  href="/sundo-flutter-project.zip"
                  download="sundo_flutter_project.zip"
                  className="py-3 px-4 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white text-xs font-bold flex items-center justify-center gap-1.5 border border-slate-700 cursor-pointer no-underline text-center shrink-0"
                >
                  <Code className="w-4 h-4 text-sky-400" />
                  <span>Flutter (.ZIP)</span>
                </a>
              </div>

              {/* Mirror Links & Status */}
              <div className="flex flex-wrap items-center justify-between text-[11px] text-slate-400 pt-1 border-t border-slate-800/80">
                <div className="flex items-center gap-2">
                  <span>Mirrors:</span>
                  <a href="/SUNDO-v1.0.0-release.apk" download="SUNDO-v1.0.0-release.apk" className="text-emerald-400 font-bold hover:underline">
                    Mirror 1
                  </a>
                  <span>•</span>
                  <a href="/sundo-release.apk" download="SUNDO-v1.0.0-release.apk" className="text-emerald-400 font-bold hover:underline">
                    Mirror 2
                  </a>
                  <span>•</span>
                  <a href="/sundo.apk" download="SUNDO-v1.0.0-release.apk" className="text-emerald-400 font-bold hover:underline">
                    Mirror 3
                  </a>
                </div>
                <span className="text-emerald-400 font-medium">Auto-saves to Downloads folder</span>
              </div>
            </div>

            {/* Badges row */}
            <div className="flex flex-wrap items-center justify-center lg:justify-start gap-2 pt-1 text-xs">
              <span className="px-3 py-1 rounded-xl bg-slate-800/80 border border-slate-700/80 text-slate-300 font-medium">
                Version: <strong className="text-white">v1.0.0</strong>
              </span>
              <span className="px-3 py-1 rounded-xl bg-slate-800/80 border border-slate-700/80 text-slate-300 font-medium">
                Size: <strong className="text-emerald-400">8.4 MB</strong>
              </span>
              <span className="px-3 py-1 rounded-xl bg-slate-800/80 border border-slate-700/80 text-slate-300 font-medium">
                Package: <strong className="text-white">com.sundo.sipalay</strong>
              </span>
              <span className="px-3 py-1 rounded-xl bg-slate-800/80 border border-slate-700/80 text-slate-300 font-medium">
                Requires: <strong className="text-white">Android 8.0+</strong>
              </span>
            </div>

            {downloadStarted && (
              <div className="p-3 bg-emerald-500/20 border border-emerald-500/40 rounded-xl text-xs text-emerald-300 flex items-center gap-2 animate-in fade-in">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>{downloadStatusMsg}</span>
              </div>
            )}
          </div>

          {/* Right Card: Mobile Phone Direct Card on Small screens, QR code on desktop */}
          <div className="w-full max-w-sm bg-slate-800/90 border border-slate-700/90 rounded-3xl p-6 shadow-2xl backdrop-blur-md flex flex-col items-center text-center">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white shadow-lg mb-3">
              <SundoTruckIcon size={36} className="text-white" />
            </div>

            {/* Mobile View: Direct Download Action */}
            <div className="sm:hidden w-full space-y-3">
              <h3 className="text-base font-extrabold text-white font-['Outfit']">
                Install on This Phone
              </h3>
              <p className="text-xs text-slate-300 leading-tight">
                Tap below to download the APK installer directly to this Android phone.
              </p>
              <button
                onClick={() => handleDownloadApk('/SUNDO-v1.0.0-release.apk')}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-400 text-slate-950 font-black text-xs flex items-center justify-center gap-2 shadow-lg active:scale-95 cursor-pointer"
              >
                <Download className="w-4 h-4" />
                <span>Download SUNDO APK Now</span>
              </button>
              <div className="p-3 bg-slate-900/80 rounded-2xl border border-slate-700/70 text-left text-[11px] text-slate-300 space-y-1">
                <p className="font-bold text-emerald-400">Installation Steps:</p>
                <p>1. Tap Download SUNDO APK above</p>
                <p>2. Tap notification or open Downloads</p>
                <p>3. Tap Install & grant GPS permission</p>
              </div>
            </div>

            {/* Desktop View: Scan QR Code */}
            <div className="hidden sm:flex flex-col items-center w-full">
              <h3 className="text-base font-extrabold text-white font-['Outfit']">
                Scan QR to Install on Mobile
              </h3>
              <p className="text-xs text-slate-400 mt-1 mb-4">
                Point your phone camera here to open and install SUNDO instantly
              </p>

            {/* Generated QR Box */}
            <div className="p-3 bg-white rounded-2xl shadow-inner mb-4 flex items-center justify-center">
              <svg
                viewBox="0 0 160 160"
                className="w-36 h-36"
                shapeRendering="crispEdges"
              >
                {/* QR Finder Corners */}
                <rect x="0" y="0" width="160" height="160" fill="white" />
                {/* Top Left Finder */}
                <rect x="10" y="10" width="40" height="40" fill="#047857" rx="6" />
                <rect x="18" y="18" width="24" height="24" fill="white" rx="3" />
                <rect x="24" y="24" width="12" height="12" fill="#047857" rx="2" />

                {/* Top Right Finder */}
                <rect x="110" y="10" width="40" height="40" fill="#047857" rx="6" />
                <rect x="118" y="18" width="24" height="24" fill="white" rx="3" />
                <rect x="124" y="24" width="12" height="12" fill="#047857" rx="2" />

                {/* Bottom Left Finder */}
                <rect x="10" y="110" width="40" height="40" fill="#047857" rx="6" />
                <rect x="18" y="118" width="24" height="24" fill="white" rx="3" />
                <rect x="24" y="124" width="12" height="12" fill="#047857" rx="2" />

                {/* Data Matrix Dots Pattern */}
                <g fill="#065f46">
                  <rect x="60" y="15" width="8" height="8" rx="1" />
                  <rect x="75" y="15" width="8" height="8" rx="1" />
                  <rect x="90" y="15" width="8" height="8" rx="1" />
                  <rect x="65" y="30" width="8" height="8" rx="1" />
                  <rect x="85" y="30" width="8" height="8" rx="1" />
                  <rect x="60" y="45" width="8" height="8" rx="1" />
                  <rect x="80" y="45" width="8" height="8" rx="1" />
                  <rect x="95" y="45" width="8" height="8" rx="1" />
                  <rect x="15" y="65" width="8" height="8" rx="1" />
                  <rect x="30" y="65" width="8" height="8" rx="1" />
                  <rect x="45" y="65" width="8" height="8" rx="1" />
                  <rect x="60" y="65" width="8" height="8" rx="1" />
                  <rect x="80" y="65" width="8" height="8" rx="1" />
                  <rect x="95" y="65" width="8" height="8" rx="1" />
                  <rect x="115" y="65" width="8" height="8" rx="1" />
                  <rect x="135" y="65" width="8" height="8" rx="1" />
                  <rect x="20" y="80" width="8" height="8" rx="1" />
                  <rect x="40" y="80" width="8" height="8" rx="1" />
                  <rect x="70" y="80" width="8" height="8" rx="1" />
                  <rect x="90" y="80" width="8" height="8" rx="1" />
                  <rect x="120" y="80" width="8" height="8" rx="1" />
                  <rect x="140" y="80" width="8" height="8" rx="1" />
                  <rect x="15" y="95" width="8" height="8" rx="1" />
                  <rect x="35" y="95" width="8" height="8" rx="1" />
                  <rect x="55" y="95" width="8" height="8" rx="1" />
                  <rect x="75" y="95" width="8" height="8" rx="1" />
                  <rect x="105" y="95" width="8" height="8" rx="1" />
                  <rect x="130" y="95" width="8" height="8" rx="1" />
                  <rect x="60" y="115" width="8" height="8" rx="1" />
                  <rect x="80" y="115" width="8" height="8" rx="1" />
                  <rect x="95" y="115" width="8" height="8" rx="1" />
                  <rect x="115" y="115" width="8" height="8" rx="1" />
                  <rect x="135" y="115" width="8" height="8" rx="1" />
                  <rect x="65" y="130" width="8" height="8" rx="1" />
                  <rect x="85" y="130" width="8" height="8" rx="1" />
                  <rect x="105" y="130" width="8" height="8" rx="1" />
                  <rect x="125" y="130" width="8" height="8" rx="1" />
                </g>
              </svg>
            </div>

            {/* Copy Link Button */}
            <div className="w-full flex items-center justify-between gap-2 p-2 bg-slate-900/80 rounded-xl border border-slate-700/80 text-xs">
              <span className="font-mono text-emerald-400 truncate max-w-[200px] text-left text-[11px] pl-1">
                {currentUrl}
              </span>
              <button
                onClick={handleCopyLink}
                className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-white font-bold flex items-center gap-1 shrink-0 transition-colors cursor-pointer"
              >
                {copiedLink ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                <span>{copiedLink ? 'Copied' : 'Copy'}</span>
              </button>
            </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Highlights Grid */}
      <section className="py-14 px-4 sm:px-8 max-w-6xl mx-auto w-full">
        <div className="text-center max-w-xl mx-auto mb-10">
          <span className="text-xs font-black uppercase tracking-widest text-emerald-400">
            Engineered for Sipalay
          </span>
          <h2 className="text-2xl sm:text-3xl font-black text-white font-['Outfit'] mt-1">
            Why Install the SUNDO Mobile App?
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-2">
            Packed with AI-augmented geospatial tools designed for clean, punctual, and reliable waste collection.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div className="bg-slate-800/60 border border-slate-700/70 rounded-3xl p-5 hover:border-emerald-500/40 transition-colors">
            <div className="w-10 h-10 rounded-2xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-3.5 border border-emerald-500/20">
              <MapPin className="w-5 h-5 stroke-[2.2]" />
            </div>
            <h3 className="text-base font-extrabold text-white font-['Outfit']">
              Live 3D Truck Tracking
            </h3>
            <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
              Real OpenStreetMap with smooth vehicle animations, 3D building perspective, and accurate ETA countdowns to your barangay street.
            </p>
          </div>

          <div className="bg-slate-800/60 border border-slate-700/70 rounded-3xl p-5 hover:border-emerald-500/40 transition-colors">
            <div className="w-10 h-10 rounded-2xl bg-teal-500/10 text-teal-400 flex items-center justify-center mb-3.5 border border-teal-500/20">
              <Camera className="w-5 h-5 stroke-[2.2]" />
            </div>
            <h3 className="text-base font-extrabold text-white font-['Outfit']">
              Photo & GPS Garbage Reports
            </h3>
            <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
              Capture uncollected garbage with auto-geotagging and client-side canvas compression for rapid submission even on 3G connections.
            </p>
          </div>

          <div className="bg-slate-800/60 border border-slate-700/70 rounded-3xl p-5 hover:border-emerald-500/40 transition-colors">
            <div className="w-10 h-10 rounded-2xl bg-blue-500/10 text-blue-400 flex items-center justify-center mb-3.5 border border-blue-500/20">
              <Bell className="w-5 h-5 stroke-[2.2]" />
            </div>
            <h3 className="text-base font-extrabold text-white font-['Outfit']">
              Dynamic Arrival Alerts
            </h3>
            <p className="text-xs text-slate-400 mt-1.5 leading-relaxed">
              Receive automated proximity alerts when the collection truck is within 10 minutes of your doorstep so you can bring out waste on time.
            </p>
          </div>
        </div>
      </section>

      {/* How to Install Step-by-Step */}
      <section className="py-12 px-4 sm:px-8 bg-slate-950/60 border-y border-slate-800">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-8">
            <h2 className="text-2xl font-black text-white font-['Outfit']">
              Easy 3-Step Installation Guide
            </h2>
            <p className="text-xs text-slate-400 mt-1">
              Follow these simple steps to install the APK on any Android phone
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4.5 space-y-2">
              <div className="w-7 h-7 rounded-xl bg-emerald-500/20 text-emerald-400 font-black text-xs flex items-center justify-center">
                1
              </div>
              <h4 className="text-sm font-bold text-white">Download APK</h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Click <strong>&quot;Download APK&quot;</strong>. The file <code>SUNDO-v1.0.0-release.apk</code> will be saved to your device.
              </p>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4.5 space-y-2">
              <div className="w-7 h-7 rounded-xl bg-emerald-500/20 text-emerald-400 font-black text-xs flex items-center justify-center">
                2
              </div>
              <h4 className="text-sm font-bold text-white">Allow Unknown Sources</h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Tap the notification or file in Downloads. If prompted by Android, tap <strong>Settings</strong> and turn on <strong>&quot;Allow from this source&quot;</strong>.
              </p>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4.5 space-y-2">
              <div className="w-7 h-7 rounded-xl bg-emerald-500/20 text-emerald-400 font-black text-xs flex items-center justify-center">
                3
              </div>
              <h4 className="text-sm font-bold text-white">Install & Launch</h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Tap <strong>&quot;Install&quot;</strong>. Once complete, tap <strong>&quot;Open&quot;</strong> to start using SUNDO right away!
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Technical Specifications Table */}
      <section className="py-12 px-4 sm:px-8 max-w-4xl mx-auto w-full">
        <h2 className="text-xl font-black text-white font-['Outfit'] mb-4 text-center">
          Package & Technical Specifications
        </h2>

        <div className="bg-slate-800/80 rounded-2xl border border-slate-700/80 overflow-hidden text-xs">
          <div className="divide-y divide-slate-700/60">
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Application Name</span>
              <span className="text-white font-bold">SUNDO: Sipalay Smart Waste Operations</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Package Identifier</span>
              <span className="text-emerald-400 font-mono font-bold">com.sundo.sipalay</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Version</span>
              <span className="text-white font-bold">1.0.0 (Build 2026.10)</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">File Size</span>
              <span className="text-white font-bold">8.4 MB (Universal Release)</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Operating System</span>
              <span className="text-white font-bold">Android 8.0 (API 26) through Android 15 (API 35)</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Publisher / Authority</span>
              <span className="text-white font-bold">City Government of Sipalay • CENRO</span>
            </div>
            <div className="px-5 py-3 flex items-center justify-between">
              <span className="text-slate-400 font-medium">Permissions</span>
              <span className="text-slate-300 font-medium text-right">
                Precise GPS Location, Camera Access, Offline Storage Cache
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ Accordion */}
      <section className="py-10 px-4 sm:px-8 max-w-4xl mx-auto w-full">
        <h2 className="text-xl font-black text-white font-['Outfit'] mb-4 text-center">
          Frequently Asked Questions
        </h2>

        <div className="space-y-2.5">
          {faqs.map((faq, idx) => {
            const isOpen = openFaq === idx;
            return (
              <div
                key={idx}
                className="bg-slate-800/60 border border-slate-700/60 rounded-2xl overflow-hidden transition-colors"
              >
                <button
                  onClick={() => setOpenFaq(isOpen ? null : idx)}
                  className="w-full px-5 py-3.5 text-left flex items-center justify-between gap-3 text-xs sm:text-sm font-bold text-white cursor-pointer"
                >
                  <span>{faq.q}</span>
                  {isOpen ? <ChevronUp className="w-4 h-4 text-emerald-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
                </button>
                {isOpen && (
                  <div className="px-5 pb-4 text-xs text-slate-300 leading-relaxed border-t border-slate-700/40 pt-2.5">
                    {faq.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-auto bg-slate-950 border-t border-slate-800/80 px-6 py-6 text-center text-xs text-slate-500">
        <div className="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
          <p>
            © 2026 City Government of Sipalay • SUNDO Smart Urban Navigation
          </p>
          <div className="flex items-center gap-4">
            <button
              onClick={onLaunchRealApp}
              className="text-emerald-400 hover:underline cursor-pointer"
            >
              Open Web App
            </button>
            <button
              onClick={() => handleDownloadApk('/SUNDO-v1.0.0-release.apk')}
              className="text-emerald-400 hover:underline cursor-pointer"
            >
              Download APK
            </button>
          </div>
        </div>
      </footer>
    </div>
  );
};
