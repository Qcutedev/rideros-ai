import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_th.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('th')];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'RiderOS AI'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In th, this message translates to:
  /// **'ผู้ช่วยวางแผนงานและกำไรสำหรับไรเดอร์'**
  String get appTagline;

  /// No description provided for @commonRetry.
  ///
  /// In th, this message translates to:
  /// **'ลองใหม่'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In th, this message translates to:
  /// **'กำลังโหลด…'**
  String get commonLoading;

  /// No description provided for @commonOptional.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ'**
  String get commonOptional;

  /// No description provided for @fieldEmail.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่าน'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่าน'**
  String get fieldConfirmPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านใหม่'**
  String get fieldNewPassword;

  /// No description provided for @fieldDisplayName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อที่แสดง'**
  String get fieldDisplayName;

  /// No description provided for @showPassword.
  ///
  /// In th, this message translates to:
  /// **'แสดงรหัสผ่าน'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In th, this message translates to:
  /// **'ซ่อนรหัสผ่าน'**
  String get hidePassword;

  /// No description provided for @validationRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกข้อมูลนี้'**
  String get validationRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In th, this message translates to:
  /// **'รูปแบบอีเมลไม่ถูกต้อง'**
  String get validationEmailInvalid;

  /// No description provided for @validationEmailTooLong.
  ///
  /// In th, this message translates to:
  /// **'อีเมลยาวเกินไป'**
  String get validationEmailTooLong;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านต้องมีอย่างน้อย {min} ตัวอักษร'**
  String validationPasswordTooShort(int min);

  /// No description provided for @validationPasswordTooLong.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านต้องไม่เกิน {max} ตัวอักษร'**
  String validationPasswordTooLong(int max);

  /// No description provided for @validationPasswordSameAsEmail.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านต้องไม่เหมือนชื่อหน้า @ ของอีเมล'**
  String get validationPasswordSameAsEmail;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงกัน'**
  String get validationPasswordMismatch;

  /// No description provided for @validationDisplayNameTooLong.
  ///
  /// In th, this message translates to:
  /// **'ชื่อต้องไม่เกิน {max} ตัวอักษร'**
  String validationDisplayNameTooLong(int max);

  /// No description provided for @validationNumberInvalid.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกตัวเลข'**
  String get validationNumberInvalid;

  /// No description provided for @validationNumberMustBePositive.
  ///
  /// In th, this message translates to:
  /// **'ต้องมากกว่า 0'**
  String get validationNumberMustBePositive;

  /// No description provided for @validationNumberMustNotBeNegative.
  ///
  /// In th, this message translates to:
  /// **'ต้องไม่ติดลบ'**
  String get validationNumberMustNotBeNegative;

  /// No description provided for @validationNumberTooManyDecimals.
  ///
  /// In th, this message translates to:
  /// **'ทศนิยมได้ไม่เกิน {places} ตำแหน่ง'**
  String validationNumberTooManyDecimals(int places);

  /// No description provided for @validationNumberTooLarge.
  ///
  /// In th, this message translates to:
  /// **'ต้องไม่เกิน {max}'**
  String validationNumberTooLarge(String max);

  /// No description provided for @validationResetTokenInvalid.
  ///
  /// In th, this message translates to:
  /// **'ลิงก์หรือรหัสรีเซ็ตไม่ถูกต้อง'**
  String get validationResetTokenInvalid;

  /// No description provided for @loginTitle.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get loginTitle;

  /// No description provided for @loginSubmit.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get loginSubmit;

  /// No description provided for @loginForgotPassword.
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีบัญชี?'**
  String get loginNoAccount;

  /// No description provided for @loginGoRegister.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิก'**
  String get loginGoRegister;

  /// No description provided for @loginSessionExpired.
  ///
  /// In th, this message translates to:
  /// **'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง'**
  String get loginSessionExpired;

  /// No description provided for @loginRegisteredPleaseLogin.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ'**
  String get loginRegisteredPleaseLogin;

  /// No description provided for @loginPasswordResetDone.
  ///
  /// In th, this message translates to:
  /// **'ตั้งรหัสผ่านใหม่แล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่'**
  String get loginPasswordResetDone;

  /// No description provided for @registerTitle.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิก'**
  String get registerTitle;

  /// No description provided for @registerSubmit.
  ///
  /// In th, this message translates to:
  /// **'สร้างบัญชี'**
  String get registerSubmit;

  /// No description provided for @registerHaveAccount.
  ///
  /// In th, this message translates to:
  /// **'มีบัญชีแล้ว?'**
  String get registerHaveAccount;

  /// No description provided for @registerGoLogin.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get registerGoLogin;

  /// No description provided for @registerPasswordHelper.
  ///
  /// In th, this message translates to:
  /// **'อย่างน้อย 8 ตัวอักษร และไม่ใช่รหัสผ่านที่พบบ่อย'**
  String get registerPasswordHelper;

  /// No description provided for @forgotTitle.
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน'**
  String get forgotTitle;

  /// No description provided for @forgotDescription.
  ///
  /// In th, this message translates to:
  /// **'กรอกอีเมลที่ใช้สมัคร เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้'**
  String get forgotDescription;

  /// No description provided for @forgotSubmit.
  ///
  /// In th, this message translates to:
  /// **'ส่งลิงก์รีเซ็ตรหัสผ่าน'**
  String get forgotSubmit;

  /// No description provided for @forgotSentTitle.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบอีเมลของคุณ'**
  String get forgotSentTitle;

  /// No description provided for @forgotSentMessage.
  ///
  /// In th, this message translates to:
  /// **'ถ้ามีบัญชีนี้ เราได้ส่งลิงก์ไปแล้ว ลิงก์ใช้ได้ครั้งเดียวและมีอายุ 30 นาที'**
  String get forgotSentMessage;

  /// No description provided for @forgotDevNote.
  ///
  /// In th, this message translates to:
  /// **'DEV ONLY: ยังไม่มีระบบส่งอีเมล ลิงก์รีเซ็ตแสดงใน Log ของ Backend'**
  String get forgotDevNote;

  /// No description provided for @forgotHaveToken.
  ///
  /// In th, this message translates to:
  /// **'มีลิงก์/รหัสแล้ว'**
  String get forgotHaveToken;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In th, this message translates to:
  /// **'กลับไปหน้าเข้าสู่ระบบ'**
  String get forgotBackToLogin;

  /// No description provided for @resetTitle.
  ///
  /// In th, this message translates to:
  /// **'ตั้งรหัสผ่านใหม่'**
  String get resetTitle;

  /// No description provided for @resetDescription.
  ///
  /// In th, this message translates to:
  /// **'วางลิงก์รีเซ็ต (หรือเฉพาะรหัสหลัง token=) แล้วตั้งรหัสผ่านใหม่ การตั้งรหัสใหม่จะออกจากระบบทุกเครื่อง'**
  String get resetDescription;

  /// No description provided for @resetTokenField.
  ///
  /// In th, this message translates to:
  /// **'ลิงก์หรือรหัสรีเซ็ต'**
  String get resetTokenField;

  /// No description provided for @resetSubmit.
  ///
  /// In th, this message translates to:
  /// **'ตั้งรหัสผ่านใหม่'**
  String get resetSubmit;

  /// No description provided for @splashRestoreFailedTitle.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อไม่สำเร็จ'**
  String get splashRestoreFailedTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่าการขับขี่'**
  String get onboardingTitle;

  /// No description provided for @onboardingDescription.
  ///
  /// In th, this message translates to:
  /// **'ใช้ข้อมูลนี้คำนวณต้นทุนต่อกิโลเมตร (ค่าน้ำมันและค่าเสื่อม) กรอกเฉพาะค่าที่รู้ เว้นว่างได้'**
  String get onboardingDescription;

  /// No description provided for @onboardingVehicleType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทยานพาหนะ'**
  String get onboardingVehicleType;

  /// No description provided for @onboardingFuelKmPerLiter.
  ///
  /// In th, this message translates to:
  /// **'อัตราสิ้นเปลือง (กม./ลิตร)'**
  String get onboardingFuelKmPerLiter;

  /// No description provided for @onboardingFuelPricePerLiter.
  ///
  /// In th, this message translates to:
  /// **'ราคาน้ำมัน (บาท/ลิตร)'**
  String get onboardingFuelPricePerLiter;

  /// No description provided for @onboardingDepreciationPerKm.
  ///
  /// In th, this message translates to:
  /// **'ค่าเสื่อม (บาท/กม.)'**
  String get onboardingDepreciationPerKm;

  /// No description provided for @onboardingRegion.
  ///
  /// In th, this message translates to:
  /// **'เขตเวลา {zone} · สกุลเงิน THB'**
  String onboardingRegion(String zone);

  /// No description provided for @onboardingSubmit.
  ///
  /// In th, this message translates to:
  /// **'บันทึกและเริ่มใช้งาน'**
  String get onboardingSubmit;

  /// No description provided for @onboardingSkip.
  ///
  /// In th, this message translates to:
  /// **'ข้ามไปก่อน'**
  String get onboardingSkip;

  /// No description provided for @vehicleNotSpecified.
  ///
  /// In th, this message translates to:
  /// **'ไม่ระบุ'**
  String get vehicleNotSpecified;

  /// No description provided for @vehicleMotorcycle.
  ///
  /// In th, this message translates to:
  /// **'มอเตอร์ไซค์'**
  String get vehicleMotorcycle;

  /// No description provided for @vehicleEvMotorcycle.
  ///
  /// In th, this message translates to:
  /// **'มอเตอร์ไซค์ไฟฟ้า'**
  String get vehicleEvMotorcycle;

  /// No description provided for @vehicleBicycle.
  ///
  /// In th, this message translates to:
  /// **'จักรยาน'**
  String get vehicleBicycle;

  /// No description provided for @vehicleCar.
  ///
  /// In th, this message translates to:
  /// **'รถยนต์'**
  String get vehicleCar;

  /// No description provided for @vehicleOther.
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get vehicleOther;

  /// No description provided for @homeHello.
  ///
  /// In th, this message translates to:
  /// **'สวัสดี'**
  String get homeHello;

  /// No description provided for @homeGreeting.
  ///
  /// In th, this message translates to:
  /// **'สวัสดี {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeBannerMessage.
  ///
  /// In th, this message translates to:
  /// **'ขับขี่ปลอดภัย\nวันนี้ก็สู้ ๆ นะ'**
  String get homeBannerMessage;

  /// No description provided for @logout.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ'**
  String get logout;

  /// No description provided for @commonCancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get commonCancel;

  /// No description provided for @demoLabel.
  ///
  /// In th, this message translates to:
  /// **'DEMO'**
  String get demoLabel;

  /// No description provided for @validationWholeNumber.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกจำนวนเต็ม'**
  String get validationWholeNumber;

  /// No description provided for @validationNumberTooSmall.
  ///
  /// In th, this message translates to:
  /// **'ต้องไม่น้อยกว่า {min}'**
  String validationNumberTooSmall(String min);

  /// No description provided for @validationTextTooLong.
  ///
  /// In th, this message translates to:
  /// **'ยาวได้ไม่เกิน {max} ตัวอักษร'**
  String validationTextTooLong(int max);

  /// No description provided for @navHome.
  ///
  /// In th, this message translates to:
  /// **'หน้าหลัก'**
  String get navHome;

  /// No description provided for @navProfit.
  ///
  /// In th, this message translates to:
  /// **'กำไร'**
  String get navProfit;

  /// No description provided for @navRoad.
  ///
  /// In th, this message translates to:
  /// **'ถนน'**
  String get navRoad;

  /// No description provided for @homeToday.
  ///
  /// In th, this message translates to:
  /// **'วันนี้ · {date}'**
  String homeToday(String date);

  /// No description provided for @homeThisWeek.
  ///
  /// In th, this message translates to:
  /// **'สัปดาห์นี้ · {range}'**
  String homeThisWeek(String range);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการในวันนี้และสัปดาห์นี้'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'เริ่มบันทึกรายได้ ค่าใช้จ่าย หรือช่วงทำงาน แล้วกำไรจริงจะแสดงที่นี่'**
  String get homeEmptyMessage;

  /// No description provided for @homeQuickActions.
  ///
  /// In th, this message translates to:
  /// **'บันทึกด่วน'**
  String get homeQuickActions;

  /// No description provided for @homeOpenProfit.
  ///
  /// In th, this message translates to:
  /// **'ดูกำไรทั้งหมด (TrueProfit)'**
  String get homeOpenProfit;

  /// No description provided for @homeAiTools.
  ///
  /// In th, this message translates to:
  /// **'เครื่องมือ AI'**
  String get homeAiTools;

  /// No description provided for @homeShiftCardTitle.
  ///
  /// In th, this message translates to:
  /// **'Shift Simulator'**
  String get homeShiftCardTitle;

  /// No description provided for @homeShiftCardMessage.
  ///
  /// In th, this message translates to:
  /// **'จำลองกะงาน ดูกำไรประมาณก่อนออกวิ่ง'**
  String get homeShiftCardMessage;

  /// No description provided for @homeOpen.
  ///
  /// In th, this message translates to:
  /// **'เปิด'**
  String get homeOpen;

  /// No description provided for @goalSetTitle.
  ///
  /// In th, this message translates to:
  /// **'ตั้งเป้ากำไรวันนี้'**
  String get goalSetTitle;

  /// No description provided for @goalSetMessage.
  ///
  /// In th, this message translates to:
  /// **'ดูว่าอีกเท่าไรจะถึงเป้า'**
  String get goalSetMessage;

  /// No description provided for @goalTarget.
  ///
  /// In th, this message translates to:
  /// **'เป้าวันนี้ {amount}'**
  String goalTarget(String amount);

  /// No description provided for @goalRemaining.
  ///
  /// In th, this message translates to:
  /// **'อีก {amount} ถึงเป้า'**
  String goalRemaining(String amount);

  /// No description provided for @goalReached.
  ///
  /// In th, this message translates to:
  /// **'ถึงเป้าแล้ว!'**
  String get goalReached;

  /// No description provided for @goalSurplus.
  ///
  /// In th, this message translates to:
  /// **'เกินเป้า {amount}'**
  String goalSurplus(String amount);

  /// No description provided for @goalPercent.
  ///
  /// In th, this message translates to:
  /// **'{percent}%'**
  String goalPercent(int percent);

  /// No description provided for @goalEdit.
  ///
  /// In th, this message translates to:
  /// **'แก้เป้า'**
  String get goalEdit;

  /// No description provided for @goalSheetTitle.
  ///
  /// In th, this message translates to:
  /// **'เป้ากำไรสุทธิต่อวัน'**
  String get goalSheetTitle;

  /// No description provided for @goalSheetMessage.
  ///
  /// In th, this message translates to:
  /// **'นับจากกำไรสุทธิของวันนี้ (รายได้ − ค่าใช้จ่าย) ตามเขตเวลาในโปรไฟล์'**
  String get goalSheetMessage;

  /// No description provided for @goalField.
  ///
  /// In th, this message translates to:
  /// **'เป้ากำไรสุทธิ'**
  String get goalField;

  /// No description provided for @goalRemove.
  ///
  /// In th, this message translates to:
  /// **'ลบเป้า'**
  String get goalRemove;

  /// No description provided for @goalSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกเป้าแล้ว'**
  String get goalSaved;

  /// No description provided for @goalRemoved.
  ///
  /// In th, this message translates to:
  /// **'ลบเป้าแล้ว'**
  String get goalRemoved;

  /// No description provided for @riderProfileDailyGoalHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · แสดงเป็นวงแหวนบนหน้าหลัก'**
  String get riderProfileDailyGoalHelper;

  /// No description provided for @timerIdleTitle.
  ///
  /// In th, this message translates to:
  /// **'พร้อมออกวิ่งไหม?'**
  String get timerIdleTitle;

  /// No description provided for @timerIdleMessage.
  ///
  /// In th, this message translates to:
  /// **'กดเริ่มตอนออกวิ่ง กดหยุดตอนเลิก แอปจะกรอกเวลาช่วงทำงานให้'**
  String get timerIdleMessage;

  /// No description provided for @timerStart.
  ///
  /// In th, this message translates to:
  /// **'เริ่มงาน'**
  String get timerStart;

  /// No description provided for @timerRunningTitle.
  ///
  /// In th, this message translates to:
  /// **'กำลังทำงาน'**
  String get timerRunningTitle;

  /// No description provided for @timerStartedAt.
  ///
  /// In th, this message translates to:
  /// **'เริ่ม {time}'**
  String timerStartedAt(String time);

  /// No description provided for @timerElapsed.
  ///
  /// In th, this message translates to:
  /// **'เวลาทำงาน {duration}'**
  String timerElapsed(String duration);

  /// No description provided for @timerStop.
  ///
  /// In th, this message translates to:
  /// **'หยุดและบันทึก'**
  String get timerStop;

  /// No description provided for @timerDiscard.
  ///
  /// In th, this message translates to:
  /// **'ทิ้ง'**
  String get timerDiscard;

  /// No description provided for @timerStoppedTitle.
  ///
  /// In th, this message translates to:
  /// **'หยุดแล้ว · ยังไม่ได้บันทึก'**
  String get timerStoppedTitle;

  /// No description provided for @timerStoppedRange.
  ///
  /// In th, this message translates to:
  /// **'{duration} · {start}–{end}'**
  String timerStoppedRange(String duration, String start, String end);

  /// No description provided for @timerSave.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วงทำงาน'**
  String get timerSave;

  /// No description provided for @timerResume.
  ///
  /// In th, this message translates to:
  /// **'ทำต่อ'**
  String get timerResume;

  /// No description provided for @timerDiscardTitle.
  ///
  /// In th, this message translates to:
  /// **'ทิ้งเวลาที่จับไว้?'**
  String get timerDiscardTitle;

  /// No description provided for @timerDiscardMessage.
  ///
  /// In th, this message translates to:
  /// **'เวลานี้ยังไม่ได้บันทึก ทิ้งแล้วเอาคืนไม่ได้'**
  String get timerDiscardMessage;

  /// No description provided for @timerTooShortTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ถึง 1 นาที'**
  String get timerTooShortTitle;

  /// No description provided for @timerTooShortMessage.
  ///
  /// In th, this message translates to:
  /// **'ช่วงทำงานต้องยาวอย่างน้อย 1 นาที จะทำต่อหรือทิ้ง?'**
  String get timerTooShortMessage;

  /// No description provided for @timerTooLongTitle.
  ///
  /// In th, this message translates to:
  /// **'ลืมกดหยุดหรือเปล่า?'**
  String get timerTooLongTitle;

  /// No description provided for @timerTooLongMessage.
  ///
  /// In th, this message translates to:
  /// **'ตัวจับเวลาเดินมา {duration} เกิน 24 ชม. ที่บันทึกได้ในช่วงเดียว ตรวจเวลาเลิกงานในหน้าถัดไป'**
  String timerTooLongMessage(String duration);

  /// No description provided for @timerTooLongContinue.
  ///
  /// In th, this message translates to:
  /// **'ไปแก้เวลา'**
  String get timerTooLongContinue;

  /// No description provided for @sessionTimerTooLong.
  ///
  /// In th, this message translates to:
  /// **'ตัวจับเวลาเดินมา {duration} · แก้เวลาเลิกงานให้ตรงจริง (ช่วงเดียวไม่เกิน 24 ชม.)'**
  String sessionTimerTooLong(String duration);

  /// No description provided for @trueProfitTitle.
  ///
  /// In th, this message translates to:
  /// **'TrueProfit'**
  String get trueProfitTitle;

  /// No description provided for @periodDay.
  ///
  /// In th, this message translates to:
  /// **'วัน'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In th, this message translates to:
  /// **'สัปดาห์'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In th, this message translates to:
  /// **'เดือน'**
  String get periodMonth;

  /// No description provided for @profitPreviousPeriod.
  ///
  /// In th, this message translates to:
  /// **'ช่วงก่อนหน้า'**
  String get profitPreviousPeriod;

  /// No description provided for @profitNextPeriod.
  ///
  /// In th, this message translates to:
  /// **'ช่วงถัดไป'**
  String get profitNextPeriod;

  /// No description provided for @profitCurrentPeriod.
  ///
  /// In th, this message translates to:
  /// **'ช่วงปัจจุบัน'**
  String get profitCurrentPeriod;

  /// No description provided for @profitBackToCurrent.
  ///
  /// In th, this message translates to:
  /// **'กลับช่วงปัจจุบัน'**
  String get profitBackToCurrent;

  /// No description provided for @profitSummaryTitle.
  ///
  /// In th, this message translates to:
  /// **'สรุปกำไรจริง'**
  String get profitSummaryTitle;

  /// No description provided for @profitEmptyPeriod.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการในช่วงนี้'**
  String get profitEmptyPeriod;

  /// No description provided for @profitTrendTitle.
  ///
  /// In th, this message translates to:
  /// **'แนวโน้มกำไรสุทธิรายช่วง ({period})'**
  String profitTrendTitle(String period);

  /// No description provided for @profitTrendEmpty.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีข้อมูลในช่วงที่แสดงกราฟ'**
  String get profitTrendEmpty;

  /// No description provided for @profitTrendSemantics.
  ///
  /// In th, this message translates to:
  /// **'กราฟแท่งกำไรสุทธิ {count} ช่วง'**
  String profitTrendSemantics(int count);

  /// No description provided for @profitTrendLegendNet.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิ'**
  String get profitTrendLegendNet;

  /// No description provided for @profitTrendLegendAverage.
  ///
  /// In th, this message translates to:
  /// **'ค่าเฉลี่ย {count} {unit}'**
  String profitTrendLegendAverage(int count, String unit);

  /// No description provided for @profitTrendLegendLine.
  ///
  /// In th, this message translates to:
  /// **'เส้นแนวโน้ม'**
  String get profitTrendLegendLine;

  /// No description provided for @profitTrendUp.
  ///
  /// In th, this message translates to:
  /// **'แนวโน้มขาขึ้น: กำไรสุทธิเพิ่มขึ้นเฉลี่ย {amount} ต่อ{unit}'**
  String profitTrendUp(String amount, String unit);

  /// No description provided for @profitTrendDown.
  ///
  /// In th, this message translates to:
  /// **'แนวโน้มขาลง: กำไรสุทธิลดลงเฉลี่ย {amount} ต่อ{unit}'**
  String profitTrendDown(String amount, String unit);

  /// No description provided for @profitTrendFlat.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่เห็นแนวโน้มขึ้นหรือลงที่ชัดเจน'**
  String get profitTrendFlat;

  /// No description provided for @profitTrendBasis.
  ///
  /// In th, this message translates to:
  /// **'คิดจาก {count} {unit}ที่มีข้อมูล · ทดสอบทางสถิติแล้ว ไม่ใช่การพยากรณ์'**
  String profitTrendBasis(int count, String unit);

  /// No description provided for @profitTrendNeedMore.
  ///
  /// In th, this message translates to:
  /// **'ต้องมีข้อมูลอย่างน้อย {need} {unit}จึงจะดูแนวโน้มได้ (ตอนนี้มี {have})'**
  String profitTrendNeedMore(int need, int have, String unit);

  /// No description provided for @profitActualOnlyNote.
  ///
  /// In th, this message translates to:
  /// **'ตัวเลขทั้งหมดคำนวณโดยเซิร์ฟเวอร์จากรายการที่คุณบันทึกจริงเท่านั้น (ไม่รวมค่าประมาณจาก Shift Simulator) · สัปดาห์เริ่มวันจันทร์ · เขตเวลา {zone}'**
  String profitActualOnlyNote(String zone);

  /// No description provided for @profitNet.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิ'**
  String get profitNet;

  /// No description provided for @profitRevenue.
  ///
  /// In th, this message translates to:
  /// **'รายได้'**
  String get profitRevenue;

  /// No description provided for @profitExpenses.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่าย'**
  String get profitExpenses;

  /// No description provided for @profitWorkingHours.
  ///
  /// In th, this message translates to:
  /// **'ชั่วโมงทำงาน'**
  String get profitWorkingHours;

  /// No description provided for @profitHoursValue.
  ///
  /// In th, this message translates to:
  /// **'{hours} ชม.'**
  String profitHoursValue(String hours);

  /// No description provided for @profitNetPerHour.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิ/ชม.'**
  String get profitNetPerHour;

  /// No description provided for @profitRevenuePerHour.
  ///
  /// In th, this message translates to:
  /// **'รายได้/ชม.'**
  String get profitRevenuePerHour;

  /// No description provided for @profitRecordCounts.
  ///
  /// In th, this message translates to:
  /// **'รายการ (ได้/จ่าย/กะ)'**
  String get profitRecordCounts;

  /// No description provided for @profitRecordCountsValue.
  ///
  /// In th, this message translates to:
  /// **'{income} / {expense} / {sessions}'**
  String profitRecordCountsValue(int income, int expense, int sessions);

  /// No description provided for @profitNotAvailable.
  ///
  /// In th, this message translates to:
  /// **'—'**
  String get profitNotAvailable;

  /// No description provided for @profitNoWorkingHours.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีชั่วโมงทำงาน จึงยังคำนวณค่าต่อชั่วโมงไม่ได้ (บันทึกช่วงทำงาน หรือกรอกชั่วโมงในรายได้)'**
  String get profitNoWorkingHours;

  /// No description provided for @patternsTitle.
  ///
  /// In th, this message translates to:
  /// **'รูปแบบการทำงาน'**
  String get patternsTitle;

  /// No description provided for @patternsInsufficient.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วงทำงานอีก {missing} ครั้ง เพื่อดูรูปแบบการทำงานของคุณ'**
  String patternsInsufficient(int missing);

  /// No description provided for @patternsProgress.
  ///
  /// In th, this message translates to:
  /// **'{have} / {need} ช่วงทำงานใน {days} วันล่าสุด'**
  String patternsProgress(int have, int need, int days);

  /// No description provided for @patternsNoClear.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่เห็นรูปแบบชัดเจนจาก {count} ช่วงทำงานใน {days} วันล่าสุด เวลาทำงานยังกระจายจนแบ่งกลุ่มได้ไม่ชัดกว่าการสุ่ม'**
  String patternsNoClear(int count, int days);

  /// No description provided for @patternsTimeMorning.
  ///
  /// In th, this message translates to:
  /// **'เช้า'**
  String get patternsTimeMorning;

  /// No description provided for @patternsTimeMidday.
  ///
  /// In th, this message translates to:
  /// **'กลางวัน'**
  String get patternsTimeMidday;

  /// No description provided for @patternsTimeEvening.
  ///
  /// In th, this message translates to:
  /// **'เย็น'**
  String get patternsTimeEvening;

  /// No description provided for @patternsTimeNight.
  ///
  /// In th, this message translates to:
  /// **'ดึก'**
  String get patternsTimeNight;

  /// No description provided for @patternsLengthShort.
  ///
  /// In th, this message translates to:
  /// **'สั้น'**
  String get patternsLengthShort;

  /// No description provided for @patternsLengthMedium.
  ///
  /// In th, this message translates to:
  /// **'กลาง'**
  String get patternsLengthMedium;

  /// No description provided for @patternsLengthLong.
  ///
  /// In th, this message translates to:
  /// **'ยาว'**
  String get patternsLengthLong;

  /// No description provided for @patternsDayWeekday.
  ///
  /// In th, this message translates to:
  /// **'วันธรรมดา'**
  String get patternsDayWeekday;

  /// No description provided for @patternsDayWeekend.
  ///
  /// In th, this message translates to:
  /// **'สุดสัปดาห์'**
  String get patternsDayWeekend;

  /// No description provided for @patternsDayMixed.
  ///
  /// In th, this message translates to:
  /// **'ทุกวัน'**
  String get patternsDayMixed;

  /// No description provided for @patternsGroupName.
  ///
  /// In th, this message translates to:
  /// **'{time} · {length} ~{hours} ชม. · {days}'**
  String patternsGroupName(
    String time,
    String length,
    String hours,
    String days,
  );

  /// No description provided for @patternsGroupDetail.
  ///
  /// In th, this message translates to:
  /// **'เริ่มราว {start} · {count} ครั้ง ({percent}%)'**
  String patternsGroupDetail(String start, int count, int percent);

  /// No description provided for @patternsPerHourBasis.
  ///
  /// In th, this message translates to:
  /// **'จาก {count} ช่วงที่ผูกรายได้'**
  String patternsPerHourBasis(int count);

  /// No description provided for @patternsNoLinkedIncome.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายได้ที่ผูกกับช่วงทำงานในกลุ่มนี้'**
  String get patternsNoLinkedIncome;

  /// No description provided for @patternsNote.
  ///
  /// In th, this message translates to:
  /// **'จัดกลุ่มด้วย K-Means จากเวลาเริ่ม ความยาว และวันธรรมดา/สุดสัปดาห์ ของ {days} วันล่าสุด · กำไร/ชม. เป็นค่าประมาณจากรายได้และค่าใช้จ่ายที่ผูกกับช่วงทำงานเท่านั้น'**
  String patternsNote(int days);

  /// No description provided for @profitHeatmapTitle.
  ///
  /// In th, this message translates to:
  /// **'กำไรต่อชั่วโมงตามช่วงเวลา'**
  String get profitHeatmapTitle;

  /// No description provided for @profitHeatmapInsufficient.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วงทำงานที่มีรายได้อีก {missing} ครั้ง เพื่อดูว่าวันและเวลาไหนได้กำไรต่อชั่วโมงดีที่สุด'**
  String profitHeatmapInsufficient(int missing);

  /// No description provided for @profitHeatmapProgress.
  ///
  /// In th, this message translates to:
  /// **'{have} / {need} ช่วงทำงานที่มีรายได้ใน {days} วันล่าสุด'**
  String profitHeatmapProgress(int have, int need, int days);

  /// No description provided for @profitHeatmapTimerHint.
  ///
  /// In th, this message translates to:
  /// **'กดปุ่มเริ่มงานที่หน้าหลักทุกครั้งที่ออกวิ่ง จะได้ช่วงทำงานพร้อมเวลาจริงโดยไม่ต้องกรอกเอง'**
  String get profitHeatmapTimerHint;

  /// No description provided for @profitHeatmapUnpaidSessions.
  ///
  /// In th, this message translates to:
  /// **'มี {count} ช่วงทำงานที่ยังไม่มีรายได้ จึงยังไม่นับ: ผูกรายได้กับช่วงทำงาน หรือบันทึกรายได้ในวันเดียวกัน'**
  String profitHeatmapUnpaidSessions(int count);

  /// No description provided for @profitHeatmapGridLabel.
  ///
  /// In th, this message translates to:
  /// **'ตารางกำไรสุทธิต่อชั่วโมง 7 วัน ช่วงละ {hours} ชั่วโมง'**
  String profitHeatmapGridLabel(int hours);

  /// No description provided for @profitHeatmapTapHint.
  ///
  /// In th, this message translates to:
  /// **'แตะช่องเพื่อดูรายละเอียด'**
  String get profitHeatmapTapHint;

  /// No description provided for @profitHeatmapPerHour.
  ///
  /// In th, this message translates to:
  /// **'{amount}/ชม.'**
  String profitHeatmapPerHour(String amount);

  /// No description provided for @profitHeatmapCellDetail.
  ///
  /// In th, this message translates to:
  /// **'รายได้ {revenue}/ชม. · {hours} ชม. จาก {count} ช่วงทำงาน'**
  String profitHeatmapCellDetail(String revenue, String hours, int count);

  /// No description provided for @profitHeatmapCellThin.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลน้อย: {count} ช่วง {hours} ชม. (ต้องมีอย่างน้อย {minSessions} ช่วง และ {minHours} ชม.)'**
  String profitHeatmapCellThin(
    int count,
    String hours,
    int minSessions,
    int minHours,
  );

  /// No description provided for @profitHeatmapCellEmpty.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีช่วงทำงานในช่วงนี้'**
  String get profitHeatmapCellEmpty;

  /// No description provided for @profitHeatmapCellSemantics.
  ///
  /// In th, this message translates to:
  /// **'{day} {range}: {detail}'**
  String profitHeatmapCellSemantics(String day, String range, String detail);

  /// No description provided for @profitHeatmapRank.
  ///
  /// In th, this message translates to:
  /// **'อันดับ {rank}'**
  String profitHeatmapRank(int rank);

  /// No description provided for @profitHeatmapLegendLow.
  ///
  /// In th, this message translates to:
  /// **'ต่ำ'**
  String get profitHeatmapLegendLow;

  /// No description provided for @profitHeatmapLegendHigh.
  ///
  /// In th, this message translates to:
  /// **'สูง'**
  String get profitHeatmapLegendHigh;

  /// No description provided for @profitHeatmapLegendRange.
  ///
  /// In th, this message translates to:
  /// **'{low} – {high} ต่อชม.'**
  String profitHeatmapLegendRange(String low, String high);

  /// No description provided for @profitHeatmapLegendLoss.
  ///
  /// In th, this message translates to:
  /// **'ขาดทุน/เท่าทุน'**
  String get profitHeatmapLegendLoss;

  /// No description provided for @profitHeatmapLegendThin.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลน้อย'**
  String get profitHeatmapLegendThin;

  /// No description provided for @profitHeatmapBestTitle.
  ///
  /// In th, this message translates to:
  /// **'ช่วงที่ได้ดีที่สุด'**
  String get profitHeatmapBestTitle;

  /// No description provided for @profitHeatmapBestNone.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีช่วงที่ข้อมูลพอ ทำงานช่วงเวลาเดิมซ้ำอย่างน้อย {minSessions} ครั้ง แล้วช่องนั้นจะแสดงกำไร/ชม.'**
  String profitHeatmapBestNone(int minSessions);

  /// No description provided for @profitHeatmapAverage.
  ///
  /// In th, this message translates to:
  /// **'เฉลี่ยทุกช่วง {amount}/ชม.'**
  String profitHeatmapAverage(String amount);

  /// No description provided for @profitHeatmapNote.
  ///
  /// In th, this message translates to:
  /// **'ค่าประมาณจาก {count} ช่วงทำงานใน {days} วันล่าสุด · รายได้และค่าใช้จ่ายเฉลี่ยเท่ากันตลอดช่วงทำงาน · รายการที่ไม่ได้ผูกช่วงทำงานแบ่งตามชั่วโมงของช่วงทำงานในวันเดียวกัน'**
  String profitHeatmapNote(int count, int days);

  /// No description provided for @profitHeatmapExcluded.
  ///
  /// In th, this message translates to:
  /// **'ไม่ได้นับ: รายได้ {income} รายการ · ค่าใช้จ่าย {expenses} รายการ · ช่วงทำงานที่ไม่มีรายได้ {sessions} ช่วง'**
  String profitHeatmapExcluded(int income, int expenses, int sessions);

  /// No description provided for @recordsTitle.
  ///
  /// In th, this message translates to:
  /// **'รายการทั้งหมด'**
  String get recordsTitle;

  /// No description provided for @recordsLoadMore.
  ///
  /// In th, this message translates to:
  /// **'โหลดเพิ่ม'**
  String get recordsLoadMore;

  /// No description provided for @recordsEnd.
  ///
  /// In th, this message translates to:
  /// **'แสดงครบทุกรายการแล้ว'**
  String get recordsEnd;

  /// No description provided for @recordSave.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get recordSave;

  /// No description provided for @recordSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกแล้ว'**
  String get recordSaved;

  /// No description provided for @recordDelete.
  ///
  /// In th, this message translates to:
  /// **'ลบ'**
  String get recordDelete;

  /// No description provided for @recordDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบแล้ว'**
  String get recordDeleted;

  /// No description provided for @recordDeleteTitle.
  ///
  /// In th, this message translates to:
  /// **'ลบรายการนี้?'**
  String get recordDeleteTitle;

  /// No description provided for @recordDeleteMessage.
  ///
  /// In th, this message translates to:
  /// **'ลบแล้วกู้คืนไม่ได้ และตัวเลขกำไรจะคำนวณใหม่'**
  String get recordDeleteMessage;

  /// No description provided for @fieldDate.
  ///
  /// In th, this message translates to:
  /// **'วันที่'**
  String get fieldDate;

  /// No description provided for @fieldAmount.
  ///
  /// In th, this message translates to:
  /// **'จำนวนเงิน'**
  String get fieldAmount;

  /// No description provided for @fieldWorkingHours.
  ///
  /// In th, this message translates to:
  /// **'ชั่วโมงทำงาน'**
  String get fieldWorkingHours;

  /// No description provided for @fieldOrderCount.
  ///
  /// In th, this message translates to:
  /// **'จำนวนออเดอร์'**
  String get fieldOrderCount;

  /// No description provided for @fieldDistanceKm.
  ///
  /// In th, this message translates to:
  /// **'ระยะทาง (กม.)'**
  String get fieldDistanceKm;

  /// No description provided for @fieldNotes.
  ///
  /// In th, this message translates to:
  /// **'หมายเหตุ'**
  String get fieldNotes;

  /// No description provided for @ordersValue.
  ///
  /// In th, this message translates to:
  /// **'{count} ออเดอร์'**
  String ordersValue(int count);

  /// No description provided for @distanceValue.
  ///
  /// In th, this message translates to:
  /// **'{km} กม.'**
  String distanceValue(String km);

  /// No description provided for @durationHours.
  ///
  /// In th, this message translates to:
  /// **'{hours} ชม.'**
  String durationHours(int hours);

  /// No description provided for @durationMinutes.
  ///
  /// In th, this message translates to:
  /// **'{minutes} นาที'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In th, this message translates to:
  /// **'{hours} ชม. {minutes} นาที'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @incomeTitle.
  ///
  /// In th, this message translates to:
  /// **'รายได้'**
  String get incomeTitle;

  /// No description provided for @incomeAdd.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรายได้'**
  String get incomeAdd;

  /// No description provided for @incomeEditTitle.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขรายได้'**
  String get incomeEditTitle;

  /// No description provided for @incomeEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายได้'**
  String get incomeEmptyTitle;

  /// No description provided for @incomeEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'บันทึกรายได้แต่ละวันหรือแต่ละกะ เพื่อคำนวณกำไรจริง'**
  String get incomeEmptyMessage;

  /// No description provided for @incomeSourceLabel.
  ///
  /// In th, this message translates to:
  /// **'แหล่งรายได้'**
  String get incomeSourceLabel;

  /// No description provided for @incomeSourceHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · พิมพ์เอง เช่น ชื่อแพลตฟอร์ม (แอปไม่ได้เชื่อมต่อแพลตฟอร์มใด)'**
  String get incomeSourceHelper;

  /// No description provided for @incomeSessionLabel.
  ///
  /// In th, this message translates to:
  /// **'ผูกกับช่วงทำงาน'**
  String get incomeSessionLabel;

  /// No description provided for @incomeSessionHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · เลือกช่วงทำงานที่เริ่มในวันที่นี้ ชั่วโมงจะนับจากช่วงทำงานนั้น'**
  String get incomeSessionHelper;

  /// No description provided for @incomeSessionNone.
  ///
  /// In th, this message translates to:
  /// **'ไม่ผูก'**
  String get incomeSessionNone;

  /// No description provided for @incomeSessionOtherDay.
  ///
  /// In th, this message translates to:
  /// **'ช่วงทำงานที่ผูกไว้ (วันอื่น)'**
  String get incomeSessionOtherDay;

  /// No description provided for @incomeSessionLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดช่วงทำงานไม่ได้'**
  String get incomeSessionLoadFailed;

  /// No description provided for @incomeHoursHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · ไม่ต้องกรอกถ้าบันทึกเวลาไว้ในช่วงทำงานแล้ว (กันชั่วโมงซ้ำ)'**
  String get incomeHoursHelper;

  /// No description provided for @expenseTitle.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่าย'**
  String get expenseTitle;

  /// No description provided for @expenseAdd.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มค่าใช้จ่าย'**
  String get expenseAdd;

  /// No description provided for @expenseEditTitle.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขค่าใช้จ่าย'**
  String get expenseEditTitle;

  /// No description provided for @expenseEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีค่าใช้จ่าย'**
  String get expenseEmptyTitle;

  /// No description provided for @expenseEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'บันทึกค่าน้ำมัน ค่าซ่อมบำรุง ค่าเสื่อม และอื่นๆ'**
  String get expenseEmptyMessage;

  /// No description provided for @expenseCategoryLabel.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get expenseCategoryLabel;

  /// No description provided for @expenseCategoryFuel.
  ///
  /// In th, this message translates to:
  /// **'น้ำมัน/ชาร์จไฟ'**
  String get expenseCategoryFuel;

  /// No description provided for @expenseCategoryMaintenance.
  ///
  /// In th, this message translates to:
  /// **'ซ่อมบำรุง'**
  String get expenseCategoryMaintenance;

  /// No description provided for @expenseCategoryDepreciation.
  ///
  /// In th, this message translates to:
  /// **'ค่าเสื่อมราคา'**
  String get expenseCategoryDepreciation;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get expenseCategoryOther;

  /// No description provided for @expenseDescriptionLabel.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด'**
  String get expenseDescriptionLabel;

  /// No description provided for @sessionTitle.
  ///
  /// In th, this message translates to:
  /// **'ช่วงทำงาน'**
  String get sessionTitle;

  /// No description provided for @sessionAdd.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วงทำงาน'**
  String get sessionAdd;

  /// No description provided for @sessionEditTitle.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขช่วงทำงาน'**
  String get sessionEditTitle;

  /// No description provided for @sessionEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีช่วงทำงาน'**
  String get sessionEmptyTitle;

  /// No description provided for @sessionEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'บันทึกเวลาเริ่ม–เลิกงาน เพื่อคำนวณกำไรต่อชั่วโมง'**
  String get sessionEmptyMessage;

  /// No description provided for @sessionStartDate.
  ///
  /// In th, this message translates to:
  /// **'วันที่เริ่ม'**
  String get sessionStartDate;

  /// No description provided for @sessionStartTime.
  ///
  /// In th, this message translates to:
  /// **'เวลาเริ่ม'**
  String get sessionStartTime;

  /// No description provided for @sessionEndTime.
  ///
  /// In th, this message translates to:
  /// **'เวลาเลิก'**
  String get sessionEndTime;

  /// No description provided for @sessionDuration.
  ///
  /// In th, this message translates to:
  /// **'รวม {duration}'**
  String sessionDuration(String duration);

  /// No description provided for @sessionCrossesMidnight.
  ///
  /// In th, this message translates to:
  /// **'เลิกวันถัดไป'**
  String get sessionCrossesMidnight;

  /// No description provided for @sessionEndsNextDay.
  ///
  /// In th, this message translates to:
  /// **'{time} (วันถัดไป)'**
  String sessionEndsNextDay(String time);

  /// No description provided for @sessionTimesEqual.
  ///
  /// In th, this message translates to:
  /// **'เวลาเริ่มและเวลาเลิกต้องไม่ตรงกัน'**
  String get sessionTimesEqual;

  /// No description provided for @navProfile.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์'**
  String get navProfile;

  /// No description provided for @profileTitle.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์'**
  String get profileTitle;

  /// No description provided for @profileMemberSince.
  ///
  /// In th, this message translates to:
  /// **'สมัครเมื่อ {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileAccountSection.
  ///
  /// In th, this message translates to:
  /// **'บัญชี'**
  String get profileAccountSection;

  /// No description provided for @profileEditName.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขชื่อที่แสดง'**
  String get profileEditName;

  /// No description provided for @profileEmailHelper.
  ///
  /// In th, this message translates to:
  /// **'ใช้เข้าสู่ระบบ · ยังเปลี่ยนอีเมลไม่ได้'**
  String get profileEmailHelper;

  /// No description provided for @profileVehicleSection.
  ///
  /// In th, this message translates to:
  /// **'ยานพาหนะและต้นทุน'**
  String get profileVehicleSection;

  /// No description provided for @profileVehicleTile.
  ///
  /// In th, this message translates to:
  /// **'ประเภทรถ ค่าน้ำมัน และค่าเสื่อม'**
  String get profileVehicleTile;

  /// No description provided for @profileVehicleNotConfigured.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้กรอกข้อมูล แตะเพื่อตั้งค่า'**
  String get profileVehicleNotConfigured;

  /// No description provided for @profileFuelEconomyValue.
  ///
  /// In th, this message translates to:
  /// **'{km} กม./ลิตร'**
  String profileFuelEconomyValue(String km);

  /// No description provided for @profileFuelPriceValue.
  ///
  /// In th, this message translates to:
  /// **'น้ำมัน {price}/ลิตร'**
  String profileFuelPriceValue(String price);

  /// No description provided for @profileDepreciationValue.
  ///
  /// In th, this message translates to:
  /// **'ค่าเสื่อม {price}/กม.'**
  String profileDepreciationValue(String price);

  /// No description provided for @profileRegionSection.
  ///
  /// In th, this message translates to:
  /// **'เขตเวลาและสกุลเงิน'**
  String get profileRegionSection;

  /// No description provided for @profileTimezone.
  ///
  /// In th, this message translates to:
  /// **'เขตเวลา'**
  String get profileTimezone;

  /// No description provided for @profileCurrency.
  ///
  /// In th, this message translates to:
  /// **'สกุลเงิน'**
  String get profileCurrency;

  /// No description provided for @profileInfoSection.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลและสัญญาอนุญาต'**
  String get profileInfoSection;

  /// No description provided for @profileAbout.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับแอปและสัญญาอนุญาต'**
  String get profileAbout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชี'**
  String get profileDeleteAccount;

  /// No description provided for @riderProfileTitle.
  ///
  /// In th, this message translates to:
  /// **'ยานพาหนะและต้นทุน'**
  String get riderProfileTitle;

  /// No description provided for @riderProfileTimezoneHelper.
  ///
  /// In th, this message translates to:
  /// **'ชื่อเขตเวลาแบบ IANA เช่น Asia/Bangkok · ใช้แบ่งวันและสัปดาห์ในสรุปกำไร'**
  String get riderProfileTimezoneHelper;

  /// No description provided for @riderProfileCurrency.
  ///
  /// In th, this message translates to:
  /// **'สกุลเงิน {currency} (ตอนนี้รองรับสกุลเดียว)'**
  String riderProfileCurrency(String currency);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชี'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In th, this message translates to:
  /// **'บัญชีและข้อมูลทั้งหมดของคุณจะถูกลบถาวรทันที ได้แก่ รายได้ ค่าใช้จ่าย ช่วงทำงาน โปรไฟล์ไรเดอร์ ร้านของฉัน บันทึกเวลารับ ประวัติการทำนาย และ Scenario กะงาน'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountIrreversible.
  ///
  /// In th, this message translates to:
  /// **'ลบแล้วกู้คืนไม่ได้ ถ้าต้องการใช้งานอีกต้องสมัครใหม่และเริ่มบันทึกใหม่ทั้งหมด'**
  String get deleteAccountIrreversible;

  /// No description provided for @deleteAccountPasswordHelper.
  ///
  /// In th, this message translates to:
  /// **'กรอกรหัสผ่านปัจจุบันเพื่อยืนยันว่าเป็นเจ้าของบัญชี'**
  String get deleteAccountPasswordHelper;

  /// No description provided for @deleteAccountSubmit.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชีถาวร'**
  String get deleteAccountSubmit;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชีถาวร?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลทั้งหมดจะถูกลบทันทีและกู้คืนไม่ได้'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @loginAccountDeleted.
  ///
  /// In th, this message translates to:
  /// **'ลบบัญชีและข้อมูลทั้งหมดแล้ว'**
  String get loginAccountDeleted;

  /// No description provided for @aboutTitle.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับแอป'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In th, this message translates to:
  /// **'ผู้ช่วยไรเดอร์ส่งอาหาร: บันทึกกำไรจริง วางแผนกะงาน และดูเหตุบนถนนที่ไรเดอร์รายงาน ตัวเลขกำไรมาจากรายการที่คุณบันทึกเอง แอปไม่ได้เชื่อมต่อแพลตฟอร์มส่งอาหารใด'**
  String get aboutDescription;

  /// No description provided for @aboutDataTitle.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลที่ใช้ฝึกโมเดลจัดประเภทรูปถนน'**
  String get aboutDataTitle;

  /// No description provided for @aboutDataBody.
  ///
  /// In th, this message translates to:
  /// **'RDD2022 (CC BY 4.0) · AlleyFloodNet (CC BY 4.0) · Flood10k (CC BY-NC 4.0, ใช้เพื่อการวิจัย/ไม่ใช่เชิงพาณิชย์) · ไม่มีรูปจากประเทศไทย ผลจัดประเภทจึงเป็นแค่คำแนะนำ · แอปไม่ได้แจกจ่ายชุดข้อมูลเหล่านี้'**
  String get aboutDataBody;

  /// No description provided for @aboutFontTitle.
  ///
  /// In th, this message translates to:
  /// **'ฟอนต์'**
  String get aboutFontTitle;

  /// No description provided for @aboutFontBody.
  ///
  /// In th, this message translates to:
  /// **'IBM Plex Sans Thai · SIL Open Font License 1.1'**
  String get aboutFontBody;

  /// No description provided for @aboutLicenses.
  ///
  /// In th, this message translates to:
  /// **'สัญญาอนุญาตโอเพนซอร์สทั้งหมด'**
  String get aboutLicenses;

  /// No description provided for @failureInvalidPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ถูกต้อง'**
  String get failureInvalidPassword;

  /// No description provided for @failureNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบรายการนี้ (อาจถูกลบไปแล้ว)'**
  String get failureNotFound;

  /// No description provided for @failureWorkSessionOverlap.
  ///
  /// In th, this message translates to:
  /// **'ช่วงเวลานี้ซ้อนกับช่วงทำงานที่บันทึกไว้แล้ว'**
  String get failureWorkSessionOverlap;

  /// No description provided for @failureInvalidTimeRange.
  ///
  /// In th, this message translates to:
  /// **'เวลาเลิกต้องอยู่หลังเวลาเริ่ม'**
  String get failureInvalidTimeRange;

  /// No description provided for @failureWorkSessionTooLong.
  ///
  /// In th, this message translates to:
  /// **'ช่วงทำงานยาวได้ไม่เกิน 24 ชั่วโมง'**
  String get failureWorkSessionTooLong;

  /// No description provided for @failureInvalidWorkSession.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบช่วงทำงานที่เลือก (อาจถูกลบไปแล้ว)'**
  String get failureInvalidWorkSession;

  /// No description provided for @badgeEstimate.
  ///
  /// In th, this message translates to:
  /// **'ค่าประมาณ'**
  String get badgeEstimate;

  /// No description provided for @navShifts.
  ///
  /// In th, this message translates to:
  /// **'กะงาน'**
  String get navShifts;

  /// No description provided for @shiftsTitle.
  ///
  /// In th, this message translates to:
  /// **'จำลองกะงาน'**
  String get shiftsTitle;

  /// No description provided for @shiftsIntro.
  ///
  /// In th, this message translates to:
  /// **'Scenario คือกะงานที่วางแผนไว้ ระบบประมาณรายได้ ค่าใช้จ่าย และกำไรให้ ทุกตัวเลขเป็นค่าประมาณและไม่นับรวมใน TrueProfit'**
  String get shiftsIntro;

  /// No description provided for @shiftsSelectHint.
  ///
  /// In th, this message translates to:
  /// **'เลือก 2–5 รายการเพื่อเปรียบเทียบ'**
  String get shiftsSelectHint;

  /// No description provided for @shiftsSelectedCount.
  ///
  /// In th, this message translates to:
  /// **'เลือกแล้ว {count} รายการ'**
  String shiftsSelectedCount(int count);

  /// No description provided for @shiftsCompareCount.
  ///
  /// In th, this message translates to:
  /// **'เปรียบเทียบ ({count})'**
  String shiftsCompareCount(int count);

  /// No description provided for @shiftsClearSelection.
  ///
  /// In th, this message translates to:
  /// **'ล้างที่เลือก'**
  String get shiftsClearSelection;

  /// No description provided for @shiftsSelect.
  ///
  /// In th, this message translates to:
  /// **'เลือก {name} เพื่อเปรียบเทียบ'**
  String shiftsSelect(String name);

  /// No description provided for @shiftsMaxSelected.
  ///
  /// In th, this message translates to:
  /// **'เลือกได้สูงสุด 5 รายการ'**
  String get shiftsMaxSelected;

  /// No description provided for @shiftsAdd.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม Scenario'**
  String get shiftsAdd;

  /// No description provided for @shiftsEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มี Scenario'**
  String get shiftsEmptyTitle;

  /// No description provided for @shiftsEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'สร้าง Scenario ของกะที่อยากลอง เช่น 17:00–22:00 วันศุกร์ แล้วดูกำไรประมาณก่อนออกวิ่งจริง เทียบกันได้ครั้งละ 2–5 แบบ'**
  String get shiftsEmptyMessage;

  /// No description provided for @shiftAnyDay.
  ///
  /// In th, this message translates to:
  /// **'ทุกวัน'**
  String get shiftAnyDay;

  /// No description provided for @shiftNetEstimate.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิประมาณ'**
  String get shiftNetEstimate;

  /// No description provided for @shiftPerHourEstimate.
  ///
  /// In th, this message translates to:
  /// **'กำไรต่อชั่วโมงประมาณ'**
  String get shiftPerHourEstimate;

  /// No description provided for @shiftPerHourValue.
  ///
  /// In th, this message translates to:
  /// **'{value}/ชม.'**
  String shiftPerHourValue(String value);

  /// No description provided for @shiftMethodAssumption.
  ///
  /// In th, this message translates to:
  /// **'จากสมมติฐาน'**
  String get shiftMethodAssumption;

  /// No description provided for @shiftMethodHistorical.
  ///
  /// In th, this message translates to:
  /// **'จากประวัติของฉัน'**
  String get shiftMethodHistorical;

  /// No description provided for @shiftMethodUnavailable.
  ///
  /// In th, this message translates to:
  /// **'วิธีที่ยังไม่เปิดใช้'**
  String get shiftMethodUnavailable;

  /// No description provided for @shiftNewTitle.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม Scenario'**
  String get shiftNewTitle;

  /// No description provided for @shiftEditTitle.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข Scenario'**
  String get shiftEditTitle;

  /// No description provided for @shiftFieldName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อ Scenario'**
  String get shiftFieldName;

  /// No description provided for @shiftFieldNameHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น เย็นวันศุกร์'**
  String get shiftFieldNameHint;

  /// No description provided for @shiftFieldStart.
  ///
  /// In th, this message translates to:
  /// **'เวลาเริ่ม'**
  String get shiftFieldStart;

  /// No description provided for @shiftFieldEnd.
  ///
  /// In th, this message translates to:
  /// **'เวลาเลิก'**
  String get shiftFieldEnd;

  /// No description provided for @shiftLengthInvalid.
  ///
  /// In th, this message translates to:
  /// **'กะต้องยาว 30 นาที ถึง 16 ชั่วโมง'**
  String get shiftLengthInvalid;

  /// No description provided for @shiftFieldWeekday.
  ///
  /// In th, this message translates to:
  /// **'วันในสัปดาห์'**
  String get shiftFieldWeekday;

  /// No description provided for @shiftWeekdayHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · วิธีจากประวัติจะใช้เฉพาะวันที่เลือก ถ้ามีข้อมูลวันนั้นอย่างน้อย 5 วัน'**
  String get shiftWeekdayHelper;

  /// No description provided for @shiftFieldMethod.
  ///
  /// In th, this message translates to:
  /// **'วิธีประมาณ'**
  String get shiftFieldMethod;

  /// No description provided for @shiftMethodAssumptionHint.
  ///
  /// In th, this message translates to:
  /// **'คำนวณจากออเดอร์ต่อชั่วโมงและรายได้ต่อออเดอร์ที่คุณกรอก'**
  String get shiftMethodAssumptionHint;

  /// No description provided for @shiftMethodHistoricalHint.
  ///
  /// In th, this message translates to:
  /// **'ใช้รายได้และค่าใช้จ่ายต่อชั่วโมงจากข้อมูลจริงของคุณ 84 วันล่าสุด'**
  String get shiftMethodHistoricalHint;

  /// No description provided for @shiftHistoryUnavailable.
  ///
  /// In th, this message translates to:
  /// **'วิธีจากประวัติใช้ได้เมื่อมีวันที่มีชั่วโมงทำงานอย่างน้อย 5 วันใน 84 วันล่าสุด (ตอนนี้ {days} วัน)'**
  String shiftHistoryUnavailable(int days);

  /// No description provided for @shiftAssumptionsTitle.
  ///
  /// In th, this message translates to:
  /// **'สมมติฐาน'**
  String get shiftAssumptionsTitle;

  /// No description provided for @shiftFieldOrdersPerHour.
  ///
  /// In th, this message translates to:
  /// **'ออเดอร์ต่อชั่วโมง'**
  String get shiftFieldOrdersPerHour;

  /// No description provided for @shiftFieldIncomePerOrder.
  ///
  /// In th, this message translates to:
  /// **'รายได้ต่อออเดอร์ (บาท)'**
  String get shiftFieldIncomePerOrder;

  /// No description provided for @shiftFieldKmPerOrder.
  ///
  /// In th, this message translates to:
  /// **'ระยะทางต่อออเดอร์ (กม.)'**
  String get shiftFieldKmPerOrder;

  /// No description provided for @shiftKmPerOrderHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · เว้นว่าง = ไม่รวมค่าน้ำมันและค่าเสื่อม'**
  String get shiftKmPerOrderHelper;

  /// No description provided for @shiftProfileFallbackHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · เว้นว่าง = ใช้ค่าจากโปรไฟล์'**
  String get shiftProfileFallbackHelper;

  /// No description provided for @shiftFieldOtherCosts.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่ายคงที่ของกะ (บาท)'**
  String get shiftFieldOtherCosts;

  /// No description provided for @shiftOtherCostsHelper.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · เช่น ที่จอดรถ ค่าข้าว'**
  String get shiftOtherCostsHelper;

  /// No description provided for @shiftFormEstimateNote.
  ///
  /// In th, this message translates to:
  /// **'บันทึกแล้วระบบจะคำนวณค่าประมาณให้ทันที'**
  String get shiftFormEstimateNote;

  /// No description provided for @shiftDetailTitle.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด Scenario'**
  String get shiftDetailTitle;

  /// No description provided for @shiftEstimatedRevenue.
  ///
  /// In th, this message translates to:
  /// **'รายได้ประมาณ'**
  String get shiftEstimatedRevenue;

  /// No description provided for @shiftEstimatedExpenses.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่ายประมาณ'**
  String get shiftEstimatedExpenses;

  /// No description provided for @shiftRangeTitle.
  ///
  /// In th, this message translates to:
  /// **'ช่วงกำไรสุทธิประมาณ'**
  String get shiftRangeTitle;

  /// No description provided for @shiftRangeValue.
  ///
  /// In th, this message translates to:
  /// **'{low} ถึง {high}'**
  String shiftRangeValue(String low, String high);

  /// No description provided for @shiftRangeHint.
  ///
  /// In th, this message translates to:
  /// **'P20–P80 ของกำไรต่อชั่วโมงรายวันในประวัติ × ชั่วโมงของกะ'**
  String get shiftRangeHint;

  /// No description provided for @shiftBasisTitle.
  ///
  /// In th, this message translates to:
  /// **'ที่มาของตัวเลข'**
  String get shiftBasisTitle;

  /// No description provided for @shiftBasisSameWeekday.
  ///
  /// In th, this message translates to:
  /// **'ใช้เฉพาะ{weekday} {days} วัน'**
  String shiftBasisSameWeekday(String weekday, int days);

  /// No description provided for @shiftBasisAllDays.
  ///
  /// In th, this message translates to:
  /// **'ใช้ทุกวันที่ทำงาน {days} วัน'**
  String shiftBasisAllDays(int days);

  /// No description provided for @shiftBasisWindow.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลช่วง {from} – {to}'**
  String shiftBasisWindow(String from, String to);

  /// No description provided for @shiftHistoricalHours.
  ///
  /// In th, this message translates to:
  /// **'ชั่วโมงทำงานในประวัติ'**
  String get shiftHistoricalHours;

  /// No description provided for @shiftRevenuePerHour.
  ///
  /// In th, this message translates to:
  /// **'รายได้ต่อชั่วโมง'**
  String get shiftRevenuePerHour;

  /// No description provided for @shiftExpensesPerHour.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่ายต่อชั่วโมง'**
  String get shiftExpensesPerHour;

  /// No description provided for @shiftHistoricalNote.
  ///
  /// In th, this message translates to:
  /// **'ใช้ค่าเฉลี่ยทั้งวัน ไม่ได้แยกตามช่วงเวลาของกะ'**
  String get shiftHistoricalNote;

  /// No description provided for @shiftShiftHours.
  ///
  /// In th, this message translates to:
  /// **'ชั่วโมงของกะ'**
  String get shiftShiftHours;

  /// No description provided for @shiftHoursValue.
  ///
  /// In th, this message translates to:
  /// **'{hours} ชม.'**
  String shiftHoursValue(String hours);

  /// No description provided for @shiftExpectedOrders.
  ///
  /// In th, this message translates to:
  /// **'ออเดอร์ที่คาด'**
  String get shiftExpectedOrders;

  /// No description provided for @shiftExpectedKm.
  ///
  /// In th, this message translates to:
  /// **'ระยะทางที่คาด (กม.)'**
  String get shiftExpectedKm;

  /// No description provided for @shiftFuelCost.
  ///
  /// In th, this message translates to:
  /// **'ค่าน้ำมัน'**
  String get shiftFuelCost;

  /// No description provided for @shiftDepreciationCost.
  ///
  /// In th, this message translates to:
  /// **'ค่าเสื่อม'**
  String get shiftDepreciationCost;

  /// No description provided for @shiftOtherCosts.
  ///
  /// In th, this message translates to:
  /// **'ค่าใช้จ่ายคงที่'**
  String get shiftOtherCosts;

  /// No description provided for @shiftSourceScenario.
  ///
  /// In th, this message translates to:
  /// **'จาก Scenario'**
  String get shiftSourceScenario;

  /// No description provided for @shiftSourceProfile.
  ///
  /// In th, this message translates to:
  /// **'จากโปรไฟล์'**
  String get shiftSourceProfile;

  /// No description provided for @shiftInputFromProfile.
  ///
  /// In th, this message translates to:
  /// **'เว้นว่าง · ใช้ค่าจากโปรไฟล์'**
  String get shiftInputFromProfile;

  /// No description provided for @shiftInputsTitle.
  ///
  /// In th, this message translates to:
  /// **'สมมติฐานที่กรอก'**
  String get shiftInputsTitle;

  /// No description provided for @shiftNotSet.
  ///
  /// In th, this message translates to:
  /// **'—'**
  String get shiftNotSet;

  /// No description provided for @shiftWarningDistance.
  ///
  /// In th, this message translates to:
  /// **'ไม่รวมต้นทุนระยะทาง (ไม่ได้กรอกระยะทางต่อออเดอร์)'**
  String get shiftWarningDistance;

  /// No description provided for @shiftWarningFuel.
  ///
  /// In th, this message translates to:
  /// **'ไม่รวมค่าน้ำมัน (ไม่มีอัตราสิ้นเปลืองหรือราคาน้ำมันทั้งใน Scenario และโปรไฟล์)'**
  String get shiftWarningFuel;

  /// No description provided for @shiftWarningDepreciation.
  ///
  /// In th, this message translates to:
  /// **'ไม่รวมค่าเสื่อม (ไม่มีค่าเสื่อมต่อ กม. ทั้งใน Scenario และโปรไฟล์)'**
  String get shiftWarningDepreciation;

  /// No description provided for @shiftWarningFewWeekdays.
  ///
  /// In th, this message translates to:
  /// **'วันเดียวกันในสัปดาห์มีข้อมูลไม่ถึง 5 วัน จึงใช้ทุกวันแทน'**
  String get shiftWarningFewWeekdays;

  /// No description provided for @shiftWarningOther.
  ///
  /// In th, this message translates to:
  /// **'คำเตือนจากระบบ: {code}'**
  String shiftWarningOther(String code);

  /// No description provided for @shiftReEstimate.
  ///
  /// In th, this message translates to:
  /// **'คำนวณใหม่ด้วยข้อมูลล่าสุด'**
  String get shiftReEstimate;

  /// No description provided for @shiftReEstimated.
  ///
  /// In th, this message translates to:
  /// **'คำนวณใหม่แล้ว'**
  String get shiftReEstimated;

  /// No description provided for @shiftEdit.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข'**
  String get shiftEdit;

  /// No description provided for @shiftDelete.
  ///
  /// In th, this message translates to:
  /// **'ลบ Scenario'**
  String get shiftDelete;

  /// No description provided for @shiftDeleteTitle.
  ///
  /// In th, this message translates to:
  /// **'ลบ Scenario นี้?'**
  String get shiftDeleteTitle;

  /// No description provided for @shiftDeleteMessage.
  ///
  /// In th, this message translates to:
  /// **'Scenario และค่าประมาณจะถูกลบ กู้คืนไม่ได้ (ไม่กระทบข้อมูลจริงใน TrueProfit)'**
  String get shiftDeleteMessage;

  /// No description provided for @shiftLinkTitle.
  ///
  /// In th, this message translates to:
  /// **'ช่วงทำงานจริง'**
  String get shiftLinkTitle;

  /// No description provided for @shiftLinkNone.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้ผูกกับช่วงทำงานจริง'**
  String get shiftLinkNone;

  /// No description provided for @shiftLinkHint.
  ///
  /// In th, this message translates to:
  /// **'ไม่บังคับ · ผูกไว้เพื่อจำว่ากะจริงตรงกับ Scenario ไหน ไม่เปลี่ยนค่าประมาณ'**
  String get shiftLinkHint;

  /// No description provided for @shiftLinkAction.
  ///
  /// In th, this message translates to:
  /// **'ผูกกับช่วงทำงานจริง'**
  String get shiftLinkAction;

  /// No description provided for @shiftLinkChange.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนช่วงทำงาน'**
  String get shiftLinkChange;

  /// No description provided for @shiftUnlink.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิกการผูก'**
  String get shiftUnlink;

  /// No description provided for @shiftLinked.
  ///
  /// In th, this message translates to:
  /// **'ผูกกับช่วงทำงานแล้ว'**
  String get shiftLinked;

  /// No description provided for @shiftUnlinked.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิกการผูกแล้ว'**
  String get shiftUnlinked;

  /// No description provided for @shiftNotInTrueProfit.
  ///
  /// In th, this message translates to:
  /// **'ค่าประมาณจาก Shift Simulator ไม่นับรวมใน TrueProfit'**
  String get shiftNotInTrueProfit;

  /// No description provided for @shiftEstimatedAt.
  ///
  /// In th, this message translates to:
  /// **'คำนวณล่าสุด {date}'**
  String shiftEstimatedAt(String date);

  /// No description provided for @shiftPickSessionTitle.
  ///
  /// In th, this message translates to:
  /// **'เลือกช่วงทำงาน'**
  String get shiftPickSessionTitle;

  /// No description provided for @shiftPickSessionEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีช่วงทำงาน'**
  String get shiftPickSessionEmptyTitle;

  /// No description provided for @shiftPickSessionEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วงทำงานจริงก่อน แล้วกลับมาผูกกับ Scenario'**
  String get shiftPickSessionEmptyMessage;

  /// No description provided for @shiftCompareTitle.
  ///
  /// In th, this message translates to:
  /// **'เปรียบเทียบ Scenario'**
  String get shiftCompareTitle;

  /// No description provided for @shiftBestNet.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิสูงสุด'**
  String get shiftBestNet;

  /// No description provided for @shiftBestPerHour.
  ///
  /// In th, this message translates to:
  /// **'กำไรต่อชั่วโมงสูงสุด'**
  String get shiftBestPerHour;

  /// No description provided for @shiftCompareNote.
  ///
  /// In th, this message translates to:
  /// **'ทุกตัวเลขเป็นค่าประมาณ ไม่นับรวมใน TrueProfit'**
  String get shiftCompareNote;

  /// No description provided for @failureInvalidShiftLength.
  ///
  /// In th, this message translates to:
  /// **'กะต้องยาว 30 นาที ถึง 16 ชั่วโมง'**
  String get failureInvalidShiftLength;

  /// No description provided for @failureMissingAssumption.
  ///
  /// In th, this message translates to:
  /// **'วิธีจากสมมติฐานต้องมีออเดอร์ต่อชั่วโมงและรายได้ต่อออเดอร์'**
  String get failureMissingAssumption;

  /// No description provided for @failureInsufficientHistory.
  ///
  /// In th, this message translates to:
  /// **'ประวัติยังไม่พอ ต้องมีวันที่มีชั่วโมงทำงานอย่างน้อย 5 วันใน 84 วันล่าสุด'**
  String get failureInsufficientHistory;

  /// No description provided for @failureEstimationMethodUnavailable.
  ///
  /// In th, this message translates to:
  /// **'วิธีประมาณนี้ยังไม่เปิดใช้'**
  String get failureEstimationMethodUnavailable;

  /// No description provided for @homeRoadTitle.
  ///
  /// In th, this message translates to:
  /// **'เหตุบนถนนใกล้คุณ'**
  String get homeRoadTitle;

  /// No description provided for @homeRoadMessage.
  ///
  /// In th, this message translates to:
  /// **'ดูแผนที่เหตุที่ไรเดอร์รายงาน และแจ้งเหตุที่คุณพบ'**
  String get homeRoadMessage;

  /// No description provided for @roadTitle.
  ///
  /// In th, this message translates to:
  /// **'เหตุบนถนน'**
  String get roadTitle;

  /// No description provided for @roadTabMap.
  ///
  /// In th, this message translates to:
  /// **'แผนที่'**
  String get roadTabMap;

  /// No description provided for @roadTabNearby.
  ///
  /// In th, this message translates to:
  /// **'ใกล้ฉัน'**
  String get roadTabNearby;

  /// No description provided for @roadReportAction.
  ///
  /// In th, this message translates to:
  /// **'รายงานเหตุ'**
  String get roadReportAction;

  /// No description provided for @roadMyReports.
  ///
  /// In th, this message translates to:
  /// **'รายงานของฉัน'**
  String get roadMyReports;

  /// No description provided for @roadCategoryFlooding.
  ///
  /// In th, this message translates to:
  /// **'น้ำท่วม'**
  String get roadCategoryFlooding;

  /// No description provided for @roadCategoryRoadDamage.
  ///
  /// In th, this message translates to:
  /// **'ถนนชำรุด'**
  String get roadCategoryRoadDamage;

  /// No description provided for @roadCategoryRoadClosure.
  ///
  /// In th, this message translates to:
  /// **'ปิดถนน'**
  String get roadCategoryRoadClosure;

  /// No description provided for @roadCategoryRoadObstacle.
  ///
  /// In th, this message translates to:
  /// **'สิ่งกีดขวาง'**
  String get roadCategoryRoadObstacle;

  /// No description provided for @roadCategoryTrafficIncident.
  ///
  /// In th, this message translates to:
  /// **'อุบัติเหตุ'**
  String get roadCategoryTrafficIncident;

  /// No description provided for @roadStatusUnverified.
  ///
  /// In th, this message translates to:
  /// **'รอผู้รายงานเพิ่ม'**
  String get roadStatusUnverified;

  /// No description provided for @roadStatusCorroborated.
  ///
  /// In th, this message translates to:
  /// **'มีผู้รายงานหลายคน'**
  String get roadStatusCorroborated;

  /// No description provided for @roadStatusResolved.
  ///
  /// In th, this message translates to:
  /// **'คลี่คลายแล้ว'**
  String get roadStatusResolved;

  /// No description provided for @roadStatusExpired.
  ///
  /// In th, this message translates to:
  /// **'หมดอายุ'**
  String get roadStatusExpired;

  /// No description provided for @roadStatusRejected.
  ///
  /// In th, this message translates to:
  /// **'ผู้ดูแลนำออก'**
  String get roadStatusRejected;

  /// No description provided for @roadReportedByUsers.
  ///
  /// In th, this message translates to:
  /// **'รายงานโดยผู้ใช้ · อัปเดตล่าสุด {ago}'**
  String roadReportedByUsers(String ago);

  /// No description provided for @roadAgoJustNow.
  ///
  /// In th, this message translates to:
  /// **'เมื่อสักครู่'**
  String get roadAgoJustNow;

  /// No description provided for @roadAgoMinutes.
  ///
  /// In th, this message translates to:
  /// **'{n} นาทีที่แล้ว'**
  String roadAgoMinutes(int n);

  /// No description provided for @roadAgoHours.
  ///
  /// In th, this message translates to:
  /// **'{n} ชั่วโมงที่แล้ว'**
  String roadAgoHours(int n);

  /// No description provided for @roadAgoDays.
  ///
  /// In th, this message translates to:
  /// **'{n} วันที่แล้ว'**
  String roadAgoDays(int n);

  /// No description provided for @roadDistanceM.
  ///
  /// In th, this message translates to:
  /// **'{m} ม.'**
  String roadDistanceM(int m);

  /// No description provided for @roadDistanceKm.
  ///
  /// In th, this message translates to:
  /// **'{km} กม.'**
  String roadDistanceKm(String km);

  /// No description provided for @roadNotice.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลรายงานโดยไรเดอร์ ไม่ได้ตรวจสอบโดย RiderOS ตำแหน่งและเวลามาจากผู้รายงานและอาจไม่เป็นปัจจุบัน'**
  String get roadNotice;

  /// No description provided for @roadMapZoomIn.
  ///
  /// In th, this message translates to:
  /// **'ซูมเข้าเพื่อดูเหตุในบริเวณนี้'**
  String get roadMapZoomIn;

  /// No description provided for @roadMapTruncated.
  ///
  /// In th, this message translates to:
  /// **'มีเหตุมากเกินกว่าจะแสดงทั้งหมด ซูมเข้าเพื่อดูให้ครบ'**
  String get roadMapTruncated;

  /// No description provided for @roadMapLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดเหตุบนแผนที่ไม่สำเร็จ'**
  String get roadMapLoadFailed;

  /// No description provided for @roadMapMyLocation.
  ///
  /// In th, this message translates to:
  /// **'ไปที่ตำแหน่งของฉัน'**
  String get roadMapMyLocation;

  /// No description provided for @roadMapIncidentCount.
  ///
  /// In th, this message translates to:
  /// **'{n} เหตุในบริเวณนี้'**
  String roadMapIncidentCount(int n);

  /// No description provided for @roadClusterLabel.
  ///
  /// In th, this message translates to:
  /// **'{n} เหตุอยู่ใกล้กัน แตะเพื่อดู'**
  String roadClusterLabel(int n);

  /// No description provided for @roadClusterSheetTitle.
  ///
  /// In th, this message translates to:
  /// **'{n} เหตุที่จุดนี้'**
  String roadClusterSheetTitle(int n);

  /// No description provided for @roadNearbyEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีเหตุใกล้คุณ'**
  String get roadNearbyEmptyTitle;

  /// No description provided for @roadNearbyEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีเหตุที่ยังเปิดอยู่ในระยะ {km} กม. จากตำแหน่งของคุณ'**
  String roadNearbyEmptyMessage(int km);

  /// No description provided for @roadNearbyHeader.
  ///
  /// In th, this message translates to:
  /// **'ในระยะ {km} กม. · เรียงจากใกล้สุด'**
  String roadNearbyHeader(int km);

  /// No description provided for @roadLocationFinding.
  ///
  /// In th, this message translates to:
  /// **'กำลังหาตำแหน่ง…'**
  String get roadLocationFinding;

  /// No description provided for @roadLocationDeniedTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้รับสิทธิ์ตำแหน่ง'**
  String get roadLocationDeniedTitle;

  /// No description provided for @roadLocationDeniedMessage.
  ///
  /// In th, this message translates to:
  /// **'อนุญาตให้ใช้ตำแหน่งขณะใช้แอป เพื่อดูเหตุใกล้คุณ แอปไม่ติดตามตำแหน่งเบื้องหลัง'**
  String get roadLocationDeniedMessage;

  /// No description provided for @roadLocationAllow.
  ///
  /// In th, this message translates to:
  /// **'อนุญาตตำแหน่ง'**
  String get roadLocationAllow;

  /// No description provided for @roadLocationDeniedForeverMessage.
  ///
  /// In th, this message translates to:
  /// **'สิทธิ์ตำแหน่งของแอปถูกปิดไว้ เปิดได้ที่การตั้งค่าแอป'**
  String get roadLocationDeniedForeverMessage;

  /// No description provided for @roadLocationOpenSettings.
  ///
  /// In th, this message translates to:
  /// **'เปิดการตั้งค่า'**
  String get roadLocationOpenSettings;

  /// No description provided for @roadLocationServiceOffTitle.
  ///
  /// In th, this message translates to:
  /// **'ตำแหน่งของเครื่องปิดอยู่'**
  String get roadLocationServiceOffTitle;

  /// No description provided for @roadLocationServiceOffMessage.
  ///
  /// In th, this message translates to:
  /// **'เปิดตำแหน่ง (GPS) ของเครื่อง แล้วลองใหม่'**
  String get roadLocationServiceOffMessage;

  /// No description provided for @roadLocationUnavailableTitle.
  ///
  /// In th, this message translates to:
  /// **'หาตำแหน่งไม่ได้'**
  String get roadLocationUnavailableTitle;

  /// No description provided for @roadLocationUnavailableMessage.
  ///
  /// In th, this message translates to:
  /// **'ลองใหม่อีกครั้ง หรือดูเหตุจากแผนที่'**
  String get roadLocationUnavailableMessage;

  /// No description provided for @roadReportTitle.
  ///
  /// In th, this message translates to:
  /// **'รายงานเหตุบนถนน'**
  String get roadReportTitle;

  /// No description provided for @roadReportCategory.
  ///
  /// In th, this message translates to:
  /// **'ประเภทเหตุ'**
  String get roadReportCategory;

  /// No description provided for @roadReportCategoryRequired.
  ///
  /// In th, this message translates to:
  /// **'เลือกประเภทเหตุ'**
  String get roadReportCategoryRequired;

  /// No description provided for @roadReportLocation.
  ///
  /// In th, this message translates to:
  /// **'ตำแหน่งของเหตุ'**
  String get roadReportLocation;

  /// No description provided for @roadReportLocationGps.
  ///
  /// In th, this message translates to:
  /// **'ตำแหน่งปัจจุบันของคุณ'**
  String get roadReportLocationGps;

  /// No description provided for @roadReportLocationManual.
  ///
  /// In th, this message translates to:
  /// **'ตำแหน่งที่คุณปักหมุด'**
  String get roadReportLocationManual;

  /// No description provided for @roadReportLocationRequired.
  ///
  /// In th, this message translates to:
  /// **'เลือกตำแหน่งของเหตุบนแผนที่'**
  String get roadReportLocationRequired;

  /// No description provided for @roadReportLocationNoGps.
  ///
  /// In th, this message translates to:
  /// **'ไม่ได้ใช้ตำแหน่งของเครื่อง ปักหมุดเองบนแผนที่ได้'**
  String get roadReportLocationNoGps;

  /// No description provided for @roadReportChooseLocation.
  ///
  /// In th, this message translates to:
  /// **'เลือกบนแผนที่'**
  String get roadReportChooseLocation;

  /// No description provided for @roadReportChangeLocation.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนตำแหน่ง'**
  String get roadReportChangeLocation;

  /// No description provided for @roadReportLocationHelp.
  ///
  /// In th, this message translates to:
  /// **'ไรเดอร์คนอื่นเห็นตำแหน่งของเหตุ แต่ไม่เห็นว่าใครรายงาน'**
  String get roadReportLocationHelp;

  /// No description provided for @roadReportPhoto.
  ///
  /// In th, this message translates to:
  /// **'รูปภาพ'**
  String get roadReportPhoto;

  /// No description provided for @roadReportPhotoHelp.
  ///
  /// In th, this message translates to:
  /// **'แอปย่อรูปก่อนส่ง เซิร์ฟเวอร์ลบข้อมูลตำแหน่งในไฟล์ (EXIF) และรูปนี้เห็นได้เฉพาะคุณ'**
  String get roadReportPhotoHelp;

  /// No description provided for @roadReportTakePhoto.
  ///
  /// In th, this message translates to:
  /// **'ถ่ายรูป'**
  String get roadReportTakePhoto;

  /// No description provided for @roadReportPickPhoto.
  ///
  /// In th, this message translates to:
  /// **'เลือกจากคลังภาพ'**
  String get roadReportPickPhoto;

  /// No description provided for @roadReportRemovePhoto.
  ///
  /// In th, this message translates to:
  /// **'ลบรูป'**
  String get roadReportRemovePhoto;

  /// No description provided for @roadReportPhotoFailed.
  ///
  /// In th, this message translates to:
  /// **'เปิดกล้องหรือคลังภาพไม่ได้ ตรวจสอบสิทธิ์ของแอปแล้วลองใหม่'**
  String get roadReportPhotoFailed;

  /// No description provided for @roadReportPhotoTooLarge.
  ///
  /// In th, this message translates to:
  /// **'รูปใหญ่เกิน 5 MB กรุณาเลือกรูปอื่น'**
  String get roadReportPhotoTooLarge;

  /// No description provided for @roadReportDescription.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียด'**
  String get roadReportDescription;

  /// No description provided for @roadReportSubmit.
  ///
  /// In th, this message translates to:
  /// **'ส่งรายงาน'**
  String get roadReportSubmit;

  /// No description provided for @roadReportSent.
  ///
  /// In th, this message translates to:
  /// **'ส่งรายงานแล้ว'**
  String get roadReportSent;

  /// No description provided for @roadReportMerged.
  ///
  /// In th, this message translates to:
  /// **'ส่งแล้ว · รวมกับเหตุเดียวกันที่มีผู้รายงานไว้ใกล้ๆ'**
  String get roadReportMerged;

  /// No description provided for @roadReportView.
  ///
  /// In th, this message translates to:
  /// **'ดู'**
  String get roadReportView;

  /// No description provided for @roadAlreadyReported.
  ///
  /// In th, this message translates to:
  /// **'คุณรายงานเหตุนี้ไว้แล้ว แจ้งว่ายังอยู่ได้ที่หน้ารายละเอียด'**
  String get roadAlreadyReported;

  /// No description provided for @roadOpenIncident.
  ///
  /// In th, this message translates to:
  /// **'เปิดเหตุนี้'**
  String get roadOpenIncident;

  /// No description provided for @roadPickLocationTitle.
  ///
  /// In th, this message translates to:
  /// **'เลือกตำแหน่ง'**
  String get roadPickLocationTitle;

  /// No description provided for @roadPickLocationHelp.
  ///
  /// In th, this message translates to:
  /// **'เลื่อนแผนที่ให้หมุดอยู่ตรงจุดเกิดเหตุ'**
  String get roadPickLocationHelp;

  /// No description provided for @roadPickLocationUse.
  ///
  /// In th, this message translates to:
  /// **'ใช้ตำแหน่งนี้'**
  String get roadPickLocationUse;

  /// No description provided for @roadDetailTitle.
  ///
  /// In th, this message translates to:
  /// **'รายละเอียดเหตุ'**
  String get roadDetailTitle;

  /// No description provided for @roadDetailReporters.
  ///
  /// In th, this message translates to:
  /// **'ผู้รายงาน'**
  String get roadDetailReporters;

  /// No description provided for @roadDetailReports.
  ///
  /// In th, this message translates to:
  /// **'รายงานทั้งหมด'**
  String get roadDetailReports;

  /// No description provided for @roadDetailCleared.
  ///
  /// In th, this message translates to:
  /// **'แจ้งว่าคลี่คลาย'**
  String get roadDetailCleared;

  /// No description provided for @roadDetailFirstReported.
  ///
  /// In th, this message translates to:
  /// **'รายงานครั้งแรก'**
  String get roadDetailFirstReported;

  /// No description provided for @roadDetailExpires.
  ///
  /// In th, this message translates to:
  /// **'หมดอายุ'**
  String get roadDetailExpires;

  /// No description provided for @roadPeople.
  ///
  /// In th, this message translates to:
  /// **'{n} คน'**
  String roadPeople(int n);

  /// No description provided for @roadTimes.
  ///
  /// In th, this message translates to:
  /// **'{n} ครั้ง'**
  String roadTimes(int n);

  /// No description provided for @roadDateTime.
  ///
  /// In th, this message translates to:
  /// **'{date} {time}'**
  String roadDateTime(String date, String time);

  /// No description provided for @roadConfirmQuestion.
  ///
  /// In th, this message translates to:
  /// **'เหตุนี้ยังอยู่ไหม?'**
  String get roadConfirmQuestion;

  /// No description provided for @roadConfirmStill.
  ///
  /// In th, this message translates to:
  /// **'ยังอยู่'**
  String get roadConfirmStill;

  /// No description provided for @roadConfirmCleared.
  ///
  /// In th, this message translates to:
  /// **'คลี่คลายแล้ว'**
  String get roadConfirmCleared;

  /// No description provided for @roadConfirmMineStill.
  ///
  /// In th, this message translates to:
  /// **'คุณแจ้งว่ายังอยู่ · {ago}'**
  String roadConfirmMineStill(String ago);

  /// No description provided for @roadConfirmMineCleared.
  ///
  /// In th, this message translates to:
  /// **'คุณแจ้งว่าคลี่คลายแล้ว · {ago}'**
  String roadConfirmMineCleared(String ago);

  /// The server counts 'gone' only after the latest report.
  ///
  /// In th, this message translates to:
  /// **'คุณแจ้งว่าคลี่คลายแล้ว · {ago} แต่มีรายงานใหม่หลังจากนั้น คำตอบเดิมจึงไม่นับ ถ้าคลี่คลายแล้วจริง กด \"คลี่คลายแล้ว\" อีกครั้ง'**
  String roadConfirmMineClearedStale(String ago);

  /// No description provided for @roadConfirmHelp.
  ///
  /// In th, this message translates to:
  /// **'คำตอบใหม่แทนคำตอบเดิมของคุณ เหตุจะปิดเมื่อมีไรเดอร์หลายคนแจ้งว่าคลี่คลาย'**
  String get roadConfirmHelp;

  /// No description provided for @roadConfirmSaved.
  ///
  /// In th, this message translates to:
  /// **'บันทึกคำตอบแล้ว'**
  String get roadConfirmSaved;

  /// No description provided for @roadClosedMessage.
  ///
  /// In th, this message translates to:
  /// **'เหตุนี้ปิดแล้ว ({status}) จึงแจ้งเพิ่มไม่ได้'**
  String roadClosedMessage(String status);

  /// No description provided for @roadMyReport.
  ///
  /// In th, this message translates to:
  /// **'รายงานของคุณ'**
  String get roadMyReport;

  /// No description provided for @roadPhotoLoadFailed.
  ///
  /// In th, this message translates to:
  /// **'โหลดรูปไม่สำเร็จ'**
  String get roadPhotoLoadFailed;

  /// No description provided for @roadAiSuggestion.
  ///
  /// In th, this message translates to:
  /// **'AI แนะนำ: {label} ({percent}%)'**
  String roadAiSuggestion(String label, int percent);

  /// No description provided for @roadAiUnsure.
  ///
  /// In th, this message translates to:
  /// **'AI ไม่แน่ใจประเภทจากรูปนี้'**
  String get roadAiUnsure;

  /// No description provided for @roadAiPending.
  ///
  /// In th, this message translates to:
  /// **'AI กำลังดูรูปนี้'**
  String get roadAiPending;

  /// No description provided for @roadAiOther.
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get roadAiOther;

  /// No description provided for @roadMyReportsEmptyTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายงาน'**
  String get roadMyReportsEmptyTitle;

  /// No description provided for @roadMyReportsEmptyMessage.
  ///
  /// In th, this message translates to:
  /// **'เหตุที่คุณรายงานจะแสดงที่นี่'**
  String get roadMyReportsEmptyMessage;

  /// No description provided for @roadHasPhoto.
  ///
  /// In th, this message translates to:
  /// **'มีรูป'**
  String get roadHasPhoto;

  /// No description provided for @failureAlreadyReported.
  ///
  /// In th, this message translates to:
  /// **'คุณรายงานเหตุนี้ไว้แล้ว'**
  String get failureAlreadyReported;

  /// No description provided for @failureIncidentClosed.
  ///
  /// In th, this message translates to:
  /// **'เหตุนี้ปิดแล้ว แจ้งเพิ่มไม่ได้'**
  String get failureIncidentClosed;

  /// No description provided for @failureUnsupportedImage.
  ///
  /// In th, this message translates to:
  /// **'รองรับเฉพาะรูป JPEG, PNG หรือ WebP'**
  String get failureUnsupportedImage;

  /// No description provided for @failureImageTooLarge.
  ///
  /// In th, this message translates to:
  /// **'รูปใหญ่เกิน 5 MB'**
  String get failureImageTooLarge;

  /// No description provided for @failureImageStorageUnavailable.
  ///
  /// In th, this message translates to:
  /// **'ตอนนี้เซิร์ฟเวอร์รับรูปไม่ได้ ส่งรายงานโดยไม่แนบรูปได้'**
  String get failureImageStorageUnavailable;

  /// No description provided for @failureInvalidBbox.
  ///
  /// In th, this message translates to:
  /// **'บริเวณแผนที่กว้างเกินไป ซูมเข้าแล้วลองใหม่'**
  String get failureInvalidBbox;

  /// No description provided for @failureNetwork.
  ///
  /// In th, this message translates to:
  /// **'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่'**
  String get failureNetwork;

  /// No description provided for @failureTimeout.
  ///
  /// In th, this message translates to:
  /// **'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่'**
  String get failureTimeout;

  /// No description provided for @failureSessionExpired.
  ///
  /// In th, this message translates to:
  /// **'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง'**
  String get failureSessionExpired;

  /// No description provided for @failureRateLimited.
  ///
  /// In th, this message translates to:
  /// **'ลองบ่อยเกินไป กรุณารอ {seconds} วินาทีแล้วลองใหม่'**
  String failureRateLimited(int seconds);

  /// No description provided for @failureRateLimitedNoTime.
  ///
  /// In th, this message translates to:
  /// **'ลองบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่'**
  String get failureRateLimitedNoTime;

  /// No description provided for @failureInvalidCredentials.
  ///
  /// In th, this message translates to:
  /// **'อีเมลหรือรหัสผ่านไม่ถูกต้อง'**
  String get failureInvalidCredentials;

  /// No description provided for @failureEmailTaken.
  ///
  /// In th, this message translates to:
  /// **'อีเมลนี้ถูกใช้สมัครแล้ว'**
  String get failureEmailTaken;

  /// No description provided for @failureWeakPassword.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านนี้ไม่ปลอดภัย (สั้นเกินไป พบบ่อยเกินไป หรือเหมือนชื่ออีเมล)'**
  String get failureWeakPassword;

  /// No description provided for @failureInvalidResetToken.
  ///
  /// In th, this message translates to:
  /// **'ลิงก์รีเซ็ตไม่ถูกต้อง หมดอายุ หรือถูกใช้ไปแล้ว กรุณาขอลิงก์ใหม่'**
  String get failureInvalidResetToken;

  /// No description provided for @failurePasswordResetUnavailable.
  ///
  /// In th, this message translates to:
  /// **'ระบบรีเซ็ตรหัสผ่านยังไม่เปิดให้บริการ'**
  String get failurePasswordResetUnavailable;

  /// No description provided for @failureInvalidTimezone.
  ///
  /// In th, this message translates to:
  /// **'เขตเวลาไม่ถูกต้อง'**
  String get failureInvalidTimezone;

  /// No description provided for @failureValidation.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลบางช่องไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'**
  String get failureValidation;

  /// No description provided for @failureServer.
  ///
  /// In th, this message translates to:
  /// **'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง'**
  String get failureServer;

  /// No description provided for @failureUnknown.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่'**
  String get failureUnknown;
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
      <String>['th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
