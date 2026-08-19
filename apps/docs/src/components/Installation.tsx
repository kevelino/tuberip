import { useState } from 'react';
import { motion } from 'framer-motion';
import { Download, Check, Monitor, Package } from 'lucide-react';

const options = [
  {
    id: 'standalone',
    label: 'Standalone App',
    title: 'Standalone Application',
    description: 'Download the ready-to-run app image. No installation required — just download and run.',
    icon: Package,
    highlight: 'Recommended',
  },
  {
    id: 'flatpak',
    label: 'Flatpak',
    title: 'Flatpak Package',
    description: 'Install from Flathub for automatic updates and sandboxed security.',
    icon: Monitor,
    highlight: 'Automatic Updates',
  },
];

export function Installation() {
  const [activeId, setActiveId] = useState('standalone');
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

        {/* Option Tabs */}
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

        {/* Info Card */}
        <motion.div
          layout
          className="bg-zinc-950 rounded-xl border border-zinc-800 shadow-xl overflow-hidden mb-8"
        >
          <div className="p-10 text-center">
            <div className="w-16 h-16 rounded-xl bg-primary-500/10 border border-primary-500/20 flex items-center justify-center mx-auto mb-6">
              {(() => {
                const Icon = active.icon;
                return <Icon className="w-8 h-8 text-primary-400" />;
              })()}
            </div>
            <h3 className="text-xl font-bold font-mono text-white mb-2">{active.title}</h3>
            <p className="text-zinc-400 max-w-md mx-auto mb-6">{active.description}</p>
            <div className="inline-flex items-center space-x-1 bg-primary-500/10 border border-primary-500/20 rounded-full px-3 py-1 text-xs text-primary-300 font-mono">
              <span>•</span>
              <span>{active.highlight}</span>
            </div>
          </div>
        </motion.div>

        {/* System Requirements */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Monitor className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">Linux</h4>
            <p className="text-zinc-500 text-xs">x86_64 or ARM64</p>
          </div>
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Download className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">~50 MB</h4>
            <p className="text-zinc-500 text-xs">Disk space</p>
          </div>
          <div className="bg-zinc-950/50 rounded-xl border border-zinc-800 p-6">
            <Check className="w-6 h-6 text-primary-400 mx-auto mb-3" />
            <h4 className="font-mono font-bold text-white text-sm mb-1">Ready</h4>
            <p className="text-zinc-500 text-xs">No setup needed</p>
          </div>
        </div>
      </div>
    </section>
  );
}
