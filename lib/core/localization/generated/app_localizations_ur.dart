// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'کراؤن سولر انرجی';

  @override
  String get routeNotFoundTitle => 'صفحہ نہیں ملا';

  @override
  String get routeNotFoundMessage => 'مطلوبہ راستہ موجود نہیں ہے۔';

  @override
  String get authMobileNumberLabel => 'رجسٹرڈ موبائل نمبر';

  @override
  String get authMobileNumberHint => 'مثال: +923001234567';

  @override
  String get authKeepSignedIn => 'مجھے سائن ان رکھیں';

  @override
  String get authContinueAction => 'جاری رکھیں';

  @override
  String get authAccountNotFound => 'اس موبائل نمبر سے کوئی اکاؤنٹ نہیں ملا۔';

  @override
  String get authSignInHeading => 'سائن ان کریں';

  @override
  String get authSignInSubtitle =>
      'کراؤن سولر کے ساتھ رجسٹرڈ موبائل نمبر استعمال کریں۔';

  @override
  String get authDevicePolicyNotice =>
      'آپ کا اکاؤنٹ ایک وقت میں ایک ہی فون پر چلتا ہے۔ نئے فون پر سائن ان کے لیے ایک SMS کوڈ درکار ہوگا۔';

  @override
  String get authSignInAction => 'سائن ان کریں';

  @override
  String get authRegisterPrompt => 'کراؤن سولر پر نئے ہیں؟';

  @override
  String get authRegisterAction => 'رجسٹر کریں';

  @override
  String get registrationTitle => 'یہ ڈیوائس رجسٹر کریں';

  @override
  String get registrationOtpPrompt =>
      'اس ڈیوائس کو فعال کرنے کے لیے اپنے موبائل نمبر پر بھیجا گیا تصدیقی کوڈ درج کریں۔';

  @override
  String get registrationAlreadyRegistered =>
      'اس اکاؤنٹ کی پہلے سے ایک فعال ڈیوائس موجود ہے۔ اس کے بجائے سائن ان کریں۔';

  @override
  String get registrationSuccess =>
      'رجسٹریشن مکمل ہو گئی۔ یہ ڈیوائس اب آپ کے اکاؤنٹ کے لیے فعال ہے۔';

  @override
  String get registrationFailed =>
      'رجسٹریشن مکمل نہیں ہو سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get otpCodeLabel => 'تصدیقی کوڈ';

  @override
  String get otpVerifyAction => 'تصدیق کریں';

  @override
  String get otpInvalidCode =>
      'یہ کوڈ درست نہیں ہے۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String otpPrototypeCodeNotice(String code) {
    return 'صرف پروٹوٹائپ — تصدیقی کوڈ: $code';
  }

  @override
  String get otpEnterCodeTitle => '6 ہندسوں کا کوڈ درج کریں';

  @override
  String otpSentTo(String number) {
    return '$number پر SMS کے ذریعے بھیجا گیا۔ یہ ایک نیا فون ہے، اس لیے سائن ان سے پہلے اس کی تصدیق کی جاتی ہے۔';
  }

  @override
  String get otpResendAction => 'کوڈ دوبارہ بھیجیں';

  @override
  String get otpVerifyAndSignInAction => 'تصدیق کریں اور سائن ان کریں';

  @override
  String get loginNewDeviceNotice =>
      'یہ آپ کے اکاؤنٹ کی معمول کی ڈیوائس نہیں ہے۔ تصدیق کے لیے بھیجا گیا کوڈ درج کریں۔';

  @override
  String get loginTrustedSuccess => 'سائن ان ہو گیا۔';

  @override
  String get loginSecondDeviceMoveNotice =>
      'یہ آپ کے اکاؤنٹ کی رجسٹریشن کے بعد پہلی ڈیوائس تبدیلی ہے۔ اس کے بعد ہر تبدیلی کے لیے کراؤن سولر CRM کی اجازت درکار ہوگی۔';

  @override
  String get loginAuthorizationPending =>
      'اس ڈیوائس کے استعمال کی درخواست کی منظوری کا انتظار ہے۔ براہ کرم بعد میں دوبارہ دیکھیں۔';

  @override
  String get loginAuthorizationRetry => 'دوبارہ چیک کریں';

  @override
  String get loginAuthorizationNotAuthorized =>
      'اس ڈیوائس کو آپ کے اکاؤنٹ کے استعمال کی اجازت نہیں دی گئی۔ آپ کی دوسری ڈیوائس فعال رہے گی۔';

  @override
  String get loginRebindingSuccess =>
      'یہ ڈیوائس اب آپ کے اکاؤنٹ کے لیے فعال ہے۔';

  @override
  String get loginRebindingFailed =>
      'ہم آپ کے اکاؤنٹ کو اس ڈیوائس پر منتقل نہیں کر سکے۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginDeviceLockedTitle => 'آپ کا اکاؤنٹ دوسرے فون کے ساتھ مقرر ہے';

  @override
  String get loginDeviceLockedBody =>
      'آپ اپنا اکاؤنٹ پہلے ہی ایک بار منتقل کر چکے ہیں۔ آپ کا دوسرا فون معمول کے مطابق کام کر رہا ہے — وہاں کچھ بھی بلاک یا معطل نہیں ہے۔';

  @override
  String get loginCrmHelpTitle => 'اگر آپ وہ فون استعمال نہیں کر سکتے';

  @override
  String get loginCrmHelpBody =>
      'کھو جانا، چوری ہونا، بک جانا یا ٹوٹ جانا — کراؤن سولر CRM نئے فون پر منتقلی کی اجازت دے سکتا ہے۔ وہ پوچھیں گے کہ کیا ہوا اور اسے ریکارڈ کریں گے۔';

  @override
  String get loginCallCrmAction => 'CRM کو کال کریں';

  @override
  String get loginNoPasswordResetNotice =>
      'یہ پاس ورڈ کا مسئلہ نہیں ہے، اس لیے یہاں پاس ورڈ ری سیٹ کی پیشکش نہیں کی جاتی۔';

  @override
  String get loginCrmAuthorizedTitle =>
      'کراؤن سولر CRM نے اس تبدیلی کی اجازت دے دی ہے';

  @override
  String get loginCrmAuthorizedBody =>
      'تبدیلی مکمل کرنے کے لیے اس فون کی تصدیق کریں۔';

  @override
  String get loginOneMoveOnlyNotice =>
      'یہ اجازت صرف ایک تبدیلی کے لیے ہے۔ اس فون کی تصدیق ہوتے ہی آپ کا اکاؤنٹ دوبارہ اسی پر مقرر ہو جائے گا۔';

  @override
  String get loginOldDeviceSignOutNotice =>
      'آپ کا پرانا فون سائن آؤٹ ہو جائے گا اور اب آپ کا اکاؤنٹ نہیں کھول سکے گا۔';

  @override
  String get loginSessionExpiredNotice =>
      'آپ کا سیشن ختم ہونے کی وجہ سے آپ کو سائن آؤٹ کر دیا گیا تھا۔ جاری رکھنے کے لیے دوبارہ سائن ان کریں — یہ ڈیوائس کی تبدیلی نہیں ہے، اور اس فون پر کسی کوڈ کی ضرورت نہیں۔';

  @override
  String get loginDeviceConflictTitle => 'یہ فون دوسرے اکاؤنٹ میں سائن ان ہے';

  @override
  String get loginDeviceConflictBody =>
      'جاری رکھنے سے وہ دوسرا اکاؤنٹ اس فون سے سائن آؤٹ ہو جائے گا اور آپ کا اکاؤنٹ یہاں منتقل ہو جائے گا۔ دوسرا اکاؤنٹ حذف نہیں ہوتا — وہ اپنے فون پر دوبارہ سائن ان کر سکتے ہیں۔';

  @override
  String get loginDeviceConflictConfirm => 'جاری رکھیں اور تصدیق کریں';

  @override
  String get loginDeviceConflictCancel => 'منسوخ کریں';

  @override
  String get homeWelcomeMessage => 'آپ سائن ان ہیں۔';

  @override
  String get homeLogoutAction => 'سائن آؤٹ';
}

