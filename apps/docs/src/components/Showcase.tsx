import { motion } from 'framer-motion';

export function Showcase() {
  return (
    <section id="demo" className="py-24 relative overflow-hidden">
      {/* Background radial glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-primary-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-5xl mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold font-mono tracking-tight text-white mb-4">
            APPLICATION <span className="text-primary-400">GUI</span>
          </h2>
          <p className="text-zinc-400 max-w-xl mx-auto font-sans">
            A beautiful, clean desktop interface. Lightweight, fast, and simple.
          </p>
        </div>

        {/* App Window Mockup */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-100px' }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
          className="relative bg-zinc-900 rounded-xl border border-zinc-800 shadow-2xl overflow-hidden group"
        >
          {/* Header Bar */}
          <div className="bg-zinc-950 px-4 py-3 border-b border-zinc-800 flex justify-between items-center select-none">
            <div className="flex space-x-2">
              <span className="w-3.5 h-3.5 rounded-full bg-red-500/70 block" />
              <span className="w-3.5 h-3.5 rounded-full bg-yellow-500/70 block" />
              <span className="w-3.5 h-3.5 rounded-full bg-green-500/70 block" />
            </div>
            <div className="w-12" />
          </div>

          {/* Screenshot Content */}
          <div className="relative aspect-video w-full bg-zinc-950">
            <img
              src="/tuberip_mockup.jpg"
              alt="TubeRip User Interface"
              className="w-full h-full object-cover select-none pointer-events-none group-hover:scale-[1.01] transition-transform duration-700 ease-out"
            />
            {/* Glossy overlay effect */}
            <div className="absolute inset-0 bg-gradient-to-t from-zinc-950/20 via-transparent to-transparent pointer-events-none" />
          </div>
        </motion.div>
      </div>
    </section>
  );
}
