import React, { useState, useEffect, useRef } from 'react';
import {
  ChevronLeft,
  MapPin,
  Camera,
  Image as ImageIcon,
  CheckCircle2,
  AlertCircle,
  Locate,
  ArrowRight,
  X,
  FlipHorizontal,
  Sparkles,
  Info,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { StatusBar } from '../common/StatusBar';
import { ResidentBottomNav } from '../layout/BottomNav';
import {
  ResidentUser,
  GarbageReport,
  GarbageType,
  EstimatedAmount,
  ResidentTab,
} from '../../types/resident';
import { GeoService } from '../../services/geoService';
import { AIRouteService } from '../../services/aiRouteService';
import { StorageService } from '../../services/storageService';

interface ReportGarbageWizardProps {
  user: ResidentUser;
  onBack: () => void;
  onNavigateTab: (tab: ResidentTab) => void;
  onSubmitSuccess: (newReport: GarbageReport) => void;
}

export const ReportGarbageWizard: React.FC<ReportGarbageWizardProps> = ({
  user,
  onBack,
  onNavigateTab,
  onSubmitSuccess,
}) => {
  // Wizard Step: 1 = Location, 2 = Photo, 3 = Info, 4 = Confirmation, 5 = Success
  const [step, setStep] = useState<1 | 2 | 3 | 4 | 5>(1);

  // Form State
  const [coords, setCoords] = useState<{ lat: number; lng: number }>({
    lat: 9.7548,
    lng: 122.4038,
  });
  const [address, setAddress] = useState('Poblacion Plaza Road, Barangay 1, Sipalay City');
  const [locating, setLocating] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);

  // Photo
  const [photoUrl, setPhotoUrl] = useState<string>('');
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [isWebcamActive, setIsWebcamActive] = useState(false);
  const [cameraFlash, setCameraFlash] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Info
  const [garbageType, setGarbageType] = useState<GarbageType>('Household Waste');
  const [estimatedAmount, setEstimatedAmount] = useState<EstimatedAmount>('Medium');
  const [description, setDescription] = useState('');

  // Result
  const [submittedReport, setSubmittedReport] = useState<GarbageReport | null>(null);

  const garbageTypesList: GarbageType[] = [
    'Household Waste',
    'Plastic',
    'Food Waste',
    'Mixed Waste',
    'Recyclable',
    'Bulky Waste',
    'Other',
  ];

  const amountsList: { id: EstimatedAmount; label: string; desc: string }[] = [
    { id: 'Small', label: 'Small', desc: '1–2 small grocery bags' },
    { id: 'Medium', label: 'Medium', desc: '3–5 standard trash bags' },
    { id: 'Large', label: 'Large', desc: 'Large pile or full barrel' },
    { id: 'Very Large', label: 'Very Large', desc: 'Street overflow / bulky furniture' },
  ];

  // Auto-request GPS location upon entering Step 1 (Section 5 Spec)
  useEffect(() => {
    handleRequestGpsLocation();
  }, []);

  const handleRequestGpsLocation = async () => {
    setLocating(true);
    setLocationError(null);
    try {
      const pos = await GeoService.getCurrentPosition();
      setCoords({ lat: pos.latitude, lng: pos.longitude });
      const addr = GeoService.approximateAddress(pos.latitude, pos.longitude);
      setAddress(addr);
    } catch (err: any) {
      console.warn('GPS location notice:', err.message);
      setLocationError(err.message || 'Unable to determine location. You can select location manually.');
      // Keep Sipalay default
      setAddress(GeoService.approximateAddress(coords.lat, coords.lng));
    } finally {
      setLocating(false);
    }
  };

  // Manual location selection via pin drag / quick presets in Sipalay
  const handleSelectPresetLocation = (lat: number, lng: number, name: string) => {
    setCoords({ lat, lng });
    setAddress(`${name}, Sipalay City, Negros Occidental`);
  };

  // Camera Viewfinder functions
  const handleOpenCamera = async () => {
    setIsCameraOpen(true);
    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment', width: { ideal: 640 } },
        });
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          setIsWebcamActive(true);
        }
      }
    } catch {
      setIsWebcamActive(false);
    }
  };

  const handleCloseCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
    setIsWebcamActive(false);
    setIsCameraOpen(false);
  };

  const handleSnapPhoto = () => {
    setCameraFlash(true);
    setTimeout(() => setCameraFlash(false), 200);

    if (isWebcamActive && videoRef.current) {
      const canvas = document.createElement('canvas');
      canvas.width = videoRef.current.videoWidth || 400;
      canvas.height = videoRef.current.videoHeight || 300;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
        setPhotoUrl(canvas.toDataURL('image/jpeg', 0.8));
        handleCloseCamera();
        return;
      }
    }

    // High quality incident snapshot fallback
    const samples = [
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1605600659873-d808a13e4d2a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=400&q=80',
    ];
    setPhotoUrl(samples[Math.floor(Math.random() * samples.length)]);
    handleCloseCamera();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      try {
        const compressed = await GeoService.compressImage(file);
        setPhotoUrl(compressed);
      } catch {
        const reader = new FileReader();
        reader.onload = (ev) => {
          if (typeof ev.target?.result === 'string') setPhotoUrl(ev.target.result);
        };
        reader.readAsDataURL(file);
      }
    }
  };

  // Final Submission
  const handleFinalSubmit = () => {
    const reportId = AIRouteService.generateReportId();
    const existingReports = StorageService.getReports();

    const priority = AIRouteService.evaluateReportPriority(
      { garbageType, estimatedAmount, latitude: coords.lat, longitude: coords.lng },
      existingReports
    );

    const newReport: GarbageReport = {
      id: reportId,
      userId: user.id,
      userName: user.name,
      garbageType,
      estimatedAmount,
      description: description.trim() || undefined,
      photoUrl: photoUrl || 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80',
      latitude: coords.lat,
      longitude: coords.lng,
      address,
      status: 'Pending',
      priority,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Save to storage
    StorageService.addReport(newReport);

    // Create confirmation notification
    const confirmationNotif = {
      id: `notif-${Date.now()}`,
      userId: user.id,
      title: 'Report Submitted',
      message: `Your garbage report ${newReport.id} has been submitted and queued for verification.`,
      type: 'report_status' as const,
      reportId: newReport.id,
      read: false,
      createdAt: 'Just now',
    };
    const currentNotifs = StorageService.getNotifications();
    StorageService.saveNotifications([confirmationNotif, ...currentNotifs]);

    setSubmittedReport(newReport);
    setStep(5);

    try {
      confetti({ particleCount: 70, spread: 70, origin: { y: 0.6 } });
    } catch {}

    // Trigger AI progression simulation in background
    AIRouteService.simulateReportProgression(newReport.id, (updated, notif) => {
      // Background callback
    });

    onSubmitSuccess(newReport);
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F8FAFC] text-slate-800 select-none overflow-hidden font-sans">
      {/* Top Header with Steps Indicator */}
      <div className="bg-white/95 backdrop-blur-md px-5 pt-1 pb-3 border-b border-slate-100 shadow-xs z-10 shrink-0">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          <button
            onClick={() => {
              if (step > 1 && step < 5) setStep((prev) => (prev - 1) as any);
              else onBack();
            }}
            className="p-1.5 -ml-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer active:scale-95"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <div className="text-center">
            <h1 className="text-sm font-black text-slate-900 font-['Outfit']">
              Report Garbage
            </h1>
            <p className="text-[10px] text-emerald-800 font-bold">
              {step === 1 && 'Step 1 of 4: Location'}
              {step === 2 && 'Step 2 of 4: Photo'}
              {step === 3 && 'Step 3 of 4: Information'}
              {step === 4 && 'Step 4 of 4: Review'}
              {step === 5 && 'Submission Completed'}
            </p>
          </div>

          <button
            onClick={onBack}
            className="text-xs text-slate-400 hover:text-slate-700 font-semibold cursor-pointer"
          >
            Cancel
          </button>
        </div>

        {/* Step Progress Bar */}
        {step < 5 && (
          <div className="flex items-center gap-1.5 mt-3">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className={`h-1.5 flex-1 rounded-full transition-all ${
                  i <= step ? 'bg-emerald-600' : 'bg-slate-200'
                }`}
              />
            ))}
          </div>
        )}
      </div>

      {/* Main Form Content */}
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4 no-scrollbar">
        {/* ================= STEP 1: GPS LOCATION ================= */}
        {step === 1 && (
          <div className="space-y-4">
            <div className="clay-card p-4">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
                  Garbage Location
                </h2>
                <button
                  onClick={handleRequestGpsLocation}
                  disabled={locating}
                  className="flex items-center gap-1 text-[11px] font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1 rounded-full transition-colors cursor-pointer"
                >
                  <Locate className={`w-3.5 h-3.5 ${locating ? 'animate-spin' : ''}`} />
                  <span>{locating ? 'Locating...' : 'Use GPS'}</span>
                </button>
              </div>

              {locationError && (
                <div className="mb-3 p-2.5 rounded-xl bg-amber-50 border border-amber-200 text-[11px] text-amber-800 flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                  <span>{locationError}</span>
                </div>
              )}

              {/* Interactive Location Pin Display (Section 5 Spec) */}
              <div className="relative w-full h-44 rounded-2xl bg-[#E2E8F0] overflow-hidden border border-slate-200 shadow-inner flex flex-col items-center justify-center">
                {/* Visual Map Surface */}
                <div className="absolute inset-0 bg-[radial-gradient(#CBD5E1_1px,transparent_1px)] [background-size:16px_16px] bg-[#E8F5E9]/60"></div>

                {/* Simulated Roads of Sipalay */}
                <svg className="absolute inset-0 w-full h-full" viewBox="0 0 300 170" fill="none">
                  <path d="M-20 80 Q100 90 200 40 L320 30" stroke="#CBD5E1" strokeWidth="18" />
                  <path d="M80 -20 Q120 100 160 190" stroke="#CBD5E1" strokeWidth="16" />
                  <path d="M-20 80 Q100 90 200 40 L320 30" stroke="#FFFFFF" strokeWidth="10" />
                  <path d="M80 -20 Q120 100 160 190" stroke="#FFFFFF" strokeWidth="8" />
                </svg>

                {/* Big Center Interactive Pin */}
                <div className="relative z-10 flex flex-col items-center animate-bounce">
                  <div className="w-10 h-10 rounded-full bg-emerald-600 text-white flex items-center justify-center shadow-lg border-2 border-white">
                    <MapPin className="w-6 h-6 stroke-[2.4]" />
                  </div>
                  <div className="w-4 h-1.5 bg-black/30 rounded-full mt-0.5 filter blur-[1px]"></div>
                </div>

                <div className="absolute bottom-2 left-2 right-2 bg-white/95 backdrop-blur-md px-3 py-1.5 rounded-xl border border-slate-200 text-center shadow-sm">
                  <span className="text-[10px] text-slate-500 font-bold uppercase tracking-wider block">
                    Your Reported Location
                  </span>
                  <span className="text-xs font-bold text-slate-900 truncate block">
                    {address}
                  </span>
                  <span className="text-[9px] font-mono text-emerald-800 font-semibold block">
                    {coords.lat.toFixed(5)}°N, {coords.lng.toFixed(5)}°E
                  </span>
                </div>
              </div>

              {/* Quick Landmark Presets for Sipalay City */}
              <div className="mt-3">
                <span className="text-[10px] font-bold text-slate-400 block mb-1.5 uppercase">
                  Or select a common area in Sipalay:
                </span>
                <div className="grid grid-cols-2 gap-2 text-left">
                  <button
                    type="button"
                    onClick={() => handleSelectPresetLocation(9.7548, 122.4038, 'Poblacion Plaza')}
                    className="p-2 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[11px] font-semibold text-slate-700 truncate cursor-pointer"
                  >
                    📍 Poblacion Plaza
                  </button>
                  <button
                    type="button"
                    onClick={() => handleSelectPresetLocation(9.7535, 122.4048, 'Public Market')}
                    className="p-2 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[11px] font-semibold text-slate-700 truncate cursor-pointer"
                  >
                    📍 Public Market
                  </button>
                  <button
                    type="button"
                    onClick={() => handleSelectPresetLocation(9.7485, 122.4072, 'Barangay 2 Health Center')}
                    className="p-2 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[11px] font-semibold text-slate-700 truncate cursor-pointer"
                  >
                    📍 Barangay 2 Center
                  </button>
                  <button
                    type="button"
                    onClick={() => handleSelectPresetLocation(9.7425, 122.4135, 'Barangay 3 Station')}
                    className="p-2 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[11px] font-semibold text-slate-700 truncate cursor-pointer"
                  >
                    📍 Barangay 3 Depot
                  </button>
                </div>
              </div>
            </div>

            <button
              onClick={() => setStep(2)}
              className="w-full py-4 px-6 clay-button-primary text-white font-extrabold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-md uppercase"
            >
              <span>Confirm Location & Continue</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* ================= STEP 2: TAKE/UPLOAD PHOTO ================= */}
        {step === 2 && (
          <div className="space-y-4">
            <div className="clay-card p-4">
              <h2 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit'] mb-1">
                Attach Garbage Photo
              </h2>
              <p className="text-[11px] text-slate-500 leading-tight mb-3">
                A clear photo helps the dispatch team identify equipment requirements and prioritize collection.
              </p>

              {/* Photo Preview or Placeholder */}
              {photoUrl ? (
                <div className="relative w-full h-52 rounded-2xl overflow-hidden border border-slate-200 shadow-inner group">
                  <img src={photoUrl} alt="Reported garbage" className="w-full h-full object-cover" />
                  <div className="absolute top-2 right-2 flex gap-1.5">
                    <button
                      onClick={() => setPhotoUrl('')}
                      className="p-1.5 rounded-full bg-black/70 text-white hover:bg-black cursor-pointer"
                      title="Remove Photo"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                  <div className="absolute bottom-2 left-2 bg-black/60 backdrop-blur-md px-3 py-1 rounded-full text-[10px] text-white font-semibold">
                    ✓ Photo Compressed & Ready
                  </div>
                </div>
              ) : (
                <div className="w-full h-44 rounded-2xl border-2 border-dashed border-slate-300 bg-slate-50 flex flex-col items-center justify-center text-slate-400 p-4">
                  <Camera className="w-10 h-10 stroke-[1.5] text-slate-400 mb-2" />
                  <span className="text-xs font-bold text-slate-700">No Photo Selected</span>
                  <span className="text-[10px] text-slate-400 mt-0.5">Use camera or choose from gallery</span>
                </div>
              )}

              {/* Action Buttons: Camera & Gallery */}
              <div className="grid grid-cols-2 gap-3 mt-4">
                <button
                  type="button"
                  onClick={handleOpenCamera}
                  className="py-3 px-4 clay-button-secondary text-slate-800 font-bold text-xs flex items-center justify-center gap-2 cursor-pointer active:scale-95"
                >
                  <Camera className="w-4 h-4 text-emerald-700 stroke-[2.2]" />
                  <span>Take Photo</span>
                </button>

                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="py-3 px-4 clay-button-secondary text-slate-800 font-bold text-xs flex items-center justify-center gap-2 cursor-pointer active:scale-95"
                >
                  <ImageIcon className="w-4 h-4 text-emerald-700 stroke-[2.2]" />
                  <span>Choose Gallery</span>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    className="hidden"
                  />
                </button>
              </div>

              {/* Sample Photo Generator if user is testing on desktop */}
              <div className="mt-3 text-center">
                <button
                  type="button"
                  onClick={() => {
                    setPhotoUrl('https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80');
                  }}
                  className="text-[11px] font-bold text-emerald-700 hover:underline cursor-pointer"
                >
                  + Use Sample Waste Photo (Demo)
                </button>
              </div>
            </div>

            <button
              onClick={() => {
                if (!photoUrl) {
                  // Prompt notice
                  setPhotoUrl('https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80');
                }
                setStep(3);
              }}
              className="w-full py-4 px-6 clay-button-primary text-white font-extrabold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-md uppercase"
            >
              <span>Continue to Waste Details</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* ================= STEP 3: GARBAGE INFORMATION ================= */}
        {step === 3 && (
          <div className="space-y-4">
            <div className="clay-card p-4 space-y-4">
              {/* Garbage Type Selector (Section 5 Spec) */}
              <div>
                <label className="text-xs font-black text-slate-900 block mb-2 font-['Outfit'] uppercase tracking-wider">
                  Garbage Type
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {garbageTypesList.map((type) => {
                    const isSelected = garbageType === type;
                    return (
                      <button
                        key={type}
                        type="button"
                        onClick={() => setGarbageType(type)}
                        className={`p-2.5 rounded-xl text-xs font-bold text-left transition-all cursor-pointer ${
                          isSelected
                            ? 'clay-button-primary text-white shadow-xs'
                            : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border border-slate-200'
                        }`}
                      >
                        {type}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Estimated Amount Selector (Section 5 Spec: Small, Medium, Large, Very Large) */}
              <div>
                <label className="text-xs font-black text-slate-900 block mb-2 font-['Outfit'] uppercase tracking-wider">
                  Estimated Amount
                </label>
                <div className="space-y-2">
                  {amountsList.map((item) => {
                    const isSelected = estimatedAmount === item.id;
                    return (
                      <div
                        key={item.id}
                        onClick={() => setEstimatedAmount(item.id)}
                        className={`p-3 rounded-2xl flex items-center justify-between cursor-pointer transition-all ${
                          isSelected
                            ? 'clay-card-mint text-emerald-950 font-bold border-2 border-emerald-500'
                            : 'bg-slate-50 text-slate-700 border border-slate-200'
                        }`}
                      >
                        <div>
                          <span className="text-xs font-bold block">{item.label}</span>
                          <span className="text-[10px] text-slate-500 font-normal">{item.desc}</span>
                        </div>
                        <div
                          className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                            isSelected ? 'border-emerald-600 bg-emerald-600' : 'border-slate-300'
                          }`}
                        >
                          {isSelected && <div className="w-1.5 h-1.5 rounded-full bg-white"></div>}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Description (Optional) */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="text-xs font-black text-slate-900 font-['Outfit'] uppercase tracking-wider">
                    Description (Optional)
                  </label>
                  <span className="text-[10px] text-slate-400 font-mono">{description.length}/200</span>
                </div>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value.slice(0, 200))}
                  placeholder="e.g. Several garbage bags placed beside the curb near electric post."
                  rows={3}
                  className="w-full p-3 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none resize-none"
                />
              </div>
            </div>

            <button
              onClick={() => setStep(4)}
              className="w-full py-4 px-6 clay-button-primary text-white font-extrabold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-md uppercase"
            >
              <span>Review Report</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* ================= STEP 4: REPORT CONFIRMATION ================= */}
        {step === 4 && (
          <div className="space-y-4">
            <div className="clay-card p-4 space-y-3.5">
              <h2 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
                Report Summary
              </h2>

              {/* Photo preview */}
              <div className="relative w-full h-36 rounded-2xl overflow-hidden border border-slate-200">
                <img src={photoUrl} alt="Report preview" className="w-full h-full object-cover" />
                <div className="absolute top-2 left-2 bg-emerald-600 text-white font-extrabold text-[10px] px-2.5 py-0.5 rounded-full">
                  {garbageType}
                </div>
              </div>

              {/* Details table */}
              <div className="bg-slate-50 rounded-2xl p-3.5 space-y-2 text-xs border border-slate-100 divide-y divide-slate-200/60">
                <div className="flex items-center justify-between pt-1">
                  <span className="text-slate-500 font-medium">Garbage Type</span>
                  <span className="font-bold text-slate-900">{garbageType}</span>
                </div>

                <div className="flex items-center justify-between pt-2">
                  <span className="text-slate-500 font-medium">Estimated Amount</span>
                  <span className="font-bold text-slate-900">{estimatedAmount}</span>
                </div>

                <div className="pt-2">
                  <span className="text-slate-500 font-medium block">Location</span>
                  <span className="font-bold text-slate-900 block mt-0.5">{address}</span>
                  <span className="text-[10px] text-slate-400 font-mono block">
                    {coords.lat.toFixed(5)}°N, {coords.lng.toFixed(5)}°E
                  </span>
                </div>

                {description && (
                  <div className="pt-2">
                    <span className="text-slate-500 font-medium block">Description</span>
                    <span className="text-slate-700 italic block mt-0.5">"{description}"</span>
                  </div>
                )}

                <div className="flex items-center justify-between pt-2">
                  <span className="text-slate-500 font-medium">Reporting Resident</span>
                  <span className="font-bold text-slate-900">{user.name}</span>
                </div>
              </div>
            </div>

            {/* Submit Action (Section 6 Spec) */}
            <button
              onClick={handleFinalSubmit}
              className="w-full py-4 px-6 clay-button-primary text-white font-extrabold text-xs tracking-wide flex items-center justify-center gap-2 cursor-pointer shadow-lg uppercase"
            >
              <span>SUBMIT REPORT</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* ================= STEP 5: SUBMITTED SUCCESS ================= */}
        {step === 5 && submittedReport && (
          <div className="clay-card p-6 flex flex-col items-center text-center space-y-3">
            <div className="w-18 h-18 rounded-full clay-card-mint flex items-center justify-center text-emerald-600 mb-1 animate-float">
              <CheckCircle2 className="w-10 h-10 stroke-[2.4]" />
            </div>

            <h2 className="text-lg font-black text-slate-900 font-['Outfit']">
              Garbage report submitted successfully.
            </h2>

            <div className="p-3 bg-emerald-50 rounded-2xl border border-emerald-200/80 w-full">
              <span className="text-[10px] text-emerald-800 font-bold uppercase tracking-wider block">
                Unique Report ID
              </span>
              <span className="text-base font-black font-mono text-emerald-900 block mt-0.5">
                {submittedReport.id}
              </span>
            </div>

            <p className="text-xs text-slate-500 leading-relaxed max-w-[260px]">
              Your report is now <span className="font-bold text-amber-700">Pending</span>. The dispatch system will review and schedule collection.
            </p>

            <div className="w-full pt-3 space-y-2">
              <button
                onClick={() => onNavigateTab('home')}
                className="w-full py-3.5 clay-button-primary text-white font-extrabold text-xs uppercase cursor-pointer"
              >
                Back to Home Dashboard
              </button>

              <button
                onClick={() => {
                  setStep(1);
                  setPhotoUrl('');
                  setDescription('');
                }}
                className="w-full py-3 clay-button-secondary text-slate-700 font-bold text-xs cursor-pointer"
              >
                Submit Another Report
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Camera Viewfinder Modal */}
      {isCameraOpen && (
        <div className="absolute inset-0 z-50 bg-black flex flex-col justify-between text-white animate-in fade-in duration-200">
          <div className="px-5 pt-3 pb-2 flex items-center justify-between z-10 bg-gradient-to-b from-black/80 to-transparent">
            <button
              onClick={handleCloseCamera}
              className="p-2 rounded-full bg-white/20 text-white cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
            <span className="text-xs font-bold text-emerald-400 uppercase tracking-widest">
              Garbage Photo Capture
            </span>
            <button
              onClick={() => setIsWebcamActive(!isWebcamActive)}
              className="p-2 rounded-full bg-white/20 text-white cursor-pointer"
            >
              <FlipHorizontal className="w-5 h-5" />
            </button>
          </div>

          <div className="relative flex-1 flex items-center justify-center overflow-hidden bg-slate-950">
            {cameraFlash && <div className="absolute inset-0 bg-white z-40"></div>}

            {isWebcamActive ? (
              <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover" />
            ) : (
              <img
                src="https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=640&q=80"
                alt="Camera viewfinder simulation"
                className="w-full h-full object-cover"
              />
            )}

            <div className="absolute inset-6 border border-white/30 rounded-2xl pointer-events-none flex items-center justify-center">
              <div className="w-12 h-12 border-2 border-emerald-400 rounded-full animate-pulse"></div>
            </div>

            <div className="absolute bottom-4 left-4 bg-black/60 px-3 py-1 rounded-full text-[10px]">
              📍 GPS: {coords.lat.toFixed(4)}°N, {coords.lng.toFixed(4)}°E
            </div>
          </div>

          <div className="py-6 px-8 flex items-center justify-around bg-black/90 z-10">
            <div className="w-10"></div>
            <button
              type="button"
              onClick={handleSnapPhoto}
              className="w-18 h-18 rounded-full border-4 border-white flex items-center justify-center p-1 active:scale-90 cursor-pointer"
            >
              <div className="w-full h-full rounded-full bg-emerald-500"></div>
            </button>
            <button onClick={handleSnapPhoto} className="text-xs text-emerald-400 font-bold cursor-pointer">
              Snap
            </button>
          </div>
        </div>
      )}

      {/* 5-Tab Bottom Nav */}
      <ResidentBottomNav
        activeTab="report"
        onTabChange={onNavigateTab}
        unreadCount={0}
      />
    </div>
  );
};
