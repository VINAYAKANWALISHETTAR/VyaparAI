import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/providers/language_provider.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _values = {
    'EN': {
      'home': 'Home',
      'records': 'Transactions',
      'reports': 'Reports',
      'more': 'Settings',
      'settings': 'Settings',
      'cash_flow': 'Cash Flow',
      'parties': 'Parties',
      'customers': 'Customers',
      'suppliers': 'Suppliers',
      'reminders': 'Reminders',
      'upload': 'Upload Invoice',
      'voice_assistant': 'Voice Assistant',
      'ai_copilot': 'AI Copilot',

      // Greetings
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'business_overview_today': "Here's your business overview for today",

      // Home Dashboard Cards
      'today_revenue': 'Today Revenue',
      'today_expense': 'Today Expense',
      'today_profit': "Today's Profit",
      'tap_to_talk': 'Tap to talk with VyaparAI',
      'add_sale': 'Add Sale',
      'add_expense': 'Add Expense',
      'upload_btn': 'Upload',
      'ask_ai': 'Ask AI',
      'recent_activity': 'Recent Activity',
      'view_all': 'View All',
      'no_recent_transactions': 'No recent transactions',
      'record_sale_sub': 'Record a sale or upload an invoice to see activity',

      // Transaction Sheet
      'add_sale_income': 'Add Sale / Income',
      'add_expense_title': 'Add Expense',
      'income': 'Income',
      'expense': 'Expense',
      'amount_label': 'Amount (₹)',
      'category_label': 'Category / Source',
      'desc_label': 'Description / Customer Name (Optional)',
      'save_record': 'Save Record',
      'valid_amount_error': 'Please enter a valid amount',

      // Voice Screen
      'bot_greeting_title': 'Hello! I am your VyaparAI Bot',
      'bot_greeting_subtitle': 'Speak to record transactions or ask financial insights',
      'tap_mic_to_speak': 'Tap mic to speak',
      'listening': 'Listening...',
      'analyzing_data': 'Analyzing business data...',
      'type_question': 'Or type your question...',
      'you_can_say': 'You can say...',
      'ask_another': 'Ask Another Question',
      'new_query': 'New Query',
      'try_again': 'Try Again',
      'voice_answer': 'VyaparAI Answer',
      'listen': 'Listen',
      'speaking': 'Speaking...',
      'was_helpful': 'Was this helpful?',
      'voice_greeting_speech': 'Hello! I am your VyaparAI bot. How can I help your business today?',

      // Sample phrases
      'phrase_1': 'Ramesh paid 5000',
      'phrase_2': 'Spent 450 on transport',
      'phrase_3': 'What is my profit today?',
      'phrase_4': 'Who owes me money?',
      'phrase_5': 'Show cash flow forecast',

      // Action Buttons
      'view_details': 'View Details',
      'show_reports': 'Show Reports',
      'set_reminder': 'Set Reminder',
      'check_cash_flow': 'Check Cash Flow',
      'view_all_receivables': 'View All Receivables',

      // Common Filters
      'all': 'All',
      'due': 'Due',
      'paid': 'Paid',
      'active': 'Active',
      'upcoming': 'Upcoming',
      'completed': 'Completed',

      // Settings & Drawer
      'language': 'Language',
      'select_language': 'Select Language',
      'business_profile': 'Business Profile',
      'security_pin': 'Security & App PIN',
      'terms_privacy': 'Terms & Privacy',
      'logout': 'Log Out',

      // Wake-word & Background Voice
      'wake_word_standby': 'Voice Wake-Up Mode',
      'wake_word_desc': "Say 'Hey Vyapar' or 'Vyapar' anytime to wake up the assistant",
      'wake_word_active': 'Always Listening for Wake-Word',
    },
    'KN': {
      'home': 'ಮುಖಪುಟ',
      'records': 'ವಹಿವಾಟುಗಳು',
      'reports': 'ವರದಿಗಳು',
      'more': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'cash_flow': 'ನಗದು ಹರಿವು',
      'parties': 'ವ್ಯಾಪಾರಿಗಳು',
      'customers': 'ಗ್ರಾಹಕರು',
      'suppliers': 'ಪೂರೈಕೆದಾರರು',
      'reminders': 'ಜ್ಞಾಪನೆಗಳು',
      'upload': 'ಇನ್‌ವಾಯ್ಸ್ ಅಪ್‌ಲೋಡ್',
      'voice_assistant': 'ಧ್ವನಿ ಸಹಾಯಕ',
      'ai_copilot': 'AI ಸಹಾಯಕ',

      // Greetings
      'good_morning': 'ಶುಭೋದಯ',
      'good_afternoon': 'ಶುಭ ಮಧ್ಯಾಹ್ನ',
      'good_evening': 'ಶುಭ ಸಂಜೆ',
      'business_overview_today': 'ಇಂದು ನಿಮ್ಮ ವ್ಯವಹಾರದ ಸಾರಾಂಶ ಇಲ್ಲಿದೆ',

      // Home Dashboard Cards
      'today_revenue': 'ಇಂದಿನ ಆದಾಯ',
      'today_expense': 'ಇಂದಿನ ವೆಚ್ಚ',
      'today_profit': 'ಇಂದಿನ ನಿವ್ವಳ ಲಾಭ',
      'tap_to_talk': 'ವ್ಯಾಪಾರ್ AI ಜೊತೆ ಮಾತನಾಡಲು ಒತ್ತಿರಿ',
      'add_sale': 'ಮಾರಾಟ ಸೇರಿಸಿ',
      'add_expense': 'ವೆಚ್ಚ ಸೇರಿಸಿ',
      'upload_btn': 'ಅಪ್‌ಲೋಡ್',
      'ask_ai': 'AI ಪ್ರಶ್ನಿಸಿ',
      'recent_activity': 'ಇತ್ತೀಚಿನ ಚಟುವಟಿಕೆ',
      'view_all': 'ಎಲ್ಲವನ್ನೂ ವೀಕ್ಷಿಸಿ',
      'no_recent_transactions': 'ಯಾವುದೇ ಇತ್ತೀಚಿನ ವಹಿವಾಟುಗಳಿಲ್ಲ',
      'record_sale_sub': 'ಚಟುವಟಿಕೆಯನ್ನು ನೋಡಲು ಮಾರಾಟ ದಾಖಲಿಸಿ ಅಥವಾ ಇನ್‌ವಾಯ್ಸ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',

      // Transaction Sheet
      'add_sale_income': 'ಮಾರಾಟ / ಆದಾಯ ಸೇರಿಸಿ',
      'add_expense_title': 'ವೆಚ್ಚ ಸೇರಿಸಿ',
      'income': 'ಆದಾಯ',
      'expense': 'ವೆಚ್ಚ',
      'amount_label': 'ಮೊತ್ತ (₹)',
      'category_label': 'ವರ್ಗ / ಮೂಲ',
      'desc_label': 'ವಿವರಣೆ / ಗ್ರಾಹಕರ ಹೆಸರು (ಐಚ್ಛಿಕ)',
      'save_record': 'ದಾಖಲೆಯನ್ನು ಉಳಿಸಿ',
      'valid_amount_error': 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಮೊತ್ತವನ್ನು ನಮೂದಿಸಿ',

      // Voice Screen
      'bot_greeting_title': 'ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ವ್ಯಾಪಾರ್ AI ಬಾಟ್',
      'bot_greeting_subtitle': 'ವಹಿವಾಟುಗಳನ್ನು ದಾಖಲಿಸಲು ಅಥವಾ ಆರ್ಥಿಕ ಒಳನೋಟಗಳನ್ನು ಕೇಳಲು ಮಾತನಾಡಿ',
      'tap_mic_to_speak': 'ಮಾತನಾಡಲು ಮೈಕ್ ಒತ್ತಿರಿ',
      'listening': 'ಆಲಿಸಲಾಗುತ್ತಿದೆ...',
      'analyzing_data': 'ವ್ಯಾಪಾರ ಡೇಟಾವನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
      'type_question': 'ಅಥವಾ ನಿಮ್ಮ ಪ್ರಶ್ನೆಯನ್ನು ಟೈಪ್ ಮಾಡಿ...',
      'you_can_say': 'ನೀವು ಹೀಗೆ ಹೇಳಬಹುದು...',
      'ask_another': 'ಮತ್ತೊಂದು ಪ್ರಶ್ನೆ ಕೇಳಿ',
      'new_query': 'ಹೊಸ ಪ್ರಶ್ನೆ',
      'try_again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      'voice_answer': 'ವ್ಯಾಪಾರ್ AI ಉತ್ತರ',
      'listen': 'ಆಲಿಸಿ',
      'speaking': 'ಮಾತನಾಡುತ್ತಿದೆ...',
      'was_helpful': 'ಇದು ಸಹಾಯಕವಾಗಿದೆಯೇ?',
      'voice_greeting_speech': 'ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ವ್ಯಾಪಾರ್ AI ಬಾಟ್. ಇಂದು ನಿಮ್ಮ ವ್ಯವಹಾರಕ್ಕೆ ನಾನು ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?',

      // Sample phrases
      'phrase_1': 'ರಮೇಶ್ 5000 ಪಾವತಿಸಿದ್ದಾರೆ',
      'phrase_2': 'ಸಾರಿಗೆಗಾಗಿ 450 ಖರ್ಚು ಮಾಡಲಾಗಿದೆ',
      'phrase_3': 'ಇಂದು ನನ್ನ ಲಾಭ ಎಷ್ಟು?',
      'phrase_4': 'ನನಗೆ ಯಾರು ಹಣ ಕೊಡಬೇಕು?',
      'phrase_5': 'ನಗದು ಹರಿವಿನ ಮುನ್ಸೂಚನೆ ತೋರಿಸಿ',

      // Action Buttons
      'view_details': 'ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'show_reports': 'ವರದಿಗಳನ್ನು ತೋರಿಸಿ',
      'set_reminder': 'ಜ್ಞಾಪನೆ ಹೊಂದಿಸಿ',
      'check_cash_flow': 'ನಗದು ಹರಿವನ್ನು ಪರಿಶೀಲಿಸಿ',
      'view_all_receivables': 'ಎಲ್ಲಾ ಬಾಕಿಗಳನ್ನು ವೀಕ್ಷಿಸಿ',

      // Common Filters
      'all': 'ಎಲ್ಲಾ',
      'due': 'ಬಾಕಿ',
      'paid': 'ಪಾವತಿಸಿದ',
      'active': 'ಸಕ್ರಿಯ',
      'upcoming': 'ಮುಂಬರುವ',
      'completed': 'ಪೂರ್ಣಗೊಂಡಿದೆ',

      // Settings & Drawer
      'language': 'ಭಾಷೆ',
      'select_language': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'business_profile': 'ವ್ಯಾಪಾರ ಪ್ರೊಫೈಲ್',
      'security_pin': 'ಭದ್ರತೆ ಮತ್ತು ಆಪ್ ಪಿನ್',
      'terms_privacy': 'ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತೆ',
      'logout': 'ಲಾಗ್ ಔಟ್',

      // Wake-word & Background Voice
      'wake_word_standby': 'ಧ್ವನಿ ವೇಕ್-ಅಪ್ ಮೋಡ್',
      'wake_word_desc': "'ಹೇ ವ್ಯಾಪಾರ್' ಅಥವಾ 'ವ್ಯಾಪಾರ್' ಎಂದು ಹೇಳಿ ಬಾಟ್ ಅನ್ನು ಎಬ್ಬಿಸಿ",
      'wake_word_active': 'ವೇಕ್-ವರ್ಡ್‌ಗಾಗಿ ಸದಾ ಆಲಿಸುತ್ತಿದೆ',
    },
    'HI': {
      'home': 'होम',
      'records': 'लेनदेन',
      'reports': 'रिपोर्ट्स',
      'more': 'सेटिंग्स',
      'settings': 'सेटिंग्स',
      'cash_flow': 'कैश फ्लो',
      'parties': 'पार्टियाँ',
      'customers': 'ग्राहक',
      'suppliers': 'आपूर्तिकर्ता',
      'reminders': 'रिमाइंडर',
      'upload': 'इनवॉइस अपलोड',
      'voice_assistant': 'वॉयस असिस्टेंट',
      'ai_copilot': 'AI सहायक',

      // Greetings
      'good_morning': 'शुभ प्रभात',
      'good_afternoon': 'शुभ दोपहर',
      'good_evening': 'शुभ संध्या',
      'business_overview_today': 'यहाँ आज का आपका व्यावसायिक सारांश है',

      // Home Dashboard Cards
      'today_revenue': 'आज का राजस्व',
      'today_expense': 'आज का खर्च',
      'today_profit': 'आज का शुद्ध लाभ',
      'tap_to_talk': 'व्यापार AI से बात करने के लिए टैप करें',
      'add_sale': 'बिक्री जोड़ें',
      'add_expense': 'खर्च जोड़ें',
      'upload_btn': 'अपलोड',
      'ask_ai': 'AI से पूछें',
      'recent_activity': 'हाल की गतिविधि',
      'view_all': 'सभी देखें',
      'no_recent_transactions': 'कोई हालिया लेनदेन नहीं',
      'record_sale_sub': 'गतिविधि देखने के लिए बिक्री रिकॉर्ड करें या इनवॉइस अपलोड करें',

      // Transaction Sheet
      'add_sale_income': 'बिक्री / आय जोड़ें',
      'add_expense_title': 'खर्च जोड़ें',
      'income': 'आय',
      'expense': 'खर्च',
      'amount_label': 'राशि (₹)',
      'category_label': 'श्रेणी / स्रोत',
      'desc_label': 'विवरण / ग्राहक का नाम (वैकल्पिक)',
      'save_record': 'रिकॉर्ड सुरक्षित करें',
      'valid_amount_error': 'कृपया एक मान्य राशि दर्ज करें',

      // Voice Screen
      'bot_greeting_title': 'नमस्ते! मैं आपका व्यापार AI बॉट हूँ',
      'bot_greeting_subtitle': 'लेनदेन रिकॉर्ड करने या वित्तीय जानकारी पूछने के लिए बोलें',
      'tap_mic_to_speak': 'बोलने के लिए माइक दबाएं',
      'listening': 'सुन रहे हैं...',
      'analyzing_data': 'डेटा का विश्लेषण किया जा रहा है...',
      'type_question': 'या अपना प्रश्न टाइप करें...',
      'you_can_say': 'आप कह सकते हैं...',
      'ask_another': 'दूसरा प्रश्न पूछें',
      'new_query': 'नया प्रश्न',
      'try_again': 'पुनः प्रयास करें',
      'voice_answer': 'व्यापार AI उत्तर',
      'listen': 'सुनें',
      'speaking': 'बोल रहा है...',
      'was_helpful': 'क्या यह उपयोगी था?',
      'voice_greeting_speech': 'नमस्ते! मैं आपका व्यापार AI बॉट हूँ। आज मैं आपके व्यवसाय में कैसे मदद कर सकता हूँ?',

      // Sample phrases
      'phrase_1': 'रमेश ने 5000 दिए',
      'phrase_2': 'परिवहन पर 450 खर्च किए',
      'phrase_3': 'आज मेरा लाभ कितना है?',
      'phrase_4': 'मुझ पर किसका बकाया है?',
      'phrase_5': 'कैश फ्लो पूर्वानुमान दिखाएं',

      // Action Buttons
      'view_details': 'विवरण देखें',
      'show_reports': 'रिपोर्ट देखें',
      'set_reminder': 'रिमाइंडर सेट करें',
      'check_cash_flow': 'कैश फ्लो देखें',
      'view_all_receivables': 'सभी प्राप्य देखें',

      // Common Filters
      'all': 'सभी',
      'due': 'बकाया',
      'paid': 'भुगतान',
      'active': 'सक्रिय',
      'upcoming': 'आगामी',
      'completed': 'पूर्ण',

      // Settings & Drawer
      'language': 'भाषा',
      'select_language': 'भाषा चुनें',
      'business_profile': 'व्यवसाय प्रोफ़ाइल',
      'security_pin': 'सुरक्षा और ऐप पिन',
      'terms_privacy': 'शर्तें और गोपनीयता',
      'logout': 'लॉग आउट',

      // Wake-word & Background Voice
      'wake_word_standby': 'वॉयस वेक-अप मोड',
      'wake_word_desc': "'हे व्यापार' या 'व्यापार' बोलकर कभी भी बॉट को सक्रिय करें",
      'wake_word_active': 'वेक-वर्ड के लिए लगातार सुन रहा है',
    },
  };

  static String get(String key, String langCode) {
    final code = langCode.toUpperCase();
    if (_values.containsKey(code) && _values[code]!.containsKey(key)) {
      return _values[code]![key]!;
    }
    // Fallback to English
    return _values['EN']?[key] ?? key;
  }
}

final appTranslationsProvider = Provider<String Function(String)>((ref) {
  final lang = ref.watch(languageProvider);
  return (String key) => AppTranslations.get(key, lang.code);
});
