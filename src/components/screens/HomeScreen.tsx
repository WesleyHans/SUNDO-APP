import React from 'react';
import {
  PlusCircle,
  Truck,
  Calendar,
  Bell,
  Clock,
  ChevronRight,
  CheckCircle2,
  AlertCircle,
  XCircle,
  MapPin,
  ArrowRight,
} from 'lucide-react';
import { StatusBar } from '../common/StatusBar';
import { ResidentBottomNav } from '../layout/BottomNav';
import {
  ResidentUser,
  GarbageReport,
  ResidentNotification,
  CollectionScheduleItem,
  CollectionVehicle,
  ResidentTab,
  ReportStatus,
} from '../../types/resident';
import { StorageService } from '../../services/storageService';

export interface ResidentHomeScreenProps {
  user?: ResidentUser | any;
  reports?: GarbageReport[];
  notifications?: ResidentNotification[] | any[];
  schedules?: CollectionScheduleItem[];
  vehicle?: CollectionVehicle;
  truck?: any;
  unreadCount?: number;
  onNavigateTab?: (tab: any) => void;
  onOpenReportWizard?: () => void;
  onViewMyReports?: (statusFilter?: ReportStatus | 'All') => void;
  onViewReportDetail?: (report: GarbageReport) => void;
  onViewLiveTruck?: () => void;
  onOpenSchedule?: () => void;
  onOpenReportConcern?: () => void;
  onOpenNotifications?: () => void;
  onOpenWasteGuide?: () => void;
  onOpenProfile?: () => void;
}

