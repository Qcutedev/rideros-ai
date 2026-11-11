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
  String get navPickup => 'Pickup';

  @override
  String get pickupTitle => 'Pickup';

  @override
  String get pickupSearchHint => 'ค้นหาชื่อร้าน เช่น POI-12';

  @override
  String get pickupSearchLabel => 'ค้นหาร้าน';

  @override
  String get pickupSearchClear => 'ล้างคำค้นหา';

  @override
  String get pickupFilterAll => 'ทั้งหมด';

  @override
  String get pickupFilterDataset => 'Dataset';

  @override
  String get pickupFilterOwn => 'ร้านของฉัน';

  @override
  String get pickupDatasetNote =>
      'ร้าน Dataset (ชื่อ POI-…) มาจากข้อมูล Meituan ของเมืองหนึ่งในประเทศจีน ไม่ใช่ร้านในไทย · ร้านของฉันใช้บันทึกเวลารับจริงของคุณ';

  @override
  String get pickupHistory => 'ประวัติการทำนาย';

  @override
  String get pickupMyLogs => 'เวลารับของฉัน';

  @override
  String get pickupModelInfo => 'ข้อมูลโมเดล';

  @override
  String get pickupAddOwn => 'เพิ่มร้านของฉัน';

  @override
  String get pickupEmptyTitle => 'ไม่พบร้าน';

  @override
  String get pickupEmptyMessage =>
      'ลองคำค้นหาอื่น หรือเพิ่มร้านของคุณเองเพื่อบันทึกเวลารับ';

  @override
  String get badgeDataset => 'Dataset';

  @override
  String get badgeOwn => 'ร้านของฉัน';

  @override
  String get badgeEstimate => 'ค่าประมาณ';

  @override
  String get dataSufficient => 'ข้อมูลเพียงพอ';

  @override
  String get dataLimited => 'ข้อมูลจำกัด';

  @override
  String get dataInsufficient => 'ข้อมูลไม่เพียงพอ';

  @override
  String pickupOrdersInData(String count) {
    return '$count ออเดอร์ในข้อมูล';
  }

  @override
  String pickupMinutesRange(String low, String high) {
    return '$low–$high นาที';
  }

  @override
  String pickupMinutesValue(String value) {
    return '$value นาที';
  }

  @override
  String get restaurantTitle => 'รายละเอียดร้าน';

  @override
  String get restaurantPredictNow => 'ทำนาย Order-to-Pickup ตอนนี้';

  @override
  String get restaurantOwnNoPrediction =>
      'ร้านของฉันใช้บันทึกเวลารับเท่านั้น โมเดลทำนายได้เฉพาะร้านจากข้อมูลชุดฝึก (Dataset)';

  @override
  String restaurantLocation(String lat, String lng) {
    return 'ตำแหน่ง $lat, $lng (เห็นเฉพาะคุณ)';
  }

  @override
  String get restaurantStatsTitle => 'สถิติจากข้อมูลชุดฝึก';

  @override
  String get restaurantStatsHint =>
      'Order-to-Pickup = เวลาตั้งแต่ลูกค้าสั่งจนไรเดอร์รับอาหารที่ร้าน (ไม่ใช่เวลารอของไรเดอร์)';

  @override
  String get restaurantMedian => 'มัธยฐาน';

  @override
  String get restaurantP25P75 => 'ช่วงกลาง P25–P75';

  @override
  String get restaurantOrders => 'จำนวนออเดอร์';

  @override
  String get restaurantPeakHour => 'ชั่วโมงที่สั่งมากสุด';

  @override
  String restaurantHourValue(String hour) {
    return '$hour:00';
  }

  @override
  String get restaurantNoOverall =>
      'ร้านนี้มีออเดอร์ในข้อมูลน้อยเกินไป จึงไม่มีสถิติ';

  @override
  String get heatmapTitle => 'มัธยฐานรายชั่วโมง (นาที)';

  @override
  String get heatmapWeekday => 'วันธรรมดา';

  @override
  String get heatmapWeekend => 'เสาร์–อาทิตย์';

  @override
  String get heatmapLegend =>
      'ตัวเลขในช่อง = มัธยฐาน (นาที) · สียิ่งเข้มข้น = ยิ่งนาน · ช่องว่าง = ไม่มีข้อมูล · ชั่วโมงตามเวลาท้องถิ่นของเมืองในข้อมูล';

  @override
  String heatmapCell(String hour, String median, int count) {
    return '$hour:00 · มัธยฐาน $median นาที · $count ออเดอร์';
  }

  @override
  String heatmapCellEmpty(String hour) {
    return '$hour:00 · ไม่มีข้อมูล';
  }

  @override
  String get waitStatsTitle => 'เวลารอจริงของฉัน';

  @override
  String get waitStatsHint =>
      'จากบันทึกเวลารับของคุณเอง (รับอาหาร − ถึงร้าน) ไม่ผสมกับข้อมูลชุดฝึก';

  @override
  String get waitStatsMedian => 'มัธยฐาน';

  @override
  String get waitStatsP80 => 'P80 (80% รอไม่เกิน)';

  @override
  String waitStatsCount(int count) {
    return 'บันทึกแล้ว $count ครั้ง';
  }

  @override
  String waitStatsNeedMore(int count) {
    return 'บันทึกอีก $count ครั้งเพื่อดูสถิติ (ต้องมีอย่างน้อย 5 ครั้ง)';
  }

  @override
  String get confidenceLow => 'ความมั่นใจต่ำ (น้อยกว่า 20 ครั้ง)';

  @override
  String get confidenceOk => 'ความมั่นใจใช้ได้';

  @override
  String get restaurantLogPickup => 'บันทึกเวลารับที่ร้านนี้';

  @override
  String get predictionTitle => 'Order-to-Pickup โดยประมาณ';

  @override
  String get predictionLoading => 'กำลังทำนาย…';

  @override
  String predictionMidpoint(String value) {
    return 'ค่ากลางประมาณ $value นาที';
  }

  @override
  String predictionCoverage(String percent) {
    return 'ช่วงนี้ครอบคลุมราว $percent% ของออเดอร์ในข้อมูลทดสอบ';
  }

  @override
  String get predictionWarningForeign =>
      'ค่าประมาณจากข้อมูลต่างประเทศ (ร้านในจีน ต.ค. 2022) ร้านในไทยอาจต่างออกไป';

  @override
  String get predictionWarningLimited =>
      'ข้อมูลร้านนี้มีจำกัด ช่วงอาจคลาดเคลื่อนมากกว่าปกติ';

  @override
  String get predictionWarningInsufficient =>
      'ข้อมูลร้านนี้ไม่เพียงพอ ช่วงอาจคลาดเคลื่อนมาก';

  @override
  String predictionWarningOther(String code) {
    return 'มีคำเตือนจากระบบ: $code';
  }

  @override
  String get predictionDisclaimerTitle => 'ข้อควรทราบ';

  @override
  String get predictionDisclaimerThai =>
      'เป็นค่าประมาณเวลาตั้งแต่สั่งจนไรเดอร์รับอาหาร เรียนรู้จากข้อมูลของเมืองหนึ่งในจีน ไม่ใช่เวลาทำอาหารหรือเวลารอของคุณที่ร้าน';

  @override
  String get predictionServerText => 'ข้อความจากระบบ';

  @override
  String predictionMeta(String version, String time) {
    return 'โมเดล $version · ขอเมื่อ $time';
  }

  @override
  String get predictionAgain => 'ทำนายอีกครั้ง';

  @override
  String get historyEmptyTitle => 'ยังไม่มีประวัติการทำนาย';

  @override
  String get historyEmptyMessage =>
      'เลือกร้านจาก Dataset แล้วกด “ทำนาย Order-to-Pickup ตอนนี้”';

  @override
  String get historyFindRestaurant => 'ค้นหาร้าน';

  @override
  String get historyDeletedRestaurant => 'ร้านที่ถูกลบ';

  @override
  String get logsTitle => 'เวลารับของฉัน';

  @override
  String get logsAdd => 'บันทึกเวลารับ';

  @override
  String get logsEmptyTitle => 'ยังไม่มีบันทึกเวลารับ';

  @override
  String get logsEmptyMessage =>
      'บันทึกเวลาถึงร้านและเวลารับอาหาร เพื่อดูเวลารอจริงของแต่ละร้าน';

  @override
  String logsWait(String minutes) {
    return 'รอ $minutes นาที';
  }

  @override
  String get logsDelete => 'ลบบันทึกนี้';

  @override
  String get logsDeleteTitle => 'ลบบันทึกเวลารับ?';

  @override
  String get logsDeleteMessage =>
      'ลบแล้วกู้คืนไม่ได้ และเวลารอจริงของร้านนี้จะคำนวณใหม่';

  @override
  String get logFormTitle => 'บันทึกเวลารับ';

  @override
  String get logFormRestaurant => 'ร้าน';

  @override
  String get logFormChooseRestaurant => 'เลือกร้าน';

  @override
  String get logFormRestaurantRequired => 'กรุณาเลือกร้าน';

  @override
  String get logFormDate => 'วันที่ถึงร้าน';

  @override
  String get logFormArrived => 'เวลาถึงร้าน';

  @override
  String get logFormPickedUp => 'เวลารับอาหาร';

  @override
  String logFormWait(String wait) {
    return 'รอ $wait';
  }

  @override
  String get logFormNextDay => 'รับวันถัดไป';

  @override
  String get logFormWaitTooLong =>
      'เวลารับต้องหลังเวลาถึงร้าน และรอได้ไม่เกิน 3 ชั่วโมง';

  @override
  String get pickerTitle => 'เลือกร้าน';

  @override
  String get ownFormTitle => 'เพิ่มร้านของฉัน';

  @override
  String get ownFormName => 'ชื่อร้าน';

  @override
  String get ownFormLocationTitle => 'ตำแหน่ง (ไม่บังคับ · เห็นเฉพาะคุณ)';

  @override
  String get ownFormLat => 'ละติจูด (lat)';

  @override
  String get ownFormLng => 'ลองจิจูด (lng)';

  @override
  String get ownFormLocationHelper => 'กรอกทั้งสองช่อง หรือเว้นว่างทั้งสองช่อง';

  @override
  String get ownFormLocationPair => 'กรอกให้ครบทั้งละติจูดและลองจิจูด';

  @override
  String get ownFormSaved => 'เพิ่มร้านแล้ว';

  @override
  String validationRange(String min, String max) {
    return 'ต้องอยู่ระหว่าง $min ถึง $max';
  }

  @override
  String get modelTitle => 'ข้อมูลโมเดล Pickup';

  @override
  String get modelWhatTitle => 'สิ่งที่โมเดลทำนาย';

  @override
  String get modelWhatBody =>
      'Order-to-Pickup: นาทีตั้งแต่ลูกค้าสั่งอาหาร จนไรเดอร์รับอาหารที่ร้าน · ไม่ใช่เวลาทำอาหาร และไม่ใช่เวลารอของไรเดอร์ที่ร้าน · แสดงผลเป็นช่วงเสมอ';

  @override
  String modelVersion(String name, String version) {
    return '$name เวอร์ชัน $version';
  }

  @override
  String modelAlgorithm(String name) {
    return 'อัลกอริทึม $name';
  }

  @override
  String modelTrainedAt(String date) {
    return 'ฝึกเมื่อ $date';
  }

  @override
  String get modelTestTitle => 'ผลทดสอบ (วันทดสอบที่แยกไว้ ประเมินครั้งเดียว)';

  @override
  String get modelMae => 'MAE ของโมเดล';

  @override
  String get modelBaselineMae => 'MAE ของ Baseline';

  @override
  String get modelBaselineHint =>
      'Baseline = มัธยฐานเดิมของแต่ละร้าน · MAE = คลาดเคลื่อนเฉลี่ย ยิ่งน้อยยิ่งดี';

  @override
  String modelTestOrders(String count) {
    return 'ออเดอร์ทดสอบ $count';
  }

  @override
  String get modelCoverageTitle => 'ความครอบคลุมของช่วง';

  @override
  String get modelNominalCoverage => 'เป้าหมาย';

  @override
  String get modelTestCoverage => 'จริงในข้อมูลทดสอบ';

  @override
  String modelMeanWidth(String value) {
    return 'ช่วงกว้างเฉลี่ย $value นาที';
  }

  @override
  String get modelLimitationsTitle => 'ข้อจำกัด';

  @override
  String get modelLimitationsBody =>
      'ข้อมูลมาจากเมืองเดียวในจีนช่วง 16–24 ต.ค. 2022 จึงไม่ใช่ตัวแทนร้านในไทย · ร้านที่ไม่มีในข้อมูลฝึก ช่วงจะครอบคลุมได้น้อยกว่าเป้าหมาย';

  @override
  String get modelServerLimitations => 'รายละเอียดจากระบบ (ภาษาอังกฤษ)';

  @override
  String get modelSourceTitle => 'แหล่งข้อมูลและสัญญาอนุญาต';

  @override
  String get modelLicense =>
      'Meituan INFORMS TSL Research Challenge · สัญญาอนุญาต CC BY-NC 4.0 (ไม่ใช่เชิงพาณิชย์) · แอปไม่ได้แจกจ่ายชุดข้อมูลนี้';

  @override
  String get profileModelInfo => 'ข้อมูลโมเดล Pickup';

  @override
  String get failureModelUnavailable =>
      'โมเดล Pickup ยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง';

  @override
  String get failureRestaurantNotSupported =>
      'ร้านนี้ทำนายไม่ได้ (ทำนายได้เฉพาะร้านจากข้อมูลชุดฝึก)';

  @override
  String get failureInvalidPickupTimes => 'เวลารับอาหารต้องไม่ก่อนเวลาถึงร้าน';

  @override
  String get failurePickupWaitTooLong => 'เวลารอยาวได้ไม่เกิน 3 ชั่วโมง';

  @override
  String get navShifts => 'กะงาน';

  @override
  String get shiftsTitle => 'จำลองกะงาน';

  @override
  String get shiftsIntro =>
      'Scenario คือกะงานที่วางแผนไว้ ระบบประมาณรายได้ ค่าใช้จ่าย และกำไรให้ ทุกตัวเลขเป็นค่าประมาณและไม่นับรวมใน TrueProfit';

  @override
  String get shiftsSelectHint => 'เลือก 2–5 รายการเพื่อเปรียบเทียบ';

  @override
  String shiftsSelectedCount(int count) {
    return 'เลือกแล้ว $count รายการ';
  }

  @override
  String shiftsCompareCount(int count) {
    return 'เปรียบเทียบ ($count)';
  }

  @override
  String get shiftsClearSelection => 'ล้างที่เลือก';

  @override
  String shiftsSelect(String name) {
    return 'เลือก $name เพื่อเปรียบเทียบ';
  }

  @override
  String get shiftsMaxSelected => 'เลือกได้สูงสุด 5 รายการ';

  @override
  String get shiftsAdd => 'เพิ่ม Scenario';

  @override
  String get shiftsEmptyTitle => 'ยังไม่มี Scenario';

  @override
  String get shiftsEmptyMessage =>
      'สร้าง Scenario ของกะที่อยากลอง เช่น 17:00–22:00 วันศุกร์ แล้วดูกำไรประมาณก่อนออกวิ่งจริง เทียบกันได้ครั้งละ 2–5 แบบ';

  @override
  String get shiftAnyDay => 'ทุกวัน';

  @override
  String get shiftNetEstimate => 'กำไรสุทธิประมาณ';

  @override
  String get shiftPerHourEstimate => 'กำไรต่อชั่วโมงประมาณ';

  @override
  String shiftPerHourValue(String value) {
    return '$value/ชม.';
  }

  @override
  String get shiftMethodAssumption => 'จากสมมติฐาน';

  @override
  String get shiftMethodHistorical => 'จากประวัติของฉัน';

  @override
  String get shiftMethodUnavailable => 'วิธีที่ยังไม่เปิดใช้';

  @override
  String get shiftNewTitle => 'เพิ่ม Scenario';

  @override
  String get shiftEditTitle => 'แก้ไข Scenario';

  @override
  String get shiftFieldName => 'ชื่อ Scenario';

  @override
  String get shiftFieldNameHint => 'เช่น เย็นวันศุกร์';

  @override
  String get shiftFieldStart => 'เวลาเริ่ม';

  @override
  String get shiftFieldEnd => 'เวลาเลิก';

  @override
  String get shiftLengthInvalid => 'กะต้องยาว 30 นาที ถึง 16 ชั่วโมง';

  @override
  String get shiftFieldWeekday => 'วันในสัปดาห์';

  @override
  String get shiftWeekdayHelper =>
      'ไม่บังคับ · วิธีจากประวัติจะใช้เฉพาะวันที่เลือก ถ้ามีข้อมูลวันนั้นอย่างน้อย 5 วัน';

  @override
  String get shiftFieldMethod => 'วิธีประมาณ';

  @override
  String get shiftMethodAssumptionHint =>
      'คำนวณจากออเดอร์ต่อชั่วโมงและรายได้ต่อออเดอร์ที่คุณกรอก';

  @override
  String get shiftMethodHistoricalHint =>
      'ใช้รายได้และค่าใช้จ่ายต่อชั่วโมงจากข้อมูลจริงของคุณ 84 วันล่าสุด';

  @override
  String shiftHistoryUnavailable(int days) {
    return 'วิธีจากประวัติใช้ได้เมื่อมีวันที่มีชั่วโมงทำงานอย่างน้อย 5 วันใน 84 วันล่าสุด (ตอนนี้ $days วัน)';
  }

  @override
  String get shiftAssumptionsTitle => 'สมมติฐาน';

  @override
  String get shiftFieldOrdersPerHour => 'ออเดอร์ต่อชั่วโมง';

  @override
  String get shiftFieldIncomePerOrder => 'รายได้ต่อออเดอร์ (บาท)';

  @override
  String get shiftFieldKmPerOrder => 'ระยะทางต่อออเดอร์ (กม.)';

  @override
  String get shiftKmPerOrderHelper =>
      'ไม่บังคับ · เว้นว่าง = ไม่รวมค่าน้ำมันและค่าเสื่อม';

  @override
  String get shiftProfileFallbackHelper =>
      'ไม่บังคับ · เว้นว่าง = ใช้ค่าจากโปรไฟล์';

  @override
  String get shiftFieldOtherCosts => 'ค่าใช้จ่ายคงที่ของกะ (บาท)';

  @override
  String get shiftOtherCostsHelper => 'ไม่บังคับ · เช่น ที่จอดรถ ค่าข้าว';

  @override
  String get shiftFormEstimateNote => 'บันทึกแล้วระบบจะคำนวณค่าประมาณให้ทันที';

  @override
  String get shiftDetailTitle => 'รายละเอียด Scenario';

  @override
  String get shiftEstimatedRevenue => 'รายได้ประมาณ';

  @override
  String get shiftEstimatedExpenses => 'ค่าใช้จ่ายประมาณ';

  @override
  String get shiftRangeTitle => 'ช่วงกำไรสุทธิประมาณ';

  @override
  String shiftRangeValue(String low, String high) {
    return '$low ถึง $high';
  }

  @override
  String get shiftRangeHint =>
      'P20–P80 ของกำไรต่อชั่วโมงรายวันในประวัติ × ชั่วโมงของกะ';

  @override
  String get shiftBasisTitle => 'ที่มาของตัวเลข';

  @override
  String shiftBasisSameWeekday(String weekday, int days) {
    return 'ใช้เฉพาะ$weekday $days วัน';
  }

  @override
  String shiftBasisAllDays(int days) {
    return 'ใช้ทุกวันที่ทำงาน $days วัน';
  }

  @override
  String shiftBasisWindow(String from, String to) {
    return 'ข้อมูลช่วง $from – $to';
  }

  @override
  String get shiftHistoricalHours => 'ชั่วโมงทำงานในประวัติ';

  @override
  String get shiftRevenuePerHour => 'รายได้ต่อชั่วโมง';

  @override
  String get shiftExpensesPerHour => 'ค่าใช้จ่ายต่อชั่วโมง';

  @override
  String get shiftHistoricalNote =>
      'ใช้ค่าเฉลี่ยทั้งวัน ไม่ได้แยกตามช่วงเวลาของกะ';

  @override
  String get shiftShiftHours => 'ชั่วโมงของกะ';

  @override
  String shiftHoursValue(String hours) {
    return '$hours ชม.';
  }

  @override
  String get shiftExpectedOrders => 'ออเดอร์ที่คาด';

  @override
  String get shiftExpectedKm => 'ระยะทางที่คาด (กม.)';

  @override
  String get shiftFuelCost => 'ค่าน้ำมัน';

  @override
  String get shiftDepreciationCost => 'ค่าเสื่อม';

  @override
  String get shiftOtherCosts => 'ค่าใช้จ่ายคงที่';

  @override
  String get shiftSourceScenario => 'จาก Scenario';

  @override
  String get shiftSourceProfile => 'จากโปรไฟล์';

  @override
  String get shiftInputFromProfile => 'เว้นว่าง · ใช้ค่าจากโปรไฟล์';

  @override
  String get shiftInputsTitle => 'สมมติฐานที่กรอก';

  @override
  String get shiftNotSet => '—';

  @override
  String get shiftWarningDistance =>
      'ไม่รวมต้นทุนระยะทาง (ไม่ได้กรอกระยะทางต่อออเดอร์)';

  @override
  String get shiftWarningFuel =>
      'ไม่รวมค่าน้ำมัน (ไม่มีอัตราสิ้นเปลืองหรือราคาน้ำมันทั้งใน Scenario และโปรไฟล์)';

  @override
  String get shiftWarningDepreciation =>
      'ไม่รวมค่าเสื่อม (ไม่มีค่าเสื่อมต่อ กม. ทั้งใน Scenario และโปรไฟล์)';

  @override
  String get shiftWarningFewWeekdays =>
      'วันเดียวกันในสัปดาห์มีข้อมูลไม่ถึง 5 วัน จึงใช้ทุกวันแทน';

  @override
  String shiftWarningOther(String code) {
    return 'คำเตือนจากระบบ: $code';
  }

  @override
  String get shiftReEstimate => 'คำนวณใหม่ด้วยข้อมูลล่าสุด';

  @override
  String get shiftReEstimated => 'คำนวณใหม่แล้ว';

  @override
  String get shiftEdit => 'แก้ไข';

  @override
  String get shiftDelete => 'ลบ Scenario';

  @override
  String get shiftDeleteTitle => 'ลบ Scenario นี้?';

  @override
  String get shiftDeleteMessage =>
      'Scenario และค่าประมาณจะถูกลบ กู้คืนไม่ได้ (ไม่กระทบข้อมูลจริงใน TrueProfit)';

  @override
  String get shiftLinkTitle => 'ช่วงทำงานจริง';

  @override
  String get shiftLinkNone => 'ยังไม่ได้ผูกกับช่วงทำงานจริง';

  @override
  String get shiftLinkHint =>
      'ไม่บังคับ · ผูกไว้เพื่อจำว่ากะจริงตรงกับ Scenario ไหน ไม่เปลี่ยนค่าประมาณ';

  @override
  String get shiftLinkAction => 'ผูกกับช่วงทำงานจริง';

  @override
  String get shiftLinkChange => 'เปลี่ยนช่วงทำงาน';

  @override
  String get shiftUnlink => 'ยกเลิกการผูก';

  @override
  String get shiftLinked => 'ผูกกับช่วงทำงานแล้ว';

  @override
  String get shiftUnlinked => 'ยกเลิกการผูกแล้ว';

  @override
  String get shiftNotInTrueProfit =>
      'ค่าประมาณจาก Shift Simulator ไม่นับรวมใน TrueProfit';

  @override
  String shiftEstimatedAt(String date) {
    return 'คำนวณล่าสุด $date';
  }

  @override
  String get shiftPickSessionTitle => 'เลือกช่วงทำงาน';

  @override
  String get shiftPickSessionEmptyTitle => 'ยังไม่มีช่วงทำงาน';

  @override
  String get shiftPickSessionEmptyMessage =>
      'บันทึกช่วงทำงานจริงก่อน แล้วกลับมาผูกกับ Scenario';

  @override
  String get shiftCompareTitle => 'เปรียบเทียบ Scenario';

  @override
  String get shiftBestNet => 'กำไรสุทธิสูงสุด';

  @override
  String get shiftBestPerHour => 'กำไรต่อชั่วโมงสูงสุด';

  @override
  String get shiftCompareNote =>
      'ทุกตัวเลขเป็นค่าประมาณ ไม่นับรวมใน TrueProfit';

  @override
  String get failureInvalidShiftLength => 'กะต้องยาว 30 นาที ถึง 16 ชั่วโมง';

  @override
  String get failureMissingAssumption =>
      'วิธีจากสมมติฐานต้องมีออเดอร์ต่อชั่วโมงและรายได้ต่อออเดอร์';

  @override
  String get failureInsufficientHistory =>
      'ประวัติยังไม่พอ ต้องมีวันที่มีชั่วโมงทำงานอย่างน้อย 5 วันใน 84 วันล่าสุด';

  @override
  String get failureEstimationMethodUnavailable => 'วิธีประมาณนี้ยังไม่เปิดใช้';

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
