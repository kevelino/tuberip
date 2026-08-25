import { motion, useReducedMotion } from 'framer-motion';
import { Download } from 'lucide-react';
import { CommandBlock } from './CommandBlock';

interface StarConfig {
  id: number;
  top: string;
  left: string;
  size: number;
  type: 'sparkle' | 'dot';
  duration: number;
  delay: number;
  colorClass: string;
  glow?: boolean;
}

const HERO_STARS: StarConfig[] = [
  // Top-left cluster
  { id: 1, top: '10%', left: '12%', size: 14, type: 'sparkle', duration: 4.2, delay: 0.2, colorClass: 'text-primary-400', glow: true },
  { id: 2, top: '18%', left: '6%', size: 4, type: 'dot', duration: 3.8, delay: 0.8, colorClass: 'bg-white', glow: true },
  { id: 3, top: '28%', left: '18%', size: 12, type: 'sparkle', duration: 4.6, delay: 1.5, colorClass: 'text-primary-300', glow: true },
  { id: 4, top: '8%', left: '28%', size: 3, type: 'dot', duration: 5.0, delay: 2.1, colorClass: 'bg-primary-200' },
  { id: 5, top: '38%', left: '8%', size: 5, type: 'dot', duration: 3.6, delay: 0.4, colorClass: 'bg-primary-400', glow: true },

  // Top-right cluster
  { id: 6, top: '12%', left: '86%', size: 16, type: 'sparkle', duration: 4.8, delay: 0.5, colorClass: 'text-primary-400', glow: true },
  { id: 7, top: '22%', left: '76%', size: 4, type: 'dot', duration: 4.0, delay: 1.2, colorClass: 'bg-white', glow: true },
  { id: 8, top: '8%', left: '68%', size: 12, type: 'sparkle', duration: 5.2, delay: 2.4, colorClass: 'text-primary-300' },
  { id: 9, top: '32%', left: '92%', size: 5, type: 'dot', duration: 3.7, delay: 1.8, colorClass: 'bg-primary-400', glow: true },
  { id: 10, top: '16%', left: '95%', size: 3, type: 'dot', duration: 4.4, delay: 0.9, colorClass: 'bg-white' },

  // Mid section sides
  { id: 11, top: '50%', left: '4%', size: 14, type: 'sparkle', duration: 4.5, delay: 1.1, colorClass: 'text-primary-300', glow: true },
  { id: 12, top: '58%', left: '15%', size: 4, type: 'dot', duration: 3.9, delay: 2.0, colorClass: 'bg-white' },
  { id: 13, top: '48%', left: '94%', size: 14, type: 'sparkle', duration: 4.3, delay: 1.6, colorClass: 'text-primary-400', glow: true },
  { id: 14, top: '60%', left: '84%', size: 5, type: 'dot', duration: 5.1, delay: 0.7, colorClass: 'bg-primary-300', glow: true },

  // Lower section
  { id: 15, top: '75%', left: '10%', size: 12, type: 'sparkle', duration: 4.0, delay: 0.3, colorClass: 'text-primary-400', glow: true },
  { id: 16, top: '84%', left: '22%', size: 4, type: 'dot', duration: 4.7, delay: 2.6, colorClass: 'bg-white' },
  { id: 17, top: '92%', left: '8%', size: 3, type: 'dot', duration: 3.5, delay: 1.4, colorClass: 'bg-primary-400' },
  { id: 18, top: '72%', left: '88%', size: 15, type: 'sparkle', duration: 4.9, delay: 1.0, colorClass: 'text-primary-300', glow: true },
  { id: 19, top: '86%', left: '76%', size: 4, type: 'dot', duration: 4.1, delay: 2.2, colorClass: 'bg-primary-400', glow: true },
  { id: 20, top: '94%', left: '90%', size: 3, type: 'dot', duration: 5.3, delay: 0.6, colorClass: 'bg-white' },

  // Center subtle accents
  { id: 21, top: '6%', left: '48%', size: 10, type: 'sparkle', duration: 5.0, delay: 2.8, colorClass: 'text-primary-300' },
  { id: 22, top: '88%', left: '46%', size: 4, type: 'dot', duration: 4.2, delay: 1.7, colorClass: 'bg-primary-400', glow: true },
];

