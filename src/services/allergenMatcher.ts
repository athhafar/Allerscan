/**
 * AllerScan Core Matcher Engine
 * Pure logic for Allergen Detection & Risk Assessment
 */

export type RiskLevel = 'TINGGI' | 'SEDANG' | 'AMAN';

export interface AllergenDef {
  id: string;
  label: string;
  subtitle?: string;
  icon?: string;
  keywords: string[];
  ambiguous?: string[];
  isCustom?: boolean;
}

export interface AllergenMatchFinding {
  allergenId: string;
  allergenLabel: string;
  matchedWord: string;
  keywordMatched: string;
  location: 'main' | 'trace' | 'ambiguous';
  reason?: string;
}

export interface MatchResult {
  riskLevel: RiskLevel;
  findings: AllergenMatchFinding[];
  normalizedText: string;
  mainText: string;
  traceText: string;
  charCount: number;
  isTextTooShort: boolean;
}

// Levenshtein distance calculation
export function levenshteinDistance(a: string, b: string): number {
  const an = a ? a.length : 0;
  const bn = b ? b.length : 0;
  if (an === 0) return bn;
  if (bn === 0) return an;

  const matrix = Array.from({ length: bn + 1 }, () => new Array(an + 1).fill(0));
  for (let i = 0; i <= an; ++i) matrix[0][i] = i;
  for (let i = 0; i <= bn; ++i) matrix[i][0] = i;

  for (let i = 1; i <= bn; ++i) {
    for (let j = 1; j <= an; ++j) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          Math.min(
            matrix[i][j - 1] + 1, // insertion
            matrix[i - 1][j] + 1 // deletion
          )
        );
      }
    }
  }
  return matrix[bn][an];
}

// Common OCR text cleanup & normalizer
export function normalizeOcrText(rawText: string): string {
  if (!rawText) return '';

  let text = rawText.toLowerCase();

  // Replace OCR misreads:
  // '|' surrounded by letters or spaces often means 'l' or 'i'
  text = text.replace(/\|/g, 'l');

  // '0' (zero) inside alphabetic words like 's0y' or 'c0ntains' -> 'o'
  text = text.replace(/([a-z])0([a-z])/g, '$1o$2');
  text = text.replace(/([a-z])0/g, '$1o');
  text = text.replace(/0([a-z])/g, 'o$1');

  // '1' (one) inside alphabetic words like 'm1lk' -> 'i'
  text = text.replace(/([a-z])1([a-z])/g, '$1i$2');

  // Replace excessive punctuation & newlines with spaces, keeping commas and periods intact for separation
  text = text.replace(/[\r\n\t]+/g, ' ');
  text = text.replace(/[;]/g, ',');
  text = text.replace(/\s+/g, ' ');

  return text.trim();
}

// Trace clause keywords indicating cross-contact / factory equipment
const TRACE_PHRASES = [
  'mungkin mengandung',
  'may contain',
  'contains traces',
  'contain traces',
  'mengandung jejak',
  'jejak alergen',
  'traces of',
  'diproduksi di fasilitas',
  'diproduksi pada fasilitas',
  'diproduksi di peralatan',
  'diproduksi pada peralatan',
  'diproses di fasilitas',
  'diproses pada fasilitas',
  'diproses di peralatan',
  'diproses pada peralatan',
  'produced in a facility',
  'produced on equipment',
  'processed in a facility',
  'processed on equipment',
  'peralatan yang juga memproses',
  'fasilitas yang juga memproses',
  'fasilitas yang sama dengan',
  'peralatan yang sama dengan'
];

// Split text into main ingredient text and trace clause text
export function splitTraceClause(normalizedText: string): { mainText: string; traceText: string } {
  let earliestIndex = -1;

  for (const phrase of TRACE_PHRASES) {
    const idx = normalizedText.indexOf(phrase);
    if (idx !== -1) {
      if (earliestIndex === -1 || idx < earliestIndex) {
        earliestIndex = idx;
      }
    }
  }

  if (earliestIndex !== -1) {
    return {
      mainText: normalizedText.slice(0, earliestIndex).trim(),
      traceText: normalizedText.slice(earliestIndex).trim(),
    };
  }

  return {
    mainText: normalizedText,
    traceText: '',
  };
}

// Disqualifiers for generic "kacang" when followed by non-peanut nuts/beans
const NON_PEANUT_FOLLOWERS = [
  'almond',
  'hijau',
  'kedelai',
  'mede',
  'mete',
  'macadamia',
  'pecan',
  'walnut',
  'pistachio',
  'arab',
  'polong',
  'merah',
  'kapri',
  'hazelnut',
  'brazil'
];

/**
 * Checks if a target phrase or keyword exists in text respecting word boundaries and fuzzy matching
 */
