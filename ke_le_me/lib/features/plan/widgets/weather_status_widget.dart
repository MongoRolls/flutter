import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/plan_provider.dart';

/// 天气状态 Widget：三态（加载中 / 成功 / 失败）
class WeatherStatusWidget extends StatefulWidget {
  final PlanProvider planProvider;

  const WeatherStatusWidget({super.key, required this.planProvider});

  @override
  State<WeatherStatusWidget> createState() => _WeatherStatusWidgetState();
}

class _WeatherStatusWidgetState extends State<WeatherStatusWidget> {
  final _cityController = TextEditingController();

  PlanProvider get _p => widget.planProvider;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _p.status;

    // 加载中
    if (status == PlanStatus.loadingWeather) {
      return _buildCard(
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '正在定位...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 天气失败
    if (status == PlanStatus.weatherError) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_off,
                  size: 16,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _p.errorMessage ?? '定位失败',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '输入城市名，如：上海',
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.bgSection,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (v) => _searchCity(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _searchCity,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 天气成功（inputReady 或 hasPlan 且有天气数据）
    final weather = _p.weather;
    if (weather != null) {
      final emoji = _weatherEmoji(weather.weatherCode);
      return _buildCard(
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${weather.temperature.round()}℃',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '体感 ${weather.apparentTemp.round()}℃',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (_p.cityName != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSection,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _p.cityName!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '湿度 ${weather.humidity.round()}%  ·  ${weather.weatherDescription}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh,
                size: 18,
                color: AppColors.textHint,
              ),
              onPressed: _p.retryWeather,
              tooltip: '刷新天气',
            ),
          ],
        ),
      );
    }

    // 默认空
    return const SizedBox.shrink();
  }

  void _searchCity() {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      _p.loadWeatherByCity(city);
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSection,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 48) return '🌫️';
    if (code <= 55) return '🌧️';
    if (code <= 65) return '🌧️';
    if (code <= 75) return '🌨️';
    if (code <= 82) return '🌦️';
    if (code == 95) return '⛈️';
    return '🌡️';
  }
}
