import React from 'react';
import {
  X,
  MapPin,
  Clock,
  CheckCircle2,
  Calendar,
  Truck,
  AlertCircle,
  XCircle,
  Sparkles,
} from 'lucide-react';
import { GarbageReport, ReportStatus } from '../../types/resident';

interface ReportDetailModalProps {
  report: GarbageReport | null;
  onClose: () => void;
  onViewOnMap?: (report: GarbageReport) => void;
}

export const ReportDetailModal: React.FC<ReportDetailModalProps> = ({
  report,
  onClose,
  onViewOnMap,
}) => {
  if (!report) return null;

  // Timeline steps: Submitted (Pending) -> Verified -> Scheduled -> Collected
  const timelineSteps: { key: ReportStatus; label: string; desc: string }[] = [
    {
      key: 'Pending',
      label: 'Submitted',
      desc: 'Report received and waiting for verification.',
    },
    {
      key: 'Verified',
      label: 'Verified',
      desc: 'Reviewed and confirmed by waste management dispatch.',
    },
    {
      key: 'Scheduled',
      label: 'Scheduled',
      desc: report.assignedRoute
        ? `Included in ${report.assignedRoute}`
        : 'Assigned to upcoming collection route.',
    },
    {
      key: 'Collected',
      label: 'Collected',
      desc: report.collectedAt
        ? `Waste successfully cleared on ${new Date(report.collectedAt).toLocaleDateString()}`
        : 'Garbage has been collected from site.',
    },
  ];

  const getStepState = (stepKey: ReportStatus) => {
    if (report.status === 'Rejected') {
      return stepKey === 'Pending' ? 'completed' : 'inactive';
    }

    const order: ReportStatus[] = ['Pending', 'Verified', 'Scheduled', 'Collected'];
    const currentIndex = order.indexOf(report.status);
    const stepIndex = order.indexOf(stepKey);

    if (stepIndex < currentIndex) return 'completed';
    if (stepIndex === currentIndex) return 'current';
    return 'upcoming';
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 select-none">
      <div className="clay-card w-full max-w-sm max-h-[90vh] overflow-y-auto bg-white p-5 flex flex-col space-y-4 no-scrollbar animate-in zoom-in-95 duration-200">
        {/* Modal Header */}
        <div className="flex items-center justify-between border-b border-slate-100 pb-3">
          <div>
            <span className="text-[10px] font-mono font-bold text-emerald-800 uppercase tracking-widest block">
              Report Status Tracking
            </span>
            <h2 className="text-base font-black text-slate-900 font-['Outfit'] mt-0.5">
              {report.id}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-500 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Photo & Badge */}
        <div className="relative w-full h-44 rounded-2xl overflow-hidden border border-slate-200 shadow-inner">
          <img src={report.photoUrl} alt="Reported garbage" className="w-full h-full object-cover" />
          <div className="absolute top-2.5 left-2.5 bg-slate-900/80 backdrop-blur-md text-white font-extrabold text-[11px] px-3 py-1 rounded-full">
            {report.garbageType} • {report.estimatedAmount}
          </div>
          {report.priority && (
            <div className={`absolute top-2.5 right-2.5 text-white font-extrabold text-[10px] px-2.5 py-1 rounded-full ${
              report.priority === 'Urgent' ? 'bg-red-600' : report.priority === 'High' ? 'bg-amber-600' : 'bg-emerald-600'
            }`}>
              {report.priority} Priority
            </div>
          )}
        </div>

        {/* Rejection Notice if rejected */}
        {report.status === 'Rejected' && (
          <div className="p-3 rounded-2xl bg-rose-50 border border-rose-200 text-xs text-rose-800 space-y-1">
            <div className="flex items-center gap-1.5 font-bold">
              <XCircle className="w-4 h-4 text-rose-600" />
              <span>Report Rejected by Authorized Personnel</span>
            </div>
            <p className="text-[11px] text-rose-700">
              {report.rejectionReason || 'The reported location could not be confirmed as municipal waste or was submitted outside the collection boundary.'}
            </p>
          </div>
        )}

        {/* Progress Timeline (Section 7 Spec) */}
        {report.status !== 'Rejected' && (
          <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 space-y-4">
            <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
              Collection Lifecycle
            </h3>

            <div className="space-y-4 relative">
              {/* Connecting rail */}
              <div className="absolute left-3.5 top-2 bottom-2 w-0.5 bg-slate-200 -z-0"></div>

              {timelineSteps.map((st) => {
                const state = getStepState(st.key);
                return (
                  <div key={st.key} className="flex items-start gap-3 relative z-10">
                    <div
                      className={`w-7 h-7 rounded-full flex items-center justify-center shrink-0 border-2 transition-all ${
                        state === 'completed'
                          ? 'bg-emerald-600 border-emerald-600 text-white shadow-xs'
                          : state === 'current'
                          ? 'bg-emerald-50 border-emerald-600 text-emerald-700 ring-4 ring-emerald-100'
                          : 'bg-white border-slate-300 text-slate-400'
                      }`}
                    >
                      {state === 'completed' ? (
                        <CheckCircle2 className="w-4 h-4 stroke-[2.5]" />
                      ) : state === 'current' ? (
                        <div className="w-2 h-2 rounded-full bg-emerald-600 animate-ping"></div>
                      ) : (
                        <div className="w-1.5 h-1.5 rounded-full bg-slate-300"></div>
                      )}
                    </div>

                    <div className="min-w-0 flex-1 pt-0.5">
                      <div className="flex items-center justify-between">
                        <h4
                          className={`text-xs font-extrabold ${
                            state === 'current'
                              ? 'text-emerald-800'
                              : state === 'completed'
                              ? 'text-slate-900'
                              : 'text-slate-400'
                          }`}
                        >
                          {st.label}
                        </h4>
                        {state === 'current' && (
                          <span className="text-[9px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                            Current Stage
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-slate-500 mt-0.5 leading-snug">{st.desc}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Location & Details Card */}
        <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-2 text-xs">
          <div className="flex items-start gap-2 text-slate-700">
            <MapPin className="w-4 h-4 text-emerald-700 shrink-0 mt-0.5" />
            <div>
              <span className="font-bold text-slate-900 block">{report.address}</span>
              <span className="text-[10px] text-slate-400 font-mono">
                {report.latitude.toFixed(5)}°N, {report.longitude.toFixed(5)}°E
              </span>
            </div>
          </div>

          {report.description && (
            <div className="pt-2 border-t border-slate-200/60 text-slate-600 italic">
              "{report.description}"
            </div>
          )}

          <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-[11px] text-slate-500">
            <span>Reported on:</span>
            <span className="font-bold text-slate-800">
              {new Date(report.createdAt).toLocaleString()}
            </span>
          </div>
        </div>

        {/* View on Map Button */}
        {onViewOnMap && (
          <button
            onClick={() => {
              onClose();
              onViewOnMap(report);
            }}
            className="w-full py-3.5 px-4 clay-button-primary text-white font-extrabold text-xs uppercase cursor-pointer"
          >
            View on Live Map
          </button>
        )}
      </div>
    </div>
  );
};
