import 'package:flutter/material.dart';
import '../models/startup.dart';

class StartupCard extends StatelessWidget {
  final Startup startup;
  final VoidCallback? onTap;

  const StartupCard({super.key, required this.startup, this.onTap});

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'ideacao':
        return Colors.orange;
      case 'mvp':
        return Colors.blue;
      case 'seed':
        return Colors.purple;
      case 'operacao':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      startup.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStageColor(
                        startup.stage,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      startup.stage,
                      style: TextStyle(
                        color: _getStageColor(startup.stage),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                startup.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(label: 'Setor', value: startup.sector),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Preço atual',
                      value: 'R\$ ${startup.currentPrice}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: 'Tokens',
                      value:
                          '${startup.tokensAvailable}/${startup.totalTokens}',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(label: 'Status', value: startup.status),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
