import { useState, useRef, useEffect, useCallback } from 'react';
import { Copy, Check, Terminal } from 'lucide-react';

export interface CommandBlockProps {
  command: string;
  title?: string;
  className?: string;
}

export function CommandBlock({
  command,
  title = 'bash',
  className = '',
}: CommandBlockProps) {
  const [copied, setCopied] = useState(false);
  const [copyFailed, setCopyFailed] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const commandTextRef = useRef<HTMLSpanElement>(null);

  const handleCopy = useCallback(async () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }
    setCopyFailed(false);

    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(command);
        setCopied(true);
      } else {
        throw new Error('Clipboard API unavailable');
      }
    } catch {
      // Fallback for browsers/contexts where Clipboard API is restricted or not supported
      let success = false;
      const textarea = document.createElement('textarea');
      try {
        textarea.value = command;
        textarea.setAttribute('readonly', '');
        textarea.style.position = 'fixed';
        textarea.style.top = '-9999px';
        textarea.style.left = '-9999px';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        textarea.setSelectionRange(0, textarea.value.length);
        success = document.execCommand('copy');
      } catch {
        success = false;
      } finally {
        if (textarea.parentNode) {
          document.body.removeChild(textarea);
        }
      }

      if (success) {
        setCopied(true);
      } else {
        // Fallback failed: highlight/select text manually and alert error state
        setCopyFailed(true);
        if (commandTextRef.current && window.getSelection) {
          const selection = window.getSelection();
          const range = document.createRange();
          range.selectNodeContents(commandTextRef.current);
          selection?.removeAllRanges();
          selection?.addRange(range);
        }
      }
    }

    timerRef.current = setTimeout(() => {
      setCopied(false);
      setCopyFailed(false);
    }, 2000);
  }, [command]);

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, []);

  const copyLabel = title ? `Copy ${title} command` : 'Copy command';

  return (
    <div
      className={`w-full max-w-2xl mx-auto rounded-xl border border-zinc-800/80 bg-zinc-950/80 backdrop-blur-md shadow-xl shadow-black/40 overflow-hidden text-left font-mono ${className}`}
    >
      {/* Title bar */}
      <div className="flex items-center justify-between px-3.5 py-2 border-b border-zinc-800/60 bg-zinc-900/50 select-none">
        <div className="flex items-center space-x-2">
          <div className="flex items-center space-x-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-zinc-700/80" />
            <span className="w-2.5 h-2.5 rounded-full bg-zinc-700/80" />
            <span className="w-2.5 h-2.5 rounded-full bg-zinc-700/80" />
          </div>
          <div className="flex items-center space-x-1.5 pl-2 text-zinc-400 text-xs font-mono">
            <Terminal className="w-3.5 h-3.5 text-primary-400/80" />
            <span className="text-zinc-400 tracking-tight">{title}</span>
          </div>
        </div>
      </div>

      {/* Command row */}
      <div className="flex items-center justify-between p-3 sm:p-4 gap-3 bg-zinc-950/40">
        <div className="flex items-center min-w-0 flex-1 overflow-x-auto scrollbar-none py-0.5">
          <span className="text-primary-400 select-none font-bold mr-2.5 text-xs sm:text-sm">
            $
          </span>
          <span
            ref={commandTextRef}
            className="text-zinc-200 text-xs sm:text-sm whitespace-nowrap selection:bg-primary-500/30 selection:text-primary-100 font-mono tracking-tight"
          >
            {command}
          </span>
        </div>

        {/* Copy button */}
        <div className="relative flex-shrink-0">
          <button
            type="button"
            onClick={handleCopy}
            aria-label={copyLabel}
            title={copied ? 'Copied!' : copyFailed ? 'Select and copy manually' : copyLabel}
            className={`flex items-center justify-center p-2 rounded-lg border transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-400 focus-visible:ring-offset-2 focus-visible:ring-offset-zinc-950 ${
              copied
                ? 'bg-primary-500/10 border-primary-500/40 text-primary-400'
                : copyFailed
                ? 'bg-red-500/10 border-red-500/40 text-red-400'
                : 'bg-zinc-900 hover:bg-zinc-800 border-zinc-800 hover:border-zinc-700 text-zinc-400 hover:text-zinc-100'
            }`}
          >
            {copied ? (
              <Check className="w-4 h-4 text-primary-400" />
            ) : (
              <Copy className="w-4 h-4" />
            )}
          </button>

          {/* Tooltip / badge */}
          {copied && (
            <div
              role="status"
              className="absolute bottom-full right-0 mb-2 px-2 py-1 bg-zinc-900 border border-primary-500/30 text-primary-300 text-[11px] font-mono rounded shadow-lg whitespace-nowrap pointer-events-none"
            >
              Copied!
            </div>
          )}
          {copyFailed && (
            <div
              role="status"
              className="absolute bottom-full right-0 mb-2 px-2 py-1 bg-zinc-900 border border-red-500/30 text-red-300 text-[11px] font-mono rounded shadow-lg whitespace-nowrap pointer-events-none"
            >
              Copy failed! Select text
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