/// The translations for Urdu, using the Latin script (`ur_Latn`).
class AppLocalizationsUrLatn extends AppLocalizationsUr {
  AppLocalizationsUrLatn() : super('ur_Latn');

  @override
  String get appTitle => 'Crown Solar Energy';

  @override
  String get routeNotFoundTitle => 'Page nahi mila';

  @override
  String get routeNotFoundMessage =>
      'Jo route maanga gaya hai wo mojood nahi hai.';

  @override
  String get authMobileNumberLabel => 'Registered mobile number';

  @override
  String get authMobileNumberHint => 'misaal: +923001234567';

  @override
  String get authKeepSignedIn => 'Mujhe sign in rakhein';

  @override
  String get authContinueAction => 'Continue karein';

  @override
  String get authAccountNotFound =>
      'Is mobile number se koi account nahi mila.';

  @override
  String get authSignInHeading => 'Sign in karein';

  @override
  String get authSignInSubtitle =>
      'Crown Solar ke saath registered mobile number istemal karein.';

  @override
  String get authDevicePolicyNotice =>
      'Aap ka account ek waqt mein ek hi phone par chalta hai. Naye phone par sign in ke liye ek SMS code darkar hoga.';

  @override
  String get authSignInAction => 'Sign In';

  @override
  String get authRegisterPrompt => 'Crown Solar par naye hain?';

  @override
  String get authRegisterAction => 'Register karein';

  @override
  String get registrationTitle => 'Ye device register karein';

  @override
  String get registrationOtpPrompt =>
      'Is device ko active karne ke liye apne mobile number par bheja gaya code darj karein.';

