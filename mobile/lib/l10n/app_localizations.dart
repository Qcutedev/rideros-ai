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

  /// No description provided for @homeGreeting.
  ///
  /// In th, this message translates to:
  /// **'สวัสดี {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSignedInAs.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบด้วย {email}'**
  String homeSignedInAs(String email);

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
  /// **'ผู้ช่วยไรเดอร์ส่งอาหาร: บันทึกกำไรจริง ประมาณเวลา Order-to-Pickup และวางแผนกะงาน ตัวเลขกำไรมาจากรายการที่คุณบันทึกเอง แอปไม่ได้เชื่อมต่อแพลตฟอร์มส่งอาหารใด'**
  String get aboutDescription;

  /// No description provided for @aboutDataTitle.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลที่ใช้ฝึกโมเดล Pickup'**
  String get aboutDataTitle;

  /// No description provided for @aboutDataBody.
  ///
  /// In th, this message translates to:
  /// **'Meituan INFORMS TSL Research Challenge (ข้อมูลการส่งอาหารในประเทศจีน) · สัญญาอนุญาต CC BY-NC 4.0 (ใช้เพื่อการวิจัย/ไม่ใช่เชิงพาณิชย์) · แอปไม่ได้แจกจ่ายชุดข้อมูลนี้'**
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

  /// No description provided for @meituanAcknowledgement.
  ///
  /// In th, this message translates to:
  /// **'This research was supported by data provided by Meituan.'**
  String get meituanAcknowledgement;

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
