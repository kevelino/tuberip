import { motion } from 'framer-motion';
import { Download } from 'lucide-react';

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
      {/* Background grids/glows */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f29370a_1px,transparent_1px),linear-gradient(to_bottom,#1f29370a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] pointer-events-none" />
      <div className="absolute top-12 left-1/2 -translate-x-1/2 w-[500px] h-[300px] bg-gradient-to-r from-primary-500/10 to-red-500/10 rounded-full blur-[100px] pointer-events-none" />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="max-w-4xl px-6 relative z-10"
      >
        {/* Main Title */}
        <motion.h1
          variants={itemVariants}
          className="text-4xl sm:text-5xl md:text-7xl font-bold font-mono tracking-tight text-white mb-6"
        >
          MEDIA ACCESS, <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-400 via-purple-400 to-red-500">
            STRIPPED CLEAN.
          </span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          variants={itemVariants}
          className="text-base sm:text-lg md:text-xl text-zinc-400 font-sans max-w-2xl mx-auto mb-10 leading-relaxed"
        >
          Download YouTube videos or extract audio with a clean, intuitive desktop application. Fast, private, and fully customizable.
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
