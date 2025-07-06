import 'package:flutter/widgets.dart';

abstract class Textstyle {
  TextStyle get titleSmBold;
  TextStyle get titleLgBold;
  TextStyle get titleMdMedium;
  TextStyle get bodyLgBold;
  TextStyle get bodyMdMedium;
  TextStyle get bodyLgMedium;
}

class SmallTextStyle extends Textstyle {
  @override
  TextStyle get titleSmBold =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  @override
  TextStyle get titleLgBold =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w700);

  @override
  TextStyle get titleMdMedium =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgBold =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w400);

  @override
  TextStyle get bodyMdMedium =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgMedium => const TextStyle(
    fontSize: 16, // Adjust size as needed
    fontWeight: FontWeight.w500, // Medium weight
  );
}

class LargeTextStyle extends Textstyle {
  @override
  TextStyle get titleSmBold =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

  @override
  TextStyle get titleLgBold =>
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

  @override
  TextStyle get titleMdMedium =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgBold =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w400);

  @override
  TextStyle get bodyMdMedium =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgMedium =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w500);
}

class MediumTextStyle implements Textstyle {
  @override
  TextStyle get titleSmBold =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  TextStyle get titleLgBold =>
      const TextStyle(fontSize: 26, fontWeight: FontWeight.w700);

  @override
  TextStyle get titleMdMedium =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgBold =>
      const TextStyle(fontSize: 19, fontWeight: FontWeight.w400);

  @override
  TextStyle get bodyMdMedium =>
      const TextStyle(fontSize: 17, fontWeight: FontWeight.w500);

  @override
  TextStyle get bodyLgMedium =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
}
