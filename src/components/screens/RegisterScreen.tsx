import React, { useState } from 'react';
import { ChevronLeft, User, Phone, Mail, Lock, Eye, EyeOff, MapPin, ChevronDown } from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { BARANGAYS_LIST } from '../../data/mockData';

interface RegisterScreenProps {
  onBack: () => void;
  onRegisterSuccess: (userData?: { name: string; email: string; phone: string; address: string }) => void;
  onGoToLogin: () => void;
}

export const RegisterScreen: React.FC<RegisterScreenProps> = ({
  onBack,
  onRegisterSuccess,
  onGoToLogin,
}) => {
  const [fullName, setFullName] = useState('Juan Dela Cruz');
  const [mobileNumber, setMobileNumber] = useState('0912 345 6789');
  const [email, setEmail] = useState('juan@gmail.com');
  const [password, setPassword] = useState('secret123');
  const [showPassword, setShowPassword] = useState(false);
  const [selectedBarangay, setSelectedBarangay] = useState('Barangay 1, Sipalay City');
  const [useCurrentLocation, setUseCurrentLocation] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onRegisterSuccess({
      name: fullName || 'Juan Dela Cruz',
      email: email || 'juan@gmail.com',
      phone: mobileNumber || '0912 345 6789',
      address: selectedBarangay,
    });
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-white text-slate-800 px-6 py-2 select-none overflow-y-auto no-scrollbar">
      <div>
        <StatusBar dark={true} />

        {/* Back navigation */}
        <div className="flex items-center -ml-2 mt-1">
          <button
            onClick={onBack}
            className="p-2 rounded-full hover:bg-slate-100 text-slate-700 transition-colors"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
        </div>

        {/* Header */}
        <div className="mt-2">
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight font-['Outfit']">
            Create Your Account
          </h1>
          <p className="mt-1 text-xs text-slate-500">
            Join SUNDO and be part of a cleaner and greener Sipalay.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="mt-5 space-y-3.5">
          {/* Full Name */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Full Name</label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <User className="w-4 h-4" />
              </span>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Juan Dela Cruz"
                className="w-full pl-9.5 pr-3 py-2.5 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none"
                required
              />
            </div>
          </div>

          {/* Mobile Number */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Mobile Number</label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <Phone className="w-4 h-4" />
              </span>
              <input
                type="tel"
                value={mobileNumber}
                onChange={(e) => setMobileNumber(e.target.value)}
                placeholder="0912 345 6789"
                className="w-full pl-9.5 pr-3 py-2.5 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none"
                required
              />
            </div>
          </div>

          {/* Email Address */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Email Address</label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <Mail className="w-4 h-4" />
              </span>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
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

          {/* Barangay / Address */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Barangay / Address</label>
            <div className="relative flex items-center">
              <span className="absolute left-3 text-slate-400">
                <MapPin className="w-4 h-4" />
              </span>
              <select
                value={selectedBarangay}
                onChange={(e) => setSelectedBarangay(e.target.value)}
                className="w-full pl-9.5 pr-8 py-2.5 clay-input text-xs text-slate-800 appearance-none focus:outline-none cursor-pointer"
              >
                {BARANGAYS_LIST.map((b) => (
                  <option key={b} value={b}>
                    {b}
                  </option>
                ))}
              </select>
              <span className="absolute right-3 text-slate-400 pointer-events-none">
                <ChevronDown className="w-4 h-4" />
              </span>
            </div>
          </div>

          {/* Use My Current Location Toggle */}
          <div className="flex items-start justify-between gap-3 pt-1">
            <div className="flex items-start gap-2.5">
              <span className="mt-0.5 text-emerald-600">
                <MapPin className="w-4 h-4" />
              </span>
              <div>
                <p className="text-xs font-bold text-slate-800">Use my current location</p>
                <p className="text-[10px] text-slate-500 leading-tight">
                  Helps us give accurate updates for your area.
                </p>
              </div>
            </div>

            {/* Toggle switch */}
            <button
              type="button"
              onClick={() => setUseCurrentLocation(!useCurrentLocation)}
              className={`w-10 h-6 rounded-full transition-colors relative cursor-pointer shrink-0 mt-0.5 shadow-inner ${
                useCurrentLocation ? 'bg-emerald-600' : 'bg-slate-300'
              }`}
              role="switch"
              aria-checked={useCurrentLocation}
            >
              <span
                className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow-md transition-transform ${
                  useCurrentLocation ? 'left-5' : 'left-1'
                }`}
              />
            </button>
          </div>

          {/* Create Account Submit */}
          <div className="pt-2">
            <button
              type="submit"
              className="w-full py-4 px-6 clay-button-primary text-white font-bold text-xs tracking-wide cursor-pointer text-center shadow-md"
            >
              Create Account
            </button>
          </div>
        </form>
      </div>

      {/* Footer */}
      <div className="py-4 text-center">
        <p className="text-xs text-slate-500">
          Already have an account?{' '}
          <button
            onClick={onGoToLogin}
            className="text-emerald-700 font-semibold hover:underline cursor-pointer"
          >
            Log In
          </button>
        </p>
      </div>
    </div>
  );
};