function HeroStars() {
  const shouldReduceMotion = useReducedMotion();

  return (
    <div
      className="absolute inset-0 overflow-hidden pointer-events-none z-[1]"
      aria-hidden="true"
    >
      {HERO_STARS.map((star) => (
        <motion.div
          key={star.id}
          className={`absolute ${
            star.type === 'sparkle'
              ? `${star.colorClass} ${star.glow ? 'drop-shadow-[0_0_8px_rgba(17,238,249,0.8)]' : ''}`
              : `rounded-full ${star.colorClass} ${star.glow ? 'shadow-[0_0_10px_rgba(17,238,249,0.9),0_0_20px_rgba(17,238,249,0.4)]' : ''}`
          }`}
          style={{
            top: star.top,
            left: star.left,
            width: `${star.size}px`,
            height: `${star.size}px`,
            opacity: shouldReduceMotion ? 0.5 : undefined,
          }}
          animate={
            shouldReduceMotion
              ? undefined
              : {
                  opacity: [0.35, 1, 0.35],
                  scale: [0.8, 1.25, 0.8],
                }
          }
          transition={
            shouldReduceMotion
              ? undefined
              : {
                  duration: star.duration,
                  delay: star.delay,
                  repeat: Infinity,
                  ease: 'easeInOut',
                }
          }
        >
          {star.type === 'sparkle' && (
            <svg
              viewBox="0 0 24 24"
              fill="currentColor"
              className="w-full h-full"
            >
              <path d="M12 0L14.5 9.5L24 12L14.5 14.5L12 24L9.5 14.5L0 12L9.5 9.5Z" />
            </svg>
          )}
        </motion.div>
      ))}
    </div>
  );
}

export function Hero() {
  // Animation container for staggered children
  const containerVariants = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: 0.15,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6, ease: 'easeOut' },
    },
  };

  return (
    <section className="relative py-24 md:py-32 flex flex-col items-center justify-center text-center overflow-hidden">
      {/* Star animation background layer */}
      <HeroStars />

      {/* Background grids/glows */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f29370a_1px,transparent_1px),linear-gradient(to_bottom,#1f29370a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] pointer-events-none" />
      <div className="absolute top-12 left-1/2 -translate-x-1/2 w-[500px] h-[300px] bg-gradient-to-r from-primary-500/10 to-red-500/10 rounded-full blur-[100px] pointer-events-none" />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="max-w-5xl px-6 relative z-10"
      >
        {/* Main Title */}
        <motion.h1
          variants={itemVariants}
          className="text-3xl sm:text-5xl md:text-5xl font-bold font-mono tracking-tight text-white mb-6"
        >
          MEDIA ACCESS, <br />
          <em
            className="font-serif italic text-primary-400 bg-clip-text"
            style={{ fontFamily: '"Sentient", Georgia, serif' }}
          >
            STRIPPED CLEAN.
          </em>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          variants={itemVariants}
          className="text-base sm:text-md md:text-md text-zinc-400 font-sans max-w-2xl mx-auto mb-10 leading-relaxed"
        >
          Download YouTube videos or extract audio with a clean, intuitive desktop app — on <span className="text-zinc-200 font-medium">Linux</span> and <span className="text-zinc-200 font-medium">Windows</span>. Fast, private, and fully customizable.
        </motion.p>

        {/* Install command mockup (Linux quick-install) */}
        <motion.div variants={itemVariants} className="w-full mb-3">
          <CommandBlock
            command="curl -fsSL https://raw.githubusercontent.com/kevelino/tuberip/main/install.sh | sh"
          />
        </motion.div>
        <motion.p
          variants={itemVariants}
          className="text-xs text-zinc-600 font-mono mb-8"
        >
          Linux one-liner · Windows installer available below ↓
        </motion.p>

        {/* CTA */}
        <motion.div
          variants={itemVariants}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <a
            href="#download"
            className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-500 hover:to-primary-600 text-white font-bold font-mono text-sm py-3.5 px-8 rounded-lg shadow-lg shadow-primary-500/20 hover:shadow-primary-500/30 transition transform hover:-translate-y-0.5 duration-200"
          >
            <Download className="w-4 h-4" />
            <span>Download Now</span>
          </a>
        </motion.div>
      </motion.div>
    </section>
  );
}
