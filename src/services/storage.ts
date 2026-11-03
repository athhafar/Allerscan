import { AllergenDef, MatchResult, RiskLevel } from './allergenMatcher';

export interface HistoryItem {
  id: string;
  productName: string;
  brandOrCategory?: string;
  rawText: string;
  riskLevel: RiskLevel;
  findings: MatchResult['findings'];
  timestamp: string;
  charCount: number;
  isTextTooShort: boolean;
  imageThumbnail?: string;
  inputType: 'camera' | 'manual';
}

const STORAGE_KEYS = {
  SELECTED_ALLERGENS: 'allerscan_selected_allergens_v1',
  CUSTOM_ALLERGENS: 'allerscan_custom_allergens_v1',
  HISTORY: 'allerscan_history_v1',
  HAS_ONBOARDED: 'allerscan_onboarded_v1',
};

export const INITIAL_PRESET_ALLERGENS: AllergenDef[] = [
  {
    id: 'kacang_tanah',
    label: 'Kacang',
    subtitle: 'Peanuts',
    icon: 'nutrition',
    keywords: [
      'kacang tanah',
      'peanut',
      'peanuts',
      'arachis',
      'groundnut',
      'pasta kacang tanah',
      'minyak kacang tanah',
      'selai kacang',
      'peanut butter',
      'tepung kacang',
    ],
    ambiguous: ['kacang'],
  },
  {
    id: 'susu',
    label: 'Susu',
    subtitle: 'Dairy & Laktosa',
    icon: 'local_cafe',
    keywords: [
      'susu',
      'milk',
      'whey',
      'kasein',
      'casein',
      'laktosa',
      'lactose',
      'krim',
      'cream',
      'mentega',
      'butter',
      'keju',
      'cheese',
      'yogurt',
      'yoghurt',
      'susu bubuk',
      'susu skim',
      'susu bubuk skim',
      'padatan susu',
      'kalsium kaseinat',
    ],
    ambiguous: [],
  },
  {
    id: 'telur',
    label: 'Telur',
    subtitle: 'Egg Albumin',
    icon: 'egg',
    keywords: [
      'telur',
      'egg',
      'eggs',
      'albumin',
      'albumen',
      'kuning telur',
      'putih telur',
      'lisozim',
      'lysozyme',
      'ovalbumin',
      'mayones',
      'mayonnaise',
      'egg yolk',
      'egg white',
      'tepung telur',
    ],
    ambiguous: [],
  },
  {
    id: 'gluten',
    label: 'Gluten',
    subtitle: 'Gandum / Tepung',
    icon: 'grain',
    keywords: [
      'gluten',
      'terigu',
      'gandum',
      'wheat',
      'barley',
      'rye',
      'malt',
      'semolina',
      'tepung terigu',
      'pati gandum',
      'oat',
      'oats',
      'havermut',
      'spelt',
      'durum',
    ],
    ambiguous: [],
  },
  {
    id: 'ikan',
    label: 'Seafood',
    subtitle: 'Ikan Laut',
    icon: 'set_meal',
    keywords: [
      'ikan',
      'fish',
      'salmon',
      'tuna',
      'tongkol',
      'tenggiri',
      'makarel',
      'anchovy',
      'teri',
      'gelatin ikan',
      'minyak ikan',
      'fish oil',
      'ekstrak ikan',
      'saus ikan',
      'kecap ikan',
      'surimi',
    ],
    ambiguous: ['seafood', 'ikan laut'],
  },
  {
    id: 'kedelai',
    label: 'Kedelai',
    subtitle: 'Soy & Lecithin',
    icon: 'eco',
    keywords: [
      'kedelai',
      'soy',
      'soya',
      'lesitin kedelai',
      'soy lecithin',
      'tempe',
      'tahu',
      'tofu',
      'kecap',
      'edamame',
      'protein kedelai',
      'minyak kedelai',
      'susu kedelai',
    ],
    ambiguous: [],
  },
  {
    id: 'wijen',
    label: 'Wijen',
    subtitle: 'Sesame Seed',
    icon: 'bubble_chart',
    keywords: [
      'wijen',
      'sesame',
      'sesame seed',
      'biji wijen',
      'minyak wijen',
      'tahini',
      'pasta wijen',
    ],
    ambiguous: [],
  },
  {
    id: 'udang',
    label: 'Udang',
    subtitle: 'Crustacea',
    icon: 'phishing',
    keywords: [
      'udang',
      'shrimp',
      'prawn',
      'krustasea',
      'crustacean',
      'crustaceans',
      'terasi',
      'kepiting',
      'crab',
      'lobster',
      'ebi',
      'rebon',
      'petis udang',
      'ekstrak udang',
    ],
    ambiguous: ['seafood'],
  },
];

