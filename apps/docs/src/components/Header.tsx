import { Github, MessageSquare } from 'lucide-react';

interface HeaderProps {
  darkMode?: boolean;
  setDarkMode?: (val: boolean | ((prev: boolean) => boolean)) => void;
}

export function Header({}: HeaderProps) {
  return (
    <header className="bg-zinc-950/80 backdrop-blur-md border-b border-zinc-900 sticky top-0 z-50">
      <nav className="max-w-6xl mx-auto flex justify-between items-center px-6 py-4">
        <a href='/' className="flex items-center space-x-3">
          {/* Logo Icon */}
          <img className='w-6 h-6 flex items-center justify-center shadow-md' src='/tuberip.svg'/>
          <img className='w-20 h-16 flex items-center justify-center shadow-md' src='/tuberip-worldmark.svg'/>
        </a>

        <div className="flex items-center space-x-6">
          <a href="#features" className="text-zinc-400 hover:text-zinc-200 transition-colors font-mono text-sm">
            Features
          </a>
          <a href="#demo" className="text-zinc-400 hover:text-zinc-200 transition-colors font-mono text-sm">
            Demo
          </a>
          <a href="#download" className="text-zinc-400 hover:text-zinc-200 transition-colors font-mono text-sm">
            Download
          </a>
          <a href="#community" className="text-zinc-400 hover:text-zinc-200 transition-colors font-mono text-sm">
            Support
          </a>
        </div>

        <div className="flex items-center space-x-6 border-l border-zinc-900 pl-4">
          <a
            href="https://github.com/kevelino/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-400 hover:text-zinc-200 transition-colors flex items-center space-x-1.5"
            title="GitHub Repository"
          >
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/github.svg'/>
          </a>
          <a
            href="https://discord.com/invite/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-400 hover:text-zinc-200 transition-colors flex items-center space-x-1.5"
            title="Discord Community"
          >
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/discord.svg'/>
          </a>
          <a
            href="https://x.com/kvlino"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-400 hover:text-zinc-200 transition-colors flex items-center space-x-1.5"
            title="Discord Community"
          >
            <img className='w-5 h-5 flex items-center justify-center shadow-md' src='/x.svg'/>
          </a>
        </div>
      </nav>
    </header>
  );
}
