import React, { useState } from 'react';
import { User, Lock, Eye, EyeOff, ArrowRight } from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { SundoTruckIcon } from '../common/SundoLogo';

interface LoginScreenProps {
  onLoginSuccess: (email?: string) => void;
  onCreateAccount: () => void;
  onForgotPassword?: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({
  onLoginSuccess,
  onCreateAccount,
  onForgotPassword,
}) => {
  const [identifier, setIdentifier] = useState('juan@gmail.com');
  const [password, setPassword] = useState('password123');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onLoginSuccess(identifier);
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 px-6 py-2 select-none overflow-y-auto no-scrollbar">
      <div>
        <StatusBar dark={true} />

        {/* Decorative corner leaves */}
        <div className="absolute top-0 right-0 w-24 h-24 pointer-events-none opacity-20">
          <svg viewBox="0 0 100 100" fill="none">
            <path d="M100 0C60 0 20 40 20 80C60 80 100 40 100 0Z" fill="#10B981" />
          </svg>
        </div>

        {/* Center SUNDO Logo */}
        <div className="mt-4 flex flex-col items-center">
          <SundoTruckIcon size={58} />
          <h2 className="text-xl font-black text-emerald-800 tracking-tight font-['Outfit'] -mt-1">
            SUNDO
          </h2>
        </div>

        {/* Header */}
        <div className="mt-4 text-center">
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight font-['Outfit']">
            Welcome Back!
          </h1>
          <p className="mt-1 text-xs text-slate-500">
            Log in to continue to a cleaner Sipalay.
          </p>
        </div>

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          {/* Email or Mobile */}
          {/* Email or Mobile */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">
              Email or Mobile Number
            </label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <User className="w-4 h-4" />
              </span>
              <input
                type="text"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder="juan@gmail.com"
                className="w-full pl-9.5 pr-3 py-2.5 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none"
                required
              />
            </div>
          </div>

          {/* Password */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Password</label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <Lock className="w-4 h-4" />
              </span>
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9.5 pr-10 py-2.5 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none font-mono"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 text-slate-400 hover:text-slate-600 p-1"
                aria-label="Toggle password visibility"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Remember me & Forgot Password */}
          <div className="flex items-center justify-between text-xs pt-0.5">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="w-4 h-4 rounded-sm text-emerald-600 focus:ring-emerald-500 border-slate-300 accent-emerald-600"
              />
              <span className="text-slate-600 text-xs font-medium">Remember me</span>
            </label>

            <button
              type="button"
              onClick={onForgotPassword}
              className="text-emerald-700 font-bold text-xs hover:underline cursor-pointer"
            >
              Forgot Password?
            </button>
          </div>

          {/* Log In Button */}
          <div className="pt-2">
            <button
              type="submit"
              className="w-full py-4 px-6 clay-button-primary text-white font-bold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-md"
            >
              <span>Log In</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </form>

        {/* Divider 'or' */}
        <div className="relative my-5">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-slate-200"></div>
          </div>
          <div className="relative flex justify-center text-xs">
            <span className="px-3 bg-white text-slate-400 font-medium">or</span>
          </div>
        </div>

        {/* Social Logins with Claymorphic Secondary Buttons */}
        <div className="space-y-3">
          {/* Google */}
          <button
            onClick={() => onLoginSuccess('juan@gmail.com')}
            className="w-full py-3 px-4 clay-button-secondary text-slate-800 font-bold text-xs flex items-center justify-center gap-3 cursor-pointer"
          >
            {/* Google G SVG */}
            <svg className="w-4 h-4" viewBox="0 0 24 24">
              <path
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                fill="#4285F4"
              />
              <path
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                fill="#34A853"
              />
              <path
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                fill="#FBBC05"
              />
              <path
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                fill="#EA4335"
              />
            </svg>
            <span>Continue with Google</span>
          </button>

          {/* Facebook */}
          <button
            onClick={() => onLoginSuccess('juan@gmail.com')}
            className="w-full py-3 px-4 clay-button-secondary text-slate-800 font-bold text-xs flex items-center justify-center gap-3 cursor-pointer"
          >
            {/* Facebook F SVG */}
            <svg className="w-4 h-4" viewBox="0 0 24 24" fill="#1877F2">
              <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
            </svg>
            <span>Continue with Facebook</span>
          </button>
        </div>
      </div>

      {/* Footer */}
      <div className="py-4 text-center">
        <p className="text-xs text-slate-500">
          Don't have an account?{' '}
          <button
            onClick={onCreateAccount}
            className="text-emerald-700 font-semibold hover:underline cursor-pointer"
          >
            Create Account
          </button>
        </p>
      </div>
    </div>
  );
};
