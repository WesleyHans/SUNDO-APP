# 🚛 SUNDO: Sipalay Smart Urban Navigation for Dynamic Waste Operations

[![React](https://img.shields.io/badge/React-19.0-61dafb.svg?style=flat&logo=react)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg?style=flat&logo=typescript)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-6.x-646CFF.svg?style=flat&logo=vite)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-4.x-38B2AC.svg?style=flat&logo=tailwind-css)](https://tailwindcss.com/)
[![Leaflet](https://img.shields.io/badge/Leaflet-1.9-199900.svg?style=flat&logo=leaflet)](https://leafletjs.com/)
[![Android](https://img.shields.io/badge/Android-APK_v1.0-3DDC84.svg?style=flat&logo=android)](https://www.android.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=flat&logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)

> **Official Civic Environmental Tech System for the City Government of Sipalay, Negros Occidental**  
> AI-Augmented Geospatial Decision Support for Solid Waste Management & Resident Operations.

---

## 🌟 Overview

**SUNDO** (*Smart Urban Navigation for Dynamic Waste Operations*) is a civic environmental application designed for Sipalay City residents and municipal waste management teams (CENRO). It bridges the gap between waste collection fleets and households through real-time vehicle GPS tracking on a 3D OpenStreetMap, dynamic schedule reminders, proximity alerts, and instant camera GPS garbage report filing.

---

## 🚀 Key Features

### 1. 🗺️ 3D Leaflet & OpenStreetMap Live Fleet Tracking
- Real-time animated waste truck tracking along calibrated Sipalay road corridors (Barangays 1, 2, 3, 4, 5, Gil Montilla, Mambulac, Nauhang).
- Realistic 3D perspective camera tilt mode with interactive zoom, rotation, and route milestone step cards.
- Live ETA calculation and proximity distance indicators (km / minutes remaining).

### 2. 📸 Resident Garbage Reporting Wizard
- 4-step streamlined photo submission flow with integrated device camera and offline simulation.
- Automatic GPS tagging and barangay auto-detection.
- Garbage categorization: Biodegradable, Recyclable, Residual, Hazardous, and Bulky Waste.
- AI-augmented decision support pipeline: **Pending Verification → City Verified → Truck Scheduled → Collected**.

### 3. 📅 Dynamic Collection Schedules
- Daily, weekly, and interactive full-month calendar views of barangay pickup schedules.
- Color-coded waste type badges with route times and designated vehicle IDs.

### 4. 🔔 Smart Alerts & Notifications
- Instant truck approaching proximity alert modal (triggered when a collection truck is within 10 minutes or 500m of household).
- Emergency weather suspension advisories and route change broadcasts.

### 5. 📱 Android APK & Cross-Platform Support
- Offline-ready Progressive Web App (PWA) with Service Worker caching.
- Direct-install Android Release APK (`SUNDO-v1.0.0-release.apk`).
- Complete native **Flutter & Dart** project structure in `/flutter_sundo`.

---

## 📁 Repository Structure

```text
├── public/                       # Static public assets, APK binaries & PWA icons
│   ├── SUNDO-v1.0.0-release.apk  # Android release APK file
│   ├── sundo-flutter-project.zip # Exportable Flutter source code
│   └── pwa-192x192.png           # PWA brand icons
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── BottomNav.tsx     # Master unified 5-tab bottom navigation
│   │   │   ├── Real3DMap.tsx     # 3D tilted Leaflet live fleet map
│   │   │   ├── RealLeafletMap.tsx# 2D high-contrast OSM map
│   │   │   └── SundoLogo.tsx     # Vector city branding & truck icons
│   │   ├── screens/
│   │   │   ├── HomeScreen.tsx    # Resident dashboard & quick actions
│   │   │   ├── LiveMapScreen.tsx # Full-screen truck tracking with HUD
│   │   │   ├── ScheduleScreen.tsx# Collection schedules & calendar
│   │   │   ├── NotificationsScreen.tsx # Proximity & civic alerts
│   │   │   ├── ReportGarbageWizard.tsx # 4-step camera GPS reporting wizard
│   │   │   ├── MyReportsScreen.tsx     # Resident report history & tracking
│   │   │   ├── ProfileScreen.tsx # Resident account, barangay & notifications
│   │   │   └── ApkDownloadWebsite.tsx  # Official APK download & installation portal
│   ├── services/
│   │   ├── aiRouteService.ts     # Intelligent collection route & report progression
│   │   └── storageService.ts     # LocalStorage state persistence
│   ├── utils/
│   │   ├── apkGenerator.ts       # In-browser APK compiler & blob delivery
│   │   └── apkBase64.ts          # Embedded APK byte representation
│   ├── types/                    # TypeScript interfaces & domain models
│   ├── App.tsx                   # Main React entry & responsive layout controller
│   └── main.tsx                  # React DOM bootstrap
├── flutter_sundo/                # Complete native Flutter / Dart codebase
├── package.json
└── vite.config.ts
```

---

## 💻 Getting Started

### Prerequisites
- Node.js 18+ or Bun
- npm or bun

### Installation
```bash
# Clone the repository
git clone https://github.com/wesleyhansplatil/sundo.git

# Navigate into the project
cd sundo

# Install dependencies
npm install

# Start local development server
npm run dev
```

Visit `http://localhost:3000` in your web browser.

### Build Production
```bash
npm run build
```

---

## 📱 How to Push to GitHub

If you have created a repository on your GitHub account (`https://github.com/wesleyhansplatil/sundo`), push your code using:

```bash
# 1. Add your GitHub remote repository
git remote add origin https://github.com/wesleyhansplatil/sundo.git

# 2. Push all code to main branch
git branch -M main
git push -u origin main
```

---

## 🏛️ Sipalay City CENRO Partnership

Developed for the **City Government of Sipalay, Negros Occidental**  
*City Environment and Natural Resources Office (CENRO)*  
Republic of the Philippines
