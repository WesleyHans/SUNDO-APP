export type UserRole = 'resident';

export interface ResidentUser {
  id: string;
  name: string;
  email: string;
  mobile: string;
  address: string;
  barangay: string;
  role: UserRole;
  avatarUrl?: string;
  locationPermission: boolean;
  createdAt: string;
}

export type GarbageType =
  | 'Household Waste'
  | 'Plastic'
  | 'Food Waste'
  | 'Mixed Waste'
  | 'Recyclable'
  | 'Bulky Waste'
  | 'Other';

export type EstimatedAmount = 'Small' | 'Medium' | 'Large' | 'Very Large';

export type ReportStatus = 'Pending' | 'Verified' | 'Scheduled' | 'Collected' | 'Rejected';

export interface GarbageReport {
  id: string; // e.g. SUNDO-2026-000123
  userId: string;
  userName: string;
  garbageType: GarbageType;
  estimatedAmount: EstimatedAmount;
  description?: string;
  photoUrl: string;
  latitude: number;
  longitude: number;
  address: string;
  status: ReportStatus;
  priority?: 'Normal' | 'High' | 'Urgent';
  rejectionReason?: string;
  scheduledDate?: string;
  assignedRoute?: string;
  collectedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ResidentNotification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: 'report_status' | 'collection_vehicle' | 'schedule' | 'announcement';
  reportId?: string;
  read: boolean;
  createdAt: string;
}

export interface CollectionScheduleItem {
  id: string;
  area: string;
  collectionDay: string;
  startTime: string;
  endTime: string;
  wasteType: string;
  active: boolean;
}

export interface CollectionVehicle {
  id: string;
  vehicleNumber: string;
  driverName: string;
  currentBarangay: string;
  latitude: number;
  longitude: number;
  status: 'Active' | 'Collecting' | 'En Route' | 'Completed' | 'Unavailable';
  isTrackingAvailable: boolean;
  routeProgress: number; // 0 to 1
  assignedRoute: string;
  etaMinutes?: number;
  lastUpdated: string;
}

export type ResidentTab = 'home' | 'map' | 'report' | 'notifications' | 'profile';
