import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final shimmerWidth = bounds.width * 0.6;
            final start =
                -shimmerWidth +
                (bounds.width + shimmerWidth * 2) * _controller.value;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE6EEF8),
                Color(0xFFF8FBFF),
                Color(0xFFE6EEF8),
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradientTransform(start),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slidePercent, 0, 0);
  }
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
      ),
    );
  }
}

class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({
    super.key,
    required this.crossAxisCount,
    required this.childAspectRatio,
    this.itemCount = 8,
    this.padding,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.shrinkWrap = false,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final int itemCount;
  final EdgeInsets? padding;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? ResponsiveLayout.pagePadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing ?? 16.w,
          mainAxisSpacing: mainAxisSpacing ?? 16.h,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _ProductCardSkeleton(),
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.glassDecoration(borderRadius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(color: Colors.white)),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: double.infinity, height: 14.h),
                SizedBox(height: 8.h),
                ShimmerBlock(width: 96.w, height: 12.h),
                SizedBox(height: 8.h),
                ShimmerBlock(width: 72.w, height: 10.h),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShimmerBlock(width: 48.w, height: 10.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListShimmer extends StatelessWidget {
  const ListShimmer({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 82,
    this.padding,
    this.withAvatar = true,
    this.withTrailing = true,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;
  final bool withAvatar;
  final bool withTrailing;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? ResponsiveLayout.pagePadding(context),
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) => Container(
          height: itemHeight.h,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              if (withAvatar) ...[
                ShimmerBlock(width: 42.w, height: 42.w, borderRadius: 12),
                SizedBox(width: 14.w),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(width: double.infinity, height: 14.h),
                    SizedBox(height: 10.h),
                    ShimmerBlock(width: 150.w, height: 12.h),
                  ],
                ),
              ),
              if (withTrailing) ...[
                SizedBox(width: 16.w),
                ShimmerBlock(width: 72.w, height: 16.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SalesReportShimmer extends StatelessWidget {
  const SalesReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: ResponsiveLayout.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.contentMaxWidth(
                context,
                maxWidth: 980,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveLayout.gridColumns(
                    context,
                    portrait: 2,
                    landscape: 2,
                    wide: 3,
                    desktop: 4,
                  ),
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.85,
                  children: List.generate(4, (_) => const _StatCardSkeleton()),
                ),
                SizedBox(height: 32.h),
                ShimmerBlock(width: 210.w, height: 20.h),
                SizedBox(height: 16.h),
                const ListShimmer(
                  itemCount: 4,
                  itemHeight: 88,
                  padding: EdgeInsets.zero,
                  withAvatar: false,
                ),
                SizedBox(height: 24.h),
                ShimmerBlock(width: double.infinity, height: 24.h),
                SizedBox(height: 12.h),
                ShimmerBlock(width: double.infinity, height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: AppStyles.glassDecoration(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerBlock(width: 40.w, height: 40.w, borderRadius: 12),
          ShimmerBlock(width: 92.w, height: 12.h),
          ShimmerBlock(width: double.infinity, height: 18.h),
        ],
      ),
    );
  }
}
