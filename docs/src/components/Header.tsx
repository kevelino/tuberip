import { Dispatch, SetStateAction } from 'react';
import { Sun, Moon, Github, MessageSquare } from 'lucide-react';
import { motion } from 'framer-motion';

interface HeaderProps {
  darkMode: boolean;
  setDarkMode: Dispatch<SetStateAction<boolean>>;
}

export function Header({ darkMode, setDarkMode }: HeaderProps) {
  return (
    <header className="bg-zinc-950/80 backdrop-blur-md border-b border-zinc-900 sticky top-0 z-50">
      <nav className="max-w-6xl mx-auto flex justify-between items-center px-6 py-4">
        <div className="flex items-center space-x-3">
          {/* Logo Icon */}
          <img className='w-8 h-8 flex items-center justify-center shadow-md' src='/tuberip.svg'/>
          <a href="#" className="text-xl font-bold font-mono tracking-wider text-white">
            Tube<span className="text-primary-400">Rip</span>
          </a>
        </div>

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

        <div className="flex items-center space-x-4 border-l border-zinc-900 pl-4">
          <a
            href="https://github.com/kevelino/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-400 hover:text-zinc-200 transition-colors"
            title="GitHub Repository"
          >
            <Github className="w-5 h-5" />
          </a>
          <a
            href="https://discord.com/invite/tuberip"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-400 hover:text-zinc-200 transition-colors"
            title="Discord Community"
          >
            <MessageSquare className="w-5 h-5" />
          </a>
          <button
            onClick={() => setDarkMode(!darkMode)}
            className="p-1.5 rounded-lg bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 hover:border-zinc-700 transition-colors focus:outline-none focus:ring-1 focus:ring-primary-500"
            aria-label="Toggle dark mode"
          >
            {darkMode ? <Sun className="w-4 h-4 text-yellow-400" /> : <Moon className="w-4 h-4 text-zinc-300" />}
          </button>
        </div>
      </nav>
    </header>
  );
}
