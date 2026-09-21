import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'VyaparAI'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get records;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cash_flow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cash_flow;

  /// No description provided for @parties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get parties;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload Invoice'**
  String get upload;

  /// No description provided for @voice_assistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voice_assistant;

  /// No description provided for @ai_copilot.
  ///
  /// In en, this message translates to:
  /// **'AI Copilot'**
  String get ai_copilot;

  /// No description provided for @ai_assistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get ai_assistant;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get good_morning;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get good_evening;

  /// No description provided for @business_overview_today.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your business overview for today'**
  String get business_overview_today;

  /// No description provided for @small_steps_quote.
  ///
  /// In en, this message translates to:
  /// **'\"Small steps'**
  String get small_steps_quote;

  /// No description provided for @build_big_businesses.
  ///
  /// In en, this message translates to:
  /// **'build big businesses\"'**
  String get build_big_businesses;

  /// No description provided for @today_revenue.
  ///
  /// In en, this message translates to:
  /// **'Today Revenue'**
  String get today_revenue;

  /// No description provided for @today_expense.
  ///
  /// In en, this message translates to:
  /// **'Today Expense'**
  String get today_expense;

  /// No description provided for @today_profit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Profit'**
  String get today_profit;

  /// No description provided for @tap_to_talk.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk with VyaparAI'**
  String get tap_to_talk;

  /// No description provided for @add_sale.
  ///
  /// In en, this message translates to:
  /// **'Add Sale'**
  String get add_sale;

  /// No description provided for @add_expense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get add_expense;

  /// No description provided for @upload_btn.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload_btn;

  /// No description provided for @ask_ai.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get ask_ai;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recent_activity;

  /// No description provided for @view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get view_all;

  /// No description provided for @no_recent_transactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get no_recent_transactions;

  /// No description provided for @record_sale_sub.
  ///
  /// In en, this message translates to:
  /// **'Record a sale or upload an invoice to see activity'**
  String get record_sale_sub;

  /// No description provided for @add_sale_income.
  ///
  /// In en, this message translates to:
  /// **'Add Sale / Income'**
  String get add_sale_income;

  /// No description provided for @add_expense_title.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get add_expense_title;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @amount_label.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amount_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Category / Source'**
  String get category_label;

  /// No description provided for @desc_label.
  ///
  /// In en, this message translates to:
  /// **'Description / Customer Name (Optional)'**
  String get desc_label;

  /// No description provided for @save_record.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get save_record;

  /// No description provided for @valid_amount_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get valid_amount_error;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @general_expense.
  ///
  /// In en, this message translates to:
  /// **'General Expense'**
  String get general_expense;

  /// No description provided for @bot_greeting_title.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your VyaparAI Bot'**
  String get bot_greeting_title;

  /// No description provided for @bot_greeting_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Speak to record transactions or ask financial insights'**
  String get bot_greeting_subtitle;

  /// No description provided for @tap_mic_to_speak.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to speak'**
  String get tap_mic_to_speak;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @analyzing_data.
  ///
  /// In en, this message translates to:
  /// **'Analyzing business data...'**
  String get analyzing_data;

  /// No description provided for @type_question.
  ///
  /// In en, this message translates to:
  /// **'Or type your question...'**
  String get type_question;

  /// No description provided for @you_can_say.
  ///
  /// In en, this message translates to:
  /// **'You can say...'**
  String get you_can_say;

  /// No description provided for @ask_another.
  ///
  /// In en, this message translates to:
  /// **'Ask Another Question'**
  String get ask_another;

  /// No description provided for @new_query.
  ///
  /// In en, this message translates to:
  /// **'New Query'**
  String get new_query;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @voice_answer.
  ///
  /// In en, this message translates to:
  /// **'VyaparAI Answer'**
  String get voice_answer;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get speaking;

  /// No description provided for @was_helpful.
  ///
  /// In en, this message translates to:
  /// **'Was this helpful?'**
  String get was_helpful;

  /// No description provided for @voice_greeting_speech.
  ///
  /// In en, this message translates to:
  /// **'Hello! Welcome to VyparaAI. How can I help your business today?'**
  String get voice_greeting_speech;

  /// No description provided for @wake_word_standby.
  ///
  /// In en, this message translates to:
  /// **'Voice Wake-Up Mode'**
  String get wake_word_standby;

  /// No description provided for @wake_word_desc.
  ///
  /// In en, this message translates to:
  /// **'Say \'Hey Vyapar\' or \'Vyapar\' anytime to wake up the assistant'**
  String get wake_word_desc;

  /// No description provided for @wake_word_active.
  ///
  /// In en, this message translates to:
  /// **'Always Listening for Wake-Word'**
  String get wake_word_active;

  /// No description provided for @mic_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Please enable it in Settings.'**
  String get mic_permission_denied;

  /// No description provided for @mic_error.
  ///
  /// In en, this message translates to:
  /// **'Microphone error occurred. Please try again.'**
  String get mic_error;

  /// No description provided for @no_voice_response.
  ///
  /// In en, this message translates to:
  /// **'No response from VyaparAI.'**
  String get no_voice_response;

  /// No description provided for @phrase_1.
  ///
  /// In en, this message translates to:
  /// **'Ramesh paid 5000'**
  String get phrase_1;

  /// No description provided for @phrase_2.
  ///
  /// In en, this message translates to:
  /// **'Spent 450 on transport'**
  String get phrase_2;

  /// No description provided for @phrase_3.
  ///
  /// In en, this message translates to:
  /// **'What is my profit today?'**
  String get phrase_3;

  /// No description provided for @phrase_4.
  ///
  /// In en, this message translates to:
  /// **'Who owes me money?'**
  String get phrase_4;

  /// No description provided for @phrase_5.
  ///
  /// In en, this message translates to:
  /// **'Show cash flow forecast'**
  String get phrase_5;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @show_reports.
  ///
  /// In en, this message translates to:
  /// **'Show Reports'**
  String get show_reports;

  /// No description provided for @set_reminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get set_reminder;

  /// No description provided for @check_cash_flow.
  ///
  /// In en, this message translates to:
  /// **'Check Cash Flow'**
  String get check_cash_flow;

  /// No description provided for @view_all_receivables.
  ///
  /// In en, this message translates to:
  /// **'View All Receivables'**
  String get view_all_receivables;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @language_switched.
  ///
  /// In en, this message translates to:
  /// **'Language switched to {name} ({nativeName})'**
  String language_switched(Object name, Object nativeName);

  /// No description provided for @business_profile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get business_profile;

  /// No description provided for @security_pin.
  ///
  /// In en, this message translates to:
  /// **'Security & App PIN'**
  String get security_pin;

  /// No description provided for @terms_privacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get terms_privacy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @business_account.
  ///
  /// In en, this message translates to:
  /// **'Business Account'**
  String get business_account;

  /// No description provided for @grow_smarter_title.
  ///
  /// In en, this message translates to:
  /// **'Grow Smarter with VyaparAI'**
  String get grow_smarter_title;

  /// No description provided for @grow_smarter_sub.
  ///
  /// In en, this message translates to:
  /// **'AI-powered insights for a better tomorrow'**
  String get grow_smarter_sub;

  /// No description provided for @build_manage_grow.
  ///
  /// In en, this message translates to:
  /// **'Build • Manage • Grow'**
  String get build_manage_grow;

  /// No description provided for @ai_welcome_text.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am VyaparAI, your AI business copilot. You can ask me about your profit, pending customer receivables, cash flow forecast, or expense summaries.'**
  String get ai_welcome_text;

  /// No description provided for @ai_suggest_1.
  ///
  /// In en, this message translates to:
  /// **'Who owes me money?'**
  String get ai_suggest_1;

  /// No description provided for @ai_suggest_2.
  ///
  /// In en, this message translates to:
  /// **'What is my profit today?'**
  String get ai_suggest_2;

  /// No description provided for @ai_suggest_3.
  ///
  /// In en, this message translates to:
  /// **'How is my business doing?'**
  String get ai_suggest_3;

  /// No description provided for @ai_server_error.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I had trouble reaching the server. Please try again.'**
  String get ai_server_error;

  /// No description provided for @ai_type_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Ask VyaparAI a business question...'**
  String get ai_type_placeholder;

  /// No description provided for @upload_invoice_doc.
  ///
  /// In en, this message translates to:
  /// **'Upload Invoice / Document'**
  String get upload_invoice_doc;

  /// No description provided for @upload_doc_sub.
  ///
  /// In en, this message translates to:
  /// **'Scan bills, receipts, or invoices with OCR'**
  String get upload_doc_sub;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @any_image.
  ///
  /// In en, this message translates to:
  /// **'Any Image'**
  String get any_image;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @extracting_ocr.
  ///
  /// In en, this message translates to:
  /// **'Extracting with VyaparAI OCR…'**
  String get extracting_ocr;

  /// No description provided for @review_extracted_details.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Details'**
  String get review_extracted_details;

  /// No description provided for @customer_vendor_name.
  ///
  /// In en, this message translates to:
  /// **'Customer / Vendor Name'**
  String get customer_vendor_name;

  /// No description provided for @invoice_number.
  ///
  /// In en, this message translates to:
  /// **'Invoice / Bill Number'**
  String get invoice_number;

  /// No description provided for @invoice_amount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Amount'**
  String get invoice_amount;

  /// No description provided for @confirm_and_save.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save Invoice'**
  String get confirm_and_save;

  /// No description provided for @saving_invoice.
  ///
  /// In en, this message translates to:
  /// **'Saving invoice...'**
  String get saving_invoice;

  /// No description provided for @ocr_unreadable_msg.
  ///
  /// In en, this message translates to:
  /// **'Could not detect readable text in this image. Please ensure good lighting and clear focus.'**
  String get ocr_unreadable_msg;

  /// No description provided for @ocr_unsupported_msg.
  ///
  /// In en, this message translates to:
  /// **'This image does not appear to contain an invoice or receipt.'**
  String get ocr_unsupported_msg;

  /// No description provided for @ocr_duplicate_msg.
  ///
  /// In en, this message translates to:
  /// **'A similar invoice already exists for this business.'**
  String get ocr_duplicate_msg;

  /// No description provided for @ocr_success_msg.
  ///
  /// In en, this message translates to:
  /// **'Invoice details successfully extracted.'**
  String get ocr_success_msg;

  /// No description provided for @ocr_limitations_notice.
  ///
  /// In en, this message translates to:
  /// **'OCR works best with clear, well-lit bills. Review values before confirming.'**
  String get ocr_limitations_notice;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String field_required(Object field);

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get email_required;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalid_email;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get password_required;

  /// No description provided for @password_min_length.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters.'**
  String get password_min_length;

  /// No description provided for @password_uppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter.'**
  String get password_uppercase;

  /// No description provided for @password_number.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number.'**
  String get password_number;

  /// No description provided for @phone_required.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get phone_required;

  /// No description provided for @invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalid_phone;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get awesome;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get something_went_wrong;

  /// No description provided for @network_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server. Check your connection.'**
  String get network_error;

  /// No description provided for @changes_saved_success.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully.'**
  String get changes_saved_success;

  /// No description provided for @document_uploaded_success.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully.'**
  String get document_uploaded_success;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @remember_me.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get remember_me;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @signing_in.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signing_in;

  /// No description provided for @or_continue_with.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get or_continue_with;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dont_have_account;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get sign_up;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get already_have_account;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @business_name.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get business_name;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @creating_account.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creating_account;

  /// No description provided for @data_privacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get data_privacy;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @pro_plan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan'**
  String get pro_plan;

  /// No description provided for @help_support.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help_support;

  /// No description provided for @notifications_alerts.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alerts'**
  String get notifications_alerts;

  /// No description provided for @auto_fetch_messages.
  ///
  /// In en, this message translates to:
  /// **'Auto-Fetch Messages (WhatsApp, SMS, Gmail)'**
  String get auto_fetch_messages;

  /// No description provided for @app_version_info.
  ///
  /// In en, this message translates to:
  /// **'VyaparAI v1.0.0 • Made with ❤️ for Indian MSMEs'**
  String get app_version_info;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirm_logout;

  /// No description provided for @a11y_home_tab.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Tab'**
  String get a11y_home_tab;

  /// No description provided for @a11y_transactions_tab.
  ///
  /// In en, this message translates to:
  /// **'Transactions Screen Tab'**
  String get a11y_transactions_tab;

  /// No description provided for @a11y_mic_button.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant Microphone Button'**
  String get a11y_mic_button;

  /// No description provided for @a11y_reports_tab.
  ///
  /// In en, this message translates to:
  /// **'Reports Screen Tab'**
  String get a11y_reports_tab;

  /// No description provided for @a11y_settings_tab.
  ///
  /// In en, this message translates to:
  /// **'Settings Screen Tab'**
  String get a11y_settings_tab;

  /// No description provided for @a11y_menu_button.
  ///
  /// In en, this message translates to:
  /// **'Open Navigation Menu'**
  String get a11y_menu_button;

  /// No description provided for @a11y_close_button.
  ///
  /// In en, this message translates to:
  /// **'Close Dialog'**
  String get a11y_close_button;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
