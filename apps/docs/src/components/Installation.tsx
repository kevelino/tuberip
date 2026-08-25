import { useState } from 'react';
import { motion } from 'framer-motion';
import { Download, Check, Monitor, Package, Clock } from 'lucide-react';

const RELEASES_URL = 'https://github.com/kevelino/tuberip/releases/latest';

const options = [
  {
    id: 'appimage',
    label: 'AppImage',
    title: 'AppImage (Linux)',
    description:
      'Download the ready-to-run AppImage from GitHub Releases. yt-dlp and ffmpeg are bundled — chmod +x and run.',
    icon: Package,
    highlight: 'Recommended',
    available: true,
  },
  {
    id: 'windows',
    label: 'Windows',
    title: 'Windows Installer',
    description:
      'Download TubeRip-Setup-x64.exe from GitHub Releases and run it. No administrator rights required — installs per-user by default.',
    icon: Monitor,
    highlight: 'New',
    available: true,
  },
  // {
  //   id: 'flatpak',
  //   label: 'Flatpak',
  //   title: 'Flatpak Package',
  //   description:
  //     'Flathub packaging is planned for later. Cookie and filesystem sandboxing need more work before a public Flatpak.',
  //   icon: Monitor,
  //   highlight: 'Coming soon',
  //   available: false,
  // },
];

export function Installation() {
  const [activeId, setActiveId] = useState('appimage');
  const active = options.find((o) => o.id === activeId) || options[0];

  return (
    <section id="download" className="py-24 bg-zinc-900/30 border-y border-zinc-900 relative">
      <div className="max-w-4xl mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold font-mono tracking-tight text-white mb-4">
            GET TUBERIP
          </h2>
          <p className="text-zinc-400 max-w-lg mx-auto">
            Download and start saving videos and audio in seconds.
          </p>
        </div>

        <div className="flex justify-center space-x-2 mb-8 bg-zinc-950 rounded-lg p-1.5 border border-zinc-800">
          {options.map((opt) => {
            const Icon = opt.icon;
            const isActive = activeId === opt.id;
            return (
              <button
                key={opt.id}
                onClick={() => setActiveId(opt.id)}
                className={`relative px-5 py-2.5 font-mono text-xs rounded-lg transition-all focus:outline-none ${
                  isActive
                    ? 'text-primary-400 bg-zinc-900 border border-zinc-800'
                    : 'text-zinc-500 hover:text-zinc-300'
                }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="active-tab-indicator"
                    className="absolute bottom-[-1px] left-0 right-0 h-[2px] bg-primary-500"
                  />
                )}
                <Icon className="w-4 h-4 inline mr-1.5" />
                {opt.label}
              </button>
            );
          })}
        </div>

        <motion.div
          layout
          className="bg-zinc-950 rounded-xl border border-zinc-800 shadow-xl overflow-hidden mb-8"
        >
          <div className="p-10 text-center">
            <div className="w-16 h-16 rounded-xl bg-primary-500/10 border border-primary-500/20 flex items-center justify-center mx-auto mb-6">
              {(() => {
                const Icon = active.available ? active.icon : Clock;
                return <Icon className="w-8 h-8 text-primary-400" />;
              })()}
            </div>
            <h3 className="text-xl font-bold font-mono text-white mb-2">{active.title}</h3>
            <p className="text-zinc-400 max-w-md mx-auto mb-6">{active.description}</p>
            <div className="inline-flex items-center space-x-1 bg-primary-500/10 border border-primary-500/20 rounded-full px-3 py-1 text-xs text-primary-300 font-mono mb-6">
              <span>•</span>
              <span>{active.highlight}</span>
            </div>

            {active.id === 'appimage' ? (
              <div className="space-y-4">
                <a
                  href={RELEASES_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center space-x-2 bg-primary-600 hover:bg-primary-500 text-white font-bold font-mono text-sm py-3 px-6 rounded-lg transition"
                >
                  <Download className="w-4 h-4" />
                  <span>GitHub Releases</span>
                </a>
                <pre className="text-left text-xs font-mono text-zinc-300 bg-zinc-900 border border-zinc-800 rounded-lg p-4 max-w-md mx-auto overflow-x-auto">
{`# One-line install (AppImage + desktop menu, no sudo):
curl -fsSL https://raw.githubusercontent.com/kevelino/tuberip/main/install.sh | sh

# Or run the AppImage directly:
chmod +x TubeRip-*-x86_64.AppImage
./TubeRip-*-x86_64.AppImage`}
                </pre>
              </div>
            ) : active.id === 'windows' ? (
              <div className="space-y-4">
                <a
                  href={RELEASES_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center space-x-2 bg-primary-600 hover:bg-primary-500 text-white font-bold font-mono text-sm py-3 px-6 rounded-lg transition"
                >
                  <Download className="w-4 h-4" />
                  <span>Download TubeRip-Setup-x64.exe</span>
                </a>
                <ol className="text-left text-xs font-mono text-zinc-300 bg-zinc-900 border border-zinc-800 rounded-lg p-4 max-w-md mx-auto space-y-1 list-none">
                  <li><span className="text-primary-400 mr-2">1.</span>Download <strong>TubeRip-Setup-x64.exe</strong> from GitHub Releases.</li>
                  <li><span className="text-primary-400 mr-2">2.</span>Run the installer — no administrator rights needed.</li>
                  <li><span className="text-primary-400 mr-2">3.</span>Launch TubeRip from the Start Menu.</li>
                </ol>
                {/* SmartScreen note */}
                <div className="max-w-md mx-auto bg-amber-500/10 border border-amber-500/30 rounded-lg px-4 py-3 text-left">
                  <p className="text-amber-300 text-xs font-mono leading-relaxed">
                    <strong>SmartScreen notice:</strong> Windows may show an "Unknown publisher" warning because the installer is not yet code-signed. Click <em>"More info → Run anyway"</em> to proceed — this is expected and safe for this release.
                  </p>
                </div>
              </div>
            ) : (
              <p className="text-zinc-500 text-sm font-mono">
                No Flatpak build yet — use the AppImage for now.
              </p>
            )}
          </div>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Monitor className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">Linux</h4>
            <p className="text-zinc-500 text-xs">AppImage · x86_64</p>
          </div>
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Monitor className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">Windows</h4>
            <p className="text-zinc-500 text-xs">Inno Setup installer · x64</p>
          </div>
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Check className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">Bundled</h4>
            <p className="text-zinc-500 text-xs">yt-dlp + ffmpeg included</p>
          </div>
        </div>
      </div>
    </section>
  );
}
