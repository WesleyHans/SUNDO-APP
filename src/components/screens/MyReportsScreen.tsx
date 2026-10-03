import React, { useState } from 'react';
import {
  ChevronLeft,
  Filter,
  Search,
  Clock,
  MapPin,
  CheckCircle2,
  Calendar,
  AlertCircle,
  XCircle,
  Plus,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { ResidentBottomNav } from '../layout/BottomNav';
import {
  GarbageReport,
  ReportStatus,
  ResidentTab,
} from '../../types/resident';

interface MyReportsScreenProps {
  reports: GarbageReport[];
  initialFilter?: ReportStatus | 'All';
  onBack: () => void;
  onNavigateTab: (tab: ResidentTab) => void;
  onSelectReport: (report: GarbageReport) => void;
  onNewReport: () => void;
}

export const MyReportsScreen: React.FC<MyReportsScreenProps> = ({
  reports,
  initialFilter = 'All',
  onBack,
  onNavigateTab,
  onSelectReport,
  onNewReport,
}) => {
  const [filter, setFilter] = useState<ReportStatus | 'All'>(initialFilter);
  const [searchQuery, setSearchQuery] = useState('');

  const filterTabs: (ReportStatus | 'All')[] = [
    'All',
    'Pending',
    'Verified',
    'Scheduled',
    'Collected',
    'Rejected',
  ];

  const filteredReports = reports.filter((r) => {
    if (filter !== 'All' && r.status !== filter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        r.id.toLowerCase().includes(q) ||
        r.garbageType.toLowerCase().includes(q) ||
        r.address.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const getStatusBadge = (status: ReportStatus) => {
    switch (status) {
      case 'Pending':
        return (
          <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-amber-100 text-amber-900 border border-amber-200">
            Pending
          </span>
        );
      case 'Verified':
        return (
          <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-blue-100 text-blue-900 border border-blue-200">
            Verified
          </span>
        );
      case 'Scheduled':
        return (
          <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-900 border border-emerald-200">
            Scheduled
          </span>
        );
      case 'Collected':
        return (
          <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-teal-100 text-teal-900 border border-teal-200">
            Collected
          </span>
        );
      case 'Rejected':
        return (
          <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-rose-100 text-rose-900 border border-rose-200">
            Rejected
          </span>
        );
    }
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F8FAFC] text-slate-800 select-none overflow-hidden font-sans">
      {/* Top Header */}
      <div className="bg-white/95 backdrop-blur-md px-5 pt-1 pb-3 border-b border-slate-100 shadow-xs z-10 shrink-0">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          <button
            onClick={onBack}
            className="p-1.5 -ml-1.5 rounded-full hover:bg-slate-100 text-slate-700 transition-colors cursor-pointer active:scale-95"
            aria-label="Back"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <h1 className="text-base font-black text-slate-900 font-['Outfit']">
            My Reports
          </h1>

          <button
            onClick={onNewReport}
            className="w-8 h-8 rounded-full bg-emerald-600 text-white flex items-center justify-center shadow-sm cursor-pointer hover:bg-emerald-700 active:scale-95"
            title="Submit New Report"
          >
            <Plus className="w-4 h-4 stroke-[2.4]" />
          </button>
        </div>

        {/* Search input */}
        <div className="mt-3 relative flex items-center">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search report ID, type, or address..."
            className="w-full pl-9 pr-3 py-2 clay-input text-xs text-slate-800 placeholder-slate-400 focus:outline-none"
          />
        </div>

        {/* Status Filter Chips (Section 8 Spec: All, Pending, Verified, Scheduled, Collected, Rejected) */}
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pt-3 -mx-2 px-2">
          {filterTabs.map((tab) => {
            const isSelected = filter === tab;
            return (
              <button
                key={tab}
                onClick={() => setFilter(tab)}
                className={`py-1.5 px-3 rounded-full text-[11px] font-extrabold whitespace-nowrap transition-all cursor-pointer ${
                  isSelected
                    ? 'clay-button-primary text-white shadow-xs'
                    : 'bg-slate-100 text-slate-600 hover:text-slate-900 border border-slate-200'
                }`}
              >
                {tab}
              </button>
            );
          })}
        </div>
      </div>

      {/* Reports List */}
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3 no-scrollbar">
        {filteredReports.length === 0 ? (
          <div className="h-64 flex flex-col items-center justify-center text-center p-6">
            <div className="w-14 h-14 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center mb-2">
              <Filter className="w-6 h-6 stroke-[1.8]" />
            </div>
            <h3 className="text-sm font-bold text-slate-700">No reports found</h3>
            <p className="text-xs text-slate-400 mt-1 max-w-[200px]">
              No garbage reports match the current filter "{filter}".
            </p>
          </div>
        ) : (
          filteredReports.map((report) => (
            <div
              key={report.id}
              onClick={() => onSelectReport(report)}
              className="clay-card p-3.5 flex items-start gap-3.5 hover:scale-[1.01] active:scale-[0.98] transition-all cursor-pointer"
            >
              <img
                src={report.photoUrl}
                alt={report.garbageType}
                className="w-16 h-16 rounded-xl object-cover border border-slate-200 shrink-0"
              />

              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between gap-1">
                  <span className="text-[10px] font-mono font-bold text-emerald-800">
                    {report.id}
                  </span>
                  {getStatusBadge(report.status)}
                </div>

                <h4 className="text-xs font-black text-slate-900 mt-0.5 truncate font-['Outfit']">
                  {report.garbageType} • {report.estimatedAmount}
                </h4>

                <p className="text-[11px] text-slate-500 truncate flex items-center gap-1 mt-0.5">
                  <MapPin className="w-3 h-3 text-slate-400 shrink-0" />
                  <span className="truncate">{report.address}</span>
                </p>

                <div className="flex items-center justify-between text-[10px] text-slate-400 font-medium mt-1.5 pt-1.5 border-t border-slate-100">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    <span>{new Date(report.createdAt).toLocaleDateString()}</span>
                  </span>
                  <span className="text-emerald-700 font-bold hover:underline">Track Status →</span>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* 5-Tab Resident Bottom Nav */}
      <ResidentBottomNav
        activeTab="report"
        onTabChange={onNavigateTab}
        unreadCount={0}
      />
    </div>
  );
};
