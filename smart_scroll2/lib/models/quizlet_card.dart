// Quizlet Card Model
// SmartScroll v1 - Quizlet Integration
// Last modified: 2024-12-19 08:20:00 UTC

class QuizletCard {
  final int id;
  final QuizletCardSide side1;
  final QuizletCardSide side2;

  QuizletCard({
    required this.id,
    required this.side1,
    required this.side2,
  });

  factory QuizletCard.fromJson(Map<String, dynamic> json) {
    return QuizletCard(
      id: json['id'] ?? 0,
      side1: QuizletCardSide.fromJson(json['side1'] ?? {}),
      side2: QuizletCardSide.fromJson(json['side2'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'side1': side1.toJson(),
      'side2': side2.toJson(),
    };
  }
}

class QuizletCardSide {
  final String text;
  final String language;

  QuizletCardSide({
    required this.text,
    required this.language,
  });

  factory QuizletCardSide.fromJson(Map<String, dynamic> json) {
    return QuizletCardSide(
      text: json['text'] ?? '',
      language: json['language'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
    };
  }
}

class QuizletSet {
  final String id;
  final String creatorId;
  final int totalCards;
  final List<QuizletCard> cards;

  QuizletSet({
    required this.id,
    required this.creatorId,
    required this.totalCards,
    required this.cards,
  });

  factory QuizletSet.fromJson(Map<String, dynamic> json) {
    return QuizletSet(
      id: json['id'] ?? '',
      creatorId: json['creatorid'] ?? '',
      totalCards: json['totalcards'] ?? 0,
      cards: (json['cards'] as List<dynamic>?)
          ?.map((card) => QuizletCard.fromJson(card))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorid': creatorId,
      'totalcards': totalCards,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }
}
