import React from 'react';
import { PhoneFrame } from './PhoneFrame';
import { SplashScreen } from './screens/SplashScreen';
import { WelcomeScreen } from './screens/WelcomeScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { LoginScreen } from './screens/LoginScreen';
import { HomeScreen } from './screens/HomeScreen';
import { LiveMapScreen } from './screens/LiveMapScreen';
import { TruckAlertModal } from './screens/TruckAlertModal';
import { ScheduleScreen } from './screens/ScheduleScreen';
import { NotificationsScreen } from './screens/NotificationsScreen';
import { ReportConcernScreen } from './screens/ReportConcernScreen';
import { ProfileScreen } from './screens/ProfileScreen';
import { UserProfile, TruckStatus, NotificationItem, ScreenId } from '../types';

interface AllScreensGalleryProps {
  user: UserProfile;
  truck: TruckStatus;
  notifications: NotificationItem[];
  unreadCount: number;
  onSelectScreenForSimulator: (screen: ScreenId) => void;
}

export const AllScreensGallery: React.FC<AllScreensGalleryProps> = ({
  user,
  truck,
  notifications,
  unreadCount,
  onSelectScreenForSimulator,
}) => {
  const dummyFn = () => {};

  return (
    <div className="w-full px-4 sm:px-8 py-6">
      {/* Top Banner explaining the 12 screens */}
      <div className="max-w-7xl mx-auto mb-8 bg-white border border-emerald-100 rounded-2xl p-5 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
              100% Complete Design Replica
            </span>
            <span className="text-xs text-slate-500 font-medium">
              12 Screens of SUNDO App
            </span>
          </div>
          <h2 className="text-xl font-extrabold text-slate-900 tracking-tight mt-1 font-['Outfit']">
            Sipalay City Smart Urban Navigation for Dynamic Waste Operations
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Click on any screen below to enter the interactive touch simulator and test real live interactions.
          </p>
        </div>

        <button
          onClick={() => onSelectScreenForSimulator('home')}
          className="px-5 py-2.5 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs transition-all shadow-sm shrink-0 self-start md:self-auto cursor-pointer"
        >
          Launch Interactive Device →
        </button>
      </div>

      {/* Grid of all 12 screens matching the exact structure from the reference photo */}
      <div className="max-w-[1700px] mx-auto grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-y-12 gap-x-6 justify-items-center">
        {/* 1. Splash Screen */}
        <div
          onClick={() => onSelectScreenForSimulator('splash')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={1} title="Splash Screen">
            <SplashScreen onContinue={() => onSelectScreenForSimulator('welcome')} />
          </PhoneFrame>
        </div>

        {/* 2. Welcome / Get Started */}
        <div
          onClick={() => onSelectScreenForSimulator('welcome')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={2} title="Welcome / Get Started">
            <WelcomeScreen
              onGetStarted={() => onSelectScreenForSimulator('home')}
              onLogIn={() => onSelectScreenForSimulator('login')}
              onCreateAccount={() => onSelectScreenForSimulator('register')}
            />
          </PhoneFrame>
        </div>

        {/* 3. Register Account */}
        <div
          onClick={() => onSelectScreenForSimulator('register')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={3} title="Register Account">
            <RegisterScreen
              onBack={() => onSelectScreenForSimulator('welcome')}
              onRegisterSuccess={() => onSelectScreenForSimulator('home')}
              onGoToLogin={() => onSelectScreenForSimulator('login')}
            />
          </PhoneFrame>
        </div>

        {/* 4. Login Screen */}
        <div
          onClick={() => onSelectScreenForSimulator('login')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={4} title="Login Screen">
            <LoginScreen
              onLoginSuccess={() => onSelectScreenForSimulator('home')}
              onCreateAccount={() => onSelectScreenForSimulator('register')}
            />
          </PhoneFrame>
        </div>

        {/* 5. Home Dashboard */}
        <div
          onClick={() => onSelectScreenForSimulator('home')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={5} title="Home Dashboard">
            <HomeScreen
              user={user}
              truck={truck}
              unreadCount={unreadCount}
              onNavigateTab={(tab) => {
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'schedule') onSelectScreenForSimulator('schedule');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
              onViewLiveTruck={() => onSelectScreenForSimulator('live_map')}
              onOpenSchedule={() => onSelectScreenForSimulator('schedule')}
              onOpenReportConcern={() => onSelectScreenForSimulator('report_concern')}
              onOpenNotifications={() => onSelectScreenForSimulator('notifications')}
              onOpenProfile={() => onSelectScreenForSimulator('profile')}
            />
          </PhoneFrame>
        </div>

        {/* 6. Live Tracking Map */}
        <div
          onClick={() => onSelectScreenForSimulator('live_map')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={6} title="Live Tracking Map">
            <LiveMapScreen
              truck={truck}
              unreadCount={unreadCount}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'schedule') onSelectScreenForSimulator('schedule');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
              onTriggerAlert={() => onSelectScreenForSimulator('truck_alert')}
            />
          </PhoneFrame>
        </div>

        {/* 7. Truck Approaching Alert */}
        <div
          onClick={() => onSelectScreenForSimulator('truck_alert')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={7} title="Truck Approaching Alert">
            <TruckAlertModal
              etaMinutes={10}
              onViewTruck={() => onSelectScreenForSimulator('live_map')}
              onDismiss={() => onSelectScreenForSimulator('home')}
              isStandalone={true}
            />
          </PhoneFrame>
        </div>

        {/* 8. Collection Schedule */}
        <div
          onClick={() => onSelectScreenForSimulator('schedule')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={8} title="Collection Schedule">
            <ScheduleScreen
              forceView="list"
              onBack={() => onSelectScreenForSimulator('home')}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
              unreadCount={unreadCount}
            />
          </PhoneFrame>
        </div>

        {/* 9. Schedule Calendar View */}
        <div
          onClick={() => onSelectScreenForSimulator('schedule_calendar')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={9} title="Schedule Calendar View">
            <ScheduleScreen
              forceView="calendar"
              onBack={() => onSelectScreenForSimulator('schedule')}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
              unreadCount={unreadCount}
            />
          </PhoneFrame>
        </div>

        {/* 10. Notifications */}
        <div
          onClick={() => onSelectScreenForSimulator('notifications')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={10} title="Notifications">
            <NotificationsScreen
              notifications={notifications}
              onBack={() => onSelectScreenForSimulator('home')}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'schedule') onSelectScreenForSimulator('schedule');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
            />
          </PhoneFrame>
        </div>

        {/* 11. Report a Concern */}
        <div
          onClick={() => onSelectScreenForSimulator('report_concern')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={11} title="Report a Concern">
            <ReportConcernScreen
              onBack={() => onSelectScreenForSimulator('home')}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'schedule') onSelectScreenForSimulator('schedule');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
                if (tab === 'profile') onSelectScreenForSimulator('profile');
              }}
            />
          </PhoneFrame>
        </div>

        {/* 12. Profile / Settings */}
        <div
          onClick={() => onSelectScreenForSimulator('profile')}
          className="cursor-pointer group transform hover:-translate-y-1.5 transition-all duration-200"
        >
          <PhoneFrame screenNumber={12} title="Profile / Settings">
            <ProfileScreen
              user={user}
              onBack={() => onSelectScreenForSimulator('home')}
              onNavigateTab={(tab) => {
                if (tab === 'home') onSelectScreenForSimulator('home');
                if (tab === 'live_map') onSelectScreenForSimulator('live_map');
                if (tab === 'schedule') onSelectScreenForSimulator('schedule');
                if (tab === 'alerts') onSelectScreenForSimulator('notifications');
              }}
              onLogout={() => onSelectScreenForSimulator('login')}
            />
          </PhoneFrame>
        </div>
      </div>
    </div>
  );
};
