enum CardValue {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  jack,
  queen,
  king,
}

extension CardValueExtension on CardValue {
  String get label {
    switch (this) {
      case CardValue.ace:
        return 'As';
      case CardValue.two:
        return '2';
      case CardValue.three:
        return '3';
      case CardValue.four:
        return '4';
      case CardValue.five:
        return '5';
      case CardValue.six:
        return '6';
      case CardValue.seven:
        return '7';
      case CardValue.eight:
        return '8';
      case CardValue.nine:
        return '9';
      case CardValue.jack:
        return 'Sota';
      case CardValue.queen:
        return 'Caballo';
      case CardValue.king:
        return 'Rey';
    }
  }

  int get points {
    switch (this) {
      case CardValue.ace:
        return 1;
      case CardValue.two:
        return 2;
      case CardValue.three:
        return 3;
      case CardValue.four:
        return 4;
      case CardValue.five:
        return 5;
      case CardValue.six:
        return 6;
      case CardValue.seven:
        return 7;
      case CardValue.eight:
        return 8;
      case CardValue.nine:
        return 9;
      case CardValue.jack:
      case CardValue.queen:
      case CardValue.king:
        return 10;
    }
  }
}
