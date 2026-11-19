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
  String get appTagline =>
      'เข้าใจงานของตัวเอง วิเคราะห์รายได้ ตัดสินใจได้ดีขึ้น';

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
  String get homeHello => 'สวัสดี';

  @override
  String homeGreeting(String name) {
    return 'สวัสดี $name';
  }

  @override
  String get homeBannerMessage => 'ขับขี่ปลอดภัย\nวันนี้ก็สู้ ๆ นะ';

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
  String get homePlanTitle => 'วางแผนกะงาน';

  @override
  String get homeShiftCardTitle => 'Shift Simulator';

  @override
  String get homeShiftCardMessage => 'จำลองกะงาน ดูกำไรประมาณก่อนออกวิ่ง';

  @override
  String get goalSetTitle => 'ตั้งเป้ากำไรวันนี้';

  @override
  String get goalSetMessage => 'ดูว่าอีกเท่าไรจะถึงเป้า';

  @override
  String goalTarget(String amount) {
    return 'เป้าวันนี้ $amount';
  }

  @override
  String goalRemaining(String amount) {
    return 'อีก $amount ถึงเป้า';
  }

  @override
  String get goalReached => 'ถึงเป้าแล้ว!';

  @override
  String goalSurplus(String amount) {
    return 'เกินเป้า $amount';
  }

  @override
  String goalPercent(int percent) {
    return '$percent%';
  }

  @override
  String get goalEdit => 'แก้เป้า';

  @override
  String get goalSheetTitle => 'เป้ากำไรสุทธิต่อวัน';

  @override
  String get goalSheetMessage =>
      'นับจากกำไรสุทธิของวันนี้ (รายได้ − ค่าใช้จ่าย) ตามเขตเวลาในโปรไฟล์';

  @override
  String get goalField => 'เป้ากำไรสุทธิ';

  @override
  String get goalRemove => 'ลบเป้า';

  @override
  String get goalSaved => 'บันทึกเป้าแล้ว';

  @override
  String get goalRemoved => 'ลบเป้าแล้ว';

  @override
  String get riderProfileDailyGoalHelper =>
      'ไม่บังคับ · แสดงเป็นวงแหวนบนหน้าหลัก';

  @override
  String get timerIdleTitle => 'พร้อมออกวิ่งไหม?';

  @override
  String get timerIdleMessage =>
      'กดเริ่มตอนออกวิ่ง กดหยุดตอนเลิก แอปจะกรอกเวลาช่วงทำงานให้';

  @override
  String get timerStart => 'เริ่มงาน';

  @override
  String get timerRunningTitle => 'กำลังทำงาน';

  @override
  String timerStartedAt(String time) {
    return 'เริ่ม $time';
  }

  @override
  String timerElapsed(String duration) {
    return 'เวลาทำงาน $duration';
  }

  @override
  String get timerStop => 'หยุดและบันทึก';

  @override
  String get timerDiscard => 'ทิ้ง';

  @override
  String get timerStoppedTitle => 'หยุดแล้ว · ยังไม่ได้บันทึก';

  @override
  String timerStoppedRange(String duration, String start, String end) {
    return '$duration · $start–$end';
  }

  @override
  String get timerSave => 'บันทึกช่วงทำงาน';

  @override
  String get timerResume => 'ทำต่อ';

  @override
  String get timerDiscardTitle => 'ทิ้งเวลาที่จับไว้?';

  @override
  String get timerDiscardMessage =>
      'เวลานี้ยังไม่ได้บันทึก ทิ้งแล้วเอาคืนไม่ได้';

  @override
  String get timerTooShortTitle => 'ยังไม่ถึง 1 นาที';

  @override
  String get timerTooShortMessage =>
      'ช่วงทำงานต้องยาวอย่างน้อย 1 นาที จะทำต่อหรือทิ้ง?';

  @override
  String get timerTooLongTitle => 'ลืมกดหยุดหรือเปล่า?';

  @override
  String timerTooLongMessage(String duration) {
    return 'ตัวจับเวลาเดินมา $duration เกิน 24 ชม. ที่บันทึกได้ในช่วงเดียว ตรวจเวลาเลิกงานในหน้าถัดไป';
  }

  @override
  String get timerTooLongContinue => 'ไปแก้เวลา';

  @override
  String sessionTimerTooLong(String duration) {
    return 'ตัวจับเวลาเดินมา $duration · แก้เวลาเลิกงานให้ตรงจริง (ช่วงเดียวไม่เกิน 24 ชม.)';
  }

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
  String get profitTrendLegendNet => 'กำไรสุทธิ';

  @override
  String profitTrendLegendAverage(int count, String unit) {
    return 'ค่าเฉลี่ย $count $unit';
  }

  @override
  String get profitTrendLegendLine => 'เส้นแนวโน้ม';

  @override
  String profitTrendUp(String amount, String unit) {
    return 'แนวโน้มขาขึ้น: กำไรสุทธิเพิ่มขึ้นเฉลี่ย $amount ต่อ$unit';
  }

  @override
  String profitTrendDown(String amount, String unit) {
    return 'แนวโน้มขาลง: กำไรสุทธิลดลงเฉลี่ย $amount ต่อ$unit';
  }

  @override
  String get profitTrendFlat => 'ยังไม่เห็นแนวโน้มขึ้นหรือลงที่ชัดเจน';

  @override
  String profitTrendBasis(int count, String unit) {
    return 'คิดจาก $count $unitที่มีข้อมูล · ทดสอบทางสถิติแล้ว ไม่ใช่การพยากรณ์';
  }

  @override
  String profitTrendNeedMore(int need, int have, String unit) {
    return 'ต้องมีข้อมูลอย่างน้อย $need $unitจึงจะดูแนวโน้มได้ (ตอนนี้มี $have)';
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
  String get patternsTitle => 'รูปแบบการทำงาน';

  @override
  String patternsInsufficient(int missing) {
    return 'บันทึกช่วงทำงานอีก $missing ครั้ง เพื่อดูรูปแบบการทำงานของคุณ';
  }

  @override
  String patternsProgress(int have, int need, int days) {
    return '$have / $need ช่วงทำงานใน $days วันล่าสุด';
  }

  @override
  String patternsNoClear(int count, int days) {
    return 'ยังไม่เห็นรูปแบบชัดเจนจาก $count ช่วงทำงานใน $days วันล่าสุด เวลาทำงานยังกระจายจนแบ่งกลุ่มได้ไม่ชัดกว่าการสุ่ม';
  }

  @override
  String get patternsTimeMorning => 'เช้า';

  @override
  String get patternsTimeMidday => 'กลางวัน';

  @override
  String get patternsTimeEvening => 'เย็น';

  @override
  String get patternsTimeNight => 'ดึก';

  @override
  String get patternsLengthShort => 'สั้น';

  @override
  String get patternsLengthMedium => 'กลาง';

  @override
  String get patternsLengthLong => 'ยาว';

  @override
  String get patternsDayWeekday => 'วันธรรมดา';

  @override
  String get patternsDayWeekend => 'สุดสัปดาห์';

  @override
  String get patternsDayMixed => 'ทุกวัน';

  @override
  String patternsGroupName(
    String time,
    String length,
    String hours,
    String days,
  ) {
    return '$time · $length ~$hours ชม. · $days';
  }

  @override
  String patternsGroupDetail(String start, int count, int percent) {
    return 'เริ่มราว $start · $count ครั้ง ($percent%)';
  }

  @override
  String patternsPerHourBasis(int count) {
    return 'จาก $count ช่วงที่ผูกรายได้';
  }

  @override
  String get patternsNoLinkedIncome =>
      'ยังไม่มีรายได้ที่ผูกกับช่วงทำงานในกลุ่มนี้';

  @override
  String patternsNote(int days) {
    return 'จัดกลุ่มด้วย K-Means จากเวลาเริ่ม ความยาว และวันธรรมดา/สุดสัปดาห์ ของ $days วันล่าสุด · กำไร/ชม. เป็นค่าประมาณจากรายได้และค่าใช้จ่ายที่ผูกกับช่วงทำงานเท่านั้น';
  }

  @override
  String get profitHeatmapTitle => 'กำไรต่อชั่วโมงตามช่วงเวลา';

  @override
  String profitHeatmapInsufficient(int missing) {
    return 'บันทึกช่วงทำงานที่มีรายได้อีก $missing ครั้ง เพื่อดูว่าวันและเวลาไหนได้กำไรต่อชั่วโมงดีที่สุด';
  }

  @override
  String profitHeatmapProgress(int have, int need, int days) {
    return '$have / $need ช่วงทำงานที่มีรายได้ใน $days วันล่าสุด';
  }

  @override
  String get profitHeatmapTimerHint =>
      'กดปุ่มเริ่มงานที่หน้าหลักทุกครั้งที่ออกวิ่ง จะได้ช่วงทำงานพร้อมเวลาจริงโดยไม่ต้องกรอกเอง';

  @override
  String profitHeatmapUnpaidSessions(int count) {
    return 'มี $count ช่วงทำงานที่ยังไม่มีรายได้ จึงยังไม่นับ: ผูกรายได้กับช่วงทำงาน หรือบันทึกรายได้ในวันเดียวกัน';
  }

  @override
  String profitHeatmapGridLabel(int hours) {
    return 'ตารางกำไรสุทธิต่อชั่วโมง 7 วัน ช่วงละ $hours ชั่วโมง';
  }

  @override
  String get profitHeatmapTapHint => 'แตะช่องเพื่อดูรายละเอียด';

  @override
  String profitHeatmapPerHour(String amount) {
    return '$amount/ชม.';
  }

  @override
  String profitHeatmapCellDetail(String revenue, String hours, int count) {
    return 'รายได้ $revenue/ชม. · $hours ชม. จาก $count ช่วงทำงาน';
  }

  @override
  String profitHeatmapCellThin(
    int count,
    String hours,
    int minSessions,
    int minHours,
  ) {
    return 'ข้อมูลน้อย: $count ช่วง $hours ชม. (ต้องมีอย่างน้อย $minSessions ช่วง และ $minHours ชม.)';
  }

  @override
  String get profitHeatmapCellEmpty => 'ยังไม่มีช่วงทำงานในช่วงนี้';

  @override
  String profitHeatmapCellSemantics(String day, String range, String detail) {
    return '$day $range: $detail';
  }

  @override
  String profitHeatmapRank(int rank) {
    return 'อันดับ $rank';
  }

  @override
  String get profitHeatmapLegendLow => 'ต่ำ';

  @override
  String get profitHeatmapLegendHigh => 'สูง';

  @override
  String profitHeatmapLegendRange(String low, String high) {
    return '$low – $high ต่อชม.';
  }

  @override
  String get profitHeatmapLegendLoss => 'ขาดทุน/เท่าทุน';

  @override
  String get profitHeatmapLegendThin => 'ข้อมูลน้อย';

  @override
  String get profitHeatmapBestTitle => 'ช่วงที่ได้ดีที่สุด';

  @override
  String profitHeatmapBestNone(int minSessions) {
    return 'ยังไม่มีช่วงที่ข้อมูลพอ ทำงานช่วงเวลาเดิมซ้ำอย่างน้อย $minSessions ครั้ง แล้วช่องนั้นจะแสดงกำไร/ชม.';
  }

  @override
  String profitHeatmapAverage(String amount) {
    return 'เฉลี่ยทุกช่วง $amount/ชม.';
  }

  @override
  String profitHeatmapNote(int count, int days) {
    return 'ค่าประมาณจาก $count ช่วงทำงานใน $days วันล่าสุด · รายได้และค่าใช้จ่ายเฉลี่ยเท่ากันตลอดช่วงทำงาน · รายการที่ไม่ได้ผูกช่วงทำงานแบ่งตามชั่วโมงของช่วงทำงานในวันเดียวกัน';
  }

  @override
  String profitHeatmapExcluded(int income, int expenses, int sessions) {
    return 'ไม่ได้นับ: รายได้ $income รายการ · ค่าใช้จ่าย $expenses รายการ · ช่วงทำงานที่ไม่มีรายได้ $sessions ช่วง';
  }

  @override
  String get recordsTitle => 'รายการทั้งหมด';

  @override
  String get recordsLoadMore => 'โหลดเพิ่ม';

  @override
  String get recordsEnd => 'แสดงครบทุกรายการแล้ว';

  @override
  String get recordSave => 'บันทึก';

  @override
  String get recordSkip => 'ข้ามไปก่อน';

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
  String incomeForSession(String range) {
    return 'บันทึกช่วงทำงาน $range แล้ว ใส่รายได้ของช่วงนี้ต่อได้เลย หรือข้ามไปก่อนแล้วค่อยใส่ทีหลัง';
  }

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
      'แอปส่งอาหารช่วยคุณรับงานและส่งอาหาร RiderOS ช่วยให้คุณเข้าใจการทำงานของตัวเอง วิเคราะห์รายได้ และตัดสินใจได้ดีขึ้น ตัวเลขทั้งหมดมาจากรายการที่คุณบันทึกเอง แอปไม่ได้เชื่อมต่อแพลตฟอร์มส่งอาหารใด';

  @override
  String get aboutDataTitle => 'การวิเคราะห์มาจากข้อมูลของคุณเท่านั้น';

  @override
  String get aboutDataBody =>
      'Heatmap กำไร/ชม., รูปแบบการทำงาน (K-Means), แนวโน้มรายได้ และ Shift Simulator แบบ \"จากประวัติ\" คำนวณจากรายได้ รายจ่าย และช่วงทำงานที่คุณบันทึก ไม่ใช้ชุดข้อมูลจากภายนอก ยิ่งบันทึกครบ ผลยิ่งตรงกับงานของคุณ';

  @override
  String get aboutFontTitle => 'ฟอนต์';

  @override
  String get aboutFontBody => 'IBM Plex Sans Thai · SIL Open Font License 1.1';

  @override
  String get aboutLicenses => 'สัญญาอนุญาตโอเพนซอร์สทั้งหมด';

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
  String get badgeEstimate => 'ค่าประมาณ';

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
