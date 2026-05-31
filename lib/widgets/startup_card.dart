import 'package:flutter/material.dart';
import '../models/startup.dart';

const _purple900 = Color(0xFF3A1C71);
const _purple600 = Color(0xFF6A4CFF);
const _purple100 = Color(0xFFEDE7FF);
const _mint = Color(0xFF00C896);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF6B7280);

class StartupCard extends StatelessWidget {
  final Startup startup;
  final VoidCallback? onTap;
  final VoidCallback? onPlayVideo;

  const StartupCard({
    super.key,
    required this.startup,
    this.onTap,
    this.onPlayVideo,
  });

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase().trim()) {
      case 'ideacao':
      case 'ideação':
      case 'nova':
        return const Color(0xFFFFB347);
      case 'mvp':
        return const Color(0xFF00A7E1);
      case 'seed':
        return _purple600;
      case 'operacao':
      case 'operação':
      case 'ativa':
        return _mint;
      case 'expansao':
      case 'expansão':
      case 'growth':
        return const Color(0xFF2F80ED);
      default:
        return _textSecondary;
    }
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'MI';
    }

    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String _formatMoney(num value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatCompact(num value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    }

    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    }

    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  double get _soldPercent {
    if (startup.totalTokens <= 0) {
      return 0;
    }

    final sold = startup.totalTokens - startup.tokensAvailable;
    return (sold / startup.totalTokens).clamp(0, 1);
  }

  double get _variationPercent {
    if (startup.initialPrice <= 0) {
      return 0;
    }

    return ((startup.currentPrice - startup.initialPrice) /
            startup.initialPrice) *
        100;
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _getStageColor(startup.stage);
    final variation = _variationPercent;
    final variationColor = variation >= 0 ? _mint : const Color(0xFFFF6B6B);
    final soldPercent = _soldPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_purple900, _purple600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _initials(startup.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startup.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _MiniChip(label: startup.sector, color: _purple600),
                            _MiniChip(label: startup.stage, color: stageColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Token',
                        style: TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatMoney(startup.currentPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _purple600,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            variation >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: variationColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1).replaceAll('.', ',')}%',
                            style: TextStyle(
                              color: variationColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                startup.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Capital',
                      value: _formatCompact(startup.capitalInvested),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Disponíveis',
                      value: '${startup.tokensAvailable}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Status',
                      value: startup.isActive ? 'Ativa' : startup.status,
                      align: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: soldPercent,
                        minHeight: 7,
                        backgroundColor: _purple100,
                        valueColor: const AlwaysStoppedAnimation(_mint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(soldPercent * 100).toStringAsFixed(0)}% vendido',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (startup.videoDemo.trim().isNotEmpty) ...[
                    IconButton(
                      tooltip: 'Ver video',
                      onPressed: onPlayVideo,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: _purple600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _textSecondary,
                    size: 20,
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

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.isEmpty ? 'Não informado' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _Metric({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
