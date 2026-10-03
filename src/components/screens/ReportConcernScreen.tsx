import React, { useState, useRef, useEffect } from 'react';
import {
  ChevronLeft,
  Camera,
  Image as ImageIcon,
  CheckCircle,
  X,
  FlipHorizontal,
  Zap,
  Sparkles,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { StatusBar } from '../common/StatusBar';
import { BottomNav } from '../common/BottomNav';
import { BottomNavTab } from '../../types';

interface ReportConcernScreenProps {
  onBack: () => void;
  onNavigateTab: (tab: BottomNavTab) => void;
  onSubmitSuccess?: () => void;
}

export const ReportConcernScreen: React.FC<ReportConcernScreenProps> = ({
  onBack,
  onNavigateTab,
  onSubmitSuccess,
}) => {
  const [concernType, setConcernType] = useState<
    'Missed Collection' | 'Uncollected Waste' | 'Route Concern' | 'Other Concern'
  >('Missed Collection');
  const [description, setDescription] = useState('');
  const [photos, setPhotos] = useState<string[]>([]);
  const [isSubmitted, setIsSubmitted] = useState(false);

  // In-app Camera Viewfinder State
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [cameraFlash, setCameraFlash] = useState(false);
  const [isWebcamActive, setIsWebcamActive] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const concernOptions = [
    'Missed Collection',
    'Uncollected Waste',
    'Route Concern',
    'Other Concern',
  ] as const;

  // Open simulated or real camera viewfinder
  const handleOpenCamera = async () => {
    setIsCameraOpen(true);
    // Attempt to access user webcam if available
    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment', width: { ideal: 640 }, height: { ideal: 480 } },
        });
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          setIsWebcamActive(true);
        }
      }
    } catch {
      // Fallback to high-quality simulated camera viewfinder
      setIsWebcamActive(false);
    }
  };

  const handleCloseCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    setIsWebcamActive(false);
    setIsCameraOpen(false);
  };

  const handleSnapPhoto = () => {
    setCameraFlash(true);
    setTimeout(() => setCameraFlash(false), 200);

    // If real webcam active, capture canvas frame
    if (isWebcamActive && videoRef.current) {
      const canvas = document.createElement('canvas');
      canvas.width = videoRef.current.videoWidth || 400;
      canvas.height = videoRef.current.videoHeight || 300;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
        setPhotos((prev) => [...prev, dataUrl]);
        handleCloseCamera();
        return;
      }
    }

    // High quality waste incident snapshots
    const samplePhotos = [
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1605600659873-d808a13e4d2a?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=400&q=80',
    ];
    const picked = samplePhotos[photos.length % samplePhotos.length];
    setPhotos((prev) => [...prev, picked]);
    handleCloseCamera();
  };

  const handleAddSamplePhoto = () => {
    if (photos.length >= 3) return;
    const samplePhotos = [
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1605600659873-d808a13e4d2a?auto=format&fit=crop&w=400&q=80',
    ];
    setPhotos([...photos, samplePhotos[photos.length % samplePhotos.length]]);
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event: ProgressEvent<FileReader>) => {
        const result = event.target?.result;
        if (typeof result === 'string') {
          setPhotos((prev) => [...prev, result]);
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitted(true);
    try {
      confetti({
        particleCount: 50,
        spread: 60,
        origin: { y: 0.7 },
      });
    } catch {
      // ignore
    }

    setTimeout(() => {
      if (onSubmitSuccess) onSubmitSuccess();
    }, 1500);
  };

  // Cleanup camera stream on unmount
  useEffect(() => {
    return () => {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-slate-50 text-slate-800 select-none overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-1 pb-3 bg-white/95 backdrop-blur-md border-b border-slate-100 shrink-0 shadow-xs">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          <button
            onClick={onBack}
            className="p-1.5 -ml-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer active:scale-95"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <h1 className="text-base font-extrabold text-slate-900 font-['Outfit']">
            Report a Concern
          </h1>

          <div className="w-5"></div>
        </div>
      </div>

      {/* Form Content with Claymorphism */}
      <div className="flex-1 overflow-y-auto px-5 py-4 no-scrollbar">
        {isSubmitted ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4 py-8">
            <div className="w-20 h-20 rounded-full clay-card-mint flex items-center justify-center mb-4 text-emerald-600 animate-float">
              <CheckCircle className="w-10 h-10 stroke-[2.2]" />
            </div>
            <h2 className="text-xl font-extrabold text-slate-900 font-['Outfit']">
              Report Submitted!
            </h2>
            <p className="text-xs text-slate-500 mt-1.5 max-w-[240px] leading-relaxed">
              Thank you for keeping Sipalay City clean. Our sanitation dispatch team has received your ticket.
            </p>
            <button
              onClick={() => {
                setIsSubmitted(false);
                setDescription('');
                setPhotos([]);
                onBack();
              }}
              className="mt-6 py-3 px-8 clay-button-primary text-white font-bold text-xs cursor-pointer"
            >
              Done
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Concern Type Card (Claymorphism) */}
            <div className="clay-card p-4">
              <label className="text-xs font-bold text-slate-900 block mb-2.5 font-['Outfit'] tracking-tight">
                Concern Type
              </label>

              <div className="space-y-2">
                {concernOptions.map((type) => {
                  const isChecked = concernType === type;
                  return (
                    <label
                      key={type}
                      onClick={() => setConcernType(type)}
                      className={`flex items-center gap-3 p-3 rounded-2xl transition-all cursor-pointer ${
                        isChecked
                          ? 'clay-card-mint text-emerald-950 font-bold'
                          : 'bg-slate-50 hover:bg-slate-100 text-slate-700'
                      }`}
                    >
                      <div
                        className={`w-4 h-4 rounded-full border-2 flex items-center justify-center transition-colors ${
                          isChecked
                            ? 'border-emerald-600 bg-emerald-600'
                            : 'border-slate-300 bg-white'
                        }`}
                      >
                        {isChecked && <div className="w-1.5 h-1.5 rounded-full bg-white"></div>}
                      </div>
                      <span className="text-xs">{type}</span>
                    </label>
                  );
                })}
              </div>
            </div>

            {/* Description Card (Claymorphism) */}
            <div className="clay-card p-4">
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold text-slate-900 font-['Outfit']">
                  Description
                </label>
                <span className="text-[11px] text-slate-400 font-mono">
                  {description.length}/300
                </span>
              </div>

              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value.slice(0, 300))}
                rows={3}
                placeholder="Please describe your concern..."
                className="w-full p-3.5 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none resize-none"
                required
              />
            </div>

            {/* Add Photos (Claymorphic Buttons) */}
            <div className="clay-card p-4">
              <label className="text-xs font-bold text-slate-900 block mb-2 font-['Outfit']">
                Add Photos (optional)
              </label>

              <div className="flex items-center gap-3">
                {/* Real In-App Camera Button */}
                <button
                  type="button"
                  onClick={handleOpenCamera}
                  className="w-16 h-16 rounded-2xl clay-button-secondary flex flex-col items-center justify-center text-slate-700 cursor-pointer active:scale-95 transition-all group"
                  title="Open Camera Viewfinder"
                >
                  <Camera className="w-6 h-6 stroke-[2] text-emerald-700 group-hover:scale-110 transition-transform" />
                  <span className="text-[9px] font-bold text-slate-600 mt-1">Camera</span>
                </button>

                {/* Gallery File Upload Button */}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-16 h-16 rounded-2xl clay-button-secondary flex flex-col items-center justify-center text-slate-700 cursor-pointer active:scale-95 transition-all group"
                  title="Upload from Gallery"
                >
                  <ImageIcon className="w-6 h-6 stroke-[2] text-slate-600 group-hover:scale-110 transition-transform" />
                  <span className="text-[9px] font-bold text-slate-600 mt-1">Gallery</span>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileUpload}
                    className="hidden"
                  />
                </button>

                {/* Quick Sample Photo Demo Button */}
                <button
                  type="button"
                  onClick={handleAddSamplePhoto}
                  className="px-3.5 py-2.5 clay-button-secondary text-emerald-700 text-[11px] font-bold rounded-2xl cursor-pointer"
                >
                  + Sample Photo
                </button>
              </div>

              {/* Photo Previews */}
              {photos.length > 0 && (
                <div className="flex items-center gap-2.5 mt-3 pt-3 border-t border-slate-100">
                  {photos.map((src, i) => (
                    <div
                      key={i}
                      className="relative w-16 h-16 rounded-xl overflow-hidden border border-slate-200 shadow-sm"
                    >
                      <img
                        src={src}
                        alt="Uploaded evidence"
                        className="w-full h-full object-cover"
                      />
                      <button
                        type="button"
                        onClick={() => setPhotos(photos.filter((_, idx) => idx !== i))}
                        className="absolute top-1 right-1 w-5 h-5 bg-black/70 text-white rounded-full flex items-center justify-center hover:bg-black cursor-pointer"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Submit Button (Claymorphic CTA) */}
            <div className="pt-2">
              <button
                type="submit"
                className="w-full py-4 px-6 clay-button-primary text-white font-bold text-xs tracking-wide cursor-pointer text-center"
              >
                Submit Report
              </button>
            </div>
          </form>
        )}
      </div>

      {/* In-App Camera Viewfinder Modal (Fixes simulator camera glitch) */}
      {isCameraOpen && (
        <div className="absolute inset-0 z-50 bg-black flex flex-col justify-between text-white animate-in fade-in duration-200">
          {/* Camera Header */}
          <div className="px-5 pt-3 pb-2 flex items-center justify-between z-10 bg-gradient-to-b from-black/80 to-transparent">
            <button
              onClick={handleCloseCamera}
              className="p-2 rounded-full bg-white/20 text-white hover:bg-white/30 cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
            <span className="text-xs font-bold tracking-wider uppercase text-emerald-400 flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-ping"></span>
              Sipalay CENRO Camera
            </span>
            <button
              onClick={() => setIsWebcamActive(!isWebcamActive)}
              className="p-2 rounded-full bg-white/20 text-white hover:bg-white/30 cursor-pointer"
            >
              <FlipHorizontal className="w-5 h-5" />
            </button>
          </div>

          {/* Camera Viewfinder Area */}
          <div className="relative flex-1 flex items-center justify-center overflow-hidden bg-slate-950">
            {/* Flash Effect Overlay */}
            {cameraFlash && (
              <div className="absolute inset-0 bg-white z-40 animate-out fade-out duration-200"></div>
            )}

            {isWebcamActive ? (
              <video
                ref={videoRef}
                autoPlay
                playsInline
                muted
                className="w-full h-full object-cover"
              />
            ) : (
              /* Simulated Realistic Waste Inspection Viewfinder */
              <div className="relative w-full h-full">
                <img
                  src="https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=640&q=80"
                  alt="Camera Preview"
                  className="w-full h-full object-cover filter brightness-95"
                />
                <div className="absolute inset-0 bg-radial from-transparent to-black/30"></div>
              </div>
            )}

            {/* Viewfinder Grid Overlay & Crosshair */}
            <div className="absolute inset-6 border border-white/30 rounded-2xl pointer-events-none flex items-center justify-center">
              <div className="w-12 h-12 border-2 border-emerald-400/80 rounded-full flex items-center justify-center animate-pulse">
                <div className="w-1.5 h-1.5 bg-emerald-400 rounded-full"></div>
              </div>
            </div>

            <div className="absolute bottom-4 left-4 bg-black/60 backdrop-blur-md px-3 py-1 rounded-full text-[10px] text-white/90">
              📍 Barangay 1, Sipalay City (GPS Tagged)
            </div>
          </div>

          {/* Camera Shutter Bottom Controls */}
          <div className="py-6 px-8 flex items-center justify-around bg-black/90 z-10">
            <div className="w-10"></div>

            {/* Large Shutter Button */}
            <button
              type="button"
              onClick={handleSnapPhoto}
              className="w-18 h-18 rounded-full border-4 border-white flex items-center justify-center active:scale-90 transition-transform cursor-pointer p-1"
            >
              <div className="w-full h-full rounded-full bg-emerald-500 hover:bg-emerald-400 shadow-lg"></div>
            </button>

            <button
              onClick={handleSnapPhoto}
              className="text-xs text-emerald-400 font-bold hover:underline cursor-pointer"
            >
              Snap
            </button>
          </div>
        </div>
      )}

      {/* Bottom Nav */}
      <BottomNav activeTab="report" onTabChange={onNavigateTab} unreadAlertsCount={2} />
    </div>
  );
};
