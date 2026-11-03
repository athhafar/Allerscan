import { createWorker } from 'tesseract.js';

export interface SampleFoodImage {
  id: string;
  name: string;
  brand: string;
  riskHint: 'TINGGI' | 'SEDANG' | 'AMAN';
  sampleText: string;
  imageAlt: string;
}

export const SAMPLE_FOOD_IMAGES: SampleFoodImage[] = [
  {
    id: 'sample-biscuit',
    name: 'Biskuit Gandum Cokelat',
    brand: 'PT Pangan Sehat Nusantara',
    riskHint: 'TINGGI',
    imageAlt: 'Biskuit Gandum Cokelat Artisan',
    sampleText: 'KOMPOSISI: Tepung terigu, gula pasir, minyak nabati, susu bubuk skim (2%), kakao bubuk, garam, pasta kacang tanah (1.5%), pengemulsi lesitin kedelai, perisa sintetik vanila.',
  },
  {
    id: 'sample-chips',
    name: 'Keripik Kentang Barbeque',
    brand: "Lay's Snack Food • 68g",
    riskHint: 'SEDANG',
    imageAlt: 'Keripik Kentang Barbeque',
    sampleText: 'KOMPOSISI: Kentang pilihan, minyak kelapa sawit, bumbu rasa barbekyu (mengandung gula, garam, penguat rasa mononatrium glutamat). Diproduksi pada peralatan yang juga memproses produk yang mengandung kacang dan udang.',
  },
  {
    id: 'sample-almond',
    name: 'Susu Almond Murni Organik',
    brand: 'Nusantara Botanica Ltd • 1000ml',
    riskHint: 'AMAN',
    imageAlt: 'Susu Almond Murni',
    sampleText: 'KOMPOSISI: Air murni, kacang almond panggang (12%), sari kurma alami, kalsium karbonat, garam laut. Tidak mengandung bahan pengawet.',
  },
  {
    id: 'sample-ambiguous',
    name: 'Wafer Cokelat Kacang',
    brand: 'Snack Enak • 45g',
    riskHint: 'SEDANG',
    imageAlt: 'Wafer Cokelat dengan Kacang',
    sampleText: 'KOMPOSISI: Tepung terigu, gula, minyak nabati, kacang, cokelat bubuk, garam.',
  },
  {
    id: 'sample-ocr-typo',
    name: 'Biskuit Krim Susu (OCR Typo)',
    brand: 'Pangan Sehat • 80g',
    riskHint: 'TINGGI',
    imageAlt: 'Biskuit Krim dengan salah baca kaseln',
    sampleText: 'KOMPOSISI: Tepung terigu, gula pasir, minyak nabati, kaseln (protein susu), garam laut.',
  },
];

let workerPromise: Promise<any> | null = null;

export async function recognizeTextFromImageFile(
  fileOrBlob: File | Blob,
  onProgress?: (p: number, status: string) => void
): Promise<string> {
  try {
    onProgress?.(0.1, 'Memuat engine OCR offline...');
    const worker = await createWorker('ind+eng');
    onProgress?.(0.4, 'Memindai karakter pada label...');
    const ret = await worker.recognize(fileOrBlob);
    onProgress?.(0.9, 'Menyelesaikan pembacaan teks...');
    await worker.terminate();
    return ret.data.text || '';
  } catch (err) {
    console.warn('Tesseract OCR error or timeout, applying image-fallback:', err);
    // If user uploaded a photo but worker was blocked by browser sandbox, return text or helpful fallback
    return '';
  }
}
