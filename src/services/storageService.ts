import {
  ResidentUser,
  GarbageReport,
  ResidentNotification,
  CollectionScheduleItem,
  CollectionVehicle,
} from '../types/resident';

const USER_KEY = 'sundo_resident_user';
const REPORTS_KEY = 'sundo_garbage_reports';
const NOTIFS_KEY = 'sundo_resident_notifications';
const DRAFT_REPORT_KEY = 'sundo_draft_report';
const SCHEDULES_KEY = 'sundo_collection_schedules';
const VEHICLE_KEY = 'sundo_collection_vehicle';

export const INITIAL_RESIDENT: ResidentUser = {
  id: 'usr-res-01',
  name: 'Juan Dela Cruz',
  email: 'juan@gmail.com',
  mobile: '09123456789',
  address: 'Rizal St., Barangay 1, Sipalay City, Negros Occidental',
  barangay: 'Barangay 1',
  role: 'resident',
  avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&h=200&q=80',
  locationPermission: true,
  createdAt: '2026-09-01T08:00:00Z',
};

export const INITIAL_REPORTS: GarbageReport[] = [
  {
    id: 'SUNDO-2026-000120',
    userId: 'usr-res-01',
    userName: 'Juan Dela Cruz',
    garbageType: 'Household Waste',
    estimatedAmount: 'Medium',
    description: '3 black garbage bags left near the community corner post.',
    photoUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=400&q=80',
    latitude: 9.7548,
    longitude: 122.4038,
    address: 'Poblacion Plaza Road, Barangay 1, Sipalay City',
    status: 'Scheduled',
    priority: 'Normal',
    scheduledDate: 'Today, 10:30 AM',
    assignedRoute: 'Route 02 (Poblacion West)',
    createdAt: '2026-10-02T14:20:00Z',
    updatedAt: '2026-10-03T07:15:00Z',
  },
  {
    id: 'SUNDO-2026-000115',
    userId: 'usr-res-01',
    userName: 'Juan Dela Cruz',
    garbageType: 'Plastic',
    estimatedAmount: 'Large',
    description: 'Plastic bottles and packaging piled up near market perimeter.',
    photoUrl: 'https://images.unsplash.com/photo-1605600659873-d808a13e4d2a?auto=format&fit=crop&w=400&q=80',
    latitude: 9.7535,
    longitude: 122.4048,
    address: 'Market St., Barangay 1, Sipalay City',
    status: 'Verified',
    priority: 'High',
    createdAt: '2026-10-02T09:10:00Z',
    updatedAt: '2026-10-02T11:45:00Z',
  },
  {
    id: 'SUNDO-2026-000108',
    userId: 'usr-res-01',
    userName: 'Juan Dela Cruz',
    garbageType: 'Mixed Waste',
    estimatedAmount: 'Small',
    description: 'Disposed yard clippings and kitchen waste.',
    photoUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=400&q=80',
    latitude: 9.7522,
    longitude: 122.4055,
    address: 'Mabini St., Barangay 1, Sipalay City',
    status: 'Collected',
    collectedAt: '2026-10-01T15:30:00Z',
    createdAt: '2026-10-01T08:30:00Z',
    updatedAt: '2026-10-01T15:30:00Z',
  },
  {
    id: 'SUNDO-2026-000098',
    userId: 'usr-res-01',
    userName: 'Juan Dela Cruz',
    garbageType: 'Bulky Waste',
    estimatedAmount: 'Large',
    description: 'Old sofa frame discarded on sidewalk.',
    photoUrl: 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?auto=format&fit=crop&w=400&q=80',
    latitude: 9.7510,
    longitude: 122.4062,
    address: 'Corner Rizal Ave, Barangay 1, Sipalay City',
    status: 'Pending',
    createdAt: '2026-10-03T05:30:00Z',
    updatedAt: '2026-10-03T05:30:00Z',
  },
];

export const INITIAL_NOTIFICATIONS: ResidentNotification[] = [
  {
    id: 'notif-01',
    userId: 'usr-res-01',
    title: 'Collection Scheduled',
    message: 'Your reported garbage location (SUNDO-2026-000120) has been scheduled for collection today.',
    type: 'report_status',
    reportId: 'SUNDO-2026-000120',
    read: false,
    createdAt: '15 minutes ago',
  },
  {
    id: 'notif-02',
    userId: 'usr-res-01',
    title: 'Collection Vehicle Nearby',
    message: 'Collection Truck 02 is currently operating in Barangay 1 near your reported area.',
    type: 'collection_vehicle',
    read: false,
    createdAt: '35 minutes ago',
  },
  {
    id: 'notif-03',
    userId: 'usr-res-01',
    title: 'Report Verified',
    message: 'Your garbage report SUNDO-2026-000115 has been verified by the dispatch team.',
    type: 'report_status',
    reportId: 'SUNDO-2026-000115',
    read: true,
    createdAt: 'Yesterday, 11:45 AM',
  },
  {
    id: 'notif-04',
    userId: 'usr-res-01',
    title: 'Garbage Collected',
    message: 'Your reported garbage (SUNDO-2026-000108) has been marked as collected. Thank you for helping keep Sipalay clean!',
    type: 'report_status',
    reportId: 'SUNDO-2026-000108',
    read: true,
    createdAt: 'Oct 01, 3:30 PM',
  },
  {
    id: 'notif-05',
    userId: 'usr-res-01',
    title: 'Community Announcement',
    message: 'Special e-waste and battery drop-off drive scheduled this coming Saturday at Sipalay City Plaza.',
    type: 'announcement',
    read: true,
    createdAt: 'Sep 29, 2026',
  },
];

