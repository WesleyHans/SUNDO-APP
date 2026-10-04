import React, { useState } from 'react';
import { ArrowRight, Navigation, Camera, Award, Radio } from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { WelcomeSceneGraphic } from '../common/CityIllustration';

interface WelcomeScreenProps {
  onGetStarted: () => void;
  onLogIn: () => void;
  onCreateAccount: () => void;
}

export const WelcomeScreen: React.FC<WelcomeScreenProps> = ({
  onGetStarted,
  onLogIn,
  onCreateAccount,
}) => {
  const [currentStep, setCurrentStep] = useState(0);

  const slides = [
    {
      title1: 'A Cleaner Sipalay',
      title2: 'Starts with You',
      tag: 'SIPALAY ECO-CLEAN INITIATIVE',
      accentColor: 'text-emerald-700',
      underlineColor: 'bg-emerald-400',
      description:
        'Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.',
      illustration: <WelcomeSceneGraphic />,
    },
    {
      title1: 'Live GPS Tracking',
      title2: 'Never Miss a Truck',
      tag: 'REAL-TIME SATELLITE RADAR',
      accentColor: 'text-emerald-600',
      underlineColor: 'bg-teal-400',
      description:
        'Watch collection trucks approach your barangay in real-time with accurate distance meters and proximity sirens.',
      illustration: (
        <div className="w-full h-[200px] rounded-2xl overflow-hidden shadow-xs border border-emerald-500/30 bg-gradient-to-br from-slate-900 via-slate-800 to-emerald-950 p-4 flex flex-col justify-between relative select-none">
          {/* Radar background circles */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-20">
            <div className="w-56 h-56 rounded-full border border-emerald-400"></div>
            <div className="w-40 h-40 rounded-full border border-emerald-400 absolute"></div>
            <div className="w-24 h-24 rounded-full border border-emerald-400 absolute"></div>
          </div>

          {/* Top telemetry badges */}
          <div className="flex items-center justify-between z-10">
            <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-900/80 border border-emerald-400/50 text-[10px] font-bold text-emerald-400 tracking-wider">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              SATELLITE GPS ACTIVE
            </div>
            <div className="px-2.5 py-1 rounded-full bg-emerald-600 text-white text-[10px] font-extrabold shadow-sm">
              ~8 MINS ETA
            </div>
          </div>

          {/* Center Route Line & Nodes */}
          <div className="relative w-full h-20 my-auto flex items-center justify-between px-6 z-10">
            <div className="absolute left-6 right-6 h-1 bg-gradient-to-r from-emerald-500 via-teal-400 to-blue-500 rounded-full shadow-[0_0_12px_rgba(52,211,153,0.8)]"></div>
            
            {/* Truck Pin */}
            <div className="relative z-10 flex flex-col items-center">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-500 to-teal-400 p-1.5 shadow-lg border-2 border-white flex items-center justify-center animate-bounce">
                <Navigation className="w-5 h-5 text-white" />
              </div>
              <span className="text-[9px] font-bold text-emerald-300 mt-1">Truck #02</span>
            </div>

            {/* Waypoint */}
            <div className="w-3 h-3 rounded-full bg-teal-300 border-2 border-white shadow-md z-10"></div>

            {/* User Location Pin */}
            <div className="relative z-10 flex flex-col items-center">
              <div className="w-9 h-9 rounded-full bg-blue-600 p-1.5 shadow-lg border-2 border-white flex items-center justify-center">
                <Radio className="w-4 h-4 text-white animate-pulse" />
              </div>
              <span className="text-[9px] font-bold text-blue-300 mt-1">You (350m)</span>
            </div>
          </div>

          {/* Bottom helper */}
          <div className="z-10 text-center text-[10px] text-slate-300 font-semibold bg-slate-900/60 py-1 rounded-lg border border-slate-700/50">
            Sipalay Poblacion Route 1 • Kuya Ronald
          </div>
        </div>
      ),
    },
    {
      title1: 'Report & Keep Track',
      title2: 'Zero Waste Sipalay',
      tag: 'COMMUNITY CENRO ACTION',
      accentColor: 'text-teal-700',
      underlineColor: 'bg-teal-400',
      description:
        'Snap photos of uncollected waste or illegal dumping, earn Eco-Points, and keep our coastlines pristine.',
      illustration: (
        <div className="w-full h-[200px] rounded-2xl overflow-hidden shadow-xs border border-emerald-200 bg-gradient-to-b from-emerald-50/70 via-sky-50/60 to-emerald-100/50 p-3.5 flex flex-col justify-between select-none">
          {/* Top Certificate Header */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1 px-2.5 py-1 rounded-xl bg-white shadow-xs border border-slate-200 text-[10px] font-bold text-emerald-800">
              <Camera className="w-3.5 h-3.5 text-emerald-600" />
              CENRO Verified Report
            </div>
            <div className="flex items-center gap-1 px-2.5 py-1 rounded-xl bg-gradient-to-r from-amber-400 to-amber-500 text-white text-[10px] font-extrabold shadow-xs">
              <Award className="w-3.5 h-3.5" />
              +50 Eco-Points
            </div>
          </div>

          {/* 3 Segregation Bins */}
          <div className="flex items-center justify-around my-auto">
            <div className="flex flex-col items-center">
              <div className="w-14 h-16 rounded-xl bg-emerald-100 border-2 border-emerald-500/40 flex flex-col items-center justify-center shadow-sm">
                <span className="text-xl">🌿</span>
                <div className="w-6 h-1 bg-emerald-500 rounded mt-1"></div>
              </div>
              <span className="text-[10px] font-extrabold text-slate-800 mt-1">Bio</span>
              <span className="text-[8.5px] font-semibold text-emerald-700">Malata</span>
            </div>

            <div className="flex flex-col items-center">
              <div className="w-14 h-16 rounded-xl bg-blue-100 border-2 border-blue-500/40 flex flex-col items-center justify-center shadow-sm">
                <span className="text-xl">♻️</span>
                <div className="w-6 h-1 bg-blue-500 rounded mt-1"></div>
              </div>
              <span className="text-[10px] font-extrabold text-slate-800 mt-1">Recycle</span>
              <span className="text-[8.5px] font-semibold text-blue-700">Mabaligya</span>
            </div>

            <div className="flex flex-col items-center">
              <div className="w-14 h-16 rounded-xl bg-amber-100 border-2 border-amber-500/40 flex flex-col items-center justify-center shadow-sm">
                <span className="text-xl">🗑️</span>
                <div className="w-6 h-1 bg-amber-500 rounded mt-1"></div>
              </div>
              <span className="text-[10px] font-extrabold text-slate-800 mt-1">Residual</span>
              <span className="text-[8.5px] font-semibold text-amber-700">Di-malata</span>
            </div>
          </div>

          {/* Bottom badge */}
          <div className="w-full py-1 text-center bg-white/90 rounded-xl border border-slate-200 text-[10px] font-bold text-slate-700">
            📸 1-Tap Photo Report • Real GPS Auto-Tagged
          </div>
        </div>
      ),
    },
  ];

  const handleNext = () => {
    if (currentStep < slides.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onGetStarted();
    }
  };

  const currentSlide = slides[currentStep];

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 px-6 py-2 select-none overflow-y-auto no-scrollbar">
      <div>
        <StatusBar dark={true} />

        {/* Top Mini Bar with Skip */}
        <div className="flex items-center justify-between mt-2">
          <div className="flex items-center gap-2">
            <img src="/sundo_logo.png" alt="SUNDO" className="w-6 h-6 object-contain rounded-md" />
            <span className="text-xs font-black tracking-wider text-slate-900 font-['Outfit']">SUNDO</span>
          </div>

          {currentStep < slides.length - 1 ? (
            <button
              onClick={() => setCurrentStep(slides.length - 1)}
              className="text-[11px] font-bold text-slate-500 hover:text-slate-800 px-2.5 py-1 rounded-full bg-slate-100 transition-colors"
            >
              Skip
            </button>
          ) : (
            <div className="w-10"></div>
          )}
        </div>

        {/* Headline */}
        <div className="mt-3 text-center transition-all duration-300">
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight leading-snug font-['Outfit']">
            {currentSlide.title1} <br />
            <span className={`${currentSlide.accentColor} relative inline-block`}>
              {currentSlide.title2}
              <span className={`absolute left-0 -bottom-1 w-full h-1 ${currentSlide.underlineColor} rounded-full`}></span>
            </span>
          </h1>

          <p className="mt-2 text-xs text-slate-600 leading-relaxed max-w-[280px] mx-auto min-h-[36px]">
            {currentSlide.description}
          </p>
        </div>

        {/* Center Illustration */}
        <div className="mt-4 w-full max-w-[320px] mx-auto transition-all duration-300">
          {currentSlide.illustration}
        </div>

        {/* Carousel Pagination Dots with Tap to Select */}
        <div className="flex items-center justify-center gap-1.5 mt-4">
          {slides.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentStep(index)}
              className={`transition-all duration-300 rounded-full cursor-pointer ${
                currentStep === index
                  ? 'w-6 h-2 bg-emerald-600 shadow-sm'
                  : 'w-2 h-2 bg-slate-300 hover:bg-slate-400'
              }`}
            />
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <div className="w-full flex flex-col items-center gap-2.5 my-3 pb-2">
        <button
          onClick={handleNext}
          className="w-full py-3.5 px-6 clay-button-primary text-white font-bold text-sm flex items-center justify-center gap-2 cursor-pointer shadow-md transition-transform active:scale-98"
        >
          <span>{currentStep === slides.length - 1 ? 'Get Started' : 'Next'}</span>
          <ArrowRight className="w-4 h-4" />
        </button>

        <button
          onClick={onLogIn}
          className="w-full py-3 px-6 clay-button-secondary text-slate-800 font-bold text-sm cursor-pointer transition-transform active:scale-98"
        >
          Log In
        </button>

        <button
          onClick={onCreateAccount}
          className="text-xs text-emerald-700 hover:text-emerald-800 font-bold mt-0.5 cursor-pointer transition-colors"
        >
          Create an Account
        </button>
      </div>
    </div>
  );
};
