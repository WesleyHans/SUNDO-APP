import React, { useState } from 'react';
import {
  GitBranch,
  Check,
  Copy,
  Download,
  ExternalLink,
  X,
  Terminal,
  ShieldCheck,
} from 'lucide-react';

interface GitHubPushModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GitHubPushModal: React.FC<GitHubPushModalProps> = ({ isOpen, onClose }) => {
  const [copiedCmd, setCopiedCmd] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleCopy = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedCmd(id);
    setTimeout(() => setCopiedCmd(null), 2500);
  };

  const pushCommand = `git remote add origin https://github.com/YOUR_USERNAME/sundo.git\ngit branch -M main\ngit push -u origin main`;

  return (
    <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-700/80 rounded-2xl w-full max-w-xl shadow-2xl overflow-hidden text-slate-100 flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4 bg-slate-800/80 border-b border-slate-700/80 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-white">
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
              </svg>
            </div>
            <div>
              <h2 className="text-base font-bold text-white font-['Outfit'] flex items-center gap-2">
                Push SUNDO to GitHub
                <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  Ready to Push
                </span>
              </h2>
              <p className="text-xs text-slate-400">
                Main branch committed with full history & documentation
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-xl hover:bg-slate-700 text-slate-400 hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto space-y-5">
          {/* Commit Status Banner */}
          <div className="p-3.5 bg-emerald-950/40 border border-emerald-500/30 rounded-xl flex items-start gap-3">
            <ShieldCheck className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
            <div className="text-xs">
              <span className="font-bold text-emerald-300 block">Repository is fully committed on `main`:</span>
              <ul className="text-slate-300 mt-1 space-y-0.5 text-[11px] list-disc list-inside">
                <li><code className="text-emerald-400">c624a86</code> docs: add comprehensive GitHub README</li>
                <li><code className="text-emerald-400">1726ff3</code> feat: unified bottom navigation bar</li>
                <li><code className="text-emerald-400">2b960de</code> initial commit: full SUNDO Sipalay platform</li>
              </ul>
            </div>
          </div>

          {/* Step by Step Terminal Instructions */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                <Terminal className="w-3.5 h-3.5 text-blue-400" />
                Quick Push Commands:
              </span>
              <button
                onClick={() => handleCopy(pushCommand, 'all')}
                className="text-[11px] font-semibold text-emerald-400 hover:text-emerald-300 flex items-center gap-1 cursor-pointer"
              >
                {copiedCmd === 'all' ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copiedCmd === 'all' ? 'Copied!' : 'Copy Commands'}</span>
              </button>
            </div>

            <div className="bg-slate-950 p-3.5 rounded-xl border border-slate-800 text-xs font-mono text-emerald-400 space-y-1">
              <p className="text-slate-500"># 1. Add your GitHub remote repository:</p>
              <p className="text-slate-200 select-all">git remote add origin https://github.com/<span className="text-amber-400 font-bold">YOUR_USERNAME</span>/sundo.git</p>
              <p className="text-slate-500 pt-1"># 2. Push to main branch:</p>
              <p className="text-slate-200 select-all">git branch -M main</p>
              <p className="text-slate-200 select-all">git push -u origin main</p>
            </div>
          </div>

          {/* Downloadable Archives */}
          <div className="space-y-2">
            <span className="text-xs font-bold text-slate-300">
              Download Complete Repository Files:
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {/* Git Bundle */}
              <a
                href="/sundo.bundle"
                download="sundo.bundle"
                className="p-3 bg-slate-800/80 hover:bg-slate-800 border border-slate-700 rounded-xl flex items-center justify-between text-xs transition-all hover:border-slate-600 no-underline"
              >
                <div className="flex items-center gap-2.5">
                  <GitBranch className="w-4 h-4 text-emerald-400 shrink-0" />
                  <div>
                    <span className="font-bold text-white block">Git Bundle (.bundle)</span>
                    <span className="text-[10px] text-slate-400">467 KB • 100% commits & branches</span>
                  </div>
                </div>
                <Download className="w-4 h-4 text-slate-400 hover:text-white" />
              </a>

              {/* Source code tar.gz */}
              <a
                href="/sundo-source-code.tar.gz"
                download="sundo-source-code.tar.gz"
                className="p-3 bg-slate-800/80 hover:bg-slate-800 border border-slate-700 rounded-xl flex items-center justify-between text-xs transition-all hover:border-slate-600 no-underline"
              >
                <div className="flex items-center gap-2.5">
                  <Download className="w-4 h-4 text-blue-400 shrink-0" />
                  <div>
                    <span className="font-bold text-white block">Source Archive (.tar.gz)</span>
                    <span className="text-[10px] text-slate-400">2.4 MB • Full code & assets</span>
                  </div>
                </div>
                <Download className="w-4 h-4 text-slate-400 hover:text-white" />
              </a>
            </div>
          </div>

          {/* GitHub Website Helper */}
          <div className="p-3.5 bg-blue-950/30 border border-blue-500/20 rounded-xl flex items-center justify-between text-xs">
            <div>
              <span className="font-bold text-blue-300 block">Need to create a new repo on GitHub?</span>
              <span className="text-[11px] text-slate-400">Create an empty repo named "sundo" on your GitHub account.</span>
            </div>
            <a
              href="https://github.com/new"
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-1.5 no-underline shrink-0"
            >
              <span>New Repo</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-3.5 bg-slate-800/50 border-t border-slate-700/80 flex items-center justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl transition-colors cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
