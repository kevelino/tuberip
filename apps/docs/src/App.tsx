import { Header } from './components/Header';
import { Hero } from './components/Hero';
import { Showcase } from './components/Showcase';
import { Features } from './components/Features';
import { Installation } from './components/Installation';
import { Community } from './components/Community';
import { Footer } from './components/Footer';

function App() {
  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 font-sans">
      <Header />
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