export const INITIAL_SCHEDULES: CollectionScheduleItem[] = [
  {
    id: 'sch-01',
    area: 'Barangay 1 (Poblacion)',
    collectionDay: 'Monday',
    startTime: '8:00 AM',
    endTime: '11:00 AM',
    wasteType: 'General Waste & Food Waste',
    active: true,
  },
  {
    id: 'sch-02',
    area: 'Barangay 1 (Poblacion)',
    collectionDay: 'Wednesday',
    startTime: '8:00 AM',
    endTime: '11:00 AM',
    wasteType: 'Recyclables & Clean Plastics',
    active: true,
  },
  {
    id: 'sch-03',
    area: 'Barangay 1 (Poblacion)',
    collectionDay: 'Friday',
    startTime: '8:00 AM',
    endTime: '11:00 AM',
    wasteType: 'General Household Waste',
    active: true,
  },
  {
    id: 'sch-04',
    area: 'Barangay 2',
    collectionDay: 'Tuesday',
    startTime: '1:00 PM',
    endTime: '4:00 PM',
    wasteType: 'Biodegradable Waste',
    active: true,
  },
  {
    id: 'sch-05',
    area: 'Barangay 3',
    collectionDay: 'Thursday',
    startTime: '8:00 AM',
    endTime: '12:00 PM',
    wasteType: 'Recyclable & Mixed Waste',
    active: true,
  },
];

export const INITIAL_VEHICLE: CollectionVehicle = {
  id: 'veh-02',
  vehicleNumber: 'Truck 02',
  driverName: 'Kuya Ronald',
  currentBarangay: 'Barangay 1',
  latitude: 9.7528,
  longitude: 122.4045,
  status: 'Collecting',
  isTrackingAvailable: true,
  routeProgress: 0.45,
  assignedRoute: 'Route 02 (Poblacion Central)',
  etaMinutes: 10,
  lastUpdated: 'Just now',
};

// Storage helper functions
export const StorageService = {
  getUser: (): ResidentUser => {
    try {
      const data = localStorage.getItem(USER_KEY);
      return data ? JSON.parse(data) : INITIAL_RESIDENT;
    } catch {
      return INITIAL_RESIDENT;
    }
  },

  saveUser: (user: ResidentUser): void => {
    try {
      localStorage.setItem(USER_KEY, JSON.stringify(user));
    } catch {}
  },

  getReports: (): GarbageReport[] => {
    try {
      const data = localStorage.getItem(REPORTS_KEY);
      return data ? JSON.parse(data) : INITIAL_REPORTS;
    } catch {
      return INITIAL_REPORTS;
    }
  },

  saveReports: (reports: GarbageReport[]): void => {
    try {
      localStorage.setItem(REPORTS_KEY, JSON.stringify(reports));
    } catch {}
  },

  addReport: (report: GarbageReport): void => {
    const list = StorageService.getReports();
    StorageService.saveReports([report, ...list]);
  },

  getNotifications: (): ResidentNotification[] => {
    try {
      const data = localStorage.getItem(NOTIFS_KEY);
      return data ? JSON.parse(data) : INITIAL_NOTIFICATIONS;
    } catch {
      return INITIAL_NOTIFICATIONS;
    }
  },

  saveNotifications: (notifs: ResidentNotification[]): void => {
    try {
      localStorage.setItem(NOTIFS_KEY, JSON.stringify(notifs));
    } catch {}
  },

  getSchedules: (): CollectionScheduleItem[] => {
    try {
      const data = localStorage.getItem(SCHEDULES_KEY);
      return data ? JSON.parse(data) : INITIAL_SCHEDULES;
    } catch {
      return INITIAL_SCHEDULES;
    }
  },

  getVehicle: (): CollectionVehicle => {
    try {
      const data = localStorage.getItem(VEHICLE_KEY);
      return data ? JSON.parse(data) : INITIAL_VEHICLE;
    } catch {
      return INITIAL_VEHICLE;
    }
  },

  saveVehicle: (veh: CollectionVehicle): void => {
    try {
      localStorage.setItem(VEHICLE_KEY, JSON.stringify(veh));
    } catch {}
  },

  // Offline Draft support
  getDraftReport: (): Partial<GarbageReport> | null => {
    try {
      const data = localStorage.getItem(DRAFT_REPORT_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  },

  saveDraftReport: (draft: Partial<GarbageReport>): void => {
    try {
      localStorage.setItem(DRAFT_REPORT_KEY, JSON.stringify(draft));
    } catch {}
  },

  clearDraftReport: (): void => {
    try {
      localStorage.removeItem(DRAFT_REPORT_KEY);
    } catch {}
  },
};
