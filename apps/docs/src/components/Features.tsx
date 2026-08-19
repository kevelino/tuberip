import { motion } from 'framer-motion';
import { Film, Sliders, Volume2, Subtitles, Pause, FolderOpen, Activity, Settings } from 'lucide-react';

const features = [
  {
    icon: Film,
    title: 'Video & Audio Modes',
    description: 'Download full resolution videos or extract audio in popular formats.',
  },
  {
    icon: Sliders,
    title: 'Quality Presets',
    description: 'Choose from best, 1080p, 720p, 480p for video, or high-quality audio.',
  },
  {
    icon: Volume2,
    title: 'Audio Quality Selection',
    description: 'Fine-tune your audio downloads with variable bitrate settings.',
  },
  {
    icon: Subtitles,
    title: 'Subtitle Download',
    description: 'Optionally download subtitles with language selection support.',
  },
  {
    icon: Pause,
    title: 'Pause & Resume',
    description: 'Suspend downloads on the fly and resume them when ready.',
  },
  {
    icon: FolderOpen,
    title: 'Custom Output Folder',
    description: 'Set your preferred download location using a native folder dialog.',
  },
  {
    icon: Activity,
    title: 'Live Queue Progress',
    description: 'Monitor downloads with real-time status, progress, and speed.',
  },
  {
    icon: Settings,
    title: 'Advanced Settings',
    description: 'Configure subtitles, metadata embedding, rate limiting, and more.',
  },
];

export function Features() {
  const containerVariants = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: 0.05,
      },
    },
  };

  const cardVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6, ease: 'easeOut' },
    },
  };

  return (
    <section id="features" className="py-24 relative z-10">
      <div className="max-w-6xl mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold font-mono tracking-tight text-white mb-4">
            APPLICATION <span className="text-primary-400">FEATURES</span>
          </h2>
          <p className="text-zinc-400 max-w-lg mx-auto">
            Everything you need for clean, reliable media downloads packaged into a desktop application.
          </p>
        </div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-100px' }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {features.map((feature, idx) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={idx}
                variants={cardVariants}
                className="bg-zinc-900/30 p-6 rounded-xl border border-zinc-800/80 hover:border-primary-500/50 hover:bg-zinc-900/50 transition-all duration-300 group"
              >
                <div className="w-10 h-10 rounded-lg bg-zinc-950 border border-zinc-800 group-hover:border-primary-500/20 flex items-center justify-center text-zinc-400 group-hover:text-primary-400 mb-4 transition-colors">
                  <Icon className="w-5 h-5" />
                </div>
                <h3 className="text-lg font-bold font-mono text-white mb-2 tracking-tight group-hover:text-primary-300 transition-colors">
                  {feature.title}
                </h3>
                <p className="text-zinc-400 text-sm leading-relaxed">
                  {feature.description}
                </p>
              </motion.div>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}
