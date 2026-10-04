// Real SUNDO Android APK, built by GitHub Actions (.github/workflows/build-apk.yml)
// and published to GitHub Releases. `/latest/download/` always resolves to the newest build.
export const APK_DOWNLOAD_URL =
  'https://github.com/wesleyhansplatil123/SUNDO-APP/releases/latest/download/SUNDO.apk';

export const APK_RELEASES_PAGE =
  'https://github.com/wesleyhansplatil123/SUNDO-APP/releases/latest';

function startApkDownload(): void {
  const a = document.createElement('a');
  a.href = APK_DOWNLOAD_URL;
  a.rel = 'noopener';
  document.body.appendChild(a);
  a.click();
  setTimeout(() => document.body.removeChild(a), 1000);
}

/**
 * Starts downloading the real SUNDO APK.
 * Kept with the original name/signature so existing callers continue to work.
 */
export async function generateAndDownloadApk(onProgress?: (msg: string) => void): Promise<boolean> {
  try {
    if (onProgress) onProgress('Starting SUNDO.apk download...');
    startApkDownload();
    return true;
  } catch (err) {
    console.error('Failed to start APK download:', err);
    window.location.href = APK_RELEASES_PAGE;
    return false;
  }
}

export function downloadOfficialApk(): void {
  try {
    startApkDownload();
  } catch (e) {
    console.error('APK download failed, opening releases page', e);
    window.location.href = APK_RELEASES_PAGE;
  }
}
