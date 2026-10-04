// Official SUNDO Android APK, compiled from Flutter source code
// and hosted on GitHub Releases. `/latest/download/` always delivers the newest build.
export const APK_DOWNLOAD_URL =
  'https://github.com/wesleyhansplatil123/SUNDO-APP/releases/latest/download/SUNDO.apk';

export const APK_RELEASES_PAGE =
  'https://github.com/wesleyhansplatil123/SUNDO-APP/releases/latest';

export function startApkDownload(): void {
  try {
    const a = document.createElement('a');
    a.href = APK_DOWNLOAD_URL;
    a.download = 'SUNDO.apk';
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
      if (document.body.contains(a)) {
        document.body.removeChild(a);
      }
    }, 500);

    // Fail-safe trigger for mobile Android Chrome & in-app browsers
    setTimeout(() => {
      window.location.assign(APK_DOWNLOAD_URL);
    }, 150);
  } catch {
    window.location.href = APK_DOWNLOAD_URL;
  }
}

/**
 * Starts downloading the real SUNDO APK.
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
