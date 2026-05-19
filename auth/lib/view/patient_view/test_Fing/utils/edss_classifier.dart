String classifyEDSS(int taps, double irregularity) {
  if (taps >= 45 && irregularity < 80) {
    return "EDSS 0.0 – 1.5 (طبيعي)";
  } else if (taps >= 35) {
    return "EDSS 2.0 – 3.0 (ضعف بسيط)";
  } else if (taps >= 25) {
    return "EDSS 3.5 – 4.5 (ضعف متوسط)";
  } else if (taps >= 15) {
    return "EDSS 5.0 – 6.0 (ضعف واضح)";
  } else {
    return "EDSS ≥ 6.5 (إعاقة شديدة)";
  }
}