  @override
  String get registrationAlreadyRegistered =>
      'Is account ki pehle se ek active device mojood hai. Iske bajaye sign in karein.';

  @override
  String get registrationSuccess =>
      'Registration mukammal ho gayi. Ye device ab aap ke account ke liye active hai.';

  @override
  String get registrationFailed =>
      'Registration mukammal nahi ho saki. Dobara koshish karein.';

  @override
  String get otpCodeLabel => 'Verification code';

  @override
  String get otpVerifyAction => 'Verify karein';

  @override
  String get otpInvalidCode => 'Ye code sahi nahi hai. Dobara koshish karein.';

  @override
  String otpPrototypeCodeNotice(String code) {
    return 'Sirf prototype — verification code: $code';
  }

  @override
  String get otpEnterCodeTitle => '6-digit code darj karein';

  @override
  String otpSentTo(String number) {
    return '$number par SMS ke zariye bheja gaya. Ye ek naya phone hai, is liye sign in se pehle iski tasdeeq ki jaati hai.';
  }

  @override
  String get otpResendAction => 'Code dobara bhejein';

  @override
  String get otpVerifyAndSignInAction => 'Verify karein aur sign in karein';

  @override
  String get loginNewDeviceNotice =>
      'Ye aap ke account ki mamool wali device nahi hai. Tasdeeq ke liye bheja gaya code darj karein.';

  @override
  String get loginTrustedSuccess => 'Sign in ho gaya.';

  @override
  String get loginSecondDeviceMoveNotice =>
      'Ye aap ke account ki registration ke baad pehli device tabdeeli hai. Iske baad har tabdeeli ke liye Crown Solar CRM ki ijazat darkar hogi.';

  @override
  String get loginAuthorizationPending =>
      'Is device ke istemal ki darkhwast ki manzoori ka intezar hai. Baad mein dobara dekhein.';

  @override
  String get loginAuthorizationRetry => 'Dobara check karein';

  @override
  String get loginAuthorizationNotAuthorized =>
      'Is device ko aap ke account ke istemal ki ijazat nahi di gayi. Aap ki doosri device active rahegi.';

  @override
  String get loginRebindingSuccess =>
      'Ye device ab aap ke account ke liye active hai.';

  @override
  String get loginRebindingFailed =>
      'Hum aap ke account ko is device par transfer nahi kar sake. Dobara koshish karein.';

  @override
  String get loginDeviceLockedTitle =>
      'Aap ka account doosre phone ke saath fix hai';

  @override
  String get loginDeviceLockedBody =>
      'Aap apna account pehle hi ek baar transfer kar chuke hain. Aap ka doosra phone mamool ke mutabiq kaam kar raha hai — wahan kuch bhi block ya suspend nahi hai.';

  @override
  String get loginCrmHelpTitle => 'Agar aap wo phone istemal nahi kar sakte';

  @override
  String get loginCrmHelpBody =>
      'Kho jana, chori hona, bik jana ya toot jana — Crown Solar CRM naye phone par move ki ijazat de sakta hai. Wo poochenge ke kya hua aur record karenge.';

  @override
  String get loginCallCrmAction => 'CRM ko call karein';

  @override
  String get loginNoPasswordResetNotice =>
      'Ye password ka masla nahi hai, is liye yahan password reset ki sahulat nahi di jaati.';

  @override
  String get loginCrmAuthorizedTitle =>
      'Crown Solar CRM ne is move ki ijazat de di hai';

  @override
  String get loginCrmAuthorizedBody =>
      'Move mukammal karne ke liye is phone ki tasdeeq karein.';

  @override
  String get loginOneMoveOnlyNotice =>
      'Ye ijazat sirf ek move ke liye hai. Is phone ki tasdeeq hote hi aap ka account dobara isi par lock ho jayega.';

  @override
  String get loginOldDeviceSignOutNotice =>
      'Aap ka purana phone sign out ho jayega aur ab aap ka account nahi khol sakega.';

  @override
  String get loginSessionExpiredNotice =>
      'Aap ka session khatam hone ki wajah se aap ko sign out kar diya gaya tha. Jaari rakhne ke liye dobara sign in karein — ye device ki tabdeeli nahi hai, aur is phone par kisi code ki zaroorat nahi.';

  @override
  String get loginDeviceConflictTitle =>
      'Ye phone doosre account mein sign in hai';

  @override
  String get loginDeviceConflictBody =>
      'Jaari rakhne se wo doosra account is phone se sign out ho jayega aur aap ka account yahan move ho jayega. Doosra account delete nahi hota — wo apne phone par dobara sign in kar sakte hain.';

  @override
  String get loginDeviceConflictConfirm => 'Jaari rakhein aur tasdeeq karein';

  @override
  String get loginDeviceConflictCancel => 'Cancel karein';

  @override
  String get homeWelcomeMessage => 'Aap sign in hain.';

  @override
  String get homeLogoutAction => 'Sign out';
}
