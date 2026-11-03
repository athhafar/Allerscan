import React, { useState } from 'react';
import { runMatcherUnitTests } from '../services/allergenMatcher.test';
import { CheckCircle2, XCircle, Play, RefreshCw, ShieldCheck } from 'lucide-react';

export const UnitTestRunner: React.FC = () => {
  const [testResults, setTestResults] = useState(() => runMatcherUnitTests());
  const [isRunning, setIsRunning] = useState(false);

  const handleRerun = () => {
    setIsRunning(true);
    setTimeout(() => {
      setTestResults(runMatcherUnitTests());
      setIsRunning(false);
    }, 400);
  };

  const allPassed = testResults.every(r => r.passed);

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm max-w-2xl mx-auto">
      <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Uji Verifikasi Algoritma Allergen Matcher</h2>
            <p className="text-xs text-slate-500">6 Kasus Uji Otomatis Sesuai Spesifikasi Prompt & Klinis</p>
          </div>
        </div>

        <button
          onClick={handleRerun}
          disabled={isRunning}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-700 text-white font-medium text-xs hover:bg-emerald-800 transition-colors shadow-sm disabled:opacity-50"
        >
          {isRunning ? <RefreshCw className="w-3.5 h-3.5 animate-spin" /> : <Play className="w-3.5 h-3.5" />}
          <span>Jalankan Ulang Tes</span>
        </button>
      </div>

      <div className="mb-4 flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100">
        <span className="text-xs font-medium text-slate-700">Status Seluruh Pengujian:</span>
        <div className="flex items-center gap-1.5">
          {allPassed ? (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-semibold">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              6 / 6 LULUS (100% Passed)
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-rose-100 text-rose-800 text-xs font-semibold">
              <XCircle className="w-3.5 h-3.5 text-rose-600" />
              Ada Tes Gagal
            </span>
          )}
        </div>
      </div>

      <div className="space-y-3">
        {testResults.map((t, idx) => (
          <div
            key={idx}
            className={`p-3.5 rounded-xl border transition-all ${
              t.passed ? 'bg-emerald-50/40 border-emerald-100' : 'bg-rose-50 border-rose-200'
            }`}
          >
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-2.5">
                {t.passed ? (
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                ) : (
                  <XCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
                )}
                <div>
                  <h4 className="text-xs font-semibold text-slate-800">{t.name}</h4>
                  {t.message && (
                    <p className="text-[11px] font-mono text-slate-500 mt-0.5">{t.message}</p>
                  )}
                </div>
              </div>
              <span
                className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${
                  t.passed ? 'bg-emerald-200 text-emerald-800' : 'bg-rose-200 text-rose-800'
                }`}
              >
                {t.passed ? 'PASS' : 'FAIL'}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
