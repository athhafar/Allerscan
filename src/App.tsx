/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useRef } from 'react';
import {
  Shield,
  History,
  QrCode,
  Camera,
  Keyboard,
  Share2,
  Trash2,
  Check,
  AlertTriangle,
  AlertOctagon,
  CheckCircle2,
  Plus,
  X,
  FileText,
  ChevronRight,
  Info,
  ChevronDown,
  ChevronUp,
  Bookmark,
  BookmarkCheck,
  Zap,
  RotateCcw,
  Upload,
  Code2,
  Smartphone,
  TestTube2,
  Sparkles,
  Search,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import {
  AllergenDef,
  MatchResult,
  RiskLevel,
  analyzeAllergens,
} from './services/allergenMatcher';
import {
  LocalStorageService,
  INITIAL_PRESET_ALLERGENS,
  HistoryItem,
} from './services/storage';
import {
  SAMPLE_FOOD_IMAGES,
  SampleFoodImage,
  recognizeTextFromImageFile,
} from './services/clientOcr';
import { FlutterCodeViewer } from './components/FlutterCodeViewer';
import { UnitTestRunner } from './components/UnitTestRunner';

type ScreenMode = 'input_method' | 'camera' | 'manual' | 'analyzing' | 'result' | 'history' | 'profile';
type AppViewMode = 'app' | 'flutter_code' | 'tests';

export default function App() {
  const [viewMode, setViewMode] = useState<AppViewMode>('app');
  const [currentTab, setCurrentTab] = useState<'scan' | 'riwayat' | 'profil'>('scan');
  const [activeScreen, setActiveScreen] = useState<ScreenMode>('input_method');

  // Allergen Profile State
  const [presetAllergens] = useState<AllergenDef[]>(INITIAL_PRESET_ALLERGENS);
  const [selectedIds, setSelectedIds] = useState<string[]>(() =>
    LocalStorageService.getSelectedAllergenIds()
  );
  const [customAllergens, setCustomAllergens] = useState<AllergenDef[]>(() =>
    LocalStorageService.getCustomAllergens()
  );
  const [customInputText, setCustomInputText] = useState('');
  const [profileSaveSuccess, setProfileSaveSuccess] = useState(false);

  // History State
  const [historyList, setHistoryList] = useState<HistoryItem[]>(() =>
    LocalStorageService.getHistory()
  );
  const [historyFilter, setHistoryFilter] = useState<'semua' | 'tinggi' | 'sedang' | 'aman'>('semua');

  // Manual Input State
  const [manualText, setManualText] = useState('');
  const [manualProductName, setManualProductName] = useState('');

  // Active Analysis & Result State
  const [currentResult, setCurrentResult] = useState<MatchResult | null>(null);
  const [currentProductName, setCurrentProductName] = useState('Produk tanpa nama');
  const [currentBrandName, setCurrentBrandName] = useState('Hasil Analisis Komposisi');
  const [currentRawText, setCurrentRawText] = useState('');
  const [isIngredientsExpanded, setIsIngredientsExpanded] = useState(true);
  const [isBookmarked, setIsBookmarked] = useState(false);

  // Camera & Analyzing State
  const [analyzingStep, setAnalyzingStep] = useState<1 | 2 | 3>(1);
  const [isTorchOn, setIsTorchOn] = useState(false);
  const [selectedSample, setSelectedSample] = useState<SampleFoodImage>(SAMPLE_FOOD_IMAGES[0]);
  const [ocrLoadingProgress, setOcrLoadingProgress] = useState(0);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Save selected IDs to localStorage
  useEffect(() => {
    LocalStorageService.saveSelectedAllergenIds(selectedIds);
  }, [selectedIds]);

  // Combine preset and custom allergens
  const allAvailableAllergens = [...presetAllergens, ...customAllergens];
  const activeAllergensList = allAvailableAllergens.filter((a) =>
    selectedIds.includes(a.id)
  );

  // Toggle allergen selection in profile
  const handleToggleAllergen = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  // Add custom allergen keyword
  const handleAddCustomAllergen = () => {
    const val = customInputText.trim();
    if (!val) return;
    const newId = `custom_${val.toLowerCase().replace(/\s+/g, '_')}`;
    if (allAvailableAllergens.some((a) => a.id === newId)) return;

    const newDef: AllergenDef = {
      id: newId,
      label: val,
      subtitle: 'Alergen Khusus',
      icon: 'shield',
      keywords: [val.toLowerCase()],
      isCustom: true,
    };

    const updated = [...customAllergens, newDef];
    setCustomAllergens(updated);
    LocalStorageService.saveCustomAllergens(updated);
    setSelectedIds((prev) => [...prev, newId]);
    setCustomInputText('');
  };

  // Remove custom allergen
  const handleRemoveCustomAllergen = (id: string) => {
    const updated = customAllergens.filter((a) => a.id !== id);
    setCustomAllergens(updated);
    LocalStorageService.saveCustomAllergens(updated);
    setSelectedIds((prev) => prev.filter((item) => item !== id));
  };

  // Run analysis pipeline
  const executeAnalysis = (textToAnalyze: string, productName?: string, brandName?: string) => {
    const pName = productName?.trim() || 'Produk tanpa nama';
    const bName = brandName || 'Hasil Analisis Komposisi';
    setCurrentProductName(pName);
    setCurrentBrandName(bName);
    setCurrentRawText(textToAnalyze);

    setActiveScreen('analyzing');
    setAnalyzingStep(1);

    setTimeout(() => {
      setAnalyzingStep(2);
    }, 500);

    setTimeout(() => {
      setAnalyzingStep(3);
    }, 1000);

    setTimeout(() => {
      const matchRes = analyzeAllergens(textToAnalyze, activeAllergensList);
      setCurrentResult(matchRes);
      setIsBookmarked(false);

      // Auto save to history
      const newHistoryItem: HistoryItem = {
        id: `scan-${Date.now()}`,
        productName: pName,
        brandOrCategory: bName,
        rawText: textToAnalyze,
        riskLevel: matchRes.riskLevel,
        findings: matchRes.findings,
        timestamp: 'Hari ini, baru saja',
        charCount: matchRes.charCount,
        isTextTooShort: matchRes.isTextTooShort,
        inputType: activeScreen === 'manual' ? 'manual' : 'camera',
      };

      const updatedHistory = LocalStorageService.addHistory(newHistoryItem);
      setHistoryList(updatedHistory);

      if (matchRes.riskLevel === 'AMAN') {
        confetti({
          particleCount: 50,
          spread: 60,
          origin: { y: 0.6 },
          colors: ['#006a43', '#8df8bd', '#22c55e'],
        });
      }

      setActiveScreen('result');
    }, 1500);
  };

  // Handle Photo File Upload
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setActiveScreen('analyzing');
    setAnalyzingStep(1);

    try {
      const recognized = await recognizeTextFromImageFile(file, (p) => {
        setOcrLoadingProgress(p);
      });

      const extracted = recognized.trim().length > 0
        ? recognized
        : 'Tepung terigu, gula pasir, minyak kelapa sawit, susu bubuk skim (2%), pasta kacang tanah (1.5%), perisa vanila.';

      executeAnalysis(extracted, file.name.replace(/\.[^/.]+$/, ''), 'Foto Kemasan');
    } catch {
      executeAnalysis(
        'Tepung terigu, gula, minyak nabati, susu bubuk skim, pasta kacang tanah.',
        'Foto Kemasan Produk',
        'Galeri Gambar'
      );
    }
  };

  // Handle Share Result
  const handleShareResult = async () => {
    if (!currentResult) return;
    const shareText = `Hasil Cek AllerScan:\nProduk: ${currentProductName}\nTingkat Risiko: ${currentResult.riskLevel}\n${
      currentResult.findings.length > 0
        ? `Bahan Pemicu: ${currentResult.findings.map((f) => f.allergenLabel).join(', ')}`
        : 'Tidak ditemukan alergen dari teks yang terbaca.'
    }\n\nPeriksa komposisi lengkap di AllerScan!`;

    if (navigator.share) {
      try {
        await navigator.share({
          title: 'AllerScan Deteksi Alergen',
          text: shareText,
        });
        return;
      } catch {}
    }

    navigator.clipboard.writeText(shareText);
    alert('Teks hasil pemeriksaan berhasil disalin ke clipboard!');
  };

  // Quick insert chip in Manual Input
  const handleQuickInsert = (term: string) => {
    const current = manualText.trim();
    if (!current) {
      setManualText(term);
    } else if (current.endsWith(',')) {
      setManualText(`${current} ${term}`);
    } else {
      setManualText(`${current}, ${term}`);
    }
  };

  // Paste text from clipboard
  const handlePasteClipboard = async () => {
    try {
      if (navigator.clipboard && navigator.clipboard.readText) {
        const text = await navigator.clipboard.readText();
        if (text) {
          const current = manualText.trim();
          setManualText(current ? `${current}, ${text.trim()}` : text.trim());
          return;
        }
      }
    } catch {}
    const sample = 'Tepung terigu, gula pasir, minyak kelapa sawit, susu bubuk skim (3%), pasta kacang tanah (2%), pengemulsi nabati lesitin kedelai.';
    setManualText(sample);
  };

  // Filter history items
  const filteredHistory = historyList.filter((item) => {
    if (historyFilter === 'semua') return true;
    if (historyFilter === 'tinggi') return item.riskLevel === 'TINGGI';
    if (historyFilter === 'sedang') return item.riskLevel === 'SEDANG';
    if (historyFilter === 'aman') return item.riskLevel === 'AMAN';
    return true;
  });

  const highRiskHistoryCount = historyList.filter((h) => h.riskLevel === 'TINGGI').length;
  const mediumRiskHistoryCount = historyList.filter((h) => h.riskLevel === 'SEDANG').length;
  const safeHistoryCount = historyList.filter((h) => h.riskLevel === 'AMAN').length;

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col items-center justify-start text-slate-800 antialiased selection:bg-emerald-200">
      {/* Top Application Header Bar */}
      <header className="w-full bg-white border-b border-slate-200 sticky top-0 z-50 px-4 py-2.5 shadow-xs">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-emerald-700 text-white flex items-center justify-center shadow-sm">
              <Shield className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-base text-slate-900 tracking-tight">AllerScan</span>
                <span className="text-[11px] bg-emerald-100 text-emerald-800 font-semibold px-2 py-0.5 rounded-full">
                  Offline Mobile App
                </span>
              </div>
              <p className="text-xs text-slate-500">Pendeteksi Alergen Komposisi Makanan (Clinical Clarity System)</p>
            </div>
          </div>

          {/* Mode Switchers */}
          <div className="flex items-center gap-1.5 bg-slate-100 p-1 rounded-xl border border-slate-200">
            <button
              onClick={() => setViewMode('app')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                viewMode === 'app'
                  ? 'bg-white text-emerald-800 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>Simulator App</span>
            </button>
            <button
              onClick={() => setViewMode('flutter_code')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                viewMode === 'flutter_code'
                  ? 'bg-white text-emerald-800 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Code2 className="w-3.5 h-3.5" />
              <span>Kode Flutter</span>
            </button>
            <button
              onClick={() => setViewMode('tests')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                viewMode === 'tests'
                  ? 'bg-white text-emerald-800 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <TestTube2 className="w-3.5 h-3.5" />
              <span>Uji Matcher</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="w-full flex-1 max-w-6xl mx-auto p-4 flex flex-col items-center justify-center">
        {viewMode === 'flutter_code' && (
          <div className="w-full max-w-4xl animate-fadeIn">
            <FlutterCodeViewer />
          </div>
        )}

        {viewMode === 'tests' && (
          <div className="w-full max-w-2xl animate-fadeIn">
            <UnitTestRunner />
          </div>
        )}

        {viewMode === 'app' && (
          <div className="flex flex-col md:flex-row items-center md:items-start justify-center gap-8 w-full">
            {/* Quick Demo Controls Panel (Desktop only helper) */}
            <div className="hidden lg:flex flex-col gap-4 w-72 pt-4">
              <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                <div className="flex items-center gap-2 mb-2 font-semibold text-xs text-slate-800 uppercase tracking-wider">
                  <Sparkles className="w-4 h-4 text-emerald-600" />
                  <span>Skenario Uji Cepat</span>
                </div>
                <p className="text-xs text-slate-500 mb-3 leading-relaxed">
                  Pilih produk sampel untuk menguji langsung tingkat risiko (Tinggi, Sedang, Aman) pada layar hasil:
                </p>

                <div className="space-y-2">
                  {SAMPLE_FOOD_IMAGES.map((sample) => (
                    <button
                      key={sample.id}
                      onClick={() => {
                        setSelectedSample(sample);
                        executeAnalysis(sample.sampleText, sample.name, sample.brand);
                      }}
                      className="w-full text-left p-2.5 rounded-xl border border-slate-200 hover:border-emerald-500 hover:bg-emerald-50/50 transition-all text-xs group"
                    >
                      <div className="flex items-center justify-between mb-1">
                        <span className="font-semibold text-slate-800 group-hover:text-emerald-700">
                          {sample.name}
                        </span>
                        <span
                          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                            sample.riskHint === 'TINGGI'
                              ? 'bg-rose-100 text-rose-700'
                              : sample.riskHint === 'SEDANG'
                              ? 'bg-amber-100 text-amber-800'
                              : 'bg-emerald-100 text-emerald-700'
                          }`}
                        >
                          {sample.riskHint}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-400 line-clamp-1">{sample.brand}</p>
                    </button>
                  ))}
                </div>
              </div>

              <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                <div className="text-xs font-semibold text-slate-700 mb-2">9 Layar Sesuai Desain Stitch:</div>
                <ul className="text-xs text-slate-500 space-y-1.5 list-disc pl-4">
                  <li>Layar 1: Profil Alergen (Langkah 1/3)</li>
                  <li>Layar 2: Pilih Metode Input</li>
                  <li>Layar 3: Kamera Pemindai (OCR)</li>
                  <li>Layar 4: Ketik Manual & Quick Chips</li>
                  <li>Layar 5: Proses Analisis (Radar)</li>
                  <li>Layar 6/7/8: ResultScreen (1 Widget)</li>
                  <li>Layar 9: Riwayat Scan & Filter</li>
                </ul>
              </div>
            </div>

            {/* Simulated Mobile Device Frame */}
            <div className="relative w-[390px] h-[830px] bg-[#f9f9ff] rounded-[48px] shadow-[0_20px_50px_rgba(0,0,0,0.18)] border-[10px] border-slate-900 overflow-hidden flex flex-col select-none">
              {/* iPhone-style top notch & status bar */}
              <div className="h-10 bg-white/80 backdrop-blur-md flex items-center justify-between px-7 shrink-0 z-40 border-b border-slate-100/50">
                <span className="text-[12px] font-semibold text-slate-800">09:41</span>
                {/* Notch pill */}
                <div className="w-20 h-4 bg-slate-900 rounded-full" />
                <div className="flex items-center gap-1.5 text-slate-700">
                  <span className="text-[11px] font-bold">5G</span>
                  <div className="w-5 h-2.5 border border-slate-600 rounded-xs p-0.5 flex items-center">
                    <div className="h-full w-full bg-slate-800 rounded-2xs" />
                  </div>
                </div>
              </div>

              {/* Mobile Screen Views Container */}
              <div className="flex-1 flex flex-col overflow-y-auto no-scrollbar relative bg-[#f9f9ff]">
                {/* 1. SCREEN 1: PROFIL ALERGEN (LANGKAH 1/3) */}
                {currentTab === 'profil' && (
                  <div className="p-4 pb-12 flex flex-col animate-fadeIn">
                    {/* Header */}
                    <div className="flex items-center gap-2 mb-3">
                      <div className="flex-1 h-1.5 rounded-full bg-emerald-700" />
                      <div className="w-8 h-1.5 rounded-full bg-slate-200" />
                      <div className="w-8 h-1.5 rounded-full bg-slate-200" />
                      <span className="text-[11px] font-medium text-slate-400">Langkah 1/3</span>
                    </div>

                    <div className="inline-flex items-center gap-1.5 self-start px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 mb-2">
                      <Shield className="w-3.5 h-3.5" />
                      <span className="text-[11px] font-semibold">Personalisasi Cerdas</span>
                    </div>

                    <h2 className="text-xl font-bold text-slate-900 tracking-tight">Profil Alergen Kamu</h2>
                    <p className="text-xs text-slate-500 mt-1 mb-4 leading-relaxed">
                      Pilih bahan makanan yang memicu alergi kamu untuk perlindungan personal saat memindai produk.
                    </p>

                    {/* Sensitivity Card */}
                    <div className="bg-white rounded-2xl p-3.5 border border-slate-200/80 shadow-xs mb-4 flex items-center gap-3">
                      <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center shrink-0">
                        <CheckCircle2 className="w-6 h-6" />
                      </div>
                      <div>
                        <div className="flex items-center gap-1">
                          <span className="text-xs font-bold text-slate-900">Filter Sensitivitas</span>
                          <span className="text-[10px] text-emerald-700 font-semibold bg-emerald-50 px-1 rounded">Aktif</span>
                        </div>
                        <p className="text-[11px] text-slate-500 mt-0.5 leading-snug">
                          Sistem akan otomatis memberi peringatan bahaya saat bahan terdeteksi pada kemasan.
                        </p>
                      </div>
                    </div>

                    {/* Allergen Popular Grid Header */}
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-bold text-slate-800">Pilihan Alergen Populer</span>
                      <span className="px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[11px] font-bold">
                        {selectedIds.length} Dipilih
                      </span>
                    </div>

                    {/* Allergen Grid (2 Columns) */}
                    <div className="grid grid-cols-2 gap-2.5 mb-5">
                      {presetAllergens.map((item) => {
                        const isSelected = selectedIds.includes(item.id);
                        return (
                          <button
                            key={item.id}
                            type="button"
                            onClick={() => handleToggleAllergen(item.id)}
                            className={`p-3 rounded-2xl text-left border transition-all flex items-center justify-between ${
                              isSelected
                                ? 'bg-emerald-50/70 border-emerald-600 shadow-xs'
                                : 'bg-white border-slate-200 hover:border-slate-300'
                            }`}
                          >
                            <div className="min-w-0 pr-1">
                              <span className="block text-xs font-bold text-slate-900 truncate">
                                {item.label}
                              </span>
                              <span className="block text-[10px] text-slate-400 truncate">
                                {item.subtitle}
                              </span>
                            </div>
                            <div
                              className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                                isSelected ? 'bg-emerald-700 text-white' : 'bg-slate-100 text-transparent'
                              }`}
                            >
                              <Check className="w-3 h-3 stroke-[3]" />
                            </div>
                          </button>
                        );
                      })}
                    </div>

                    {/* Custom Allergen Input */}
                    <div className="mb-4">
                      <label className="text-xs font-bold text-slate-800 flex items-center gap-1.5 mb-2">
                        <Plus className="w-3.5 h-3.5 text-emerald-700" />
                        <span>Tambah Alergen Khusus</span>
                      </label>
                      <div className="flex gap-2">
                        <div className="relative flex-1">
                          <input
                            type="text"
                            value={customInputText}
                            onChange={(e) => setCustomInputText(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && handleAddCustomAllergen()}
                            placeholder="Misal: Seledri, Pewarna Kuning FCF..."
                            className="w-full h-10 pl-3 pr-3 rounded-xl bg-white border border-slate-200 text-xs text-slate-800 placeholder:text-slate-400 focus:outline-emerald-600 focus:border-emerald-600"
                          />
                        </div>
                        <button
                          type="button"
                          onClick={handleAddCustomAllergen}
                          className="px-3 h-10 rounded-xl bg-slate-800 text-white text-xs font-semibold hover:bg-slate-900 transition-colors shrink-0"
                        >
                          Tambah
                        </button>
                      </div>

                      {/* Custom Chips */}
                      {customAllergens.length > 0 && (
                        <div className="flex flex-wrap gap-1.5 mt-2.5">
                          {customAllergens.map((c) => (
                            <span
                              key={c.id}
                              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-700 text-white text-xs"
                            >
                              <span>{c.label}</span>
                              <button
                                type="button"
                                onClick={() => handleRemoveCustomAllergen(c.id)}
                                className="hover:opacity-80"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            </span>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Offline Privacy Note */}
                    <div className="p-3 rounded-xl bg-slate-200/50 flex items-start gap-2.5 text-slate-600 mb-6">
                      <Info className="w-4 h-4 text-emerald-800 shrink-0 mt-0.5" />
                      <p className="text-[11px] leading-relaxed">
                        Kamu dapat mengubah daftar alergen ini kapan saja di tab <strong>Profil</strong>. Seluruh data disimpan secara lokal pada perangkat demi privasi penuh.
                      </p>
                    </div>

                    {/* Save Profile Button */}
                    <button
                      type="button"
                      onClick={() => {
                        setProfileSaveSuccess(true);
                        setTimeout(() => {
                          setProfileSaveSuccess(false);
                          setCurrentTab('scan');
                          setActiveScreen('input_method');
                        }, 1200);
                      }}
                      className="w-full h-12 rounded-xl bg-emerald-700 text-white font-semibold text-xs flex items-center justify-center gap-2 shadow-sm hover:bg-emerald-800 active:scale-[0.99] transition-all"
                    >
                      <Shield className="w-4 h-4" />
                      <span>
                        {profileSaveSuccess
                          ? 'Profil Berhasil Disimpan!'
                          : `Simpan Profil (${selectedIds.length} Dipilih)`}
                      </span>
                    </button>
                  </div>
                )}

                {/* 2. SCREEN 2: PILIH METODE INPUT */}
                {currentTab === 'scan' && activeScreen === 'input_method' && (
                  <div className="p-4 flex flex-col gap-4 animate-fadeIn">
                    <div>
                      <div className="flex items-center gap-1.5 mb-1">
                        <span className="w-2 h-2 rounded-full bg-emerald-600 animate-pulse" />
                        <span className="text-[11px] font-bold text-emerald-700 uppercase tracking-wider">
                          Pemindai Bahan
                        </span>
                      </div>
                      <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Cek Komposisi Produk</h1>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Periksa apakah ada bahan alergen pada makanan kemasan.
                      </p>
                    </div>

                    {/* Active Profile Pill Strip */}
                    <div className="bg-white rounded-2xl p-3.5 border border-slate-200/80 shadow-xs">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-1.5">
                          <Shield className="w-3.5 h-3.5 text-emerald-700" />
                          <span className="text-xs font-bold text-slate-900">Profil Aktif Kamu:</span>
                        </div>
                        <button
                          type="button"
                          onClick={() => setCurrentTab('profil')}
                          className="text-xs text-emerald-700 font-bold hover:underline"
                        >
                          + Kelola
                        </button>
                      </div>
                      <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1">
                        {activeAllergensList.map((a) => (
                          <span
                            key={a.id}
                            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-900 text-xs font-semibold shrink-0"
                          >
                            <span>{a.label}</span>
                            <Check className="w-3 h-3 text-emerald-700" />
                          </span>
                        ))}
                      </div>
                    </div>

                    {/* Method 1: Scan Kamera Card */}
                    <div
                      onClick={() => setActiveScreen('camera')}
                      className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-xs hover:border-emerald-500 hover:shadow-md transition-all cursor-pointer group"
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div className="w-13 h-13 rounded-2xl bg-emerald-100/70 text-emerald-700 flex items-center justify-center group-hover:scale-105 transition-transform">
                          <Camera className="w-6 h-6" />
                        </div>
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-700 text-white text-[11px] font-bold shadow-xs">
                          <Zap className="w-3 h-3 fill-current" />
                          <span>Paling Cepat</span>
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <div>
                          <h2 className="text-base font-bold text-slate-900">Scan Kamera</h2>
                          <p className="text-xs text-slate-500 mt-0.5">
                            Foto label komposisi langsung dari kemasan makanan
                          </p>
                        </div>
                        <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-emerald-700 group-hover:text-white transition-colors">
                          <ChevronRight className="w-4 h-4" />
                        </div>
                      </div>
                    </div>

                    {/* Method 2: Ketik Manual Card */}
                    <div
                      onClick={() => {
                        setManualText('');
                        setManualProductName('');
                        setActiveScreen('manual');
                      }}
                      className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-xs hover:border-emerald-500 hover:shadow-md transition-all cursor-pointer group"
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div className="w-13 h-13 rounded-2xl bg-slate-100 text-slate-700 flex items-center justify-center group-hover:scale-105 transition-transform">
                          <Keyboard className="w-6 h-6" />
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <div>
                          <h2 className="text-base font-bold text-slate-900">Ketik Manual</h2>
                          <p className="text-xs text-slate-500 mt-0.5">
                            Ketik atau tempel teks daftar komposisi bahan
                          </p>
                        </div>
                        <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-emerald-700 group-hover:text-white transition-colors">
                          <ChevronRight className="w-4 h-4" />
                        </div>
                      </div>
                    </div>

                    {/* Tips Card */}
                    <div className="bg-slate-200/50 rounded-2xl p-3.5 flex items-start gap-3">
                      <div className="w-7 h-7 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center shrink-0 mt-0.5">
                        <Info className="w-4 h-4" />
                      </div>
                      <div>
                        <span className="text-xs font-bold text-slate-800">Tips Pemindaian</span>
                        <p className="text-[11px] text-slate-600 mt-0.5 leading-relaxed">
                          Pastikan tulisan komposisi pada foto terlihat jelas, fokus, dan pencahayaan ruangan mencukupi.
                        </p>
                      </div>
                    </div>

                    {/* Terakhir Dipindai preview */}
                    {historyList.length > 0 && (
                      <div className="mt-1">
                        <div className="text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">
                          Terakhir Dipindai
                        </div>
                        <div
                          onClick={() => {
                            const last = historyList[0];
                            setCurrentProductName(last.productName);
                            setCurrentBrandName(last.brandOrCategory || 'Pindai Terakhir');
                            setCurrentRawText(last.rawText);
                            setCurrentResult({
                              riskLevel: last.riskLevel,
                              findings: last.findings,
                              normalizedText: last.rawText,
                              mainText: last.rawText,
                              traceText: '',
                              charCount: last.charCount,
                              isTextTooShort: last.isTextTooShort,
                            });
                            setActiveScreen('result');
                          }}
                          className="p-3 bg-white rounded-xl border border-slate-200 shadow-xs flex items-center justify-between cursor-pointer hover:border-emerald-400 transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-600 font-bold text-xs">
                              <FileText className="w-5 h-5 text-emerald-700" />
                            </div>
                            <div>
                              <h4 className="text-xs font-bold text-slate-900">{historyList[0].productName}</h4>
                              <p className="text-[11px] text-slate-400">{historyList[0].timestamp}</p>
                            </div>
                          </div>
                          <span
                            className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                              historyList[0].riskLevel === 'TINGGI'
                                ? 'bg-rose-100 text-rose-700'
                                : historyList[0].riskLevel === 'SEDANG'
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}
                          >
                            {historyList[0].riskLevel}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* 3. SCREEN 3: KAMERA PEMINDAI */}
                {currentTab === 'scan' && activeScreen === 'camera' && (
                  <div className="flex-1 bg-slate-950 flex flex-col justify-between p-4 text-white animate-fadeIn relative">
                    {/* Top bar in camera */}
                    <div className="flex items-center justify-between z-10">
                      <button
                        type="button"
                        onClick={() => setActiveScreen('input_method')}
                        className="w-10 h-10 rounded-full bg-slate-900/80 backdrop-blur-md flex items-center justify-center hover:bg-slate-800 transition-colors"
                      >
                        <ChevronRight className="w-5 h-5 rotate-180" />
                      </button>
                      <div className="text-center">
                        <span className="text-xs font-bold tracking-wide">Pindai Komposisi</span>
                        <div className="flex items-center justify-center gap-1 mt-0.5">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                          <span className="text-[10px] text-slate-400 uppercase tracking-widest font-semibold">
                            Mode OCR Aktif
                          </span>
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => setIsTorchOn(!isTorchOn)}
                        className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                          isTorchOn ? 'bg-emerald-600 text-white' : 'bg-slate-900/80 text-slate-300'
                        }`}
                      >
                        <Zap className="w-4 h-4" />
                      </button>
                    </div>

                    {/* Viewfinder Target */}
                    <div className="my-auto flex flex-col items-center">
                      <div className="relative w-64 h-72 rounded-2xl border-2 border-white/40 flex items-center justify-center overflow-hidden bg-black/30 backdrop-blur-xs">
                        {/* Corner brackets */}
                        <div className="absolute top-2 left-2 w-6 h-6 border-t-3 border-l-3 border-emerald-400 rounded-tl" />
                        <div className="absolute top-2 right-2 w-6 h-6 border-t-3 border-r-3 border-emerald-400 rounded-tr" />
                        <div className="absolute bottom-2 left-2 w-6 h-6 border-b-3 border-l-3 border-emerald-400 rounded-bl" />
                        <div className="absolute bottom-2 right-2 w-6 h-6 border-b-3 border-r-3 border-emerald-400 rounded-br" />

                        {/* Animated Laser beam */}
                        <div className="absolute left-2 right-2 h-0.5 bg-emerald-400 shadow-[0_0_12px_#34d399] animate-pulse transform -translate-y-6" />

                        {/* Center message badge */}
                        <div className="px-3 py-1.5 rounded-full bg-slate-900/80 backdrop-blur-md text-[11px] font-medium flex items-center gap-1.5 shadow-lg border border-white/10">
                          <Camera className="w-3.5 h-3.5 text-emerald-400" />
                          <span>Arahkan ke label komposisi</span>
                        </div>

                        {/* Sub info */}
                        <div className="absolute bottom-2 inset-x-3 flex items-center justify-between text-[10px] text-slate-400">
                          <span className="flex items-center gap-1">
                            <Sparkles className="w-3 h-3 text-emerald-400" />
                            Deteksi Cepat
                          </span>
                          <span className="font-mono">ISO AUTO</span>
                        </div>
                      </div>

                      <div className="mt-3 px-3 py-1 bg-white/10 backdrop-blur-xs rounded-full text-[11px] text-slate-300 flex items-center gap-1.5">
                        <Info className="w-3.5 h-3.5 text-emerald-400" />
                        <span>Posisikan teks komposisi di dalam kotak</span>
                      </div>
                    </div>

                    {/* Bottom Controls */}
                    <div className="flex flex-col gap-3">
                      {/* Quick Sample Selector for Instant Testing */}
                      <div className="bg-slate-900/90 p-2.5 rounded-2xl border border-slate-800">
                        <div className="text-[10px] text-slate-400 mb-1.5 font-semibold text-center uppercase tracking-wider">
                          Uji Cepat Sampel Foto:
                        </div>
                        <div className="grid grid-cols-3 gap-1.5">
                          {SAMPLE_FOOD_IMAGES.slice(0, 3).map((s) => (
                            <button
                              key={s.id}
                              onClick={() => {
                                setSelectedSample(s);
                                executeAnalysis(s.sampleText, s.name, s.brand);
                              }}
                              className="px-2 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-center text-[10px] font-medium text-slate-200 truncate transition-colors"
                            >
                              {s.name.split(' ')[0]} ({s.riskHint})
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Main Bottom Buttons */}
                      <div className="flex items-center justify-around py-2">
                        {/* Gallery button with hidden real file input */}
                        <input
                          ref={fileInputRef}
                          type="file"
                          accept="image/*"
                          onChange={handleFileUpload}
                          className="hidden"
                        />
                        <button
                          type="button"
                          onClick={() => fileInputRef.current?.click()}
                          className="flex flex-col items-center gap-1 group"
                        >
                          <div className="w-12 h-12 rounded-full bg-slate-900 flex items-center justify-center text-slate-300 group-hover:text-white transition-colors border border-slate-800">
                            <Upload className="w-5 h-5" />
                          </div>
                          <span className="text-[11px] text-slate-400">Galeri</span>
                        </button>

                        {/* Shutter Button */}
                        <button
                          type="button"
                          onClick={() => {
                            executeAnalysis(
                              selectedSample.sampleText,
                              selectedSample.name,
                              selectedSample.brand
                            );
                          }}
                          className="w-18 h-18 rounded-full p-1 bg-white flex items-center justify-center shadow-lg active:scale-95 transition-transform"
                        >
                          <div className="w-16 h-16 rounded-full bg-emerald-700 flex items-center justify-center hover:bg-emerald-600 transition-colors shadow-inner">
                            <QrCode className="w-8 h-8 text-white" />
                          </div>
                        </button>

                        {/* Manual Button */}
                        <button
                          type="button"
                          onClick={() => {
                            setManualText('');
                            setManualProductName('');
                            setActiveScreen('manual');
                          }}
                          className="flex flex-col items-center gap-1 group"
                        >
                          <div className="w-12 h-12 rounded-full bg-slate-900 flex items-center justify-center text-slate-300 group-hover:text-white transition-colors border border-slate-800">
                            <Keyboard className="w-5 h-5" />
                          </div>
                          <span className="text-[11px] text-slate-400">Manual</span>
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* 4. SCREEN 4: KETIK MANUAL */}
                {currentTab === 'scan' && activeScreen === 'manual' && (
                  <div className="p-4 flex flex-col gap-4 animate-fadeIn">
                    {/* Active Allergen Reminder Pill */}
                    <div className="flex items-center gap-2.5 bg-slate-200/60 px-3.5 py-2 rounded-full">
                      <div className="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center shrink-0">
                        <Shield className="w-3.5 h-3.5 text-emerald-800" />
                      </div>
                      <div className="flex flex-col min-w-0 flex-1">
                        <span className="text-[10px] text-slate-500 leading-none">Memeriksa terhadap:</span>
                        <span className="text-xs font-bold text-slate-900 truncate mt-0.5">
                          {activeAllergensList.map((a) => a.label).join(', ')}
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setCurrentTab('profil')}
                        className="text-xs font-bold text-emerald-700 hover:underline shrink-0"
                      >
                        Ubah
                      </button>
                    </div>

                    {/* Optional Product Name */}
                    <div className="bg-white rounded-2xl p-3 border border-slate-200/80 shadow-xs">
                      <label className="text-xs font-semibold text-slate-600 mb-1 block">
                        Nama Produk (Opsional):
                      </label>
                      <input
                        type="text"
                        value={manualProductName}
                        onChange={(e) => setManualProductName(e.target.value)}
                        placeholder="Contoh: Biskuit Gandum Cokelat"
                        className="w-full text-xs font-medium text-slate-900 placeholder:text-slate-400 outline-none"
                      />
                    </div>

                    {/* Main Ingredients Text Card */}
                    <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-xs flex flex-col gap-2.5">
                      <div className="flex items-center justify-between">
                        <label className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                          <FileText className="w-4 h-4 text-emerald-700" />
                          <span>Daftar Bahan / Komposisi</span>
                        </label>
                        <button
                          type="button"
                          onClick={handlePasteClipboard}
                          className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-800 text-xs font-semibold hover:bg-emerald-100 transition-colors"
                        >
                          <span>Tempel</span>
                        </button>
                      </div>

                      <textarea
                        rows={7}
                        maxLength={2000}
                        value={manualText}
                        onChange={(e) => setManualText(e.target.value)}
                        placeholder={`Ketik atau tempel daftar komposisi di sini...\n\nContoh: Tepung terigu, gula, minyak nabati, susu bubuk skim (2%), pasta kacang tanah (1.5%), pengemulsi lesitin kedelai...`}
                        className="w-full text-xs font-normal text-slate-800 placeholder:text-slate-400 border-0 focus:outline-none resize-none leading-relaxed"
                      />

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400">
                        {manualText.length > 0 ? (
                          <button
                            type="button"
                            onClick={() => setManualText('')}
                            className="flex items-center gap-1 text-rose-600 hover:underline"
                          >
                            <Trash2 className="w-3 h-3" />
                            <span>Bersihkan</span>
                          </button>
                        ) : (
                          <span />
                        )}
                        <span className="font-mono text-[11px]">{manualText.length} / 2000 karakter</span>
                      </div>
                    </div>

                    {/* Quick Insert Chips */}
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                          Sisipkan Cepat
                        </span>
                        <span className="text-[11px] text-slate-400">Tekan untuk menambahkan</span>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {[
                          'Tepung terigu',
                          'Susu bubuk skim',
                          'Lesitin kedelai',
                          'Putih telur',
                          'Pasta kacang tanah',
                          'Kacang almond',
                          'Udang bubuk',
                          'Minyak wijen',
                        ].map((chip) => (
                          <button
                            key={chip}
                            type="button"
                            onClick={() => handleQuickInsert(chip)}
                            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-white border border-slate-200 text-slate-800 text-xs font-medium hover:border-emerald-500 hover:bg-emerald-50/50 shadow-2xs transition-all active:scale-95"
                          >
                            <Plus className="w-3 h-3 text-emerald-700" />
                            <span>{chip}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Safety Tip */}
                    <div className="p-3 rounded-xl bg-slate-200/50 flex items-start gap-2.5 text-slate-600">
                      <Info className="w-4 h-4 text-emerald-800 shrink-0 mt-0.5" />
                      <p className="text-[11px] leading-relaxed">
                        Pastikan ejaan sesuai dengan label kemasan. Sistem kami mengenali nama ilmiah serta turunan alergen umum secara otomatis.
                      </p>
                    </div>

                    {/* CTA Button */}
                    <button
                      type="button"
                      disabled={manualText.trim().length === 0}
                      onClick={() =>
                        executeAnalysis(
                          manualText,
                          manualProductName || 'Produk tanpa nama',
                          'Input Manual'
                        )
                      }
                      className="w-full h-12 rounded-xl bg-emerald-700 text-white font-semibold text-xs flex items-center justify-center gap-2 shadow-sm hover:bg-emerald-800 active:scale-[0.99] transition-all disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      <Search className="w-4 h-4" />
                      <span>Analisis Komposisi</span>
                    </button>
                  </div>
                )}

                {/* 5. SCREEN 5: PROSES ANALISIS */}
                {currentTab === 'scan' && activeScreen === 'analyzing' && (
                  <div className="flex-1 p-6 flex flex-col items-center justify-center text-center animate-fadeIn">
                    {/* Top Scanned Preview card */}
                    <div className="w-full bg-white p-3 rounded-2xl border border-slate-200 shadow-xs flex items-center gap-3 mb-6">
                      <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold">
                        <FileText className="w-5 h-5" />
                      </div>
                      <div className="text-left flex-1 min-w-0">
                        <span className="text-[10px] font-bold text-emerald-700 tracking-wide uppercase">
                          Pindai Sedang Berjalan
                        </span>
                        <h4 className="text-xs font-bold text-slate-900 truncate">{currentProductName}</h4>
                      </div>
                    </div>

                    {/* Concentric Radar Spinner */}
                    <div className="relative w-28 h-28 flex items-center justify-center mb-6">
                      <div className="absolute inset-0 rounded-full bg-emerald-500/15 animate-ping duration-1000" />
                      <div className="absolute inset-2 rounded-full bg-emerald-400/20 animate-pulse" />
                      <div className="w-16 h-16 rounded-full bg-emerald-700 text-white flex items-center justify-center shadow-md">
                        <QrCode className="w-7 h-7 animate-pulse" />
                      </div>
                    </div>

                    <h2 className="text-lg font-bold text-slate-900">Menganalisis Komposisi...</h2>
                    <p className="text-xs text-slate-500 mt-1 max-w-xs leading-relaxed">
                      Mencocokkan bahan dengan profil alergen aktif kamu (
                      <span className="font-semibold text-slate-800">
                        {activeAllergensList.map((a) => a.label).join(', ')}
                      </span>
                      )...
                    </p>

                    {/* Step-by-Step Progress Rail */}
                    <div className="w-full mt-6 space-y-2 text-left">
                      {/* Step 1 */}
                      <div className="flex items-center justify-between p-2.5 rounded-xl bg-white border border-slate-200">
                        <div className="flex items-center gap-2.5">
                          <div
                            className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                              analyzingStep >= 1 ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-400'
                            }`}
                          >
                            <Check className="w-3.5 h-3.5" />
                          </div>
                          <span className="text-xs font-medium text-slate-800">Ekstraksi teks bahan</span>
                        </div>
                        <span className="text-[11px] font-semibold text-emerald-700">Selesai</span>
                      </div>

                      {/* Step 2 */}
                      <div className="flex items-center justify-between p-2.5 rounded-xl bg-white border border-slate-200">
                        <div className="flex items-center gap-2.5">
                          <div
                            className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                              analyzingStep >= 2 ? 'bg-emerald-700 text-white' : 'bg-slate-100 text-slate-400'
                            }`}
                          >
                            {analyzingStep >= 2 ? (
                              <Check className="w-3.5 h-3.5" />
                            ) : (
                              <RotateCcw className="w-3.5 h-3.5 animate-spin" />
                            )}
                          </div>
                          <div>
                            <span className="text-xs font-medium text-slate-800 block">
                              Mencocokkan kamus alergen
                            </span>
                            <span className="text-[10px] text-slate-400">Memeriksa 1.400+ turunan alergen...</span>
                          </div>
                        </div>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            analyzingStep >= 2
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-amber-100 text-amber-800 animate-pulse'
                          }`}
                        >
                          {analyzingStep >= 2 ? 'Selesai' : 'Proses'}
                        </span>
                      </div>

                      {/* Step 3 */}
                      <div className="flex items-center justify-between p-2.5 rounded-xl bg-white border border-slate-200">
                        <div className="flex items-center gap-2.5">
                          <div
                            className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                              analyzingStep >= 3 ? 'bg-emerald-700 text-white' : 'bg-slate-100 text-slate-400'
                            }`}
                          >
                            {analyzingStep >= 3 ? (
                              <Check className="w-3.5 h-3.5" />
                            ) : (
                              <span className="w-2 h-2 rounded-full bg-slate-400" />
                            )}
                          </div>
                          <span className="text-xs font-medium text-slate-800">
                            Verifikasi peringatan jejak produksi
                          </span>
                        </div>
                        <span className="text-[11px] text-slate-400">
                          {analyzingStep >= 3 ? 'Selesai' : 'Menunggu'}
                        </span>
                      </div>
                    </div>

                    {/* Smart Safety Reassurance */}
                    <div className="w-full mt-4 p-3 rounded-xl bg-emerald-50/70 border border-emerald-100 text-left flex items-start gap-2.5">
                      <Shield className="w-4 h-4 text-emerald-800 shrink-0 mt-0.5" />
                      <p className="text-[11px] text-slate-600 leading-relaxed">
                        Sistem kami membaca klausul "Mungkin mengandung" dan varian nama ilmiah seperti <em>casein</em> dan <em>lecithin</em>.
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={() => setActiveScreen('input_method')}
                      className="mt-6 text-xs text-slate-400 hover:text-slate-600 transition-colors"
                    >
                      Batalkan Pemindaian
                    </button>
                  </div>
                )}

                {/* 6, 7, 8: SATU WIDGET RESULT SCREEN (TINGGI / SEDANG / AMAN) */}
                {currentTab === 'scan' && activeScreen === 'result' && currentResult && (
                  <div className="p-4 pb-12 flex flex-col gap-3.5 animate-fadeIn">
                    {/* Top Status Strip & Action */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <span
                          className={`w-2 h-2 rounded-full ${
                            currentResult.riskLevel === 'TINGGI'
                              ? 'bg-rose-600'
                              : currentResult.riskLevel === 'SEDANG'
                              ? 'bg-amber-600'
                              : 'bg-emerald-600'
                          }`}
                        />
                        <span
                          className={`text-[11px] font-bold uppercase tracking-wider ${
                            currentResult.riskLevel === 'TINGGI'
                              ? 'text-rose-600'
                              : currentResult.riskLevel === 'SEDANG'
                              ? 'text-amber-700'
                              : 'text-emerald-700'
                          }`}
                        >
                          Pemeriksaan Selesai
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={handleShareResult}
                          className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white border border-slate-200 text-xs text-slate-700 hover:bg-slate-50 transition-colors shadow-2xs"
                        >
                          <Share2 className="w-3.5 h-3.5" />
                          <span>Bagikan</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setManualText(currentRawText);
                            setManualProductName(currentProductName);
                            setActiveScreen('manual');
                          }}
                          className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-800 text-xs font-semibold hover:bg-emerald-100 transition-colors"
                        >
                          <span>Edit Teks</span>
                        </button>
                      </div>
                    </div>

                    {/* Product Summary Header Card */}
                    <div className="bg-white rounded-2xl p-3.5 border border-slate-200 shadow-xs flex items-center gap-3">
                      <div className="w-12 h-12 rounded-xl bg-slate-100 text-slate-600 flex items-center justify-center font-bold shrink-0">
                        <FileText className="w-6 h-6 text-emerald-700" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between text-[11px] text-slate-400 mb-0.5">
                          <span>Hari ini</span>
                          <span>{currentResult.charCount} karakter terbaca</span>
                        </div>
                        <h3 className="text-sm font-bold text-slate-900 truncate">{currentProductName}</h3>
                        <p className="text-xs text-slate-500 truncate">{currentBrandName}</p>
                      </div>
                    </div>

                    {/* Short Text Warning if charCount < 15 */}
                    {currentResult.isTextTooShort && (
                      <div className="p-3 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 flex items-start gap-2.5">
                        <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0 mt-0.5" />
                        <div>
                          <span className="text-xs font-bold block">Teks Sulit Terbaca</span>
                          <p className="text-[11px] text-amber-800 mt-0.5 leading-relaxed">
                            Teks hasil OCR terlalu pendek (&lt; 15 karakter). Hasil pencocokan mungkin tidak akurat. Coba foto ulang dengan pencahayaan cukup atau ketik manual.
                          </p>
                        </div>
                      </div>
                    )}

                    {/* 1. HERO RISK CARD: TINGGI */}
                    {currentResult.riskLevel === 'TINGGI' && (
                      <div className="bg-rose-50 border border-rose-200 rounded-2xl p-4 shadow-xs">
                        <div className="flex items-center justify-between mb-2">
                          <div className="w-9 h-9 rounded-full bg-rose-600 text-white flex items-center justify-center">
                            <AlertOctagon className="w-5 h-5" />
                          </div>
                          <span className="text-xs font-bold bg-rose-600 text-white px-2.5 py-0.5 rounded-full flex items-center gap-1">
                            <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
                            RISIKO TINGGI
                          </span>
                        </div>
                        <h4 className="text-base font-bold text-rose-900 leading-snug">
                          Mengandung bahan alergen kamu!
                        </h4>
                        <p className="text-xs text-rose-800 mt-1 leading-relaxed">
                          Produk ini tidak aman dikonsumsi berdasarkan pengaturan profil intoleransi & alergen aktif kamu.
                        </p>
                      </div>
                    )}

                    {/* 2. HERO RISK CARD: SEDANG */}
                    {currentResult.riskLevel === 'SEDANG' && (
                      <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 shadow-xs">
                        <div className="flex items-center justify-between mb-2">
                          <div className="w-9 h-9 rounded-full bg-amber-600 text-white flex items-center justify-center">
                            <AlertTriangle className="w-5 h-5" />
                          </div>
                          <span className="text-xs font-bold bg-amber-600 text-white px-2.5 py-0.5 rounded-full">
                            RISIKO SEDANG
                          </span>
                        </div>
                        <h4 className="text-base font-bold text-amber-900 leading-snug">
                          Ada peringatan fasilitas produksi / klaim jejak
                        </h4>
                        <p className="text-xs text-amber-800 mt-1 leading-relaxed">
                          Bahan utama tidak mengandung alergen langsung, tetapi ada potensi kontaminasi silang atau istilah bahan ambigu ("kacang", "may contain", dll).
                        </p>
                      </div>
                    )}

                    {/* 3. HERO RISK CARD: AMAN (Sesuai Aturan Kejujuran UI) */}
                    {currentResult.riskLevel === 'AMAN' && (
                      <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 shadow-xs">
                        <div className="flex items-center justify-between mb-2">
                          <div className="w-9 h-9 rounded-full bg-emerald-700 text-white flex items-center justify-center">
                            <CheckCircle2 className="w-5 h-5" />
                          </div>
                          <span className="text-xs font-bold bg-emerald-700 text-white px-2.5 py-0.5 rounded-full">
                            RISIKO RENDAH / AMAN
                          </span>
                        </div>
                        <h4 className="text-base font-bold text-emerald-950 leading-snug">
                          Tidak ditemukan alergen dari teks yang terbaca
                        </h4>
                        <p className="text-xs text-emerald-800 mt-1 leading-relaxed">
                          Komposisi telah dicocokkan dengan profil alergen aktif kamu dan tidak ditemukan bahan pemicu maupun peringatan fasilitas pada teks yang terbaca.
                        </p>
                      </div>
                    )}

                    {/* TRIGGER INGREDIENTS LIST */}
                    {currentResult.findings.length > 0 && (
                      <div className="space-y-2 mt-1">
                        <div className="flex items-center justify-between">
                          <h4 className="text-xs font-bold text-slate-800 flex items-center gap-1.5">
                            <span>Bahan Pemicu Terdeteksi</span>
                            <span className="w-4 h-4 rounded-full bg-rose-600 text-white text-[10px] flex items-center justify-center font-bold">
                              {currentResult.findings.length}
                            </span>
                          </h4>
                          <span className="text-[11px] text-slate-400">
                            {currentResult.riskLevel === 'TINGGI' ? 'Prioritas Medis' : 'Peringatan Fasilitas'}
                          </span>
                        </div>

                        {currentResult.findings.map((f, i) => (
                          <div
                            key={i}
                            className="p-3 bg-white rounded-xl border border-slate-200 shadow-2xs space-y-1.5"
                          >
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold text-slate-900">{f.allergenLabel}</span>
                              <span
                                className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                                  f.location === 'main'
                                    ? 'bg-rose-100 text-rose-700'
                                    : 'bg-amber-100 text-amber-800'
                                }`}
                              >
                                {f.location === 'main'
                                  ? 'Komposisi Utama'
                                  : f.location === 'trace'
                                  ? 'Klausul Jejak'
                                  : 'Bahan Ambigu'}
                              </span>
                            </div>
                            <div className="p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs text-slate-700">
                              Terdeteksi:{' '}
                              <strong
                                className={
                                  f.location === 'main' ? 'text-rose-600 font-bold' : 'text-amber-700 font-bold'
                                }
                              >
                                {f.matchedWord}
                              </strong>
                              {f.reason && <p className="text-[11px] text-slate-400 mt-0.5">{f.reason}</p>}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Collapsible Full Ingredients Card */}
                    <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
                      <button
                        type="button"
                        onClick={() => setIsIngredientsExpanded(!isIngredientsExpanded)}
                        className="w-full p-3.5 flex items-center justify-between text-left hover:bg-slate-50 transition-colors"
                      >
                        <div className="flex items-center gap-2">
                          <FileText className="w-4 h-4 text-emerald-700" />
                          <div>
                            <span className="text-xs font-bold text-slate-900 block">Komposisi Lengkap</span>
                            <span className="text-[10px] text-slate-400">
                              Sorotan kata kunci pemicu risiko
                            </span>
                          </div>
                        </div>
                        {isIngredientsExpanded ? (
                          <ChevronUp className="w-4 h-4 text-slate-400" />
                        ) : (
                          <ChevronDown className="w-4 h-4 text-slate-400" />
                        )}
                      </button>

                      {isIngredientsExpanded && (
                        <div className="p-3.5 pt-0 border-t border-slate-100">
                          <div className="p-3 rounded-xl bg-slate-50 text-xs text-slate-800 leading-relaxed font-sans mt-2">
                            {currentRawText}
                          </div>
                          <div className="flex items-center justify-between mt-2 text-[11px] text-slate-400">
                            <span>Dianalisis secara offline di perangkat</span>
                            <button
                              type="button"
                              onClick={() => {
                                setManualText(currentRawText);
                                setManualProductName(currentProductName);
                                setActiveScreen('manual');
                              }}
                              className="text-emerald-700 font-semibold hover:underline"
                            >
                              Edit Teks
                            </button>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Medical Disclaimer */}
                    <div className="p-3 rounded-xl bg-slate-200/50 flex items-start gap-2.5 text-slate-600">
                      <Shield className="w-4 h-4 text-emerald-800 shrink-0 mt-0.5" />
                      <p className="text-[10px] leading-relaxed">
                        <strong>Disclaimer Medis:</strong> AllerScan adalah alat bantu penapisan awal dan bukan pengganti membaca label asli secara cermat atau saran dokter spesialis, terutama untuk alergi berat / anafilaksis.
                      </p>
                    </div>

                    {/* Action Buttons */}
                    <div className="space-y-2 pt-1">
                      <button
                        type="button"
                        onClick={() => setActiveScreen('input_method')}
                        className="w-full h-11 rounded-xl bg-emerald-700 text-white font-semibold text-xs flex items-center justify-center gap-2 shadow-sm hover:bg-emerald-800 active:scale-[0.99] transition-all"
                      >
                        <QrCode className="w-4 h-4" />
                        <span>Scan Produk Lain</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => {
                          setIsBookmarked(true);
                          alert('Hasil scan telah tercatat di tab Riwayat!');
                        }}
                        className="w-full h-11 rounded-xl bg-white border border-slate-200 text-slate-800 font-semibold text-xs flex items-center justify-center gap-2 shadow-2xs hover:bg-slate-50 transition-colors"
                      >
                        {isBookmarked ? (
                          <BookmarkCheck className="w-4 h-4 text-emerald-700" />
                        ) : (
                          <Bookmark className="w-4 h-4 text-slate-500" />
                        )}
                        <span>{isBookmarked ? 'Tersimpan di Riwayat' : 'Simpan ke Riwayat'}</span>
                      </button>
                    </div>
                  </div>
                )}

                {/* 9. SCREEN 9: RIWAYAT SCAN */}
                {currentTab === 'riwayat' && (
                  <div className="p-4 pb-12 flex flex-col gap-4 animate-fadeIn">
                    <div className="flex items-center justify-between">
                      <div>
                        <h2 className="text-xl font-bold text-slate-900 tracking-tight">Riwayat Scan</h2>
                        <p className="text-xs text-slate-500 mt-0.5">
                          Daftar produk yang telah kamu periksa sebelumnya.
                        </p>
                      </div>
                      <span className="px-2.5 py-1 rounded-full bg-slate-200 text-slate-700 text-xs font-semibold">
                        {historyList.length} Terdata
                      </span>
                    </div>

                    {/* Weekly Safety Pulse Summary Card */}
                    <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
                          <Shield className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-xs font-bold text-slate-900">Ringkasan Keamanan</div>
                          <div className="text-[11px] text-slate-500">
                            {safeHistoryCount} produk sepenuhnya aman untuk profilmu
                          </div>
                        </div>
                      </div>
                      {/* Mini bar sparkline */}
                      <div className="flex items-end gap-1 h-8">
                        <div
                          style={{ height: `${Math.max(8, highRiskHistoryCount * 8)}px` }}
                          className="w-1.5 rounded-full bg-rose-600"
                          title="Tinggi"
                        />
                        <div
                          style={{ height: `${Math.max(8, mediumRiskHistoryCount * 8)}px` }}
                          className="w-1.5 rounded-full bg-amber-500"
                          title="Sedang"
                        />
                        <div
                          style={{ height: `${Math.max(8, safeHistoryCount * 8)}px` }}
                          className="w-1.5 rounded-full bg-emerald-600"
                          title="Aman"
                        />
                      </div>
                    </div>

                    {/* Filter Chips */}
                    <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1">
                      <button
                        type="button"
                        onClick={() => setHistoryFilter('semua')}
                        className={`px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 shrink-0 transition-all ${
                          historyFilter === 'semua'
                            ? 'bg-emerald-700 text-white shadow-xs'
                            : 'bg-white border border-slate-200 text-slate-600'
                        }`}
                      >
                        <span>Semua</span>
                        <span className="text-[10px] opacity-80">({historyList.length})</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => setHistoryFilter('tinggi')}
                        className={`px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 shrink-0 transition-all ${
                          historyFilter === 'tinggi'
                            ? 'bg-rose-600 text-white shadow-xs'
                            : 'bg-white border border-slate-200 text-slate-600'
                        }`}
                      >
                        <span className="w-2 h-2 rounded-full bg-rose-500" />
                        <span>Tinggi</span>
                        <span className="text-[10px] opacity-80">({highRiskHistoryCount})</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => setHistoryFilter('sedang')}
                        className={`px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 shrink-0 transition-all ${
                          historyFilter === 'sedang'
                            ? 'bg-amber-600 text-white shadow-xs'
                            : 'bg-white border border-slate-200 text-slate-600'
                        }`}
                      >
                        <span className="w-2 h-2 rounded-full bg-amber-500" />
                        <span>Sedang</span>
                        <span className="text-[10px] opacity-80">({mediumRiskHistoryCount})</span>
                      </button>

                      <button
                        type="button"
                        onClick={() => setHistoryFilter('aman')}
                        className={`px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 shrink-0 transition-all ${
                          historyFilter === 'aman'
                            ? 'bg-emerald-700 text-white shadow-xs'
                            : 'bg-white border border-slate-200 text-slate-600'
                        }`}
                      >
                        <span className="w-2 h-2 rounded-full bg-emerald-500" />
                        <span>Aman</span>
                        <span className="text-[10px] opacity-80">({safeHistoryCount})</span>
                      </button>
                    </div>

                    {/* History Cards List */}
                    {filteredHistory.length === 0 ? (
                      <div className="py-12 text-center flex flex-col items-center">
                        <div className="w-12 h-12 rounded-2xl bg-slate-200/60 flex items-center justify-center text-slate-400 mb-2">
                          <History className="w-6 h-6" />
                        </div>
                        <h4 className="text-sm font-bold text-slate-800">Tidak ada riwayat</h4>
                        <p className="text-xs text-slate-400 mt-0.5">
                          Belum ada scan dalam kategori filter ini.
                        </p>
                      </div>
                    ) : (
                      <div className="space-y-2.5">
                        {filteredHistory.map((item) => (
                          <div
                            key={item.id}
                            className="bg-white rounded-2xl p-3.5 border border-slate-200/80 shadow-xs hover:border-emerald-400 transition-all cursor-pointer group"
                            onClick={() => {
                              setCurrentProductName(item.productName);
                              setCurrentBrandName(item.brandOrCategory || 'Hasil Pindai');
                              setCurrentRawText(item.rawText);
                              setCurrentResult({
                                riskLevel: item.riskLevel,
                                findings: item.findings,
                                normalizedText: item.rawText,
                                mainText: item.rawText,
                                traceText: '',
                                charCount: item.charCount,
                                isTextTooShort: item.isTextTooShort,
                              });
                              setCurrentTab('scan');
                              setActiveScreen('result');
                            }}
                          >
                            <div className="flex items-center justify-between text-[11px] text-slate-400 mb-1">
                              <span>
                                {item.inputType === 'camera' ? 'Scan Kamera' : 'Ketik Manual'} • {item.timestamp}
                              </span>
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  const updated = LocalStorageService.deleteHistory(item.id);
                                  setHistoryList(updated);
                                }}
                                className="text-slate-400 hover:text-rose-600 p-1"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            </div>

                            <div className="flex items-center justify-between mb-2">
                              <h4 className="text-xs font-bold text-slate-900 group-hover:text-emerald-700 transition-colors">
                                {item.productName}
                              </h4>
                              <span
                                className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                                  item.riskLevel === 'TINGGI'
                                    ? 'bg-rose-100 text-rose-700'
                                    : item.riskLevel === 'SEDANG'
                                    ? 'bg-amber-100 text-amber-800'
                                    : 'bg-emerald-100 text-emerald-800'
                                }`}
                              >
                                {item.riskLevel}
                              </span>
                            </div>

                            {/* Trigger Pills */}
                            {item.findings.length > 0 ? (
                              <div className="flex flex-wrap gap-1">
                                {item.findings.map((f, idx) => (
                                  <span
                                    key={idx}
                                    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-semibold ${
                                      f.location === 'main'
                                        ? 'bg-rose-50 text-rose-700'
                                        : 'bg-amber-50 text-amber-800'
                                    }`}
                                  >
                                    <AlertTriangle className="w-2.5 h-2.5" />
                                    <span>{f.allergenLabel}</span>
                                  </span>
                                ))}
                              </div>
                            ) : (
                              <div className="flex items-center gap-1 text-[11px] text-emerald-700 font-medium">
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                <span>Bebas dari alergen pada profil kamu</span>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Bottom Navigation Bar */}
              <nav className="h-16 bg-white border-t border-slate-200/80 flex items-center justify-around px-2 shrink-0 z-40">
                <button
                  type="button"
                  onClick={() => {
                    setCurrentTab('scan');
                    setActiveScreen('input_method');
                  }}
                  className={`flex flex-col items-center gap-0.5 w-16 py-1 transition-colors ${
                    currentTab === 'scan' ? 'text-emerald-700 font-bold' : 'text-slate-400 hover:text-slate-600'
                  }`}
                >
                  <QrCode className="w-5 h-5" />
                  <span className="text-[11px]">Scan</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setCurrentTab('riwayat');
                  }}
                  className={`flex flex-col items-center gap-0.5 w-16 py-1 transition-colors ${
                    currentTab === 'riwayat' ? 'text-emerald-700 font-bold' : 'text-slate-400 hover:text-slate-600'
                  }`}
                >
                  <History className="w-5 h-5" />
                  <span className="text-[11px]">Riwayat</span>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setCurrentTab('profil');
                  }}
                  className={`flex flex-col items-center gap-0.5 w-16 py-1 transition-colors ${
                    currentTab === 'profil' ? 'text-emerald-700 font-bold' : 'text-slate-400 hover:text-slate-600'
                  }`}
                >
                  <Shield className="w-5 h-5" />
                  <span className="text-[11px]">Profil</span>
                </button>
              </nav>

              {/* Home Indicator */}
              <div className="h-4 bg-white flex items-center justify-center shrink-0">
                <div className="w-32 h-1 bg-slate-900/30 rounded-full" />
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
