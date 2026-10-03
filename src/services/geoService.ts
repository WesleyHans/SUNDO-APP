export interface GeoCoordinates {
  latitude: number;
  longitude: number;
}

// Known landmark points in Sipalay City for accurate neighborhood address lookup
const SIPALAY_LOCALITIES = [
  { name: 'Poblacion Plaza Road, Barangay 1', lat: 9.7548, lng: 122.4038 },
  { name: 'Public Market, Barangay 1', lat: 9.7535, lng: 122.4048 },
  { name: 'Mabini St. / Port Area, Barangay 1', lat: 9.7565, lng: 122.4022 },
  { name: 'Health Station / Rizal St., Barangay 2', lat: 9.7485, lng: 122.4072 },
  { name: 'Depot Road / Highway, Barangay 3', lat: 9.7425, lng: 122.4135 },
  { name: 'Gil Montilla Road, Sipalay City', lat: 9.7380, lng: 122.4180 },
];

export const GeoService = {
  // Request user's current GPS location with error handling
  getCurrentPosition: (): Promise<GeoCoordinates> => {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by this browser/device.'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          });
        },
        (error) => {
          let errorMsg = 'Unable to retrieve location.';
          if (error.code === error.PERMISSION_DENIED) {
            errorMsg = 'Location permission denied. Please allow GPS or select location manually.';
          } else if (error.code === error.POSITION_UNAVAILABLE) {
            errorMsg = 'Location information is unavailable.';
          } else if (error.code === error.TIMEOUT) {
            errorMsg = 'Location request timed out.';
          }
          reject(new Error(errorMsg));
        },
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 60000 }
      );
    });
  },

  // Approximate address from coordinates for Sipalay City
  approximateAddress: (lat: number, lng: number): string => {
    // Find closest Sipalay locality
    let closest = SIPALAY_LOCALITIES[0];
    let minDistance = 999999;

    for (const loc of SIPALAY_LOCALITIES) {
      const dLat = loc.lat - lat;
      const dLng = loc.lng - lng;
      const dist = Math.sqrt(dLat * dLat + dLng * dLng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = loc;
      }
    }

    if (minDistance < 0.05) {
      return `${closest.name}, Sipalay City, Negros Occidental`;
    }

    return `Near ${lat.toFixed(4)}°N, ${lng.toFixed(4)}°E, Sipalay City`;
  },

  // Calculate Haversine distance in kilometers
  getDistanceKm: (lat1: number, lon1: number, lat2: number, lon2: number): number => {
    const R = 6371; // Earth radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  },

  // Image compression utility before uploading
  compressImage: (file: File, maxWidth = 1000, quality = 0.8): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          let width = img.width;
          let height = img.height;

          if (width > maxWidth) {
            height = Math.round((height * maxWidth) / width);
            width = maxWidth;
          }

          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            resolve(e.target?.result as string);
            return;
          }
          ctx.drawImage(img, 0, 0, width, height);
          resolve(canvas.toDataURL('image/jpeg', quality));
        };
        img.onerror = () => reject(new Error('Failed to load image for compression.'));
        img.src = e.target?.result as string;
      };
      reader.onerror = () => reject(new Error('Failed to read file.'));
      reader.readAsDataURL(file);
    });
  },
};