// Seed initial history matching Stitch design mockups
export const INITIAL_HISTORY_SEED: HistoryItem[] = [
  {
    id: 'seed-1',
    productName: 'Biskuit Gandum Cokelat',
    brandOrCategory: 'Kraft Mondelez Food • 120g',
    rawText: 'Tepung terigu, gula pasir, minyak nabati, susu bubuk skim (2%), kakao bubuk, garam, pasta kacang tanah (1.5%), pengemulsi lesitin kedelai, perisa sintetik vanila.',
    riskLevel: 'TINGGI',
    findings: [
      {
        allergenId: 'susu',
        allergenLabel: 'Susu Sapi',
        matchedWord: 'susu bubuk skim (2%)',
        keywordMatched: 'susu bubuk skim',
        location: 'main',
        reason: 'Terdeteksi dalam komposisi utama: "susu bubuk skim"',
      },
      {
        allergenId: 'kacang_tanah',
        allergenLabel: 'Kacang Tanah',
        matchedWord: 'pasta kacang tanah (1.5%)',
        keywordMatched: 'pasta kacang tanah',
        location: 'main',
        reason: 'Terdeteksi dalam komposisi utama: "pasta kacang tanah"',
      },
    ],
    timestamp: 'Hari ini, 10:42',
    charCount: 168,
    isTextTooShort: false,
    inputType: 'camera',
  },
  {
    id: 'seed-2',
    productName: 'Keripik Kentang Barbeque',
    brandOrCategory: "Lay's Snack Food • 68g",
    rawText: 'Kentang pilihan, minyak kelapa sawit, bumbu rasa barbekyu (mengandung gula, garam, penguat rasa mononatrium glutamat). Diproduksi pada peralatan yang juga memproses produk yang mengandung kacang dan udang.',
    riskLevel: 'SEDANG',
    findings: [
      {
        allergenId: 'kacang_tanah',
        allergenLabel: 'Kacang Tanah',
        matchedWord: 'kacang',
        keywordMatched: 'kacang',
        location: 'trace',
        reason: 'Terdeteksi pada klausul fasilitas/jejak: "kacang"',
      },
      {
        allergenId: 'udang',
        allergenLabel: 'Jejak Udang & Krustasea',
        matchedWord: 'udang',
        keywordMatched: 'udang',
        location: 'trace',
        reason: 'Terdeteksi pada klausul fasilitas/jejak: "udang"',
      },
    ],
    timestamp: 'Hari ini, 09:15',
    charCount: 206,
    isTextTooShort: false,
    inputType: 'manual',
  },
  {
    id: 'seed-3',
    productName: 'Susu Almond Murni Organik',
    brandOrCategory: '137 Degrees Pure • 1000ml',
    rawText: 'Air murni, kacang almond panggang (12%), sari kurma alami, kalsium karbonat, garam laut.',
    riskLevel: 'AMAN',
    findings: [],
    timestamp: 'Kemarin, 16:30',
    charCount: 88,
    isTextTooShort: false,
    inputType: 'camera',
  },
  {
    id: 'seed-4',
    productName: 'Roti Tawar Gandum Utuh',
    brandOrCategory: 'Sari Roti Premium • 350g',
    rawText: 'Tepung terigu, tepung gandum utuh, air, ragi, gula pasir, mentega nabati, garam, kalsium propionat.',
    riskLevel: 'TINGGI',
    findings: [
      {
        allergenId: 'gluten',
        allergenLabel: 'Gluten Tinggi',
        matchedWord: 'tepung terigu',
        keywordMatched: 'tepung terigu',
        location: 'main',
        reason: 'Terdeteksi dalam komposisi utama: "tepung terigu"',
      },
    ],
    timestamp: '14 Okt 2026',
    charCount: 104,
    isTextTooShort: false,
    inputType: 'camera',
  },
];

export const LocalStorageService = {
  getSelectedAllergenIds(): string[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.SELECTED_ALLERGENS);
      if (saved) return JSON.parse(saved);
    } catch {}
    // Default 4 selected per Stitch design screen 1
    return ['kacang_tanah', 'susu', 'gluten', 'udang'];
  },

  saveSelectedAllergenIds(ids: string[]) {
    try {
      localStorage.setItem(STORAGE_KEYS.SELECTED_ALLERGENS, JSON.stringify(ids));
    } catch {}
  },

  getCustomAllergens(): AllergenDef[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.CUSTOM_ALLERGENS);
      if (saved) return JSON.parse(saved);
    } catch {}
    return [];
  },

  saveCustomAllergens(list: AllergenDef[]) {
    try {
      localStorage.setItem(STORAGE_KEYS.CUSTOM_ALLERGENS, JSON.stringify(list));
    } catch {}
  },

  getHistory(): HistoryItem[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.HISTORY);
      if (saved) return JSON.parse(saved);
    } catch {}
    return INITIAL_HISTORY_SEED;
  },

  saveHistory(history: HistoryItem[]) {
    try {
      localStorage.setItem(STORAGE_KEYS.HISTORY, JSON.stringify(history));
    } catch {}
  },

  addHistory(item: HistoryItem): HistoryItem[] {
    const list = this.getHistory();
    const updated = [item, ...list];
    this.saveHistory(updated);
    return updated;
  },

  deleteHistory(id: string): HistoryItem[] {
    const list = this.getHistory();
    const updated = list.filter(item => item.id !== id);
    this.saveHistory(updated);
    return updated;
  },

  clearHistory() {
    this.saveHistory([]);
  },
};
