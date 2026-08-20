import { useState, useEffect } from 'react';
import { Header } from './components/Header';
import { Hero } from './components/Hero';
import { Showcase } from './components/Showcase';
import { Features } from './components/Features';
import { Installation } from './components/Installation';
import { Community } from './components/Community';
import { Footer } from './components/Footer';

function App() {
  const [darkMode, setDarkMode] = useState(() => {
    const savedMode = localStorage.getItem('darkMode');
    if (savedMode === null) {
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return savedMode === 'true';
  });

  useEffect(() => {
    document.documentElement.classList.toggle('dark', darkMode);
    localStorage.setItem('darkMode', String(darkMode));
  }, [darkMode]);

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 transition-colors duration-300 dark:bg-zinc-950 dark:text-zinc-100 light:bg-zinc-50 light:text-zinc-900">
      <Header darkMode={darkMode} setDarkMode={setDarkMode} />
      <main className="max-w-6xl mx-auto py-12">
        <Hero />
        <Showcase />
        <Features />
        <Installation />
        <Community />
      </main>
      <Footer />
    </div>
  );
}

export default App;