export function findMatchInText(
  text: string,
  keyword: string,
  isAmbiguous = false,
  allergenId = ''
): { matched: boolean; actualWord: string } {
  if (!text || !keyword) return { matched: false, actualWord: '' };

  const normText = text.toLowerCase();
  const normKw = keyword.toLowerCase().trim();

  // Special rule for ambiguous "kacang":
  // If text has "kacang almond", "kacang hijau", etc., don't match ambiguous peanut
  if (allergenId === 'kacang_tanah' && normKw === 'kacang') {
    // Check if "kacang" appears without non-peanut qualifiers
    const kacangRegex = /\bkacang\b/gi;
    let match: RegExpExecArray | null;
    while ((match = kacangRegex.exec(normText)) !== null) {
      const matchPos = match.index;
      const followingSlice = normText.slice(matchPos + 6, matchPos + 30).trim();
      const isDisqualified = NON_PEANUT_FOLLOWERS.some(nonPeanut => followingSlice.startsWith(nonPeanut));
      if (!isDisqualified) {
        return { matched: true, actualWord: 'kacang' };
      }
    }
    return { matched: false, actualWord: '' };
  }

  // Multi-word keyword (e.g. "kacang tanah", "susu bubuk skim", "pasta kacang tanah")
  if (normKw.includes(' ')) {
    // Exact word boundary match for multi-word phrases
    const escaped = normKw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(^|[^a-z0-9])${escaped}([^a-z0-9]|$)`, 'i');
    const match = regex.exec(normText);
    if (match) {
      return { matched: true, actualWord: normKw };
    }
    return { matched: false, actualWord: '' };
  }

  // Single-word keyword:
  // Extract word tokens from text
  const tokens = normText.match(/[a-z0-9]+/g) || [];

  for (const token of tokens) {
    if (token === normKw) {
      return { matched: true, actualWord: token };
    }

    // Fuzzy matching: for keyword length >= 6, allow Levenshtein distance 1
    if (normKw.length >= 6 && token.length >= 5 && Math.abs(token.length - normKw.length) <= 1) {
      const dist = levenshteinDistance(token, normKw);
      if (dist === 1) {
        return { matched: true, actualWord: token };
      }
    }
  }

  return { matched: false, actualWord: '' };
}

/**
 * Main analyze function as specified in prompt:
 * MatchResult analyze(String ocrText, List<AllergenDef> activeAllergens)
 */
export function analyzeAllergens(ocrText: string, activeAllergens: AllergenDef[]): MatchResult {
  const normalized = normalizeOcrText(ocrText);
  const charCount = normalized.length;
  const isTextTooShort = charCount < 15;

  const { mainText, traceText } = splitTraceClause(normalized);
  const findings: AllergenMatchFinding[] = [];

  for (const allergen of activeAllergens) {
    let allergenMatchedInMain: AllergenMatchFinding | null = null;
    let allergenMatchedInTrace: AllergenMatchFinding | null = null;
    let allergenMatchedAmbiguous: AllergenMatchFinding | null = null;

    // 1. Check exact / fuzzy keywords in mainText
    for (const kw of allergen.keywords) {
      const res = findMatchInText(mainText, kw, false, allergen.id);
      if (res.matched) {
        allergenMatchedInMain = {
          allergenId: allergen.id,
          allergenLabel: allergen.label,
          matchedWord: res.actualWord,
          keywordMatched: kw,
          location: 'main',
          reason: `Terdeteksi dalam komposisi utama: "${res.actualWord}"`,
        };
        break;
      }
    }

    // 2. Check keywords in traceText (only if not found in mainText)
    if (!allergenMatchedInMain && traceText) {
      for (const kw of allergen.keywords) {
        const res = findMatchInText(traceText, kw, false, allergen.id);
        if (res.matched) {
          allergenMatchedInTrace = {
            allergenId: allergen.id,
            allergenLabel: allergen.label,
            matchedWord: res.actualWord,
            keywordMatched: kw,
            location: 'trace',
            reason: `Terdeteksi pada klausul peringatan fasilitas / jejak: "${res.actualWord}"`,
          };
          break;
        }
      }
    }

    // 3. Check ambiguous keywords (e.g. "kacang" for kacang_tanah)
    if (!allergenMatchedInMain && !allergenMatchedInTrace && allergen.ambiguous && allergen.ambiguous.length > 0) {
      for (const amb of allergen.ambiguous) {
        // Check in mainText first
        let res = findMatchInText(mainText, amb, true, allergen.id);
        let loc: 'main' | 'trace' = 'main';
        if (!res.matched && traceText) {
          res = findMatchInText(traceText, amb, true, allergen.id);
          loc = 'trace';
        }

        if (res.matched) {
          allergenMatchedAmbiguous = {
            allergenId: allergen.id,
            allergenLabel: allergen.label,
            matchedWord: res.actualWord,
            keywordMatched: amb,
            location: 'ambiguous',
            reason: allergen.id === 'kacang_tanah'
              ? 'Terdeteksi kata "kacang" tanpa spesifikasi varietas, berpotensi kacang tanah'
              : `Terdeteksi kata umum "${res.actualWord}" yang berpotensi memicu ${allergen.label}`,
          };
          break;
        }
      }
    }

    if (allergenMatchedInMain) {
      findings.push(allergenMatchedInMain);
    } else if (allergenMatchedInTrace) {
      findings.push(allergenMatchedInTrace);
    } else if (allergenMatchedAmbiguous) {
      findings.push(allergenMatchedAmbiguous);
    }
  }

  // Determine final risk level
  let riskLevel: RiskLevel = 'AMAN';
  if (findings.some(f => f.location === 'main')) {
    riskLevel = 'TINGGI';
  } else if (findings.some(f => f.location === 'trace' || f.location === 'ambiguous')) {
    riskLevel = 'SEDANG';
  } else {
    riskLevel = 'AMAN';
  }

  return {
    riskLevel,
    findings,
    normalizedText: normalized,
    mainText,
    traceText,
    charCount,
    isTextTooShort,
  };
}