export const ResidentHomeScreen: React.FC<ResidentHomeScreenProps> = (props) => {
  // Resolve data either from props or from StorageService
  const user: ResidentUser = {
    id: props.user?.id || 'usr-res-01',
    name: props.user?.name || 'Juan Dela Cruz',
    email: props.user?.email || 'juan@gmail.com',
    mobile: props.user?.phone || props.user?.mobile || '09123456789',
    address: props.user?.address || 'Rizal St., Barangay 1, Sipalay City',
    barangay: props.user?.barangay || 'Barangay 1',
    role: 'resident',
    locationPermission: true,
    createdAt: '2026-09-01T08:00:00Z',
  };

  const reports: GarbageReport[] = props.reports || StorageService.getReports();
  const notifications: ResidentNotification[] =
    props.notifications?.map((n: any, idx: number) => ({
      id: n.id || `notif-${idx}`,
      userId: user.id,
      title: n.title || 'Notification',
      message: n.message || n.desc || '',
      type: n.type || 'announcement',
      read: n.read !== undefined ? n.read : n.isRead !== undefined ? n.isRead : true,
      createdAt: n.createdAt || n.time || 'Today',
    })) || StorageService.getNotifications();

  const schedules: CollectionScheduleItem[] =
    props.schedules || StorageService.getSchedules();

  const vehicle: CollectionVehicle = props.vehicle || {
    ...StorageService.getVehicle(),
    isTrackingAvailable: true,
    etaMinutes: props.truck?.etaMinutes || 10,
  };

  const handleNavigateTab = (tab: ResidentTab) => {
    if (props.onNavigateTab) {
      if (tab === 'map') props.onNavigateTab('live_map');
      else if (tab === 'notifications') props.onNavigateTab('alerts');
      else props.onNavigateTab(tab);
    }
  };

  const handleOpenReportWizard = () => {
    if (props.onOpenReportWizard) props.onOpenReportWizard();
    else if (props.onOpenReportConcern) props.onOpenReportConcern();
    else if (props.onNavigateTab) props.onNavigateTab('report_concern');
  };

  const handleViewMyReports = (filter: ReportStatus | 'All' = 'All') => {
    if (props.onViewMyReports) props.onViewMyReports(filter);
    else handleOpenReportWizard();
  };

  const handleViewReportDetail = (report: GarbageReport) => {
    if (props.onViewReportDetail) props.onViewReportDetail(report);
  };
  const onNavigateTab = handleNavigateTab;
  const onOpenReportWizard = handleOpenReportWizard;
  const onViewMyReports = handleViewMyReports;
  const onViewReportDetail = handleViewReportDetail;

  // Counts by status
  const pendingCount = reports.filter((r) => r.status === 'Pending').length;
  const verifiedCount = reports.filter((r) => r.status === 'Verified').length;
  const scheduledCount = reports.filter((r) => r.status === 'Scheduled').length;
  const collectedCount = reports.filter((r) => r.status === 'Collected').length;
  const rejectedCount = reports.filter((r) => r.status === 'Rejected').length;

  const unreadNotifsCount = notifications.filter((n) => !n.read).length;

  // Next schedule for user's area
  const nextSchedule = schedules.find((s) => s.area.includes(user.barangay)) || schedules[0];

  return (
    <div className="relative w-full h-full flex flex-col justify-between bg-[#F8FAFC] text-slate-800 select-none overflow-hidden font-sans">
      {/* Top Header */}
      <div className="bg-white/95 backdrop-blur-md px-5 pt-1 pb-3 border-b border-slate-100 shadow-xs z-10 shrink-0">
        <StatusBar dark={true} />

        <div className="flex items-center justify-between mt-2">
          {/* Greeting from Spec: "Good day, [User Name]" */}
          <div>
            <div className="flex items-center gap-1.5 text-xs text-emerald-800 font-bold uppercase tracking-wider">
              <span>🌿 Sipalay Resident</span>
            </div>
            <h1 className="text-xl font-black text-slate-900 tracking-tight font-['Outfit'] mt-0.5">
              Good day, {user.name.split(' ')[0]}!
            </h1>
            <p className="text-[11px] text-slate-500 font-medium flex items-center gap-1 mt-0.5">
              <MapPin className="w-3 h-3 text-emerald-600" />
              <span>{user.barangay}, Sipalay City</span>
            </p>
          </div>

          {/* Quick Profile/Alert Button */}
          <div className="flex items-center gap-2.5">
            <button
              onClick={() => onNavigateTab('notifications')}
              className="relative p-2.5 rounded-2xl clay-button-secondary text-slate-700 cursor-pointer active:scale-95"
              aria-label="Notifications"
            >
              <Bell className="w-4.5 h-4.5 stroke-[2.2]" />
              {unreadNotifsCount > 0 && (
                <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white animate-pulse"></span>
              )}
            </button>

            <button
              onClick={() => onNavigateTab('profile')}
              className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 text-white flex items-center justify-center font-bold text-xs shadow-md border-2 border-white cursor-pointer active:scale-95 transition-transform"
            >
              {user.name.slice(0, 2).toUpperCase()}
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Feed */}
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4 no-scrollbar">
        {/* HERO: Quick Report Button (Section 4 Spec) */}
        <div className="clay-card-mint p-4.5 flex flex-col items-center text-center relative overflow-hidden">
          <div className="max-w-[280px]">
            <span className="text-[10px] font-black uppercase tracking-widest text-emerald-800 block">
              Dynamic Waste Operations
            </span>
            <h2 className="text-base font-extrabold text-slate-900 font-['Outfit'] mt-1">
              Spotted uncollected garbage?
            </h2>
            <p className="text-xs text-slate-600 mt-1 leading-snug font-medium">
              Submit photo and GPS location to trigger dispatch and route scheduling.
            </p>
          </div>

          {/* Large REPORT GARBAGE Button */}
          <button
            onClick={onOpenReportWizard}
            className="w-full mt-3.5 py-4 px-6 clay-button-primary text-white font-extrabold text-sm tracking-wide flex items-center justify-center gap-2.5 shadow-lg active:scale-95 cursor-pointer uppercase font-['Outfit']"
          >
            <PlusCircle className="w-5 h-5 stroke-[2.5]" />
            <span>REPORT GARBAGE</span>
          </button>
        </div>

        {/* Current Collection Status (Section 4 & 11 Spec) */}
        <div className="clay-card p-4">
          <div className="flex items-center justify-between mb-2.5">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-ping"></span>
              <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
                Collection Activity
              </h3>
            </div>
            <span className="clay-badge text-[10px] font-extrabold px-2.5 py-0.5 bg-emerald-50 text-emerald-800 border border-emerald-200">
              {vehicle.isTrackingAvailable ? 'Vehicle Active' : 'Offline'}
            </span>
          </div>

          {vehicle.isTrackingAvailable ? (
            <div className="bg-slate-50 rounded-2xl p-3 border border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-emerald-100/80 text-emerald-700 flex items-center justify-center shrink-0 shadow-xs">
                  <Truck className="w-5 h-5 stroke-[2.2]" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">{vehicle.vehicleNumber} ({vehicle.driverName})</h4>
                  <p className="text-[11px] text-slate-500 font-medium">
                    Currently near {vehicle.currentBarangay}
                  </p>
                  <p className="text-[10px] text-emerald-700 font-bold mt-0.5">
                    ETA to your street: ~{vehicle.etaMinutes} minutes
                  </p>
                </div>
              </div>

              <button
                onClick={() => onNavigateTab('map')}
                className="p-2 rounded-xl bg-white shadow-xs text-emerald-700 hover:bg-emerald-50 cursor-pointer"
                title="View on Map"
              >
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div className="p-3 bg-slate-50 rounded-2xl text-xs text-slate-500 text-center font-medium">
              Live tracking is currently unavailable. Next scheduled round will begin shortly.
            </div>
          )}
        </div>

        {/* My Reports Summary (Section 4 & 7 Spec) */}
        <div className="clay-card p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
              My Reports Summary
            </h3>
            <button
              onClick={() => onViewMyReports('All')}
              className="text-xs font-bold text-emerald-700 hover:underline cursor-pointer flex items-center gap-1"
            >
              <span>View All</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Status Chips Grid (Section 4: Pending, Verified, Scheduled, Collected, Rejected) */}
          <div className="grid grid-cols-5 gap-1.5 text-center">
            {/* Pending */}
            <button
              onClick={() => onViewMyReports('Pending')}
              className="p-2 rounded-xl bg-amber-50 hover:bg-amber-100/80 border border-amber-200 transition-all cursor-pointer"
            >
              <span className="text-sm font-black text-amber-800 block">{pendingCount}</span>
              <span className="text-[9px] font-bold text-amber-700 leading-tight block mt-0.5">Pending</span>
            </button>

            {/* Verified */}
            <button
              onClick={() => onViewMyReports('Verified')}
              className="p-2 rounded-xl bg-blue-50 hover:bg-blue-100/80 border border-blue-200 transition-all cursor-pointer"
            >
              <span className="text-sm font-black text-blue-800 block">{verifiedCount}</span>
              <span className="text-[9px] font-bold text-blue-700 leading-tight block mt-0.5">Verified</span>
            </button>

            {/* Scheduled */}
            <button
              onClick={() => onViewMyReports('Scheduled')}
              className="p-2 rounded-xl bg-emerald-50 hover:bg-emerald-100/80 border border-emerald-200 transition-all cursor-pointer"
            >
              <span className="text-sm font-black text-emerald-800 block">{scheduledCount}</span>
              <span className="text-[9px] font-bold text-emerald-700 leading-tight block mt-0.5">Scheduled</span>
            </button>

            {/* Collected */}
            <button
              onClick={() => onViewMyReports('Collected')}
              className="p-2 rounded-xl bg-teal-50 hover:bg-teal-100/80 border border-teal-200 transition-all cursor-pointer"
            >
              <span className="text-sm font-black text-teal-800 block">{collectedCount}</span>
              <span className="text-[9px] font-bold text-teal-700 leading-tight block mt-0.5">Collected</span>
            </button>

            {/* Rejected */}
            <button
              onClick={() => onViewMyReports('Rejected')}
              className="p-2 rounded-xl bg-rose-50 hover:bg-rose-100/80 border border-rose-200 transition-all cursor-pointer"
            >
              <span className="text-sm font-black text-rose-800 block">{rejectedCount}</span>
              <span className="text-[9px] font-bold text-rose-700 leading-tight block mt-0.5">Rejected</span>
            </button>
          </div>

          {/* Quick List Preview of latest report */}
          {reports.length > 0 && (
            <div
              onClick={() => onViewReportDetail(reports[0])}
              className="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between cursor-pointer hover:bg-slate-50 -mx-2 px-2 rounded-xl transition-colors"
            >
              <div className="flex items-center gap-2.5 min-w-0">
                <img
                  src={reports[0].photoUrl}
                  alt="Recent report"
                  className="w-10 h-10 rounded-lg object-cover border border-slate-200 shrink-0"
                />
                <div className="min-w-0">
                  <p className="text-xs font-bold text-slate-900 truncate">
                    {reports[0].id} • {reports[0].garbageType}
                  </p>
                  <p className="text-[11px] text-slate-500 truncate">{reports[0].address}</p>
                </div>
              </div>

              <span
                className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full shrink-0 ${
                  reports[0].status === 'Collected'
                    ? 'bg-emerald-100 text-emerald-800'
                    : reports[0].status === 'Scheduled'
                    ? 'bg-teal-100 text-teal-800'
                    : reports[0].status === 'Verified'
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-amber-100 text-amber-800'
                }`}
              >
                {reports[0].status}
              </span>
            </div>
          )}
        </div>

        {/* Collection Schedule Card (Section 4 & 14 Spec) */}
        <div className="clay-card p-4">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
              Collection Schedule
            </h3>
            <span className="text-[11px] font-bold text-emerald-700">{user.barangay}</span>
          </div>

          <div className="bg-slate-50 rounded-2xl p-3.5 flex items-center justify-between border border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-50 border border-amber-200 text-amber-600 flex items-center justify-center shrink-0">
                <Calendar className="w-5 h-5 stroke-[2.2]" />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-900">{nextSchedule.collectionDay}</p>
                <p className="text-[11px] text-slate-600 font-medium">{nextSchedule.wasteType}</p>
                <div className="flex items-center gap-1 text-[10px] text-slate-400 mt-0.5">
                  <Clock className="w-3 h-3" />
                  <span>{nextSchedule.startTime} – {nextSchedule.endTime}</span>
                </div>
              </div>
            </div>

            <button
              onClick={() => onNavigateTab('map')}
              className="px-3 py-1.5 clay-button-secondary text-xs font-bold text-slate-700 cursor-pointer"
            >
              Schedule
            </button>
          </div>
        </div>

        {/* Latest Notifications (Section 4 Spec) */}
        <div className="clay-card p-4">
          <div className="flex items-center justify-between mb-2.5">
            <h3 className="text-xs font-black text-slate-900 uppercase tracking-wider font-['Outfit']">
              Latest Notifications
            </h3>
            <button
              onClick={() => onNavigateTab('notifications')}
              className="text-xs font-bold text-emerald-700 hover:underline cursor-pointer"
            >
              See all ({notifications.length})
            </button>
          </div>

          <div className="space-y-2">
            {notifications.slice(0, 2).map((notif) => (
              <div
                key={notif.id}
                onClick={() => onNavigateTab('notifications')}
                className={`p-2.5 rounded-xl border flex items-start gap-2.5 transition-colors cursor-pointer ${
                  notif.read ? 'bg-white border-slate-100' : 'bg-emerald-50/50 border-emerald-100'
                }`}
              >
                <div className="w-2 h-2 rounded-full bg-emerald-500 mt-1.5 shrink-0"></div>
                <div className="min-w-0 flex-1">
                  <h4 className="text-xs font-bold text-slate-900 leading-snug">{notif.title}</h4>
                  <p className="text-[11px] text-slate-600 line-clamp-1 mt-0.5">{notif.message}</p>
                  <span className="text-[9px] text-slate-400 block mt-1">{notif.createdAt}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 5-Tab Resident Bottom Nav */}
      <ResidentBottomNav
        activeTab="home"
        onTabChange={onNavigateTab}
        unreadCount={unreadNotifsCount}
      />
    </div>
  );
};

export const HomeScreen = ResidentHomeScreen;

