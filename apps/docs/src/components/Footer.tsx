import { Github, MessageSquare } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-zinc-950 border-t border-zinc-900 py-12 mt-20">
      <div className="max-w-6xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center space-x-3">
          <img className='w-8 h-8 flex items-center justify-center shadow-md' src='/tuberip.svg'/>
          <span className="text-sm font-bold font-mono tracking-wider text-white">
            Tube<span className="text-primary-400">Rip</span>
          </span>
        </div>

        <p className="text-xs font-sans text-zinc-500 text-center md:text-left">
          Download videos and audio from YouTube with ease.
        </p>

        <div className="flex items-center space-x-6 text-sm font-mono">
          <a
            href="https://github.com/kevelino/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-1.5 text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <Github className="w-4 h-4" />
            <span>GitHub</span>
          </a>
          <a
            href="https://discord.com/invite/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-1.5 text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <MessageSquare className="w-4 h-4" />
            <span>Discord</span>
          </a>
        </div>
      </div>
    </footer>
  );
}
