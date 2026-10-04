import { ArrowDownToLine, ArrowRight, Check, Leaf, Smartphone, Truck } from 'lucide-react';
import { SundoTruckIcon } from './components/common/SundoLogo';

const downloadUrl = '/download-apk';
export default function App() {
  return <div className="installer">
    <header className="site-header"><a className="brand" href="#" aria-label="SUNDO home"><SundoTruckIcon size={55} /><span>SUNDO<small>Sipalay City</small></span></a><a className="header-download" href={downloadUrl}><ArrowDownToLine size={17}/> Download APK</a></header>
    <main>
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy"><span className="eyebrow"><Leaf size={15}/> A cleaner Sipalay starts with you</span><h1 id="hero-title">Clean city.<br/>One little <span>download.</span></h1><p className="intro">Meet SUNDO, your companion for waste collection in Sipalay. Get the Android app and help keep your neighborhood clean.</p>
        <a className="download-button" href={downloadUrl}><span className="download-icon"><ArrowDownToLine size={24}/></span><span>Download for Android<small>APK · Version 1.1.0 · Free</small></span><ArrowRight size={22}/></a>
        <p className="download-note"><Smartphone size={15}/> Android only. Open the downloaded APK to install.</p>
        <div className="release-note"><span className="status-dot"/><p><strong>Development preview</strong>Explore the new clay design. Live accounts, reports and truck tracking require the city’s Supabase service to be activated.</p></div>
        </div>
        <div className="hero-art"><img src="/clay-city-hero.png" alt="A green recycling truck surrounded by clay trees and the city skyline" width="1024" height="1536" fetchPriority="high"/><div className="art-tag"><span className="tag-icon"><Truck size={24}/></span><span>Small steps.<strong>A cleaner Sipalay.</strong></span><Check size={19}/></div></div>
      </section>
      <section className="install-section" aria-labelledby="install-title"><div className="section-heading"><span className="eyebrow">Ready in a few taps</span><h2 id="install-title">From download to your phone.</h2><p>No browser account needed. Everything starts in the app.</p></div><ol className="install-steps"><li><span className="step-number">01</span><h3>Download the APK</h3><p>Tap the green button and save the SUNDO file to your Android phone.</p></li><li><span className="step-number">02</span><h3>Open and install</h3><p>Open the file in Downloads. If Android asks, allow this browser to install this APK.</p></li><li><span className="step-number">03</span><h3>Welcome to SUNDO</h3><p>Open the app and explore the preview. You can turn the installation permission off afterward.</p></li></ol></section>
      <section className="help-section"><div><h2>A little help before you install.</h2><p>Everything you need to know about this version.</p></div><div className="questions"><details><summary>Can I install this on an iPhone?</summary><p>This download is an Android APK. An iPhone installer is not available yet.</p></details><details><summary>Does this version show live city data?</summary><p>The current download is a development preview with sample schedules and truck information. Real resident accounts, report submissions and driver GPS work after the Supabase backend is configured. Local demo reports stay on your phone.</p></details><details><summary>Android says the app is from an unknown source.</summary><p>This APK is installed directly instead of through Google Play. This preview uses development signing. Download it only from this page or the linked SUNDO GitHub release.</p></details><details><summary>Where can I find the download again?</summary><p>Look in your phone’s Downloads folder for SUNDO.apk, then tap it to start the installer.</p></details></div></section>
    </main><footer><span className="footer-brand"><Leaf size={18}/> SUNDO</span><p>Smart Urban Navigation for Dynamic Waste Operations</p><a href="https://github.com/wesleyhansplatil123/SUNDO-APP/releases/latest" target="_blank" rel="noreferrer">Release details <ArrowRight size={14}/></a></footer>
  </div>;
}
