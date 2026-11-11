// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'RiderOS AI';

  @override
  String get appTagline => 'ผู้ช่วยวางแผนงานและกำไรสำหรับไรเดอร์';

  @override
  String get commonRetry => 'ลองใหม่';

  @override
  String get commonLoading => 'กำลังโหลด…';

  @override
  String get commonOptional => 'ไม่บังคับ';

  @override
  String get fieldEmail => 'อีเมล';

  @override
  String get fieldPassword => 'รหัสผ่าน';

  @override
  String get fieldConfirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get fieldNewPassword => 'รหัสผ่านใหม่';

  @override
  String get fieldDisplayName => 'ชื่อที่แสดง';

  @override
  String get showPassword => 'แสดงรหัสผ่าน';

  @override
  String get hidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get validationRequired => 'กรุณากรอกข้อมูลนี้';

  @override
  String get validationEmailInvalid => 'รูปแบบอีเมลไม่ถูกต้อง';

  @override
  String get validationEmailTooLong => 'อีเมลยาวเกินไป';

  @override
  String validationPasswordTooShort(int min) {
    return 'รหัสผ่านต้องมีอย่างน้อย $min ตัวอักษร';
  }

  @override
  String validationPasswordTooLong(int max) {
    return 'รหัสผ่านต้องไม่เกิน $max ตัวอักษร';
  }

  @override
  String get validationPasswordSameAsEmail =>
      'รหัสผ่านต้องไม่เหมือนชื่อหน้า @ ของอีเมล';

  @override
  String get validationPasswordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String validationDisplayNameTooLong(int max) {
    return 'ชื่อต้องไม่เกิน $max ตัวอักษร';
  }

  @override
  String get validationNumberInvalid => 'กรุณากรอกตัวเลข';

  @override
  String get validationNumberMustBePositive => 'ต้องมากกว่า 0';

  @override
  String get validationNumberMustNotBeNegative => 'ต้องไม่ติดลบ';

  @override
  String validationNumberTooManyDecimals(int places) {
    return 'ทศนิยมได้ไม่เกิน $places ตำแหน่ง';
  }

  @override
  String validationNumberTooLarge(String max) {
    return 'ต้องไม่เกิน $max';
  }

  @override
  String get validationResetTokenInvalid => 'ลิงก์หรือรหัสรีเซ็ตไม่ถูกต้อง';

  @override
  String get loginTitle => 'เข้าสู่ระบบ';

  @override
  String get loginSubmit => 'เข้าสู่ระบบ';

  @override
  String get loginForgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get loginNoAccount => 'ยังไม่มีบัญชี?';

  @override
  String get loginGoRegister => 'สมัครสมาชิก';

  @override
  String get loginSessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get loginRegisteredPleaseLogin => 'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ';

  @override
  String get loginPasswordResetDone =>
      'ตั้งรหัสผ่านใหม่แล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่';

  @override
  String get registerTitle => 'สมัครสมาชิก';

  @override
  String get registerSubmit => 'สร้างบัญชี';

  @override
  String get registerHaveAccount => 'มีบัญชีแล้ว?';

  @override
  String get registerGoLogin => 'เข้าสู่ระบบ';

  @override
  String get registerPasswordHelper =>
      'อย่างน้อย 8 ตัวอักษร และไม่ใช่รหัสผ่านที่พบบ่อย';

  @override
  String get forgotTitle => 'ลืมรหัสผ่าน';

  @override
  String get forgotDescription =>
      'กรอกอีเมลที่ใช้สมัคร เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้';

  @override
  String get forgotSubmit => 'ส่งลิงก์รีเซ็ตรหัสผ่าน';

  @override
  String get forgotSentTitle => 'ตรวจสอบอีเมลของคุณ';

  @override
  String get forgotSentMessage =>
      'ถ้ามีบัญชีนี้ เราได้ส่งลิงก์ไปแล้ว ลิงก์ใช้ได้ครั้งเดียวและมีอายุ 30 นาที';

  @override
  String get forgotDevNote =>
      'DEV ONLY: ยังไม่มีระบบส่งอีเมล ลิงก์รีเซ็ตแสดงใน Log ของ Backend';

  @override
  String get forgotHaveToken => 'มีลิงก์/รหัสแล้ว';

  @override
  String get forgotBackToLogin => 'กลับไปหน้าเข้าสู่ระบบ';

  @override
  String get resetTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String get resetDescription =>
      'วางลิงก์รีเซ็ต (หรือเฉพาะรหัสหลัง token=) แล้วตั้งรหัสผ่านใหม่ การตั้งรหัสใหม่จะออกจากระบบทุกเครื่อง';

  @override
  String get resetTokenField => 'ลิงก์หรือรหัสรีเซ็ต';

  @override
  String get resetSubmit => 'ตั้งรหัสผ่านใหม่';

  @override
  String get splashRestoreFailedTitle => 'เชื่อมต่อไม่สำเร็จ';

  @override
  String get onboardingTitle => 'ตั้งค่าการขับขี่';

  @override
  String get onboardingDescription =>
      'ใช้ข้อมูลนี้คำนวณต้นทุนต่อกิโลเมตร (ค่าน้ำมันและค่าเสื่อม) กรอกเฉพาะค่าที่รู้ เว้นว่างได้';

  @override
  String get onboardingVehicleType => 'ประเภทยานพาหนะ';

  @override
  String get onboardingFuelKmPerLiter => 'อัตราสิ้นเปลือง (กม./ลิตร)';

  @override
  String get onboardingFuelPricePerLiter => 'ราคาน้ำมัน (บาท/ลิตร)';

  @override
  String get onboardingDepreciationPerKm => 'ค่าเสื่อม (บาท/กม.)';

  @override
  String onboardingRegion(String zone) {
    return 'เขตเวลา $zone · สกุลเงิน THB';
  }

  @override
  String get onboardingSubmit => 'บันทึกและเริ่มใช้งาน';

  @override
  String get onboardingSkip => 'ข้ามไปก่อน';

  @override
  String get vehicleNotSpecified => 'ไม่ระบุ';

  @override
  String get vehicleMotorcycle => 'มอเตอร์ไซค์';

  @override
  String get vehicleEvMotorcycle => 'มอเตอร์ไซค์ไฟฟ้า';

  @override
  String get vehicleBicycle => 'จักรยาน';

  @override
  String get vehicleCar => 'รถยนต์';

  @override
  String get vehicleOther => 'อื่นๆ';

  @override
  String homeGreeting(String name) {
    return 'สวัสดี $name';
  }

  @override
  String homeSignedInAs(String email) {
    return 'เข้าสู่ระบบด้วย $email';
  }

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get demoLabel => 'DEMO';

  @override
  String get validationWholeNumber => 'กรุณากรอกจำนวนเต็ม';

  @override
  String validationNumberTooSmall(String min) {
    return 'ต้องไม่น้อยกว่า $min';
  }

  @override
  String validationTextTooLong(int max) {
    return 'ยาวได้ไม่เกิน $max ตัวอักษร';
  }

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navProfit => 'กำไร';

  @override
  String homeToday(String date) {
    return 'วันนี้ · $date';
  }

  @override
  String homeThisWeek(String range) {
    return 'สัปดาห์นี้ · $range';
  }

  @override
  String get homeEmptyTitle => 'ยังไม่มีรายการในวันนี้และสัปดาห์นี้';

  @override
  String get homeEmptyMessage =>
      'เริ่มบันทึกรายได้ ค่าใช้จ่าย หรือช่วงทำงาน แล้วกำไรจริงจะแสดงที่นี่';

  @override
  String get homeQuickActions => 'บันทึกด่วน';

  @override
  String get homeOpenProfit => 'ดูกำไรทั้งหมด (TrueProfit)';

  @override
  String get trueProfitTitle => 'TrueProfit';

  @override
  String get periodDay => 'วัน';

  @override
  String get periodWeek => 'สัปดาห์';

  @override
  String get periodMonth => 'เดือน';

  @override
  String get profitPreviousPeriod => 'ช่วงก่อนหน้า';

  @override
  String get profitNextPeriod => 'ช่วงถัดไป';

  @override
  String get profitCurrentPeriod => 'ช่วงปัจจุบัน';

  @override
  String get profitBackToCurrent => 'กลับช่วงปัจจุบัน';

  @override
  String get profitSummaryTitle => 'สรุปกำไรจริง';

  @override
  String get profitEmptyPeriod => 'ยังไม่มีรายการในช่วงนี้';

  @override
  String profitTrendTitle(String period) {
    return 'แนวโน้มกำไรสุทธิรายช่วง ($period)';
  }

  @override
  String get profitTrendEmpty => 'ยังไม่มีข้อมูลในช่วงที่แสดงกราฟ';

  @override
  String profitTrendSemantics(int count) {
    return 'กราฟแท่งกำไรสุทธิ $count ช่วง';
  }

  @override
  String profitActualOnlyNote(String zone) {
    return 'ตัวเลขทั้งหมดคำนวณโดยเซิร์ฟเวอร์จากรายการที่คุณบันทึกจริงเท่านั้น (ไม่รวมค่าประมาณจาก Shift Simulator) · สัปดาห์เริ่มวันจันทร์ · เขตเวลา $zone';
  }

  @override
  String get profitNet => 'กำไรสุทธิ';

  @override
  String get profitRevenue => 'รายได้';

  @override
  String get profitExpenses => 'ค่าใช้จ่าย';

  @override
  String get profitWorkingHours => 'ชั่วโมงทำงาน';

  @override
  String profitHoursValue(String hours) {
    return '$hours ชม.';
  }

  @override
  String get profitNetPerHour => 'กำไรสุทธิ/ชม.';

  @override
  String get profitRevenuePerHour => 'รายได้/ชม.';

  @override
  String get profitRecordCounts => 'รายการ (ได้/จ่าย/กะ)';

  @override
  String profitRecordCountsValue(int income, int expense, int sessions) {
    return '$income / $expense / $sessions';
  }

  @override
  String get profitNotAvailable => '—';

  @override
  String get profitNoWorkingHours =>
      'ยังไม่มีชั่วโมงทำงาน จึงยังคำนวณค่าต่อชั่วโมงไม่ได้ (บันทึกช่วงทำงาน หรือกรอกชั่วโมงในรายได้)';

  @override
  String get recordsTitle => 'รายการทั้งหมด';

  @override
  String get recordsLoadMore => 'โหลดเพิ่ม';

  @override
  String get recordsEnd => 'แสดงครบทุกรายการแล้ว';

  @override
  String get recordSave => 'บันทึก';

  @override
  String get recordSaved => 'บันทึกแล้ว';

  @override
  String get recordDelete => 'ลบ';

  @override
  String get recordDeleted => 'ลบแล้ว';

  @override
  String get recordDeleteTitle => 'ลบรายการนี้?';

  @override
  String get recordDeleteMessage =>
      'ลบแล้วกู้คืนไม่ได้ และตัวเลขกำไรจะคำนวณใหม่';

  @override
  String get fieldDate => 'วันที่';

  @override
  String get fieldAmount => 'จำนวนเงิน';

  @override
  String get fieldWorkingHours => 'ชั่วโมงทำงาน';

  @override
  String get fieldOrderCount => 'จำนวนออเดอร์';

  @override
  String get fieldDistanceKm => 'ระยะทาง (กม.)';

  @override
  String get fieldNotes => 'หมายเหตุ';

  @override
  String ordersValue(int count) {
    return '$count ออเดอร์';
  }

  @override
  String distanceValue(String km) {
    return '$km กม.';
  }

  @override
  String durationHours(int hours) {
    return '$hours ชม.';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ชม. $minutes นาที';
  }

  @override
  String get incomeTitle => 'รายได้';

  @override
  String get incomeAdd => 'เพิ่มรายได้';

  @override
  String get incomeEditTitle => 'แก้ไขรายได้';

  @override
  String get incomeEmptyTitle => 'ยังไม่มีรายได้';

  @override
  String get incomeEmptyMessage =>
      'บันทึกรายได้แต่ละวันหรือแต่ละกะ เพื่อคำนวณกำไรจริง';

  @override
  String get incomeSourceLabel => 'แหล่งรายได้';

  @override
  String get incomeSourceHelper =>
      'ไม่บังคับ · พิมพ์เอง เช่น ชื่อแพลตฟอร์ม (แอปไม่ได้เชื่อมต่อแพลตฟอร์มใด)';

  @override
  String get incomeSessionLabel => 'ผูกกับช่วงทำงาน';

  @override
  String get incomeSessionHelper =>
      'ไม่บังคับ · เลือกช่วงทำงานที่เริ่มในวันที่นี้ ชั่วโมงจะนับจากช่วงทำงานนั้น';

  @override
  String get incomeSessionNone => 'ไม่ผูก';

  @override
  String get incomeSessionOtherDay => 'ช่วงทำงานที่ผูกไว้ (วันอื่น)';

  @override
  String get incomeSessionLoadFailed => 'โหลดช่วงทำงานไม่ได้';

  @override
  String get incomeHoursHelper =>
      'ไม่บังคับ · ไม่ต้องกรอกถ้าบันทึกเวลาไว้ในช่วงทำงานแล้ว (กันชั่วโมงซ้ำ)';

  @override
  String get expenseTitle => 'ค่าใช้จ่าย';

  @override
  String get expenseAdd => 'เพิ่มค่าใช้จ่าย';

  @override
  String get expenseEditTitle => 'แก้ไขค่าใช้จ่าย';

  @override
  String get expenseEmptyTitle => 'ยังไม่มีค่าใช้จ่าย';

  @override
  String get expenseEmptyMessage =>
      'บันทึกค่าน้ำมัน ค่าซ่อมบำรุง ค่าเสื่อม และอื่นๆ';

  @override
  String get expenseCategoryLabel => 'หมวดหมู่';

  @override
  String get expenseCategoryFuel => 'น้ำมัน/ชาร์จไฟ';

  @override
  String get expenseCategoryMaintenance => 'ซ่อมบำรุง';

  @override
  String get expenseCategoryDepreciation => 'ค่าเสื่อมราคา';

  @override
  String get expenseCategoryOther => 'อื่นๆ';

  @override
  String get expenseDescriptionLabel => 'รายละเอียด';

  @override
  String get sessionTitle => 'ช่วงทำงาน';

  @override
  String get sessionAdd => 'บันทึกช่วงทำงาน';

  @override
  String get sessionEditTitle => 'แก้ไขช่วงทำงาน';

  @override
  String get sessionEmptyTitle => 'ยังไม่มีช่วงทำงาน';

  @override
  String get sessionEmptyMessage =>
      'บันทึกเวลาเริ่ม–เลิกงาน เพื่อคำนวณกำไรต่อชั่วโมง';

  @override
  String get sessionStartDate => 'วันที่เริ่ม';

  @override
  String get sessionStartTime => 'เวลาเริ่ม';

  @override
  String get sessionEndTime => 'เวลาเลิก';

  @override
  String sessionDuration(String duration) {
    return 'รวม $duration';
  }

  @override
  String get sessionCrossesMidnight => 'เลิกวันถัดไป';

  @override
  String sessionEndsNextDay(String time) {
    return '$time (วันถัดไป)';
  }

  @override
  String get sessionTimesEqual => 'เวลาเริ่มและเวลาเลิกต้องไม่ตรงกัน';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get profileTitle => 'โปรไฟล์';

  @override
  String profileMemberSince(String date) {
    return 'สมัครเมื่อ $date';
  }

  @override
  String get profileAccountSection => 'บัญชี';

  @override
  String get profileEditName => 'แก้ไขชื่อที่แสดง';

  @override
  String get profileEmailHelper => 'ใช้เข้าสู่ระบบ · ยังเปลี่ยนอีเมลไม่ได้';

  @override
  String get profileVehicleSection => 'ยานพาหนะและต้นทุน';

  @override
  String get profileVehicleTile => 'ประเภทรถ ค่าน้ำมัน และค่าเสื่อม';

  @override
  String get profileVehicleNotConfigured =>
      'ยังไม่ได้กรอกข้อมูล แตะเพื่อตั้งค่า';

  @override
  String profileFuelEconomyValue(String km) {
    return '$km กม./ลิตร';
  }

  @override
  String profileFuelPriceValue(String price) {
    return 'น้ำมัน $price/ลิตร';
  }

  @override
  String profileDepreciationValue(String price) {
    return 'ค่าเสื่อม $price/กม.';
  }

  @override
  String get profileRegionSection => 'เขตเวลาและสกุลเงิน';

  @override
  String get profileTimezone => 'เขตเวลา';

  @override
  String get profileCurrency => 'สกุลเงิน';

  @override
  String get profileInfoSection => 'ข้อมูลและสัญญาอนุญาต';

  @override
  String get profileAbout => 'เกี่ยวกับแอปและสัญญาอนุญาต';

  @override
  String get profileDeleteAccount => 'ลบบัญชี';

  @override
  String get riderProfileTitle => 'ยานพาหนะและต้นทุน';

  @override
  String get riderProfileTimezoneHelper =>
      'ชื่อเขตเวลาแบบ IANA เช่น Asia/Bangkok · ใช้แบ่งวันและสัปดาห์ในสรุปกำไร';

  @override
  String riderProfileCurrency(String currency) {
    return 'สกุลเงิน $currency (ตอนนี้รองรับสกุลเดียว)';
  }

  @override
  String get deleteAccountTitle => 'ลบบัญชี';

  @override
  String get deleteAccountWarning =>
      'บัญชีและข้อมูลทั้งหมดของคุณจะถูกลบถาวรทันที ได้แก่ รายได้ ค่าใช้จ่าย ช่วงทำงาน โปรไฟล์ไรเดอร์ ร้านของฉัน บันทึกเวลารับ ประวัติการทำนาย และ Scenario กะงาน';

  @override
  String get deleteAccountIrreversible =>
      'ลบแล้วกู้คืนไม่ได้ ถ้าต้องการใช้งานอีกต้องสมัครใหม่และเริ่มบันทึกใหม่ทั้งหมด';

  @override
  String get deleteAccountPasswordHelper =>
      'กรอกรหัสผ่านปัจจุบันเพื่อยืนยันว่าเป็นเจ้าของบัญชี';

  @override
  String get deleteAccountSubmit => 'ลบบัญชีถาวร';

  @override
  String get deleteAccountConfirmTitle => 'ลบบัญชีถาวร?';

  @override
  String get deleteAccountConfirmMessage =>
      'ข้อมูลทั้งหมดจะถูกลบทันทีและกู้คืนไม่ได้';

  @override
  String get loginAccountDeleted => 'ลบบัญชีและข้อมูลทั้งหมดแล้ว';

  @override
  String get aboutTitle => 'เกี่ยวกับแอป';

  @override
  String get aboutDescription =>
      'ผู้ช่วยไรเดอร์ส่งอาหาร: บันทึกกำไรจริง ประมาณเวลา Order-to-Pickup และวางแผนกะงาน ตัวเลขกำไรมาจากรายการที่คุณบันทึกเอง แอปไม่ได้เชื่อมต่อแพลตฟอร์มส่งอาหารใด';

  @override
  String get aboutDataTitle => 'ข้อมูลที่ใช้ฝึกโมเดล Pickup';

  @override
  String get aboutDataBody =>
      'Meituan INFORMS TSL Research Challenge (ข้อมูลการส่งอาหารในประเทศจีน) · สัญญาอนุญาต CC BY-NC 4.0 (ใช้เพื่อการวิจัย/ไม่ใช่เชิงพาณิชย์) · แอปไม่ได้แจกจ่ายชุดข้อมูลนี้';

  @override
  String get aboutFontTitle => 'ฟอนต์';

  @override
  String get aboutFontBody => 'IBM Plex Sans Thai · SIL Open Font License 1.1';

  @override
  String get aboutLicenses => 'สัญญาอนุญาตโอเพนซอร์สทั้งหมด';

  @override
  String get meituanAcknowledgement =>
      'This research was supported by data provided by Meituan.';

  @override
  String get failureInvalidPassword => 'รหัสผ่านไม่ถูกต้อง';

  @override
  String get failureNotFound => 'ไม่พบรายการนี้ (อาจถูกลบไปแล้ว)';

  @override
  String get failureWorkSessionOverlap =>
      'ช่วงเวลานี้ซ้อนกับช่วงทำงานที่บันทึกไว้แล้ว';

  @override
  String get failureInvalidTimeRange => 'เวลาเลิกต้องอยู่หลังเวลาเริ่ม';

  @override
  String get failureWorkSessionTooLong => 'ช่วงทำงานยาวได้ไม่เกิน 24 ชั่วโมง';

  @override
  String get failureInvalidWorkSession =>
      'ไม่พบช่วงทำงานที่เลือก (อาจถูกลบไปแล้ว)';

  @override
  String get failureNetwork =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';

  @override
  String get failureTimeout => 'เซิร์ฟเวอร์ตอบช้าเกินไป กรุณาลองใหม่';

  @override
  String get failureSessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String failureRateLimited(int seconds) {
    return 'ลองบ่อยเกินไป กรุณารอ $seconds วินาทีแล้วลองใหม่';
  }

  @override
  String get failureRateLimitedNoTime =>
      'ลองบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';

  @override
  String get failureInvalidCredentials => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get failureEmailTaken => 'อีเมลนี้ถูกใช้สมัครแล้ว';

  @override
  String get failureWeakPassword =>
      'รหัสผ่านนี้ไม่ปลอดภัย (สั้นเกินไป พบบ่อยเกินไป หรือเหมือนชื่ออีเมล)';

  @override
  String get failureInvalidResetToken =>
      'ลิงก์รีเซ็ตไม่ถูกต้อง หมดอายุ หรือถูกใช้ไปแล้ว กรุณาขอลิงก์ใหม่';

  @override
  String get failurePasswordResetUnavailable =>
      'ระบบรีเซ็ตรหัสผ่านยังไม่เปิดให้บริการ';

  @override
  String get failureInvalidTimezone => 'เขตเวลาไม่ถูกต้อง';

  @override
  String get failureValidation =>
      'ข้อมูลบางช่องไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';

  @override
  String get failureServer => 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง';

  @override
  String get failureUnknown => 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่';
}
