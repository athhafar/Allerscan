import { analyzeAllergens, AllergenDef } from './allergenMatcher';

const sampleAllergens: Record<string, AllergenDef> = {
  kacang_tanah: {
    id: 'kacang_tanah',
    label: 'Kacang Tanah',
    keywords: ['kacang tanah', 'peanut', 'peanuts', 'arachis', 'groundnut', 'pasta kacang tanah', 'minyak kacang tanah'],
    ambiguous: ['kacang'],
  },
  susu: {
    id: 'susu',
    label: 'Susu',
    keywords: ['susu', 'milk', 'whey', 'kasein', 'casein', 'laktosa', 'lactose', 'krim', 'cream', 'mentega', 'butter', 'keju', 'cheese', 'yogurt', 'yoghurt', 'susu bubuk', 'susu skim', 'susu bubuk skim'],
    ambiguous: [],
  },
  udang: {
    id: 'udang',
    label: 'Udang',
    keywords: ['udang', 'shrimp', 'prawn', 'krustasea', 'crustacean', 'terasi', 'kepiting', 'crab', 'lobster'],
    ambiguous: ['seafood'],
  },
};

export function runMatcherUnitTests() {
  const results: { name: string; passed: boolean; message?: string }[] = [];

  // Test 1: "tepung terigu, gula, susu bubuk skim (2%), pasta kacang tanah" with profile [susu, kacang_tanah] -> TINGGI, 2 temuan
  {
    const text = 'tepung terigu, gula, susu bubuk skim (2%), pasta kacang tanah';
    const profile = [sampleAllergens.susu, sampleAllergens.kacang_tanah];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'TINGGI' && res.findings.length === 2;
    results.push({
      name: 'Test 1: Bahan utama susu bubuk skim dan pasta kacang tanah -> TINGGI (2 temuan)',
      passed,
      message: `Risk: ${res.riskLevel}, Findings: ${res.findings.length} (${res.findings.map(f => f.allergenLabel).join(', ')})`,
    });
  }

  // Test 2: "air, kacang almond, garam" with profile [kacang_tanah] -> AMAN
  {
    const text = 'air, kacang almond, garam';
    const profile = [sampleAllergens.kacang_tanah];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'AMAN' && res.findings.length === 0;
    results.push({
      name: 'Test 2: "kacang almond" tidak memicu kacang_tanah -> AMAN',
      passed,
      message: `Risk: ${res.riskLevel}, Findings: ${res.findings.length}`,
    });
  }

  // Test 3: "air, gula. Diproduksi pada peralatan yang juga memproses kacang tanah dan udang" with profile [kacang_tanah, udang] -> SEDANG
  {
    const text = 'air, gula. Diproduksi pada peralatan yang juga memproses kacang tanah dan udang';
    const profile = [sampleAllergens.kacang_tanah, sampleAllergens.udang];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'SEDANG' && res.findings.length === 2;
    results.push({
      name: 'Test 3: Klausul jejak "Diproduksi pada peralatan..." -> SEDANG',
      passed,
      message: `Risk: ${res.riskLevel}, Findings: ${res.findings.length}`,
    });
  }

  // Test 4: teks kosong -> AMAN (dengan isTextTooShort = true)
  {
    const text = '';
    const profile = [sampleAllergens.susu];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'AMAN' && res.isTextTooShort === true;
    results.push({
      name: 'Test 4: Teks kosong -> AMAN dengan isTextTooShort = true',
      passed,
      message: `Risk: ${res.riskLevel}, isTextTooShort: ${res.isTextTooShort}`,
    });
  }

  // Test 5: salah baca OCR "kaseln" with profile [susu] -> TINGGI (Levenshtein 1 dari kasein)
  {
    const text = 'gula, minyak nabati, kaseln, garam';
    const profile = [sampleAllergens.susu];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'TINGGI' && res.findings.some(f => f.allergenId === 'susu');
    results.push({
      name: 'Test 5: Salah baca OCR "kaseln" cocok ke "kasein" (fuzzy dist 1) -> TINGGI',
      passed,
      message: `Risk: ${res.riskLevel}, Matched: ${res.findings[0]?.matchedWord}`,
    });
  }

  // Test 6: "kacang, garam" with profile [kacang_tanah] -> SEDANG (ambiguous)
  {
    const text = 'kacang, garam';
    const profile = [sampleAllergens.kacang_tanah];
    const res = analyzeAllergens(text, profile);
    const passed = res.riskLevel === 'SEDANG' && res.findings.some(f => f.location === 'ambiguous');
    results.push({
      name: 'Test 6: Kata ambiguous "kacang" tanpa nama varietas -> SEDANG',
      passed,
      message: `Risk: ${res.riskLevel}, Location: ${res.findings[0]?.location}, Reason: ${res.findings[0]?.reason}`,
    });
  }

  return results;
}
