import 'package:flutter/material.dart';

import '../models/card_value_model.dart';

class CardCounter extends StatelessWidget {
  final CardValue card;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CardCounter({
    super.key,
    required this.card,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                card.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: quantity > 0 ? onRemove : null,
              icon: const Icon(Icons.remove),
              tooltip: 'Quitar una carta',
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: 'Añadir una carta',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
