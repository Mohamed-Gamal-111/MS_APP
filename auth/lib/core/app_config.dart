class AppConfig {
  static const String baseUrl = 'https://parkinson-ai-backend-production.up.railway.app';

  static const String fingerEndpoint = '/analyze/finger';
  static const String rombergEndpoint = '/analyze/romberg';
  static const String tandemEndpoint = '/analyze/tandem';

  // اسم الملف في طلب الرفع. لو الباك إند عندك مستني اسم مختلف غير video غيره هنا فقط.
  static const String videoFieldName = 'video';
}
