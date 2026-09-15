import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/util/responsive_layout.dart';

/// Kartu produk harus muat proporsional di semua dimensi & orientasi tablet.
void main() {
  const spacing = 24.0;

  ({int columns, double aspectRatio, double tileWidth, double tileHeight})
  metricsOf(Size area, EdgeInsets padding) {
    final m = ResponsiveLayout.productGridMetrics(
      area,
      padding: padding,
      spacing: spacing,
    );
    final usableWidth = area.width - padding.horizontal;
    final tileWidth = (usableWidth - spacing * (m.columns - 1)) / m.columns;
    return (
      columns: m.columns,
      aspectRatio: m.aspectRatio,
      tileWidth: tileWidth,
      tileHeight: tileWidth / m.aspectRatio,
    );
  }

  // Padding nyata: 20.w (ponsel) / 20.w ×1.5 (tablet) per sisi.
  const phonePadding = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  const tabletPadding = EdgeInsets.symmetric(horizontal: 30, vertical: 10);

  test('ponsel portrait: 2 kolom, bentuk kartu tetap 0.72', () {
    final m = metricsOf(const Size(393, 650), phonePadding);
    expect(m.columns, 2);
    expect(m.tileWidth, closeTo(164.5, 0.5));
    expect(m.aspectRatio, closeTo(0.72, 0.01));
  });

  test('tablet lanskap: kolom bertambah, kartu tidak raksasa', () {
    final m = metricsOf(const Size(1280, 604), tabletPadding);
    expect(m.columns, 5);
    expect(m.tileWidth, inInclusiveRange(150, 240));
    expect(m.aspectRatio, closeTo(0.95, 0.01));
    expect(m.tileHeight, lessThan(260)); // dulu 0.72 → ~312 tinggi
  });

  test('tablet portrait: kartu menyempit, tinggi tetap wajar', () {
    final m = metricsOf(const Size(800, 1060), tabletPadding);
    expect(m.columns, 4);
    expect(m.tileWidth, inInclusiveRange(150, 240));
    expect(m.aspectRatio, closeTo(0.72, 0.01));
  });

  test('area pendek (lanskap ponsel): kartu memendek, bukan memanjang', () {
    final m = metricsOf(const Size(812, 120), phonePadding);
    expect(m.aspectRatio, greaterThan(1.0));
    expect(m.tileHeight, greaterThanOrEqualTo(150));
  });

  test('kolom bertambah monoton saat area melebar', () {
    var previous = 0;
    for (final width in [393.0, 600.0, 800.0, 1024.0, 1280.0, 1600.0]) {
      final m = metricsOf(Size(width, 700), tabletPadding);
      expect(m.columns, greaterThanOrEqualTo(previous));
      previous = m.columns;
    }
  });

  test('lebar kartu selalu dalam batas min/max di semua orientasi', () {
    const sizes = [
      Size(393, 852),
      Size(600, 960),
      Size(800, 1280),
      Size(1024, 768),
      Size(1024, 1366),
      Size(1280, 800),
      Size(1366, 1024),
      Size(1920, 1080),
    ];
    for (final size in sizes) {
      final isTabletWidth = size.width >= 600;
      final m = metricsOf(
        size,
        isTabletWidth
            ? tabletPadding
            : EdgeInsets.symmetric(horizontal: size.width * 0.05),
      );
      expect(m.columns, inInclusiveRange(1, 8), reason: '$size');
      expect(m.tileWidth, inInclusiveRange(140, 250), reason: '$size');
      expect(m.tileHeight, greaterThanOrEqualTo(140), reason: '$size');
      expect(m.aspectRatio.isFinite, isTrue, reason: '$size');
    }
  });

  test('area tanpa batas tinggi tetap menghasilkan rasio terbatas', () {
    final m = ResponsiveLayout.productGridMetrics(
      const Size(1024, double.infinity),
      padding: tabletPadding,
      spacing: spacing,
    );
    expect(m.aspectRatio.isFinite, isTrue);
    expect(m.aspectRatio, greaterThan(0));
  });
}
