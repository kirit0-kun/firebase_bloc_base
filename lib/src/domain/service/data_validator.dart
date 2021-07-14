class BaseDataValidator {
  static const kPhoneRegex =
      r'''\+?(9[976]\d|8[987530]\d|6[987]\d|5[90]\d|42\d|3[875]\d|2[98654321]\d|9[8543210]|8[6421]|6[6543210]|5[87654321]|4[987654310]|3[9643210]|2[70]|7|1)\d{1,14}$''';
  static const kEmailRegex =
      r'''(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''';
  static const kPasswordRegex =
      r'''^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&-+=()])(?=\\S+$).{8, 20}$'''; // r'.{8,}';
  static const kNameRegex = r'.{1,}';
  static const kPersonNameRegex = r'(.+\s){2,}';

  String get emailRegex => kEmailRegex;
  String get phoneRegex => kPhoneRegex;
  String get passwordRegex => kPasswordRegex;
  String get nameRegex => kNameRegex;
  String get personRegex => kPersonNameRegex;

  bool isEmailValid(String? email) {
    return match(email, emailRegex, caseSensitive: false);
  }

  bool isPasswordValid(String? password) {
    return match(password, passwordRegex);
  }

  bool isNameValid(String? name) {
    return match(name, nameRegex);
  }

  bool isPhoneNumberValid(String? phoneNumber) {
    return match(phoneNumber, phoneRegex);
  }

  bool isPersonNameValid(String? name) {
    return match(name, personRegex);
  }

  bool match(String? input, String regex,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool unicode = false,
      bool dotAll = false}) {
    if (input?.isNotEmpty != true) {
      return false;
    }
    return RegExp(regex,
            caseSensitive: caseSensitive,
            dotAll: dotAll,
            multiLine: multiLine,
            unicode: unicode)
        .hasMatch(input!);
  }
}
