import React, { useState, useEffect } from 'react';
import {
  Smartphone,
  Maximize2,
  Grid,
  BellRing,
  RotateCcw,
  Sparkles,
  ChevronDown,
  Code,
  FileText,
  Download,
  GitBranch,
} from 'lucide-react';
import { PhoneFrame } from './components/PhoneFrame';
import { SplashScreen } from './components/screens/SplashScreen';
import { WelcomeScreen } from './components/screens/WelcomeScreen';
import { RegisterScreen } from './components/screens/RegisterScreen';
import { LoginScreen } from './components/screens/LoginScreen';
import { HomeScreen } from './components/screens/HomeScreen';
import { LiveMapScreen } from './components/screens/LiveMapScreen';
import { TruckAlertModal } from './components/screens/TruckAlertModal';
import { ScheduleScreen } from './components/screens/ScheduleScreen';
import { NotificationsScreen } from './components/screens/NotificationsScreen';
import { ReportConcernScreen } from './components/screens/ReportConcernScreen';
import { ReportGarbageWizard } from './components/screens/ReportGarbageWizard';
import { MyReportsScreen } from './components/screens/MyReportsScreen';
import { ReportDetailModal } from './components/screens/ReportDetailModal';
import { ProfileScreen } from './components/screens/ProfileScreen';
import { AllScreensGallery } from './components/AllScreensGallery';
import { FlutterCodeModal } from './components/common/FlutterCodeModal';
import { DownloadApkModal } from './components/common/DownloadApkModal';
import { GitHubPushModal } from './components/common/GitHubPushModal';
import { MobileInstallBanner } from './components/common/MobileInstallBanner';
import { ApkDownloadWebsite } from './components/screens/ApkDownloadWebsite';
import { downloadOfficialApk } from './utils/apkGenerator';
import { StorageService } from './services/storageService';
import { AIRouteService } from './services/aiRouteService';
import { GarbageReport, ReportStatus } from './types/resident';
import {
  INITIAL_USER,
  INITIAL_TRUCK,
  INITIAL_NOTIFICATIONS,
} from './data/mockData';
import {
  ScreenId,
  BottomNavTab,
  UserProfile,
  TruckStatus,
  NotificationItem,
} from './types';

