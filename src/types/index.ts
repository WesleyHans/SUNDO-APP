export type ScreenId =
  | 'splash'
  | 'welcome'
  | 'register'
  | 'login'
  | 'home'
  | 'live_map'
  | 'truck_alert'
  | 'schedule'
  | 'schedule_calendar'
  | 'notifications'
  | 'report_concern'
  | 'report_wizard'
  | 'my_reports'
  | 'profile';

export type BottomNavTab = 'home' | 'live_map' | 'schedule' | 'alerts' | 'profile';

export interface UserProfile {
  name: string;
  email: string;
  phone: string;
  address: string;
  avatarUrl: string;
  locationPermission: boolean;
}

export interface ScheduleItem {
  id: string;
  barangay: string;
  timeWindow: string;
  route: string;
  wasteType: string;
  statusTag: 'Today' | 'Upcoming' | 'Wed, Nov 13' | 'Thu, Nov 14' | 'Completed';
  tagColor: 'green' | 'amber' | 'gray';
  dateStr: string;
  dayOfMonth: number;
}

export interface NotificationItem {
  id: string;
  type: 'alert' | 'update' | 'route' | 'completed' | 'special';
  category: 'Alerts' | 'Announcements';
  title: string;
  message: string;
  time: string;
  isRead: boolean;
}

export interface WasteConcern {
  id: string;
  type: 'Missed Collection' | 'Uncollected Waste' | 'Route Concern' | 'Other Concern';
  description: string;
  photos: string[];
  submittedAt: string;
  status: 'Pending' | 'In Progress' | 'Resolved';
}

export interface TruckStatus {
  truckId: string;
  name: string;
  status: 'Not Started' | 'On Route' | 'Approaching' | 'Nearby' | 'Completed';
  distanceKm: number;
  etaMinutes: number;
  currentBarangay: string;
  routeNumber: string;
  speedKmh: number;
  latitude: number;
  longitude: number;
  pathProgress: number; // 0 to 1
}
