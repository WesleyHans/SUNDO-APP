import React from 'react';
import { ArrowRight } from 'lucide-react';
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
  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 px-6 py-2 select-none overflow-y-auto no-scrollbar">
      <div>
        <StatusBar dark={true} />

        {/* Headline */}
        <div className="mt-4 text-center">
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight leading-snug font-['Outfit']">
            A Cleaner Sipalay <br />
            <span className="text-emerald-700 relative inline-block">
              Starts with You
              <span className="absolute left-0 -bottom-1 w-full h-1 bg-emerald-400 rounded-full"></span>
            </span>
          </h1>

          <p className="mt-3 text-xs text-slate-600 leading-relaxed max-w-[280px] mx-auto">
            Track garbage trucks, know collection schedules, receive alerts, and help keep our city clean.
          </p>
        </div>

        {/* Center Illustration */}
        <div className="mt-6 w-full max-w-[320px] mx-auto">
          <WelcomeSceneGraphic />
        </div>

        {/* Carousel Pagination Dots */}
        <div className="flex items-center justify-center gap-1.5 mt-5">
          <span className="w-2 h-2 rounded-full bg-slate-300"></span>
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-600"></span>
          <span className="w-2 h-2 rounded-full bg-slate-300"></span>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="w-full flex flex-col items-center gap-3 my-4 pb-2">
        <button
          onClick={onGetStarted}
          className="w-full py-4 px-6 clay-button-primary text-white font-bold text-sm flex items-center justify-center gap-2 cursor-pointer shadow-md"
        >
          <span>Get Started</span>
          <ArrowRight className="w-4 h-4" />
        </button>

        <button
          onClick={onLogIn}
          className="w-full py-3.5 px-6 clay-button-secondary text-slate-800 font-bold text-sm cursor-pointer"
        >
          Log In
        </button>

        <button
          onClick={onCreateAccount}
          className="text-xs text-emerald-700 hover:text-emerald-800 font-bold mt-1 cursor-pointer transition-colors"
        >
          Create an Account
        </button>
      </div>
    </div>
  );
};
