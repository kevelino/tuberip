
export function Footer() {
  return (
    <footer className="bg-zinc-950 border-t border-zinc-900 py-12 mt-20">
      <div className="max-w-6xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center space-x-3">
          <img className='w-6 h-6 flex items-center justify-center shadow-md' src='/tuberip.svg'/>
          <img className='w-20 h-16 flex items-center justify-center shadow-md' src='/tuberip-worldmark.svg'/>
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
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/github.svg'/>
            <span>GitHub</span>
          </a>
          <a
            href="https://discord.com/invite/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-1.5 text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/discord.svg'/>
            <span>Discord</span>
          </a>
          <a
            href="https://x.com/kvlino"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center space-x-1.5 text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/x.svg'/>
          </a>
        </div>
      </div>
    </footer>
  );
}
