import fs from 'fs';
import { execSync } from 'child_process';
import path from 'path';

const brandingDir = path.resolve('assets/branding');
if (!fs.existsSync(brandingDir)) {
  fs.mkdirSync(brandingDir, { recursive: true });
}

// 1. Logo SVG (Multi-color Master Vector)
const logoSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <filter id="subtleGlow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.18"/>
    </filter>
  </defs>

  <!-- Solid Background for Master Logo -->
  <rect width="1024" height="1024" rx="224" fill="#006A43"/>

  <!-- 4 Viewfinder Scanner Brackets -->
  <g stroke="#8DF8BD" stroke-width="32" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <!-- Top-Left -->
    <path d="M 280, 370 V 310 C 280, 290 296, 274 316, 274 H 376"/>
    <!-- Top-Right -->
    <path d="M 648, 274 H 708 C 728, 274 744, 290 744, 310 V 370"/>
    <!-- Bottom-Left -->
    <path d="M 280, 654 V 714 C 280, 734 296, 750 316, 750 H 376"/>
    <!-- Bottom-Right -->
    <path d="M 648, 750 H 708 C 728, 750 744, 734 744, 714 V 654"/>
  </g>

  <!-- Central Protective Medical Shield with Shadow -->
  <g filter="url(#subtleGlow)">
    <path d="M 370, 338 C 370, 338 512, 320 512, 320 C 512, 320 654, 338 654, 338 C 674, 340 688, 356 688, 376 V 496 C 688, 608 596, 686 512, 720 C 428, 686 336, 608 336, 496 V 376 C 336, 356 350, 340 370, 338 Z"
          fill="#FFFFFF"/>
  </g>

  <!-- Inner Leaf & Verified Checkmark Motif -->
  <!-- Leaf element (Purity / Allergen-free nature) -->
  <path d="M 512, 400 C 564, 400 610, 436 618, 488 C 572, 496 524, 474 500, 432 C 496, 424 502, 400 512, 400 Z"
        fill="#8DF8BD"/>

  <!-- Checkmark (Clinical Safety & Verified) -->
  <path d="M 426, 508 L 486, 568 L 598, 452"
        fill="none"
        stroke="#006A43"
        stroke-width="36"
        stroke-linecap="round"
        stroke-linejoin="round"/>
</svg>`;

// 2. Icon Full SVG (1024x1024 solid background for legacy launcher)
const iconFullSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <rect width="1024" height="1024" fill="#006A43"/>

  <!-- 4 Viewfinder Scanner Brackets -->
  <g stroke="#8DF8BD" stroke-width="32" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M 280, 370 V 310 C 280, 290 296, 274 316, 274 H 376"/>
    <path d="M 648, 274 H 708 C 728, 274 744, 290 744, 310 V 370"/>
    <path d="M 280, 654 V 714 C 280, 734 296, 750 316, 750 H 376"/>
    <path d="M 648, 750 H 708 C 728, 750 744, 734 744, 714 V 654"/>
  </g>

  <!-- Central Protective Shield -->
  <path d="M 370, 338 C 370, 338 512, 320 512, 320 C 512, 320 654, 338 654, 338 C 674, 340 688, 356 688, 376 V 496 C 688, 608 596, 686 512, 720 C 428, 686 336, 608 336, 496 V 376 C 336, 356 350, 340 370, 338 Z"
        fill="#FFFFFF"/>

  <!-- Leaf Accent -->
  <path d="M 512, 400 C 564, 400 610, 436 618, 488 C 572, 496 524, 474 500, 432 C 496, 424 502, 400 512, 400 Z"
        fill="#8DF8BD"/>

  <!-- Checkmark -->
  <path d="M 426, 508 L 486, 568 L 598, 452"
        fill="none"
        stroke="#006A43"
        stroke-width="36"
        stroke-linecap="round"
        stroke-linejoin="round"/>
</svg>`;

