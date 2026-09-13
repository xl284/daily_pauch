import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/stats_providers.dart';

class StatsOverviewScreen extends ConsumerWidget {
  const StatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(allTaskRatesProvider);
    final trendAsync = ref.watch(trendProvider(30));

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('各任务打卡率',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ratesAsync.when(
            loading: () => const SizedBox(
                height: 250, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('出错了: $e'),
            data: (data) => data.isEmpty
                ? const SizedBox(
                    height: 250, child: Center(child: Text('暂无任务')))
                : SizedBox(height: 320, child: _TaskRateChart(data: data)),
          ),
          const SizedBox(height: 24),
          const Text('近 30 天完成趋势',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          trendAsync.when(
            loading: () => const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('出错了: $e'),
            data: (data) => SizedBox(height: 200, child: _TrendChart(data: data)),
          ),
        ],
      ),
    );
  }
}

class _TaskRateChart extends StatelessWidget {
  final List<(int, String, double)> data;
  const _TaskRateChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 截断任务名到 4 字内避免溢出
    final names = data.map((e) {
      final n = e.$2;
      return n.length > 4 ? '${n.substring(0, 4)}…' : n;
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: data.length <= 1
                  ? BarChartAlignment.center
                  : BarChartAlignment.spaceAround,
              maxY: 1.15,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      '${(v * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= names.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          names[idx],
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data
                  .asMap()
                  .entries
                  .map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.$3,
                            color: scheme.primary,
                            width: data.length <= 3 ? 36 : 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
        // 底部百分比文字标签
        SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data
                .map((e) => Text(
                      '${(e.$3 * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<(DateTime, int, int)> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    final spots = data.asMap().entries.map((e) {
      final (_, due, done) = e.value;
      final rate = due == 0 ? 0.0 : done / due;
      return FlSpot(e.key.toDouble(), rate);
    }).toList();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                '${(v * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 5,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final d = data[idx].$1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month}-${d.day}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
