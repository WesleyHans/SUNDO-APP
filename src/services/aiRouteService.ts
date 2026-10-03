import { GarbageReport, ReportStatus, ResidentNotification } from '../types/resident';
import { StorageService } from './storageService';

export const AIRouteService = {
  // Simulates backend decision-support scoring on newly submitted resident reports
  evaluateReportPriority: (
    report: Partial<GarbageReport>,
    existingReports: GarbageReport[]
  ): 'Normal' | 'High' | 'Urgent' => {
    let score = 0;

    // 1. Amount weight
    if (report.estimatedAmount === 'Very Large') score += 35;
    else if (report.estimatedAmount === 'Large') score += 25;
    else if (report.estimatedAmount === 'Medium') score += 15;
    else score += 5;

    // 2. Type weight
    if (report.garbageType === 'Food Waste') score += 20; // Decomposing fast
    else if (report.garbageType === 'Bulky Waste') score += 15;
    else if (report.garbageType === 'Mixed Waste') score += 10;
    else score += 8;

    // 3. Geographic clustering (check if nearby reports exist within ~200m)
    if (report.latitude && report.longitude) {
      const nearbyCount = existingReports.filter((r) => {
        const dLat = Math.abs(r.latitude - (report.latitude || 0));
        const dLng = Math.abs(r.longitude - (report.longitude || 0));
        return dLat < 0.003 && dLng < 0.003;
      }).length;

      score += Math.min(30, nearbyCount * 10);
    }

    if (score >= 50) return 'Urgent';
    if (score >= 30) return 'High';
    return 'Normal';
  },

  // Generates unique report ID format requested: SUNDO-2026-XXXXXX
  generateReportId: (): string => {
    const randomNum = Math.floor(100000 + Math.random() * 900000);
    return `SUNDO-2026-${randomNum}`;
  },

  // Simulates backend decision lifecycle (Pending -> Verified -> Scheduled -> Collected)
  simulateReportProgression: (
    reportId: string,
    onStatusChange: (updatedReport: GarbageReport, notification: ResidentNotification) => void
  ) => {
    // After 10s: Verified
    setTimeout(() => {
      const reports = StorageService.getReports();
      const report = reports.find((r) => r.id === reportId);
      if (report && report.status === 'Pending') {
        report.status = 'Verified';
        report.updatedAt = new Date().toISOString();
        StorageService.saveReports(reports);

        const notif: ResidentNotification = {
          id: `notif-${Date.now()}`,
          userId: report.userId,
          title: 'Report Verified',
          message: `Your garbage report ${report.id} has been reviewed and verified by dispatch.`,
          type: 'report_status',
          reportId: report.id,
          read: false,
          createdAt: 'Just now',
        };
        const notifs = StorageService.getNotifications();
        StorageService.saveNotifications([notif, ...notifs]);
        onStatusChange(report, notif);
      }
    }, 10000);

    // After 25s: Scheduled for collection
    setTimeout(() => {
      const reports = StorageService.getReports();
      const report = reports.find((r) => r.id === reportId);
      if (report && report.status === 'Verified') {
        report.status = 'Scheduled';
        report.scheduledDate = 'Today, 2:30 PM';
        report.assignedRoute = 'Route 02 (Poblacion West)';
        report.updatedAt = new Date().toISOString();
        StorageService.saveReports(reports);

        const notif: ResidentNotification = {
          id: `notif-${Date.now()}`,
          userId: report.userId,
          title: 'Collection Scheduled',
          message: `Your reported location (${report.id}) is included in the upcoming Route 02 collection.`,
          type: 'report_status',
          reportId: report.id,
          read: false,
          createdAt: 'Just now',
        };
        const notifs = StorageService.getNotifications();
        StorageService.saveNotifications([notif, ...notifs]);
        onStatusChange(report, notif);
      }
    }, 25000);
  },
};