// 3. Icon Foreground SVG (1024x1024 transparent, symbol within center 66% safe zone)
const iconForegroundSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <!-- 4 Viewfinder Scanner Brackets -->
  <g stroke="#8DF8BD" stroke-width="32" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M 280, 370 V 310 C 280, 290 296, 274 316, 274 H 376"/>
    <path d="M 648, 274 H 708 C 728, 274 744, 290 744, 310 V 370"/>
    <path d="M 280, 654 V 714 C 280, 734 296, 750 316, 750 H 376"/>
    <path d="M 648, 750 H 708 C 728, 750 744, 734 744, 714 V 654"/>
  </g>

  <!-- Central Protective Shield -->
  <path d="M 370, 338 C 370, 338 512, 320 512, 320 C 512, 320 654, 338 654, 338 C 674, 340 688, 356 688, 376 V 496 C 688, 608 596, 686 512, 720 C 428, 686 336, 608 336, 496 V 376 C 336, 356 350, 340 370, 338 Z"
        fill="#FFFFFF"/>

  <!-- Leaf Accent -->
  <path d="M 512, 400 C 564, 400 610, 436 618, 488 C 572, 496 524, 474 500, 432 C 496, 424 502, 400 512, 400 Z"
        fill="#8DF8BD"/>

  <!-- Checkmark -->
  <path d="M 426, 508 L 486, 568 L 598, 452"
        fill="none"
        stroke="#006A43"
        stroke-width="36"
        stroke-linecap="round"
        stroke-linejoin="round"/>
</svg>`;

// 4. Icon Monochrome SVG (1024x1024 transparent, pure white for Android 13+ Themed Icons)
const iconMonochromeSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <!-- 4 Viewfinder Scanner Brackets -->
  <g stroke="#FFFFFF" stroke-width="32" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M 280, 370 V 310 C 280, 290 296, 274 316, 274 H 376"/>
    <path d="M 648, 274 H 708 C 728, 274 744, 290 744, 310 V 370"/>
    <path d="M 280, 654 V 714 C 280, 734 296, 750 316, 750 H 376"/>
    <path d="M 648, 750 H 708 C 728, 750 744, 734 744, 714 V 654"/>
  </g>

  <!-- Central Protective Shield (Stroke so it stays distinct on monochrome background) -->
  <path d="M 370, 338 C 370, 338 512, 320 512, 320 C 512, 320 654, 338 654, 338 C 674, 340 688, 356 688, 376 V 496 C 688, 608 596, 686 512, 720 C 428, 686 336, 608 336, 496 V 376 C 336, 356 350, 340 370, 338 Z"
        fill="none"
        stroke="#FFFFFF"
        stroke-width="36"
        stroke-linejoin="round"/>

  <!-- Leaf Accent -->
  <path d="M 512, 400 C 564, 400 610, 436 618, 488 C 572, 496 524, 474 500, 432 C 496, 424 502, 400 512, 400 Z"
        fill="#FFFFFF"/>

  <!-- Checkmark -->
  <path d="M 426, 508 L 486, 568 L 598, 452"
        fill="none"
        stroke="#FFFFFF"
        stroke-width="36"
        stroke-linecap="round"
        stroke-linejoin="round"/>
</svg>`;

// Write master logo.svg
fs.writeFileSync(path.join(brandingDir, 'logo.svg'), logoSvg.trim());

// Helper to render HTML with Chrome
function renderSvgToPng(svgContent, outputPath, isTransparent = true) {
  const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body {
    width: 1024px;
    height: 1024px;
    overflow: hidden;
    background: ${isTransparent ? 'transparent' : '#006A43'};
  }
  svg {
    width: 1024px;
    height: 1024px;
    display: block;
  }
</style>
</head>
<body>
${svgContent}
</body>
</html>`;

  const tmpHtml = `/tmp/render_${Date.now()}_${Math.random().toString(36).substring(7)}.html`;
  fs.writeFileSync(tmpHtml, html);

  const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  const cmd = `"${chromePath}" --headless=new --screenshot="${outputPath}" --window-size=1024,1024 --default-background-color=${isTransparent ? '00000000' : 'ff006a43'} "file://${tmpHtml}"`;

  execSync(cmd, { stdio: 'pipe' });
  fs.unlinkSync(tmpHtml);
}

console.log('Rendering icon_full.png...');
renderSvgToPng(iconFullSvg, path.join(brandingDir, 'icon_full.png'), false);

console.log('Rendering icon_foreground.png...');
renderSvgToPng(iconForegroundSvg, path.join(brandingDir, 'icon_foreground.png'), true);

console.log('Rendering icon_monochrome.png...');
renderSvgToPng(iconMonochromeSvg, path.join(brandingDir, 'icon_monochrome.png'), true);

console.log('All branding assets generated successfully.');
