import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/plan_provider.dart';

/// 天气状态 Widget：三态（加载中 / 成功 / 失败）+ 城市可编辑
class WeatherStatusWidget extends StatefulWidget {
  final PlanProvider planProvider;

  const WeatherStatusWidget({super.key, required this.planProvider});

  @override
  State<WeatherStatusWidget> createState() => _WeatherStatusWidgetState();
}

class _WeatherStatusWidgetState extends State<WeatherStatusWidget> {
  final _cityController = TextEditingController();
  bool _showCityInput = false;

  PlanProvider get _p => widget.planProvider;

  @override
  void initState() {
    super.initState();
    _p.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _p.removeListener(_onProviderChanged);
    _cityController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    // 天气加载成功后自动收起城市输入框
    if (_p.status == PlanStatus.inputReady && _showCityInput) {
      setState(() => _showCityInput = false);
    }
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
              '正在获取天气...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 天气失败 → 直接显示城市输入
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
            _buildCitySearchRow(),
          ],
        ),
      );
    }

    // 天气成功（inputReady 或 hasPlan 且有天气数据）
    final weather = _p.weather;
    if (weather != null) {
      final emoji = _weatherEmoji(weather.weatherCode);
      return _buildCard(
        child: Column(
          children: [
            Row(
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
                // 城市名标签（可点击切换城市）
                GestureDetector(
                  onTap: () => setState(() => _showCityInput = !_showCityInput),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _p.cityName ?? '自动定位',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _showCityInput
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 展开的城市输入框
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showCityInput
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCitySearchRow(),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    // 默认空
    return const SizedBox.shrink();
  }

  /// 城市搜索输入行（复用）
  Widget _buildCitySearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityController,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '输入城市名，如：上海',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppColors.bgMain,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onSubmitted: (_) => _searchCity(),
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
            child: const Icon(Icons.search, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
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