export default function App() {
  // Navigation & View Mode: 'real_app' (pure responsive native view), 'apk_downloader' (official APK download portal), 'simulator' (phone frame), 'gallery' (12-screens grid)
  const [viewMode, setViewMode] = useState<'real_app' | 'apk_downloader' | 'simulator' | 'gallery'>('real_app');
  const [currentScreen, setCurrentScreen] = useState<ScreenId>('home');
  const [showAlertModal, setShowAlertModal] = useState(false);
  const [flutterModalOpen, setFlutterModalOpen] = useState(false);
  const [downloadApkModalOpen, setDownloadApkModalOpen] = useState(false);
  const [githubModalOpen, setGithubModalOpen] = useState(false);

  // Resident Garbage Reports & Detail Modal
  const [reports, setReports] = useState<GarbageReport[]>(() => StorageService.getReports());
  const [selectedReportDetail, setSelectedReportDetail] = useState<GarbageReport | null>(null);
  const [myReportsInitialFilter, setMyReportsInitialFilter] = useState<ReportStatus | 'All'>('All');

  // App Data State with LocalStorage persistence
  const [user, setUser] = useState<UserProfile>(() => {
    try {
      const saved = localStorage.getItem('sundo_user');
      return saved ? JSON.parse(saved) : INITIAL_USER;
    } catch {
      return INITIAL_USER;
    }
  });

  const [truck, setTruck] = useState<TruckStatus>(INITIAL_TRUCK);
  const [notifications, setNotifications] = useState<NotificationItem[]>(() => {
    try {
      const saved = localStorage.getItem('sundo_notifications');
      return saved ? JSON.parse(saved) : INITIAL_NOTIFICATIONS;
    } catch {
      return INITIAL_NOTIFICATIONS;
    }
  });

  // Save to LocalStorage
  useEffect(() => {
    try {
      localStorage.setItem('sundo_user', JSON.stringify(user));
    } catch {}
  }, [user]);

  useEffect(() => {
    try {
      localStorage.setItem('sundo_notifications', JSON.stringify(notifications));
    } catch {}
  }, [notifications]);

  // Handle URL download trigger (e.g. ?download=apk or #apk)
  useEffect(() => {
    try {
      const params = new URLSearchParams(window.location.search);
      if (
        params.get('download') === 'apk' ||
        params.get('apk') === '1' ||
        window.location.hash === '#apk' ||
        window.location.hash === '#download'
      ) {
        setViewMode('apk_downloader');
        setTimeout(() => {
          downloadOfficialApk();
        }, 800);
      }
    } catch {}
  }, []);

  const unreadAlertsCount = notifications.filter((n) => !n.isRead).length;

  // Handle Tab Navigation from bottom bar
  const handleBottomTabChange = (tab: any) => {
    switch (tab) {
      case 'home':
        setCurrentScreen('home');
        break;
      case 'live_map':
      case 'map':
        setCurrentScreen('live_map');
        break;
      case 'schedule':
      case 'schedule_calendar':
        setCurrentScreen('schedule');
        break;
      case 'alerts':
      case 'notifications':
        setCurrentScreen('notifications');
        break;
      case 'report':
      case 'report_wizard':
        setCurrentScreen('report_wizard');
        break;
      case 'profile':
        setCurrentScreen('profile');
        break;
      default:
        break;
    }
  };

  const handleReportSubmitted = (newReport: GarbageReport) => {
    StorageService.addReport(newReport);
    setReports(StorageService.getReports());

    // Trigger AI Decision-Support Progression (Pending -> Verified -> Scheduled -> Collected)
    AIRouteService.simulateReportProgression(newReport.id, (updatedReport, notif) => {
      setReports(StorageService.getReports());
      setNotifications((prev) => [
        {
          id: notif.id,
          type: notif.type === 'collection_vehicle' ? 'alert' : 'update',
          category: 'Alerts',
          title: notif.title,
          message: notif.message,
          time: 'Just now',
          isRead: false,
        },
        ...prev,
      ]);
    });

    setCurrentScreen('my_reports');
  };

  const screensList: { id: ScreenId; number: number; label: string }[] = [
    { id: 'splash', number: 1, label: '1. Splash Screen' },
    { id: 'welcome', number: 2, label: '2. Welcome / Get Started' },
    { id: 'register', number: 3, label: '3. Register Account' },
    { id: 'login', number: 4, label: '4. Login Screen' },
    { id: 'home', number: 5, label: '5. Home Dashboard' },
    { id: 'live_map', number: 6, label: '6. Live Tracking Map' },
    { id: 'truck_alert', number: 7, label: '7. Truck Approaching Alert' },
    { id: 'schedule', number: 8, label: '8. Collection Schedule' },
    { id: 'schedule_calendar', number: 9, label: '9. Schedule Calendar View' },
    { id: 'notifications', number: 10, label: '10. Notifications' },
    { id: 'report_wizard', number: 11, label: '11. Report Garbage (GPS & Camera)' },
    { id: 'my_reports', number: 12, label: '12. My Reports & Tracker' },
    { id: 'report_concern', number: 13, label: '13. Report a Concern' },
    { id: 'profile', number: 14, label: '14. Profile / Settings' },
  ];

  // Render the active screen
  const renderActiveScreen = () => {
    switch (currentScreen) {
      case 'splash':
        return <SplashScreen onContinue={() => setCurrentScreen('welcome')} />;

      case 'welcome':
        return (
          <WelcomeScreen
            onGetStarted={() => setCurrentScreen('home')}
            onLogIn={() => setCurrentScreen('login')}
            onCreateAccount={() => setCurrentScreen('register')}
          />
        );

      case 'register':
        return (
          <RegisterScreen
            onBack={() => setCurrentScreen('welcome')}
            onRegisterSuccess={(data) => {
              if (data) {
                setUser((prev) => ({
                  ...prev,
                  name: data.name,
                  email: data.email,
                  phone: data.phone,
                  address: data.address,
                }));
              }
              setCurrentScreen('home');
            }}
            onGoToLogin={() => setCurrentScreen('login')}
          />
        );

      case 'login':
        return (
          <LoginScreen
            onLoginSuccess={(email) => {
              if (email) setUser((prev) => ({ ...prev, email }));
              setCurrentScreen('home');
            }}
            onCreateAccount={() => setCurrentScreen('register')}
          />
        );

      case 'home':
        return (
          <HomeScreen
            user={user}
            reports={reports}
            truck={truck}
            unreadCount={unreadAlertsCount}
            onNavigateTab={(tab) => {
              if (tab === 'report') setCurrentScreen('report_wizard');
              else handleBottomTabChange(tab as BottomNavTab);
            }}
            onOpenReportWizard={() => setCurrentScreen('report_wizard')}
            onViewMyReports={(filter) => {
              setMyReportsInitialFilter(filter || 'All');
              setCurrentScreen('my_reports');
            }}
            onViewReportDetail={(rep) => setSelectedReportDetail(rep)}
            onViewLiveTruck={() => setCurrentScreen('live_map')}
            onOpenSchedule={() => setCurrentScreen('schedule')}
            onOpenReportConcern={() => setCurrentScreen('report_wizard')}
            onOpenNotifications={() => setCurrentScreen('notifications')}
            onOpenWasteGuide={() => setCurrentScreen('schedule')}
            onOpenProfile={() => setCurrentScreen('profile')}
          />
        );

      case 'report_wizard':
        return (
          <ReportGarbageWizard
            user={{
              id: 'usr-res-01',
              name: user.name,
              email: user.email,
              mobile: user.phone,
              address: user.address,
              barangay: 'Barangay 1',
              role: 'resident',
              locationPermission: user.locationPermission,
              createdAt: '2026-09-01T08:00:00Z',
            }}
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            onSubmitSuccess={handleReportSubmitted}
          />
        );

      case 'my_reports':
        return (
          <MyReportsScreen
            reports={reports}
            initialFilter={myReportsInitialFilter}
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            onSelectReport={(rep) => setSelectedReportDetail(rep)}
            onNewReport={() => setCurrentScreen('report_wizard')}
          />
        );

      case 'live_map':
        return (
          <LiveMapScreen
            truck={truck}
            unreadCount={unreadAlertsCount}
            onNavigateTab={handleBottomTabChange}
            onTriggerAlert={() => setShowAlertModal(true)}
            onUpdateTruckProgress={(p) =>
              setTruck((prev) => ({
                ...prev,
                pathProgress: p,
                distanceKm: Number((Math.max(0.1, 2.8 * (1 - p))).toFixed(1)),
                etaMinutes: Math.max(1, Math.round(14 * (1 - p))),
              }))
            }
          />
        );

      case 'truck_alert':
        return (
          <TruckAlertModal
            etaMinutes={10}
            onViewTruck={() => setCurrentScreen('live_map')}
            onDismiss={() => setCurrentScreen('home')}
            isStandalone={true}
          />
        );

      case 'schedule':
        return (
          <ScheduleScreen
            initialViewMode="today"
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            unreadCount={unreadAlertsCount}
          />
        );

      case 'schedule_calendar':
        return (
          <ScheduleScreen
            initialViewMode="calendar"
            forceView="calendar"
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            unreadCount={unreadAlertsCount}
          />
        );

      case 'notifications':
        return (
          <NotificationsScreen
            notifications={notifications}
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            onNotificationClick={(item) => {
              if (item.type === 'alert') {
                setShowAlertModal(true);
              }
              setNotifications((prev) =>
                prev.map((n) => (n.id === item.id ? { ...n, isRead: true } : n))
              );
            }}
          />
        );

      case 'report_concern':
        return (
          <ReportConcernScreen
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            onSubmitSuccess={() => setCurrentScreen('home')}
          />
        );

      case 'profile':
        return (
          <ProfileScreen
            user={user}
            onBack={() => setCurrentScreen('home')}
            onNavigateTab={handleBottomTabChange}
            onLogout={() => setCurrentScreen('login')}
            onUpdateUser={(updated) => setUser((prev) => ({ ...prev, ...updated }))}
            onOpenDownloadApk={() => setDownloadApkModalOpen(true)}
          />
        );

      default:
        return (
          <HomeScreen
            user={user}
            reports={reports}
            truck={truck}
            unreadCount={unreadAlertsCount}
            onNavigateTab={(tab) => {
              if (tab === 'report') setCurrentScreen('report_wizard');
              else handleBottomTabChange(tab as BottomNavTab);
            }}
            onOpenReportWizard={() => setCurrentScreen('report_wizard')}
            onViewMyReports={(filter) => {
              setMyReportsInitialFilter(filter || 'All');
              setCurrentScreen('my_reports');
            }}
            onViewReportDetail={(rep) => setSelectedReportDetail(rep)}
            onViewLiveTruck={() => setCurrentScreen('live_map')}
            onOpenSchedule={() => setCurrentScreen('schedule')}
            onOpenReportConcern={() => setCurrentScreen('report_wizard')}
            onOpenNotifications={() => setCurrentScreen('notifications')}
            onOpenProfile={() => setCurrentScreen('profile')}
          />
        );
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col font-sans">
      {/* Mobile Top Bar (Clean, instant access to APK download & switch) */}
      <div className="md:hidden bg-slate-900 border-b border-slate-800 px-3.5 py-2 flex items-center justify-between sticky top-0 z-50 shadow-md">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center font-bold text-white text-xs shadow-md">
            SD
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-black text-white font-['Outfit']">SUNDO</span>
              <span className="text-[9px] font-bold px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400">
                Official
              </span>
            </div>
            <p className="text-[10px] text-slate-400">Sipalay City CENRO</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              downloadOfficialApk();
            }}
            className="px-2.5 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-extrabold text-xs flex items-center gap-1 shadow-sm active:scale-95 cursor-pointer"
            title="Download SUNDO APK to phone"
          >
            <Download className="w-3.5 h-3.5 text-white" />
            <span>APK</span>
          </button>

          <button
            onClick={() => setViewMode(viewMode === 'real_app' ? 'apk_downloader' : 'real_app')}
            className="px-2.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold border border-slate-700 cursor-pointer"
          >
            {viewMode === 'real_app' ? 'Portal' : 'App'}
          </button>

          <button
            onClick={() => setCurrentScreen('profile')}
            className="w-7 h-7 rounded-full overflow-hidden border border-emerald-500/50 cursor-pointer active:scale-95 shrink-0"
            title="User Profile"
          >
            <img src={user.avatarUrl} alt="Profile" className="w-full h-full object-cover" />
          </button>
        </div>
      </div>

      {/* Desktop Application Control Bar */}
      <header className={`sticky top-0 z-50 bg-slate-900/95 backdrop-blur-md border-b border-slate-800 px-4 sm:px-6 py-2.5 ${viewMode === 'real_app' ? 'hidden md:block' : 'block'}`}>
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-3">
          {/* Brand info */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-xl bg-emerald-600 flex items-center justify-center font-black text-white text-xs shadow-md">
              SD
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-sm font-extrabold tracking-tight text-white font-['Outfit']">
                  SUNDO
                </span>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  Sipalay City
                </span>
                <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-blue-500/20 text-blue-400 border border-blue-500/30 hidden sm:inline">
                  Real GPS Map Active
                </span>
              </div>
              <p className="text-[11px] text-slate-400 hidden sm:block">
                Smart Urban Navigation for Dynamic Waste Operations
              </p>
            </div>
          </div>

          {/* Center: Mode Switcher (Real App vs APK Website vs Phone Frame vs 12 Screens Grid) */}
          <div className="flex items-center bg-slate-800 p-1 rounded-xl border border-slate-700">
            <button
              onClick={() => setViewMode('real_app')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'real_app'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
              title="Real full-screen application"
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>Real App</span>
            </button>

            <button
              onClick={() => setViewMode('apk_downloader')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'apk_downloader'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
              title="Official APK Download Website"
            >
              <Download className="w-3.5 h-3.5" />
              <span>APK Website</span>
            </button>

            <button
              onClick={() => setViewMode('simulator')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'simulator'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
              title="View in mobile smartphone frame"
            >
              <Maximize2 className="w-3.5 h-3.5" />
              <span className="hidden md:inline">Phone Frame</span>
            </button>

            <button
              onClick={() => setViewMode('gallery')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                viewMode === 'gallery'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-400 hover:text-white'
              }`}
              title="View all 12 design screens grid"
            >
              <Grid className="w-3.5 h-3.5" />
              <span className="hidden md:inline">12 Screens</span>
            </button>
          </div>

          {/* Right Tools: APK Download, Flutter Code, Screen Jump & Alert Trigger */}
          <div className="flex items-center gap-2">
            {/* Download APK Link */}
            <button
              onClick={() => {
                setViewMode('apk_downloader');
                downloadOfficialApk();
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white border border-emerald-400/40 text-xs font-bold transition-all shadow-sm cursor-pointer active:scale-95"
              title="Download Android APK file"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download APK</span>
            </button>

            {/* Flutter Code Exporter Button */}
            <button
              onClick={() => setFlutterModalOpen(true)}
              className="flex items-center gap-1 px-2.5 py-1.5 rounded-xl bg-blue-500/20 hover:bg-blue-500/30 text-blue-300 border border-blue-500/40 text-xs font-semibold transition-all cursor-pointer"
              title="View Flutter (Dart) Source Code"
            >
              <Code className="w-3.5 h-3.5 text-blue-400" />
              <span className="hidden lg:inline">Flutter Code</span>
            </button>

            {/* GitHub Push & Source Modal Button */}
            <button
              onClick={() => setGithubModalOpen(true)}
              className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-semibold transition-all cursor-pointer"
              title="Push to GitHub or Download Git Bundle"
            >
              <GitBranch className="w-3.5 h-3.5 text-emerald-400" />
              <span className="hidden lg:inline">GitHub</span>
            </button>

            {/* Direct Screen Selector */}
            <div className="relative">
              <select
                value={currentScreen}
                onChange={(e) => {
                  setCurrentScreen(e.target.value as ScreenId);
                  if (viewMode === 'gallery') setViewMode('simulator');
                }}
                className="bg-slate-800 border border-slate-700 text-slate-200 text-xs rounded-xl px-3 py-1.5 pr-8 appearance-none focus:outline-none focus:border-emerald-500 cursor-pointer"
              >
                {screensList.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.label}
                  </option>
                ))}
              </select>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>

            {/* Trigger Truck Alert Modal button */}
            <button
              onClick={() => {
                setShowAlertModal(true);
                if (viewMode === 'gallery') setViewMode('simulator');
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 border border-amber-500/40 text-xs font-semibold transition-all cursor-pointer"
              title="Test Screen 7: Truck Approaching Alert Modal"
            >
              <BellRing className="w-3.5 h-3.5 text-amber-400 animate-bounce" />
              <span className="hidden md:inline">Test Alert</span>
            </button>

            {/* Reset */}
            <button
              onClick={() => {
                localStorage.removeItem('sundo_user');
                localStorage.removeItem('sundo_notifications');
                setUser(INITIAL_USER);
                setTruck(INITIAL_TRUCK);
                setNotifications(INITIAL_NOTIFICATIONS);
                setCurrentScreen('home');
              }}
              className="p-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-colors cursor-pointer"
              title="Reset Data"
            >
              <RotateCcw className="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col items-center justify-center relative overflow-x-hidden">
        {viewMode === 'apk_downloader' ? (
          /* Official APK Downloader Website & Mobile Installation Portal */
          <div className="w-full min-h-full">
            <ApkDownloadWebsite
              onLaunchRealApp={() => setViewMode('real_app')}
              onOpenFlutterCode={() => setFlutterModalOpen(true)}
            />
          </div>
        ) : viewMode === 'real_app' ? (
          /* Real Native Web Application (Clean, responsive, full viewport mobile-first experience) */
          <div className="w-full flex-1 md:max-w-md md:my-3 md:h-[calc(100vh-80px)] md:rounded-3xl md:shadow-2xl bg-white relative flex flex-col overflow-hidden min-h-[calc(100dvh-50px)] md:min-h-0">
            {renderActiveScreen()}

            {/* Overlaid Alert Modal if triggered */}
            {showAlertModal && (
              <div className="absolute inset-0 z-50">
                <TruckAlertModal
                  etaMinutes={truck.etaMinutes}
                  onViewTruck={() => {
                    setShowAlertModal(false);
                    setCurrentScreen('live_map');
                  }}
                  onDismiss={() => setShowAlertModal(false)}
                  isStandalone={false}
                />
              </div>
            )}

            {/* Overlaid Report Detail Modal if opened */}
            {selectedReportDetail && (
              <ReportDetailModal
                report={selectedReportDetail}
                onClose={() => setSelectedReportDetail(null)}
                onViewOnMap={() => {
                  setSelectedReportDetail(null);
                  setCurrentScreen('live_map');
                }}
              />
            )}

            {/* Mobile Install Prompt Banner */}
            <MobileInstallBanner onOpenApkPortal={() => setViewMode('apk_downloader')} />
          </div>
        ) : viewMode === 'simulator' ? (
          <div className="w-full flex-1 flex flex-col items-center justify-center py-6 px-4">
            {/* Quick Screen Breadcrumb / Selector strip */}
            <div className="mb-4 flex items-center gap-1.5 overflow-x-auto max-w-full px-2 py-1 no-scrollbar">
              {screensList.map((s) => {
                const isActive = currentScreen === s.id;
                return (
                  <button
                    key={s.id}
                    onClick={() => setCurrentScreen(s.id)}
                    className={`px-2.5 py-1 rounded-full text-[11px] font-semibold whitespace-nowrap transition-all cursor-pointer ${
                      isActive
                        ? 'bg-emerald-500 text-white ring-2 ring-emerald-400/40'
                        : 'bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700'
                    }`}
                  >
                    {s.number}. {s.label.split('. ')[1]}
                  </button>
                );
              })}
            </div>

            {/* Phone Container */}
            <div className="relative">
              <PhoneFrame
                interactive={true}
                title={screensList.find((s) => s.id === currentScreen)?.label.split('. ')[1]}
                screenNumber={screensList.find((s) => s.id === currentScreen)?.number}
              >
                {/* Active screen */}
                {renderActiveScreen()}

                {/* Overlaid Alert Modal if triggered */}
                {showAlertModal && (
                  <div className="absolute inset-0 z-50">
                    <TruckAlertModal
                      etaMinutes={truck.etaMinutes}
                      onViewTruck={() => {
                        setShowAlertModal(false);
                        setCurrentScreen('live_map');
                      }}
                      onDismiss={() => setShowAlertModal(false)}
                      isStandalone={false}
                    />
                  </div>
                )}

                {/* Overlaid Report Detail Modal if opened */}
                {selectedReportDetail && (
                  <ReportDetailModal
                    report={selectedReportDetail}
                    onClose={() => setSelectedReportDetail(null)}
                    onViewOnMap={() => {
                      setSelectedReportDetail(null);
                      setCurrentScreen('live_map');
                    }}
                  />
                )}
              </PhoneFrame>
            </div>
          </div>
        ) : (
          /* 12 Screens Grid Mode matching the uploaded image 100% */
          <div className="w-full bg-slate-950/60 min-h-full">
            <AllScreensGallery
              user={user}
              truck={truck}
              notifications={notifications}
              unreadCount={unreadAlertsCount}
              onSelectScreenForSimulator={(screen) => {
                setCurrentScreen(screen);
                setViewMode('simulator');
              }}
            />
          </div>
        )}
      </main>

      {/* Flutter Code Modal */}
      <FlutterCodeModal
        isOpen={flutterModalOpen}
        onClose={() => setFlutterModalOpen(false)}
      />

      {/* Download APK / Install Modal */}
      <DownloadApkModal
        isOpen={downloadApkModalOpen}
        onClose={() => setDownloadApkModalOpen(false)}
        onOpenFlutterCode={() => setFlutterModalOpen(true)}
      />

      {/* GitHub Push & Source Modal */}
      <GitHubPushModal
        isOpen={githubModalOpen}
        onClose={() => setGithubModalOpen(false)}
      />

      {/* Footer */}
      <footer className="bg-slate-900 border-t border-slate-800/80 px-6 py-3 text-center text-xs text-slate-500">
        <p>
          SUNDO: Smart Urban Navigation for Dynamic Waste Operations • Sipalay City Official Clean Initiative
        </p>
      </footer>
    </div>
  );
}

