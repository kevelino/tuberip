import { motion } from 'framer-motion';
import { ArrowRight } from 'lucide-react';

export function Community() {
  return (
    <section id="community" className="py-24 relative overflow-hidden">
      {/* Background neon dots or grids */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-zinc-900/10 via-zinc-950 to-zinc-950 pointer-events-none" />

      <div className="max-w-4xl mx-auto px-4 text-center relative">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="bg-gradient-to-br from-zinc-900 via-zinc-900/80 to-zinc-950 border border-zinc-800 p-8 md:p-12 rounded-2xl shadow-xl max-w-2xl mx-auto"
        >
          <div className="w-16 h-16 bg-[#5865F2]/10 border border-[#5865F2]/20 rounded-2xl flex items-center justify-center mx-auto mb-6 text-[#5865F2]">
            <img className="w-8 h-8 flex items-center justify-center shadow-md" src="/discord.svg" alt="Discord logo" />
          </div>

          <h2 className="text-3xl font-bold font-mono tracking-tight text-white mb-4">
            JOIN THE COMMUNITY
          </h2>
          <p className="text-zinc-400 mb-8 max-w-md mx-auto">
            Need help? Want to suggest features or share feedback? Come hang out on our Discord server with fellow Linux users.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="https://discord.com/invite/tuberip"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 bg-[#5865F2] hover:bg-[#4752C4] text-white font-bold font-mono text-sm py-3.5 px-8 rounded-lg shadow-lg hover:shadow-[#5865F2]/20 transition duration-300"
            >
              <span>Join Discord</span>
              <ArrowRight className="w-4 h-4" />
            </a>
            <a
              href="https://github.com/kevelino/tuberip/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 bg-zinc-950 hover:bg-zinc-900 border border-zinc-800 hover:border-zinc-700 text-zinc-300 font-bold font-mono text-sm py-3.5 px-8 rounded-lg transition duration-300"
            >
              <img className="w-4 h-4 flex items-center justify-center shadow-md" src="/github.svg" alt="" />
              <span>GitHub Issues</span>
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
