// card_payment_form.dart - Native card payment form
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardPaymentForm extends StatefulWidget {
  final Function(Map<String, String>) onPaymentSubmit;
  final bool isLoading;

  const CardPaymentForm({
    Key? key,
    required this.onPaymentSubmit,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  // Color scheme
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkCharcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFCCCCCC);
  static const Color errorRed = Color(0xFFFF5252);

  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  String _cardType = 'unknown';
  bool _isCardNumberValid = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _detectCardType(String number) {
    final cleanNumber = number.replaceAll(' ', '');
    
    if (cleanNumber.isEmpty) return 'unknown';
    
    // Visa
    if (RegExp(r'^4').hasMatch(cleanNumber)) return 'visa';
    
    // Mastercard
    if (RegExp(r'^5[1-5]|^2[2-7]').hasMatch(cleanNumber)) return 'mastercard';
    
    // American Express
    if (RegExp(r'^3[47]').hasMatch(cleanNumber)) return 'amex';
    
    // Discover
    if (RegExp(r'^6(?:011|5)').hasMatch(cleanNumber)) return 'discover';
    
    return 'unknown';
  }

  bool _validateCardNumber(String number) {
    final cleanNumber = number.replaceAll(' ', '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  String _formatCardNumber(String value) {
    final cleanValue = value.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleanValue.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanValue[i]);
    }

    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final cleanValue = value.replaceAll('/', '');
    if (cleanValue.length >= 2) {
      return '${cleanValue.substring(0, 2)}/${cleanValue.substring(2)}';
    }
    return cleanValue;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final cardData = {
        'card_number': _cardNumberController.text.replaceAll(' ', ''),
        'expiry_month': _expiryController.text.split('/')[0],
        'expiry_year': _expiryController.text.split('/')[1],
        'cvv': _cvvController.text,
        'name': _nameController.text,
        'card_type': _cardType,
      };

      widget.onPaymentSubmit(cardData);
    }
  }

  Widget _buildCardTypeIcon() {
    IconData icon;
    Color color;

    switch (_cardType) {
      case 'visa':
        return Image.asset('assets/visa.png', width: 40, height: 25);
      case 'mastercard':
        return Image.asset('assets/mastercard.png', width: 40, height: 25);
      case 'amex':
        return Image.asset('assets/amex.png', width: 40, height: 25);
      default:
        return const Icon(Icons.credit_card, color: lightGray, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card number field
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: white, fontSize: 16),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
            ],
            onChanged: (value) {
              setState(() {
                _cardType = _detectCardType(value);
                _isCardNumberValid = _validateCardNumber(value);
              });

              // Auto-format
              final formatted = _formatCardNumber(value);
              if (formatted != value) {
                _cardNumberController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
            decoration: InputDecoration(
              labelText: 'Card Number',
              labelStyle: const TextStyle(color: primaryGold),
              hintText: '4•••• •••• •••• ••••',
              hintStyle: const TextStyle(color: lightGray),
              filled: true,
              fillColor: darkGray,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCardNumberValid)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    _buildCardTypeIcon(),
                  ],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryGold, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: errorRed),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Card number is required';
              }
              if (!_validateCardNumber(value)) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expiry and CVV row
          Row(
            children: [
              // Expiry date
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: white, fontSize: 16),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) {
                    final formatted = _formatExpiry(value);
                    if (formatted != value) {
                      _expiryController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Expiry',
                    labelStyle: const TextStyle(color: primaryGold),
                    hintText: 'MM/YY',
                    hintStyle: const TextStyle(color: lightGray),
                    filled: true,
                    fillColor: darkGray,
                    prefixIcon: const Icon(Icons.calendar_today, color: primaryGold, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryGold, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!value.contains('/') || value.length < 5) {
                      return 'Invalid';
                    }
                    final parts = value.split('/');
                    final month = int.tryParse(parts[0]);
                    if (month == null || month < 1 || month > 12) {
                      return 'Invalid month';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),

              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  style: const TextStyle(color: white, fontSize: 16),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    labelStyle: const TextStyle(color: primaryGold),
                    hintText: '•••',
                    hintStyle: const TextStyle(color: lightGray),
                    filled: true,
                    fillColor: darkGray,
                    prefixIcon: const Icon(Icons.lock, color: primaryGold, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: primaryGold, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 3) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cardholder name
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              labelStyle: const TextStyle(color: primaryGold),
              hintText: 'Name on card',
              hintStyle: const TextStyle(color: lightGray),
              filled: true,
              fillColor: darkGray,
              prefixIcon: const Icon(Icons.person, color: primaryGold, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryGold, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Cardholder name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Security notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryGold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: primaryGold, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your payment information is encrypted and secure',
                    style: TextStyle(color: lightGray.withOpacity(0.8), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: pureBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(pureBlack),
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}